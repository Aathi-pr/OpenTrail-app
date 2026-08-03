import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RemainingRouteLayer extends StatelessWidget {
  const RemainingRouteLayer({super.key, required this.route});

  final List<LatLng> route;
  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [Polyline(points: route, color: Colors.lightGreenAccent, strokeWidth: 3)],
    );
  }
}
