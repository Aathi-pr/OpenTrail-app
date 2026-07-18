import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/models/navigation_step.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/services/location_search_service.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/services/route_service.dart';
import 'package:open_trail/widgets/inline_search_bar.dart';
import 'package:open_trail/widgets/inline_search_results.dart';
import 'package:open_trail/widgets/route_summary_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.rideDocumentId, this.initialRide});

  final String? rideDocumentId;
  final RideModel? initialRide;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  static final Map<String, _MapPageSnapshot> _stateCache = {};

  late final AnimatedMapController _animatedMapController;
  final RideService _rideService = RideService();
  final RouteService _routeService = RouteService();
  final LocationSearchService _searchService = LocationSearchService();
  final Map<String, List<LatLng>> _leaderRoutes = {};
  bool get _isLeader => _currentRide?.leaderId == _rideService.currentUserId;
  int _leaderRouteRequestId = 0;
  bool _isLoadingLeaderRoutes = false;
  bool _needsLeaderRouteRefresh = false;
  Timer? _leaderRouteRefreshTimer;
  DateTime? _lastLeaderRouteRefreshAt;
  LatLng? _lastLeaderRouteLeader;
  final Map<String, LatLng> _lastLeaderRouteTargets = {};
  static const _leaderRouteRefreshInterval = Duration(seconds: 8);
  static const _leaderRouteEndpointMinDistanceMeters = 12;

  StreamSubscription<RideModel?>? _rideSubscription;
  RideModel? _currentRide;
  bool isSatteliteMode = false;

  Position? _currentPosition;
  LatLng? _searchedLocation;
  List<LatLng> _remainingRoute = [];
  List<LatLng> _completedRoute = [];
  LatLng? _restoredMapCenter;
  double? _restoredMapZoom;
  bool _restoredFromCache = false;
  bool _resumeNavigationAfterLocation = false;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  double? _remainingDistanceMeters;
  double? _remainingDurationSeconds;
  bool _isNavigating = false;
  bool _routeReceived = false;

  List<NavigationStep> _steps = [];
  int _currentStep = 0;
  double _distanceToNextTurn = 0;
  bool _showTurnBanner = true;
  Timer? _turnBannerTimer;

  String get _stateCacheKey => widget.rideDocumentId ?? '__standalone_map__';

  void _showNavigationBanner() {
    _turnBannerTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _showTurnBanner = !_isSearching;
    });

    _turnBannerTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTurnBanner = false;
      });
    });
  }

  LatLng get _initialMapCenter {
    if (_restoredMapCenter != null) return _restoredMapCenter!;
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return const LatLng(9.9312, 76.2673);
  }

  double get _initialMapZoom => _restoredMapZoom ?? 16;

  void _closeSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSearching = false;
      _searchQuery = "";
      _searchController.clear();
    });

    if (_isNavigating) {
      _showNavigationBanner();
    }
  }

  void _restoreCachedState() {
    final snapshot = _stateCache[_stateCacheKey];
    if (snapshot == null) return;

    _restoredFromCache = true;
    _resumeNavigationAfterLocation = snapshot.isNavigating;
    _currentRide = snapshot.currentRide ?? widget.initialRide;
    _currentPosition = snapshot.currentPosition;
    _searchedLocation = snapshot.searchedLocation;
    _remainingRoute = List.of(snapshot.remainingRoute);
    _completedRoute = List.of(snapshot.completedRoute);
    _restoredMapCenter = snapshot.mapCenter;
    _restoredMapZoom = snapshot.mapZoom;
    _routeDistanceMeters = snapshot.routeDistanceMeters;
    _routeDurationSeconds = snapshot.routeDurationSeconds;
    _remainingDistanceMeters = snapshot.remainingDistanceMeters;
    _remainingDurationSeconds = snapshot.remainingDurationSeconds;
    _isNavigating = snapshot.isNavigating;
    _routeReceived = snapshot.routeReceived;
    _steps = List.of(snapshot.steps);
    _currentStep = snapshot.currentStep;
    _distanceToNextTurn = snapshot.distanceToNextTurn;
    _showTurnBanner = snapshot.showTurnBanner;
    _isSearching = snapshot.isSearching;
    _searchQuery = snapshot.searchQuery;
    _searchController.text = snapshot.searchQuery;
    _otherRiders = List.of(snapshot.otherRiders);
    _leaderRoutes
      ..clear()
      ..addEntries(
        snapshot.leaderRoutes.entries.map(
          (entry) => MapEntry(entry.key, List<LatLng>.of(entry.value)),
        ),
      );
  }

  void _persistState() {
    LatLng? mapCenter = _restoredMapCenter;
    double? mapZoom = _restoredMapZoom;

    try {
      final camera = _animatedMapController.mapController.camera;
      mapCenter = camera.center;
      mapZoom = camera.zoom;
    } catch (_) {}

    _stateCache[_stateCacheKey] = _MapPageSnapshot(
      currentRide: _currentRide,
      currentPosition: _currentPosition,
      searchedLocation: _searchedLocation,
      remainingRoute: List.of(_remainingRoute),
      completedRoute: List.of(_completedRoute),
      mapCenter: mapCenter,
      mapZoom: mapZoom,
      routeDistanceMeters: _routeDistanceMeters,
      routeDurationSeconds: _routeDurationSeconds,
      remainingDistanceMeters: _remainingDistanceMeters,
      remainingDurationSeconds: _remainingDurationSeconds,
      isNavigating: _isNavigating,
      routeReceived: _routeReceived,
      steps: List.of(_steps),
      currentStep: _currentStep,
      distanceToNextTurn: _distanceToNextTurn,
      showTurnBanner: _showTurnBanner,
      isSearching: _isSearching,
      searchQuery: _searchQuery,
      otherRiders: List.of(_otherRiders),
      leaderRoutes: {
        for (final entry in _leaderRoutes.entries)
          entry.key: List<LatLng>.of(entry.value),
      },
    );
  }

  bool get _hasRouteSummary =>
      _searchedLocation != null &&
      _remainingDistanceMeters != null &&
      _remainingDurationSeconds != null;

  String get _routeDistanceLabel {
    final meters = _remainingDistanceMeters ?? 0;

    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km";
    }

    return "${meters.round()} m";
  }

  String get _routeDurationLabel {
    final seconds = (_remainingDurationSeconds ?? 0).round();
    final minutes = (seconds / 60).ceil();

    if (minutes < 60) return "$minutes min";

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) return "$hours hr";
    return "$hours hr $remainingMinutes min";
  }

  double _polylineDistanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0;

    final distance = const Distance();
    var total = 0.0;

    for (var i = 1; i < points.length; i++) {
      total += distance.as(LengthUnit.Meter, points[i - 1], points[i]);
    }

    return total;
  }

  void _setRouteSummary({
    required double distanceMeters,
    required double durationSeconds,
  }) {
    _routeDistanceMeters = distanceMeters;
    _routeDurationSeconds = durationSeconds;
    _remainingDistanceMeters = distanceMeters;
    _remainingDurationSeconds = durationSeconds;
  }

  void _updateRemainingRouteSummary(LatLng current) {
    final routeDistance = _routeDistanceMeters;
    final routeDuration = _routeDurationSeconds;

    if (routeDistance == null || routeDuration == null) return;

    final remainingDistance = _remainingRoute.isEmpty
        ? const Distance().as(LengthUnit.Meter, current, _searchedLocation!)
        : const Distance().as(
                LengthUnit.Meter,
                current,
                _remainingRoute.first,
              ) +
              _polylineDistanceMeters(_remainingRoute);

    _remainingDistanceMeters = remainingDistance;
    _remainingDurationSeconds = routeDistance <= 0
        ? routeDuration
        : routeDuration * (remainingDistance / routeDistance).clamp(0.0, 1.0);
  }

  LatLng? get _leaderLatLng {
    final leaderId = _currentRide?.leaderId ?? widget.initialRide?.leaderId;
    final currentUserId = _rideService.currentUserId;

    if (leaderId != null &&
        leaderId == currentUserId &&
        _currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }

    for (final rider in _otherRiders) {
      if ((leaderId != null && rider.userId == leaderId) ||
          rider.role == 'leader') {
        return LatLng(rider.latitude!, rider.longitude!);
      }
    }

    return null;
  }

  List<MapEntry<String, LatLng>> get _convoyRouteTargets {
    final currentUserId = _rideService.currentUserId;
    final leaderId = _currentRide?.leaderId ?? widget.initialRide?.leaderId;
    final targets = <MapEntry<String, LatLng>>[
      for (final rider in _otherRiders)
        if (rider.role != 'leader' && rider.userId != leaderId)
          MapEntry(rider.userId, LatLng(rider.latitude!, rider.longitude!)),
    ];

    if (currentUserId != null &&
        currentUserId != leaderId &&
        _currentPosition != null) {
      targets.add(
        MapEntry(
          currentUserId,
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }

    return targets;
  }

  bool _leaderRouteEndpointsChanged(
    LatLng leader,
    List<MapEntry<String, LatLng>> targets,
  ) {
    final lastLeader = _lastLeaderRouteLeader;
    final distance = const Distance();

    if (lastLeader == null ||
        distance.as(LengthUnit.Meter, leader, lastLeader) >
            _leaderRouteEndpointMinDistanceMeters) {
      return true;
    }

    if (targets.length != _lastLeaderRouteTargets.length) return true;

    for (final target in targets) {
      final lastTarget = _lastLeaderRouteTargets[target.key];

      if (lastTarget == null ||
          distance.as(LengthUnit.Meter, target.value, lastTarget) >
              _leaderRouteEndpointMinDistanceMeters) {
        return true;
      }
    }

    return false;
  }

  void _rememberLeaderRouteEndpoints(
    LatLng leader,
    List<MapEntry<String, LatLng>> targets,
  ) {
    _lastLeaderRouteLeader = leader;
    _lastLeaderRouteTargets
      ..clear()
      ..addEntries(targets);
  }

  void _clearLeaderRouteEndpoints() {
    _lastLeaderRouteLeader = null;
    _lastLeaderRouteTargets.clear();
  }

  void _scheduleLeaderRouteRefresh() {
    if (widget.rideDocumentId == null || !mounted) return;

    final now = DateTime.now();
    final lastRefresh = _lastLeaderRouteRefreshAt;
    final delay =
        lastRefresh == null ||
            now.difference(lastRefresh) >= _leaderRouteRefreshInterval
        ? Duration.zero
        : _leaderRouteRefreshInterval - now.difference(lastRefresh);

    _leaderRouteRefreshTimer?.cancel();
    _leaderRouteRefreshTimer = Timer(delay, () {
      _leaderRouteRefreshTimer = null;
      _loadAllLeaderRoutes();
    });
  }

  Future<void> _loadAllLeaderRoutes() async {
    if (_isLoadingLeaderRoutes) {
      _needsLeaderRouteRefresh = true;
      return;
    }

    _isLoadingLeaderRoutes = true;
    final requestId = ++_leaderRouteRequestId;
    final leader = _leaderLatLng;
    final targets = _convoyRouteTargets;

    try {
      if (leader == null || targets.isEmpty) {
        _clearLeaderRouteEndpoints();

        if (!mounted) return;
        setState(_leaderRoutes.clear);
        return;
      }

      _lastLeaderRouteRefreshAt = DateTime.now();

      if (_leaderRoutes.isNotEmpty &&
          !_leaderRouteEndpointsChanged(leader, targets)) {
        return;
      }

      final routes = <String, List<LatLng>>{};

      for (final target in targets) {
        try {
          final route = await _routeService.getRoute(
            start: leader,
            end: target.value,
          );
          routes[target.key] = route.geometry;
        } catch (e) {
          debugPrint("Failed to build leader route for ${target.key}: $e");
        }
      }

      if (!mounted || requestId != _leaderRouteRequestId) return;

      _rememberLeaderRouteEndpoints(leader, targets);

      setState(() {
        _leaderRoutes
          ..clear()
          ..addAll(routes);
      });
    } finally {
      _isLoadingLeaderRoutes = false;

      if (_needsLeaderRouteRefresh) {
        _needsLeaderRouteRefresh = false;
        _scheduleLeaderRouteRefresh();
      }
    }
  }

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _navigationSubscription;

  StreamSubscription<List<RiderLocationModel>>? _memberLocationsSubscription;
  List<RiderLocationModel> _otherRiders = [];

  DateTime? _lastLocationPushAt;
  LatLng? _lastPushedLatLng;
  static const _locationPushInterval = Duration(seconds: 4);
  static const _locationPushMinDistanceMeters = 8;

  // State Management Flags for Loading and Permissions
  bool _isLoadingLocation = true;
  bool _isLocationServiceDisabled = false;
  String _cachedUserName = "You";

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );

    _cacheUserProfile();
    _restoreCachedState();
    _initializeLocation();
    _listenToConvoy();
    _listenToRide();
  }

  void _cacheUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName?.trim().isNotEmpty == true) {
      _cachedUserName = user!.displayName!;
    }
  }

  void _listenToRide() {
    if (widget.rideDocumentId == null) return;

    _rideSubscription = _rideService.watchRide(widget.rideDocumentId!).listen((
      ride,
    ) async {
      if (!mounted || ride == null) return;

      _currentRide = ride;

      if (ride.leaderId == _rideService.currentUserId) return;

      if (!ride.isNavigating) {
        if (_isNavigating) {
          _navigationSubscription?.cancel();
          _navigationSubscription = null;

          setState(() {
            _isNavigating = false;
          });

          _routeReceived = false;
          _startGeneralPositionStream();
        }
        return;
      }

      if (_routeReceived) return;

      if (ride.destinationLatitude == null ||
          ride.destinationLongitude == null) {
        return;
      }

      if (_currentPosition == null) return;

      final destination = LatLng(
        ride.destinationLatitude!,
        ride.destinationLongitude!,
      );

      try {
        final route = await _routeService.getRoute(
          start: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          end: destination,
        );

        if (!mounted) return;

        setState(() {
          _searchedLocation = destination;
          _remainingRoute = List.from(route.geometry);
          _completedRoute = [];
          _setRouteSummary(
            distanceMeters: route.distanceMeters,
            durationSeconds: route.durationSeconds,
          );
          _steps = route.steps;
          _currentStep = 0;
          _distanceToNextTurn = 0;
        });

        _routeReceived = true;
        await startNavigation();
      } catch (e) {
        debugPrint("Failed to build convoy route: $e");
      }
    });
  }

  void _listenToConvoy() {
    if (widget.rideDocumentId == null) return;

    _memberLocationsSubscription = _rideService
        .watchMemberLocations(widget.rideDocumentId!)
        .listen(
          (riders) {
            if (!mounted) return;
            final selfId = _rideService.currentUserId;
            setState(() {
              _otherRiders = riders
                  .where((r) => r.userId != selfId && r.hasLocation)
                  .toList();
            });

            _scheduleLeaderRouteRefresh();
          },
          onError: (e) {
            debugPrint("Convoy stream error: $e");
          },
        );
  }

  Future<void> _maybePushLocation(Position position) async {
    if (widget.rideDocumentId == null) return;

    final current = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    final elapsedEnough =
        _lastLocationPushAt == null ||
        now.difference(_lastLocationPushAt!) > _locationPushInterval;

    final movedEnough =
        _lastPushedLatLng == null ||
        const Distance().as(LengthUnit.Meter, current, _lastPushedLatLng!) >
            _locationPushMinDistanceMeters;

    if (!elapsedEnough && !movedEnough) return;

    _lastLocationPushAt = now;
    _lastPushedLatLng = current;

    try {
      await _rideService.updateMemberLocation(
        widget.rideDocumentId!,
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
    } catch (e) {}
  }

  Future<void> startNavigation() async {
    if (_searchedLocation == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination first.")),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });
    _showNavigationBanner();

    if (widget.rideDocumentId != null &&
        widget.initialRide?.leaderId == _rideService.currentUserId) {
      await _rideService.startRideNavigation(widget.rideDocumentId!);
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _navigationSubscription?.cancel();

    _navigationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
        ).listen((position) async {
          if (!mounted) return;

          final current = LatLng(position.latitude, position.longitude);
          const distance = Distance();

          if (_remainingRoute.isNotEmpty) {
            while (_remainingRoute.length > 1 &&
                distance(current, _remainingRoute.first) < 15) {
              _completedRoute.add(_remainingRoute.removeAt(0));
            }
            setState(() {});
          }

          setState(() {
            _currentPosition = position;
            _updateRemainingRouteSummary(current);

            if (_steps.isNotEmpty && _currentStep < _steps.length) {
              final waypoint = _steps[_currentStep].waypointIndex;

              if (waypoint >= 0 && waypoint < _remainingRoute.length) {
                _distanceToNextTurn = const Distance().as(
                  LengthUnit.Meter,
                  current,
                  _remainingRoute[waypoint],
                );

                if (_distanceToNextTurn < 20 &&
                    _currentStep < _steps.length - 1) {
                  _currentStep++;
                  _showNavigationBanner();
                } else if (_distanceToNextTurn < 200 && !_showTurnBanner) {
                  _showNavigationBanner();
                }
              }
            }
          });

          _animatedMapController.animateTo(dest: current, zoom: 18);
          _maybePushLocation(position);
          _scheduleLeaderRouteRefresh();

          final remainingDistance = const Distance().as(
            LengthUnit.Meter,
            current,
            _searchedLocation!,
          );

          if (remainingDistance < 20) {
            setState(() {
              _remainingDistanceMeters = 0;
              _remainingDurationSeconds = 0;
            });
            stopNavigation();
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("You've arrived 🎉")));
            return;
          }
        }, onError: (e) {});
  }

  void stopNavigation() {
    _navigationSubscription?.cancel();
    _navigationSubscription = null;

    setState(() {
      _isNavigating = false;
    });

    if (widget.rideDocumentId != null &&
        widget.initialRide?.leaderId == _rideService.currentUserId) {
      _rideService.stopRideNavigation(widget.rideDocumentId!);
    }

    _startGeneralPositionStream();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _isLocationServiceDisabled = false;
    });

    // Check if device hardware location tracking services are active
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLocationServiceDisabled = true;
          _isLoadingLocation = false;
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      if (!_restoredFromCache) {
        _animatedMapController.animateTo(
          dest: LatLng(position.latitude, position.longitude),
          zoom: 16,
        );
      }

      _maybePushLocation(position);
      _scheduleLeaderRouteRefresh();
      _startGeneralPositionStream();

      if (_resumeNavigationAfterLocation && _searchedLocation != null) {
        _resumeNavigationAfterLocation = false;
        await startNavigation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _startGeneralPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
          });
          _maybePushLocation(position);
          _scheduleLeaderRouteRefresh();
        });
  }

  void _onLocationSelected(LatLng destination, String label) async {
    if (_currentPosition == null) return;

    if (_isSearching) {
      _closeSearch();
    }

    try {
      final route = await _routeService.getRoute(
        start: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        end: destination,
      );

      if (!mounted) return;

      setState(() {
        _searchedLocation = destination;
        _remainingRoute = List.from(route.geometry);
        _completedRoute = [];
        _setRouteSummary(
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
        );
        _steps = route.steps;
        _currentStep = 0;
        _distanceToNextTurn = 0;
      });

      if (widget.rideDocumentId != null) {
        await _rideService.updateDestination(
          widget.rideDocumentId!,
          destination: label,
          latitude: destination.latitude,
          longitude: destination.longitude,
        );
      }

      if (!mounted) return;

      _animatedMapController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.geometry),
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (e) {
      debugPrint("Route building fallback error: $e");
      final fallbackDistance = const Distance().as(
        LengthUnit.Meter,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination,
      );

      setState(() {
        _searchedLocation = destination;
        _completedRoute = [];
        _remainingRoute = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination,
        ];
        _setRouteSummary(
          distanceMeters: fallbackDistance,
          durationSeconds: fallbackDistance / 13.9,
        );
      });
    }
  }

  @override
  void dispose() {
    _persistState();
    _searchController.dispose();
    _positionSubscription?.cancel();
    _navigationSubscription?.cancel();
    _memberLocationsSubscription?.cancel();
    _rideSubscription?.cancel();
    _turnBannerTimer?.cancel();
    _leaderRouteRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: GlassScaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                initialCenter: _initialMapCenter,
                initialZoom: _initialMapZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {
                    'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                    'id': isSatteliteMode
                        ? 'mapbox/satellite-streets-v12'
                        : 'mapbox/dark-v11',
                  },
                  tileDimension: 512,
                  zoomOffset: -1,
                ),
                if (_currentPosition != null) _buildUserMarkerLayer(),
                if (_otherRiders.isNotEmpty) _buildConvoyMarkerLayer(),
                if (_searchedLocation != null) _buildDestinationMarkerLayer(),
                if (_completedRoute.isNotEmpty) _buildCompletedRouteLayer(),
                if (_remainingRoute.isNotEmpty) _buildRemainingRouteLayer(),
                if (_leaderRoutes.isNotEmpty) _buildLeaderRoutes(),
              ],
            ),

            if (!_isLoadingLocation && !_isLocationServiceDisabled)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        child: !_isSearching
                            ? _buildHeaderCardRow()
                            : InlineSearchBar(
                                controller: _searchController,
                                searchQuery: _searchQuery,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                onCloseSearch: _closeSearch,
                              ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            (_isNavigating &&
                                !_isSearching &&
                                _steps.isNotEmpty &&
                                _showTurnBanner)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: GlassCard(
                                  useOwnLayer: true,
                                  quality: GlassQuality.premium,
                                  settings: LiquidGlassSettings(
                                    thickness: 15,
                                    blur: 2,
                                    refractiveIndex: 15.12,
                                  ),
                                  shape: LiquidRoundedRectangle(
                                    borderRadius: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      // Turn Icon
                                      SizedBox(
                                        width: 36,
                                        child: Icon(
                                          iconForType(
                                            _steps[_currentStep].type,
                                          ),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Instruction
                                      Expanded(
                                        child: Text(
                                          _steps[_currentStep].instruction,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Distance
                                      SizedBox(
                                        width: 65,
                                        child: Text(
                                          "${_distanceToNextTurn.round()} m",
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: (_hasRouteSummary && !_isSearching)
                            ? Padding(
                                key: const ValueKey('route_summary_card'),
                                padding: const EdgeInsets.only(top: 10),
                                child: RouteSummaryCard(
                                  distance: _routeDistanceLabel,
                                  duration: _routeDurationLabel,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: (_isSearching && _searchQuery.trim().length >= 2)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: InlineSearchResults(
                                  searchQuery: _searchQuery,
                                  searchService: _searchService,
                                  onPlaceSelected: _onLocationSelected,
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                      const Spacer(),
                      if (!_isSearching) _buildBottomControlsRow(),
                    ],
                  ),
                ),
              ),

            // Minimal High-Contrast Loading Overlay
            if (_isLoadingLocation)
              GlassContainer(
                useOwnLayer: true,
                settings: LiquidGlassSettings(
                  thickness: 15,
                  blur: 5,
                  refractiveIndex: 15.12,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),

            if (_isLocationServiceDisabled)
              GlassCard(
                settings: LiquidGlassSettings(
                  thickness: 15,
                  blur: 5,
                  refractiveIndex: 15.12,
                ),
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.location_slash,
                      color: Colors.white38,
                      size: 44,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Location Services Disabled",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Open Trail requires device system GPS access to calculate real-time navigation streams and manage team telemetry.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: GlassButton(
                        icon: Icon(Icons.location_on_outlined),
                        label: "Turn on Location",
                        shape: LiquidRoundedRectangle(borderRadius: 50),
                        onTap: () async {
                          await Geolocator.openLocationSettings();
                          _initializeLocation();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      icon: Icon(Icons.replay_outlined),
                      onTap: _initializeLocation,
                      label: "Retry Connection",
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 120,
          height: 70,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _cachedUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _isLeader
                      ? Colors.orangeAccent
                      : Colors.lightBlueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  MarkerLayer _buildConvoyMarkerLayer() {
    return MarkerLayer(
      markers: _otherRiders.map((rider) {
        return Marker(
          point: LatLng(rider.latitude!, rider.longitude!),
          width: (rider.displayName.length * 11 + 32)
              .clamp(120, 280)
              .toDouble(),
          height: 60,
          alignment: Alignment.topCenter,
          child: _RiderMarker(rider: rider),
        );
      }).toList(),
    );
  }

  MarkerLayer _buildDestinationMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _searchedLocation!,
          width: 45,
          height: 45,
          child: const Icon(
            Icons.location_on_outlined,
            color: Colors.red,
            size: 40,
          ),
        ),
      ],
    );
  }

  PolylineLayer _buildLeaderRoutes() {
    return PolylineLayer(
      polylines: _leaderRoutes.values.map((points) {
        return Polyline(
          points: points,
          strokeWidth: 4,
          color: Colors.lightBlueAccent,
          borderStrokeWidth: 2,
          borderColor: Colors.black54,
          pattern: StrokePattern.dashed(
            segments: const [14, 10],
            patternFit: PatternFit.extendFinalDash,
          ),
        );
      }).toList(),
    );
  }

  PolylineLayer _buildCompletedRouteLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _completedRoute,
          strokeWidth: 6,
          color: Colors.grey.shade700,
        ),
      ],
    );
  }

  PolylineLayer _buildRemainingRouteLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(points: _remainingRoute, strokeWidth: 3, color: Colors.white),
      ],
    );
  }

  Widget _buildHeaderCardRow() {
    return Row(
      key: const ValueKey('info_card_row'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RideInfoCard(
            rideDocumentId: widget.rideDocumentId,
            initialRide: widget.initialRide,
            rideService: _rideService,
          ),
        ),
        if (_currentRide?.leaderId == _rideService.currentUserId) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = true;
              });
            },
            child: GlassCard(
              useOwnLayer: true,
              settings: LiquidGlassSettings(
                thickness: 15,
                refractiveIndex: 15.12,
                blur: 3,
              ),
              quality: GlassQuality.premium,
              shape: LiquidRoundedRectangle(borderRadius: 50),
              child: const Center(
                child: Icon(Icons.search_outlined, color: Colors.white70),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomControlsRow() {
    return Row(
      children: [
        GlassButton(
          shape: LiquidRoundedRectangle(borderRadius: 50),
          width: MediaQuery.of(context).size.width * 0.2,
          useOwnLayer: true,
          settings: LiquidGlassSettings(
            thickness: 15,
            refractiveIndex: 15.12,
            blur: 2,
          ),
          quality: GlassQuality.premium,
          icon: Icon(
            isSatteliteMode ? Icons.layers : Icons.layers_outlined,
            color: Colors.white,
          ),
          onTap: () {
            setState(() {
              isSatteliteMode = !isSatteliteMode;
            });
          },
        ),
        const Spacer(),
        if (_currentRide?.leaderId == _rideService.currentUserId)
          GlassButton(
            shape: LiquidRoundedRectangle(borderRadius: 50),
            width: MediaQuery.of(context).size.width * 0.4,
            useOwnLayer: true,
            settings: LiquidGlassSettings(
              thickness: 15,
              refractiveIndex: 15.12,
              blur: 2,
            ),
            quality: GlassQuality.premium,
            icon: Icon(
              _isNavigating
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.location_north_fill,
              color: Colors.white70,
            ),
            onTap: () {
              if (_isNavigating) {
                stopNavigation();
              } else {
                startNavigation();
              }
            },
          ),
        Spacer(),

        GlassButton(
          shape: LiquidRoundedRectangle(borderRadius: 50),
          width: MediaQuery.of(context).size.width * 0.2,
          useOwnLayer: true,
          settings: LiquidGlassSettings(
            thickness: 15,
            refractiveIndex: 15.12,
            blur: 2,
          ),
          quality: GlassQuality.premium,
          icon: Icon(Icons.gps_fixed, color: Colors.white),
          onTap: () {
            _animatedMapController.animateTo(
              dest: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 18,
            );
          },
        ),
      ],
    );
  }
}

class _RiderMarker extends StatelessWidget {
  const _RiderMarker({required this.rider});

  final RiderLocationModel rider;

  // ignore: unused_element
  String get _initials {
    final trimmed = rider.displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Color get _color =>
      rider.role == 'leader' ? Colors.orangeAccent : Colors.lightBlueAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(50),
            border: BoxBorder.all(color: Colors.white30),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            rider.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(.45),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RideInfoCard extends StatelessWidget {
  const _RideInfoCard({
    required this.rideDocumentId,
    required this.initialRide,
    required this.rideService,
  });

  final String? rideDocumentId;
  final RideModel? initialRide;
  final RideService rideService;

  @override
  Widget build(BuildContext context) {
    if (rideDocumentId == null) return const SizedBox.shrink();

    return StreamBuilder<RideModel?>(
      stream: rideService.watchRide(rideDocumentId!),
      initialData: initialRide,
      builder: (context, snapshot) {
        final ride = snapshot.data;

        return GlassCard(
          width: MediaQuery.of(context).size.width * 0.94,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: LiquidRoundedRectangle(borderRadius: 50),
          quality: GlassQuality.premium,
          useOwnLayer: true,
          settings: LiquidGlassSettings(
            thickness: 15,
            refractiveIndex: 15.12,
            blur: 2,
          ),
          child: _buildContent(context, snapshot, ride),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<RideModel?> snapshot,
    RideModel? ride,
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error: ${snapshot.error}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }

    if (ride == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.only(right: 16.0, top: 4.0, bottom: 4.0),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                debugPrint('Group icon tapped');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ride.memberCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: ride.rideId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride ID copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TAP TO COPY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ride.rideId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPageSnapshot {
  const _MapPageSnapshot({
    required this.currentRide,
    required this.currentPosition,
    required this.searchedLocation,
    required this.remainingRoute,
    required this.completedRoute,
    required this.mapCenter,
    required this.mapZoom,
    required this.routeDistanceMeters,
    required this.routeDurationSeconds,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.isNavigating,
    required this.routeReceived,
    required this.steps,
    required this.currentStep,
    required this.distanceToNextTurn,
    required this.showTurnBanner,
    required this.isSearching,
    required this.searchQuery,
    required this.otherRiders,
    required this.leaderRoutes,
  });

  final RideModel? currentRide;
  final Position? currentPosition;
  final LatLng? searchedLocation;
  final List<LatLng> remainingRoute;
  final List<LatLng> completedRoute;
  final LatLng? mapCenter;
  final double? mapZoom;
  final double? routeDistanceMeters;
  final double? routeDurationSeconds;
  final double? remainingDistanceMeters;
  final double? remainingDurationSeconds;
  final bool isNavigating;
  final bool routeReceived;
  final List<NavigationStep> steps;
  final int currentStep;
  final double distanceToNextTurn;
  final bool showTurnBanner;
  final bool isSearching;
  final String searchQuery;
  final List<RiderLocationModel> otherRiders;
  final Map<String, List<LatLng>> leaderRoutes;
}

IconData iconForType(int type) {
  switch (type) {
    case 0:
      return Icons.turn_left;

    case 1:
      return Icons.turn_right;

    case 2:
      return Icons.turn_sharp_left;

    case 3:
      return Icons.turn_sharp_right;

    case 4:
      return Icons.turn_slight_left;

    case 5:
      return Icons.turn_slight_right;

    case 6:
      return Icons.straight;

    case 7:
      return Icons.roundabout_right;

    case 9:
      return Icons.u_turn_left;

    case 10:
      return Icons.flag;

    case 11:
      return Icons.navigation;

    default:
      return Icons.navigation;
  }
}
