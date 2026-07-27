import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LeaderRouteLayer extends StatelessWidget {
  const LeaderRouteLayer({super.key, required this.routes});
  final Map<String, List<LatLng>> routes;

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: routes.values.map((points) {
        return Polyline(points: points,
        strokeWidth: 4,
        color: Colors.lightBlueAccent,
        borderStrokeWidth: 2,
        borderColor: Colors.black54,
        pattern: StrokePattern.dashed(segments: const [14,10],
        patternFit: PatternFit.extendFinalDash,
        )
        );
      }).toList(),
    );
  }
}
