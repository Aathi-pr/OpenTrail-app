import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DestinationMarkerLayer extends StatelessWidget {
  const DestinationMarkerLayer({super.key, required this.destination});

  final LatLng destination;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: destination,
          width: 45,
          height: 45,
          child: const Icon(
            Icons.square,
            color: Colors.red,
            size: 20,
          ),
        ),
      ],
    );
  }
}
