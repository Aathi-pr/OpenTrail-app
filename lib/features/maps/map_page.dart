import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/services/ride_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.rideDocumentId, this.initialRide});

  final String? rideDocumentId;
  final RideModel? initialRide;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final RideService _rideService = RideService();

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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

    _mapController.move(LatLng(position.latitude, position.longitude), 16);

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(9.9312, 76.2673),
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {
              'accessToken':
                  dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
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
                  width: 15,
                  height: 15,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(color: Colors.white),
                  ),
                ),
              ],
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _RideInfoCard(
                    rideDocumentId: widget.rideDocumentId,
                    initialRide: widget.initialRide,
                    rideService: _rideService,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {

                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black
                          ),
                          child: Icon(Icons.search_outlined, color: Colors.white,),
                        )
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
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
          height: 63,
          width: MediaQuery.of(context).size.width * 0.94,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black, // Pure black as seen in the image
            borderRadius: BorderRadius.zero,
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

            // RIGHT: Dot, Group Icon, and Count
            GestureDetector(
              onTap: () {
                // TODO: Add group action here
                debugPrint('Group icon tapped');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiny white status dot
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
                    Icons.people_outline, // Closest match to the group icon
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
            // Copy logic
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
