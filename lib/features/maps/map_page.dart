import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
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

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.rideDocumentId, this.initialRide});

  final String? rideDocumentId;
  final RideModel? initialRide;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  final RideService _rideService = RideService();
  final RouteService _routeService = RouteService();
  final LocationSearchService _searchService = LocationSearchService();

  StreamSubscription<RideModel?>? _rideSubscription;
  RideModel? _currentRide;
  bool isSatteliteMode = false;

  Position? _currentPosition;
  LatLng? _searchedLocation;
  List<LatLng> _remainingRoute = [];
  List<LatLng> _completedRoute = [];
  bool _isNavigating = false;
  bool _routeReceived = false;

  List<NavigationStep> _steps = [];
  int _currentStep = 0;
  double _distanceToNextTurn = 0;
  bool _showTurnBanner = true;
  Timer? _turnBannerTimer;
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

          final remainingDistance = const Distance().as(
            LengthUnit.Meter,
            current,
            _searchedLocation!,
          );

          if (remainingDistance < 20) {
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

      _animatedMapController.animateTo(
        dest: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );

      _maybePushLocation(position);
      _startGeneralPositionStream();
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
        });
  }

  void _onLocationSelected(LatLng destination, String label) async {
    if (_currentPosition == null) return;

    try {
      final route = await _routeService.getRoute(
        start: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        end: destination,
      );

      setState(() {
        _searchedLocation = destination;
        _remainingRoute = List.from(route.geometry);
        _completedRoute = [];
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

      _animatedMapController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.geometry),
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (e) {
      debugPrint("Route building fallback error: $e");
      setState(() {
        _searchedLocation = destination;
        _completedRoute = [];
        _remainingRoute = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination,
        ];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionSubscription?.cancel();
    _navigationSubscription?.cancel();
    _memberLocationsSubscription?.cancel();
    _rideSubscription?.cancel();
    _turnBannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: const MapOptions(
              initialCenter: LatLng(9.9312, 76.2673),
              initialZoom: 16,
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
              // if (_currentPosition !=null && _otherRiders.isNotEmpty) _buildRouteConvoyToRider(),
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
                              onCloseSearch: () => setState(() {
                                _isSearching = false;
                                _searchQuery = "";
                                _searchController.clear();

                                if (_isNavigating) {
                                  _showNavigationBanner();
                                }
                              }),
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
                                shape: LiquidRoundedRectangle(borderRadius: 20),
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
                                        iconForType(_steps[_currentStep].type),
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
            Container(
              color: Colors.black,
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
                  color: Colors.orangeAccent,
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

  //   PolylineLayer _buildRouteConvoyToRider() {
  //   if (_currentPosition == null || _otherRiders.isEmpty) {
  //     return const PolylineLayer(polylines: []);
  //   }

  //   final List<Polyline> linesToRiders = _otherRiders.map((rider) {
  //     return Polyline(
  //       points: [
  //         LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
  //         LatLng(
  //           rider
  //               .latitude!,
  //           rider.longitude!,
  //         ),
  //       ],
  //       strokeWidth: 6,
  //       color: Colors.grey.shade700,
  //       strokeCap: StrokeCap.round,
  //       strokeJoin: StrokeJoin.round,
  //     );
  //   }).toList(); // Convert the iterable back into a List<Polyline>

  //   // 3. Return the layer containing all your generated lines
  //   return PolylineLayer(polylines: linesToRiders);
  // }


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
            border: BoxBorder.all(
              color: Colors.white30
            )
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
