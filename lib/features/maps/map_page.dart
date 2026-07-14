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
import 'package:open_trail/delegates/location_search_delegate.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/services/route_service.dart';

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
  StreamSubscription<RideModel?>? _rideSubscription;
  RideModel? _currentRide;

  Position? _currentPosition;
  LatLng? _searchedLocation;
  List<LatLng> _remainingRoute = [];
  List<LatLng> _completedRoute = [];
  bool _isNavigating = false;
  bool _routeReceived = false;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _navigationSubscription;

  StreamSubscription<List<RiderLocationModel>>? _memberLocationsSubscription;
  List<RiderLocationModel> _otherRiders = [];

  DateTime? _lastLocationPushAt;
  LatLng? _lastPushedLatLng;
  static const _locationPushInterval = Duration(seconds: 4);
  static const _locationPushMinDistanceMeters = 8;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );

    _initializeLocation();
    _listenToConvoy();
    _listenToRide();
  }

  void _listenToRide() {
    if (widget.rideDocumentId == null) return;

    _rideSubscription = _rideService.watchRide(widget.rideDocumentId!).listen((
      ride,
    ) async {
      if (!mounted || ride == null) return;

      _currentRide = ride;

      // Ignore updates if I'm the leader.
      if (ride.leaderId == _rideService.currentUserId) {
        return;
      }

      // Leader stopped navigation.
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

      // Already following this route.
      if (_routeReceived) return;

      // Destination not set yet.
      if (ride.destinationLatitude == null ||
          ride.destinationLongitude == null) {
        return;
      }

      // Wait until GPS is available.
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
          _remainingRoute = List.from(route);
          _completedRoute = [];
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
            debugPrint("❌ Convoy stream error: $e");
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
      // ignore: empty_catches
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
          debugPrint("📍 ${position.latitude}, ${position.longitude}");
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
          });

          _animatedMapController.animateTo(dest: current, zoom: 18);

          _maybePushLocation(position);

          final remainingDistance = const Distance().as(
            LengthUnit.Meter,
            current,
            _searchedLocation!,
          );

          debugPrint("Remaining: ${remainingDistance.toStringAsFixed(1)} m");

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

    // Only the leader should notify everyone that navigation stopped.
    if (widget.rideDocumentId != null &&
        widget.initialRide?.leaderId == _rideService.currentUserId) {
      _rideService.stopRideNavigation(widget.rideDocumentId!);
    }

    _startGeneralPositionStream();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _navigationSubscription?.cancel();
    _memberLocationsSubscription?.cancel();
    _rideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) return;

    setState(() {
      _currentPosition = position;
    });

    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: 16,
    );

    _maybePushLocation(position);

    _startGeneralPositionStream();
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

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // floatingActionButton: FloatingActionButton.extended(
      //   shape: Border.all(style: BorderStyle.solid),
      //   backgroundColor: Colors.black,
      //   foregroundColor: Colors.white,
      //   onPressed: () {
      //     if (_isNavigating) {
      //       stopNavigation();
      //     } else {
      //       startNavigation();
      //     }
      //   },
      //   icon: Icon(_isNavigating ? Icons.stop : Icons.navigation),
      //   label: Text(_isNavigating ? "Stop" : "Start"),
      // ),
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
                  'id': 'mapbox/dark-v11',
                },
                tileDimension: 512,
                zoomOffset: -1,
              ),

              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 120,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: Builder(
                        builder: (context) {
                          final user = FirebaseAuth.instance.currentUser;

                          final name =
                              user?.displayName?.trim().isNotEmpty == true
                              ? user!.displayName!
                              : "You";

                          return Column(
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
                                  name,
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

              if (_otherRiders.isNotEmpty)
                MarkerLayer(
                  markers: _otherRiders.map((rider) {
                    return Marker(
                      point: LatLng(rider.latitude!, rider.longitude!),
                      width: 46,
                      height: 56,
                      child: _RiderMarker(rider: rider),
                    );
                  }).toList(),
                ),

              if (_searchedLocation != null)
                MarkerLayer(
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
                ),

              if (_completedRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _completedRoute,
                      strokeWidth: 6,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),

              if (_remainingRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _remainingRoute,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ],
                ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RideInfoCard(
                          rideDocumentId: widget.rideDocumentId,
                          initialRide: widget.initialRide,
                          rideService: _rideService,
                        ),
                      ),

                      const SizedBox(width: 12),

                     if (_currentRide?.leaderId == _rideService.currentUserId)
                        GestureDetector(
                          onTap: () async {
                            final result =
                                await showSearch<Map<String, dynamic>?>(
                                  context: context,
                                  delegate: LocationSearchDelegate(),
                                );

                            if (result == null) return;

                            final coordinates =
                                result['geometry']['coordinates'];

                            final lon = (coordinates[0] as num).toDouble();
                            final lat = (coordinates[1] as num).toDouble();

                            final destination = LatLng(lat, lon);

                            if (_currentPosition == null) return;

                            try {
                              final route = await _routeService.getRoute(
                                start: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                end: destination,
                              );

                              setState(() {
                                _searchedLocation = destination;
                                _remainingRoute = List.from(route);
                                _completedRoute = [];
                              });

                              if (widget.rideDocumentId != null) {
                                await _rideService.updateDestination(
                                  widget.rideDocumentId!,
                                  destination:
                                      result['place_name'] ?? 'Destination',
                                  latitude: destination.latitude,
                                  longitude: destination.longitude,
                                );
                              }

                              _animatedMapController.animatedFitCamera(
                                cameraFit: CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(route),
                                  padding: const EdgeInsets.all(60),
                                ),
                              );
                            } catch (e) {
                              debugPrint("Route error: $e");

                              setState(() {
                                _searchedLocation = destination;
                                _completedRoute = [];
                                _remainingRoute = [
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  destination,
                                ];
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Couldn't fetch route. Showing straight line instead.",
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 57,
                            height: 57,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.search_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_currentRide?.leaderId == _rideService.currentUserId)
          Positioned(
            bottom: 30,
            right: 20,
            child: Container(
              width: 57,
              height: 57,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(
                  _isNavigating
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.location_north_line,
                  color: Colors.white70,
                ),
                onPressed: () {
                  if (_isNavigating) {
                    stopNavigation();
                  } else {
                    startNavigation();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pin showing a convoy member's initials + name label.
class _RiderMarker extends StatelessWidget {
  const _RiderMarker({required this.rider});

  final RiderLocationModel rider;

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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            rider.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            overflow: TextOverflow.ellipsis,
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

        return Container(
          height: 57,
          width: MediaQuery.of(context).size.width * 0.94,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.black),
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
