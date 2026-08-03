import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/features/maps/widgets/_waypoint_info_sheet.dart';
import 'package:open_trail/features/maps/widgets/add_waypoint_sheet.dart';
import 'package:open_trail/features/maps/widgets/floating_control_bar.dart';
import 'package:open_trail/features/maps/widgets/map_view.dart';
import 'package:open_trail/features/maps/widgets/navigation_banner.dart';
import 'package:open_trail/features/maps/widgets/ride_info_card.dart';
import 'package:open_trail/features/maps/widgets/waypoint_search_bar.dart';
import 'package:open_trail/features/maps/widgets/waypoint_search_results.dart';
import 'package:open_trail/models/navigation_step.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/live_location_service.dart';
import 'package:open_trail/services/location_search_service.dart';
import 'package:open_trail/services/navigation_service.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/services/route_service.dart';
import 'package:open_trail/services/waypoint_service.dart';
import 'package:open_trail/widgets/inline_search_bar.dart';
import 'package:open_trail/widgets/inline_search_results.dart';

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
  late final NavigationService _navigationService;
  final Map<String, List<LatLng>> _leaderRoutes = {};
  final LiveLocationService _liveLocationService = LiveLocationService();
  final WaypointService _waypointService = WaypointService();

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
  StreamSubscription<List<WaypointModel>>? _waypointSubscription;
  RideModel? _currentRide;
  bool isSatteliteMode = false;

  Position? _currentPosition;
  LatLng? _searchedLocation;
  String? _searchedLocationLabel;
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
  bool _arrivalHandled = false;

  List<NavigationStep> _steps = [];
  int _currentStep = 0;
  double _distanceToNextTurn = 0;
  bool _showTurnBanner = true;
  Timer? _turnBannerTimer;

  Timer? _searchDebounce;
  final LocationSearchService _locationSearchService = LocationSearchService();
  List<dynamic> _searchResults = [];
  bool _showSearch = false;
  bool _isSearching = false;
  String _searchQuery = "";

  bool _showWaypointSearch = false;
  bool _isWaypointSearching = false;
  String _waypointSearchQuery = "";
  List<dynamic> _waypointSearchResults = [];
  final TextEditingController _waypointSearchController =
      TextEditingController();

  late final Stream<List<RiderLocationModel>> _ridersStream;
  late final Stream<List<WaypointModel>> _waypointsStream;

  List<RiderLocationModel> _allRiders = [];
  List<RiderLocationModel> _otherRiders = [];
  List<WaypointModel> _waypoints = [];

  Future<void> _performSearch(String query) async {
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() {
        _isSearching = true;
      });

      final results = await _locationSearchService.searchPlaces(
        query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _performWaypointSearch(String query) async {
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _waypointSearchResults = [];
        _isWaypointSearching = false;
      });

      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() {
        _isWaypointSearching = true;
      });

      final results = await _locationSearchService.searchPlaces(
        query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (!mounted) return;

      setState(() {
        _waypointSearchResults = results;
        _isWaypointSearching = false;
      });
    });
  }

  void _closeWaypointSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    _searchDebounce?.cancel();
    _waypointSearchController.clear();

    setState(() {
      _showWaypointSearch = false;
      _waypointSearchQuery = "";
      _waypointSearchResults.clear();
      _isWaypointSearching = false;
    });
  }

  Future<void> _onAddWaypointPressed() async {
    await HapticFeedback.mediumImpact();

    if (!_isLeader || widget.rideDocumentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only the ride leader can add waypoints."),
        ),
      );
      return;
    }

    setState(() {
      _showWaypointSearch = true;
    });
  }

  Future<void> _onWaypointPlaceSelected(
    LatLng location,
    String locationName,
  ) async {
    _closeWaypointSearch();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddWaypointSheet(
        rideId: widget.rideDocumentId!,
        location: location,
        locationName: locationName,
      ),
    );
  }

  Future<void> _showWaypointInfo(WaypointModel waypoint) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WaypointInfoSheet(
        waypoint: waypoint,
        isLeader: _isLeader,
        onEdit: _isLeader ? () => _editWaypoint(waypoint) : null,
        onDelete: _isLeader ? () => _deleteWaypoint(waypoint) : null,
        onToggleCompleted: _isLeader
            ? () => _setWaypointCompleted(waypoint, !waypoint.completed)
            : null,
      ),
    );
  }

  Future<void> _editWaypoint(WaypointModel waypoint) async {
    Navigator.pop(context);

    if (widget.rideDocumentId == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddWaypointSheet(
        rideId: widget.rideDocumentId!,
        location: waypoint.location,
        locationName: waypoint.locationName,
        waypoint: waypoint,
      ),
    );
  }

  Future<void> _deleteWaypoint(WaypointModel waypoint) async {
    Navigator.pop(context);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Delete waypoint?"),
          content: Text(
            "${waypoint.title} will be removed from this ride itinerary.",
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true || widget.rideDocumentId == null) return;

    try {
      await _waypointService.deleteWaypoint(
        rideId: widget.rideDocumentId!,
        waypointId: waypoint.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setWaypointCompleted(
    WaypointModel waypoint,
    bool completed,
  ) async {
    Navigator.pop(context);

    if (widget.rideDocumentId == null) return;

    try {
      await _waypointService.setWaypointCompleted(
        rideId: widget.rideDocumentId!,
        waypointId: waypoint.id,
        completed: completed,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

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

    _searchDebounce?.cancel();

    setState(() {
      _showSearch = false;
      _isSearching = false;
      _searchQuery = "";
      _searchResults = [];
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
    _leaderRoutes
      ..clear()
      ..addEntries(
        snapshot.leaderRoutes.entries.map(
          (entry) => MapEntry(entry.key, List<LatLng>.of(entry.value)),
        ),
      );
    _allRiders = List.of(snapshot.allRiders);
    _otherRiders = List.of(snapshot.otherRiders);
    _searchedLocationLabel = snapshot.searchedLocationLabel;
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
      allRiders: List.of(_allRiders),
      searchedLocationLabel: _searchedLocationLabel,
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

  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<RiderLocationModel>>? _memberLocationsSubscription;

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

    if (widget.rideDocumentId != null) {
      _ridersStream = _liveLocationService.watchLocations(
        widget.rideDocumentId!,
      );

      _waypointsStream = _waypointService.watchWaypoints(
        widget.rideDocumentId!,
      );
    }

    _navigationService = NavigationService(_routeService)
      ..addListener(_handleNavigationStateChanged);

    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );

    _cacheUserProfile();
    _currentRide = widget.initialRide;
    _restoreCachedState();
    _initializeLocation();
    _listenToConvoy();
    _listenToRide();
    _listenToWaypoints();
  }

  void _handleNavigationStateChanged() {
    final navState = _navigationService.state;
    if (!mounted || navState == null) return;

    final previousStep = _currentStep;
    final wasNavigating = _isNavigating;

    setState(() {
      if (navState.currentPosition != null) {
        _currentPosition = navState.currentPosition;
      }
      _searchedLocation = navState.destination;
      _remainingRoute = List.of(navState.remainingRoute);
      _completedRoute = List.of(navState.completedRoute);
      _remainingDistanceMeters = navState.remainingDistance;
      _remainingDurationSeconds = navState.remainingDuration;
      _routeDistanceMeters = navState.remainingDistance;
      _routeDurationSeconds = navState.remainingDuration;
      _isNavigating = navState.navigating;
      _routeReceived = navState.remainingRoute.isNotEmpty;
      _steps = List.of(navState.steps);
      _currentStep = _steps.isEmpty
          ? 0
          : navState.currentStepIndex.clamp(0, _steps.length - 1).toInt();
      _distanceToNextTurn = navState.distanceToNextStep;
    });

    if (navState.navigating) {
      _animatedMapController.animateTo(
        dest: navState.snappedLocation,
        zoom: 18,
      );

      final gpsPosition = navState.currentPosition;
      if (gpsPosition != null) {
        _maybePushLocation(gpsPosition);
      }
      _scheduleLeaderRouteRefresh();
    }

    if (navState.navigating &&
        (previousStep != _currentStep ||
            (!wasNavigating && navState.steps.isNotEmpty) ||
            (_distanceToNextTurn < 200 && !_showTurnBanner))) {
      _showNavigationBanner();
    }

    if (navState.arrived && !_arrivalHandled) {
      _arrivalHandled = true;
      unawaited(_handleArrival());
    }
  }

  Future<void> _handleArrival() async {
    if (widget.rideDocumentId != null && _isLeader) {
      await _rideService.stopRideNavigation(widget.rideDocumentId!);
    }

    _startGeneralPositionStream();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("You've arrived")));
  }

  void _cacheUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName?.trim().isNotEmpty == true) {
      _cachedUserName = user!.displayName!;
    }
  }

  void _updateRideWaypoints(List<WaypointModel> waypoints) {
    if (!mounted) return;
    setState(() {
      _waypoints = List<WaypointModel>.unmodifiable(waypoints);
      if (_currentRide != null) {
        _currentRide = _currentRide!.copyWith(
          waypoints: List<WaypointModel>.from(waypoints),
        );
      }
    });
  }

void _listenToWaypoints() {
    if (widget.rideDocumentId == null || _waypointsStream == null) return;

    _waypointSubscription = _waypointsStream.listen(
      (waypoints) {
        _updateRideWaypoints(waypoints);
      },
      onError: (e) {
        debugPrint('Waypoint stream error: $e');
      },
    );
  }

  void _listenToRide() {
    if (widget.rideDocumentId == null) return;

    _rideSubscription = _rideService.watchRide(widget.rideDocumentId!).listen((
      ride,
    ) async {
      if (!mounted || ride == null) return;

      setState(() {
        _currentRide = ride;
      });

      if (ride.leaderId == _rideService.currentUserId) return;

      if (!ride.isNavigating) {
        if (_isNavigating) {
          await _navigationService.stopNavigation();

          if (!mounted) return;

          setState(() {
            _isNavigating = false;
            _routeReceived = false;
          });

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

      if (!mounted) return;

      setState(() {
        _searchedLocation = destination;
        _routeReceived = true;
      });

      await startNavigation();
    });
  }

  void _listenToConvoy() {
    if (widget.rideDocumentId == null) return;

    _memberLocationsSubscription = _ridersStream.listen(
      (riders) {
        if (!mounted) return;

        final selfId = _rideService.currentUserId;

        setState(() {
          _allRiders = riders;

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
      await _liveLocationService.updateLocation(
        rideId: widget.rideDocumentId!,
        uid: FirebaseAuth.instance.currentUser!.uid,
        displayName: _cachedUserName,
        role: _isLeader ? "leader" : "member",
        position: position,
      );
    } catch (e) {
      debugPrint("Failed to push live location: $e");
    }
  }

  Future<void> startNavigation() async {
    if (_searchedLocation == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination first.")),
      );
      return;
    }

    _arrivalHandled = false;

    if (widget.rideDocumentId != null && _isLeader) {
      await _rideService.startRideNavigation(widget.rideDocumentId!);
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      await _navigationService.startNavigation(
        start: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: _searchedLocation!,
      );
    } catch (e) {
      debugPrint("Failed to start navigation: $e");
      if (!mounted) return;
      setState(() {
        _isNavigating = false;
        _routeReceived = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to start route.")));
      _startGeneralPositionStream();
    }
  }

  Future<void> stopNavigation() async {
    await _navigationService.stopNavigation();

    if (widget.rideDocumentId != null && _isLeader) {
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

      final user = FirebaseAuth.instance.currentUser;

      if (widget.rideDocumentId != null && user != null) {
        await _liveLocationService.enableDisconnectRemoval(
          rideId: widget.rideDocumentId!,
          uid: user.uid,
        );
      }

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
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
        ).listen((position) {
          debugPrint(
            "GPS: ${position.latitude}, ${position.longitude} "
            "accuracy=${position.accuracy}m",
          );

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

    if (_showSearch) {
      _closeSearch();
    }

    try {
      await _navigationService.previewRoute(
        start: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: destination,
      );

      if (!mounted) return;

      setState(() {
        _searchedLocation = destination;
        _searchedLocationLabel = label;
        _searchResults = [];
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

      final routePoints = List<LatLng>.from(
        _navigationService.state?.remainingRoute ?? [],
      );

      // Remove any invalid coordinates.
      routePoints.removeWhere(
        (point) => !point.latitude.isFinite || !point.longitude.isFinite,
      );

      if (routePoints.isEmpty) {
        routePoints.add(destination);
      }

      if (routePoints.length == 1) {
        _animatedMapController.animateTo(dest: routePoints.first, zoom: 16);
      } else {
        _animatedMapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(routePoints),
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Route building error: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to build route.")));
    }
  }

  @override
  void dispose() {
    _persistState();
    _searchController.dispose();
    _waypointSearchController.dispose();
    _positionSubscription?.cancel();
    _navigationService.removeListener(_handleNavigationStateChanged);
    _navigationService.dispose();
    _memberLocationsSubscription?.cancel();
    _rideSubscription?.cancel();
    _turnBannerTimer?.cancel();
    _leaderRouteRefreshTimer?.cancel();
    _searchDebounce?.cancel();
    _waypointSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _rideService.currentUserId;
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: !_showSearch && !_showWaypointSearch,

      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_showSearch) {
            _closeSearch();
            return;
          }

          if (_showWaypointSearch) {
            _closeWaypointSearch();
            return;
          }
        }
      },
      child: GlassScaffold(
        body: Stack(
          children: [
            MapView(
              mapController: _animatedMapController.mapController,
              initialCenter: _initialMapCenter,
              initialZoom: _initialMapZoom,
              isSatelliteMode: isSatteliteMode,
              currentPosition: _currentPosition,
              navigationPosition: _navigationService.state?.currentPosition,
              searchedLocation: _searchedLocation,
              completedRoute: _completedRoute,
              remainingRoute: _remainingRoute,
              otherRiders: _otherRiders,
              leaderRoutes: _leaderRoutes,
              waypoints: _waypoints,
              onWaypointTap: _showWaypointInfo,
              cachedUserName: _cachedUserName,
              isLeader: _isLeader,
            ),

            if (!_isLoadingLocation && !_isLocationServiceDisabled)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 72,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            AnimatedOpacity(
                              opacity: (!_showSearch && !_showWaypointSearch)
                                  ? 1
                                  : 0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: _showSearch || _showWaypointSearch,
                                child: RideInfoCard(
                                  ride: _currentRide,
                                  distance: _routeDistanceLabel,
                                  duration: _routeDurationLabel,
                                  navigationService: _navigationService,
                                  riders: _allRiders,
                                  currentUserName: _cachedUserName,
                                  currentUserId: currentUserId,
                                  isLeader: _isLeader,
                                  isNavigating: _isNavigating,
                                ),
                              ),
                            ),

                            AnimatedOpacity(
                              opacity: _showSearch ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_showSearch,
                                child: InlineSearchBar(
                                  controller: _searchController,
                                  searchQuery: _searchQuery,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });

                                    _performSearch(value);
                                  },
                                  onCloseSearch: _closeSearch,
                                ),
                              ),
                            ),

                            AnimatedOpacity(
                              opacity: _showWaypointSearch ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_showWaypointSearch,
                                child: WaypointSearchBar(
                                  controller: _waypointSearchController,
                                  searchQuery: _waypointSearchQuery,
                                  onChanged: (value) {
                                    setState(() {
                                      _waypointSearchQuery = value;
                                    });

                                    _performWaypointSearch(value);
                                  },
                                  onClose: _closeWaypointSearch,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child:
                            (_showWaypointSearch &&
                                _waypointSearchQuery.trim().length >= 2)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: WaypointSearchResults(
                                  places: _waypointSearchResults,
                                  isLoading: _isWaypointSearching,
                                  onPlaceSelected: _onWaypointPlaceSelected,
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: NavigationBanner(
                          key: const ValueKey('navigation_banner'),
                          isVisible:
                              _isNavigating &&
                              !_isSearching &&
                              !_showSearch &&
                              !_showWaypointSearch &&
                              _steps.isNotEmpty &&
                              _showTurnBanner,
                          step: _steps.isEmpty ? null : _steps[_currentStep],
                          distanceToNextTurn: _distanceToNextTurn,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child:
                            (_hasRouteSummary &&
                                !_showSearch &&
                                !_showWaypointSearch)
                            ? Padding(
                                key: const ValueKey('route_summary_card'),
                                padding: const EdgeInsets.only(top: 10),
                                // child: RouteSummaryCard(
                                //   distance: _routeDistanceLabel,
                                //   duration: _routeDurationLabel,
                                // ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: (_showSearch && _searchQuery.trim().length >= 2)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: InlineSearchResults(
                                  places: _searchResults,
                                  isLoading: _isSearching,
                                  onPlaceSelected: _onLocationSelected,
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),

                      const Spacer(),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.9,
                                end: 1.0,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: (!_showSearch && !_showWaypointSearch)
                            ? FloatingControlBar(
                                key: const ValueKey('floating_toolbar'),
                                isSatelliteMode: isSatteliteMode,
                                isNavigating: _isNavigating,

                                onSearch: () async {
                                  await HapticFeedback.mediumImpact();

                                  setState(() {
                                    _showSearch = true;
                                  });
                                },

                                onToggleSatellite: () async {
                                  await HapticFeedback.mediumImpact();

                                  setState(() {
                                    isSatteliteMode = !isSatteliteMode;
                                  });
                                },

                                onNavigation: () async {
                                  await HapticFeedback.heavyImpact();

                                  if (_isNavigating) {
                                    await stopNavigation();
                                  } else {
                                    await startNavigation();
                                  }
                                },

                                onCenterLocation: () async {
                                  await HapticFeedback.heavyImpact();

                                  if (_currentPosition == null) return;

                                  final navState = _navigationService.state;

                                  final target = navState?.navigating == true
                                      ? navState!.snappedLocation
                                      : LatLng(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                        );

                                  _animatedMapController.animateTo(
                                    dest: target,
                                    zoom: 18,
                                  );
                                },
                                onAddWaypoint: _onAddWaypointPressed,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('empty_toolbar'),
                              ),
                      ),
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
                          await HapticFeedback.heavyImpact();
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
    required this.allRiders,
    required this.searchedLocationLabel,
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
  final List<RiderLocationModel> allRiders;
  final String? searchedLocationLabel;
}
