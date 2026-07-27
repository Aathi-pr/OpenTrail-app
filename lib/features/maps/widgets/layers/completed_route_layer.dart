import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CompletedRouteLayer extends StatelessWidget {
  const CompletedRouteLayer({super.key, required this.route});

  final List<LatLng> route;
  @override
  Widget build(BuildContext context) {
    return PolylineLayer(polylines: [
      Polyline(
        points: route,
      strokeWidth:6,
      color: Colors.grey.shade700,
      )
    ]);
  }
}
