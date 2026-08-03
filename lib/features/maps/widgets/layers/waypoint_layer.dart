import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:open_trail/models/waypoint_model.dart';

class WaypointLayer extends StatelessWidget {
  const WaypointLayer({
    super.key,
    required this.waypoints,
    required this.onWaypointTap,
  });

  final List<WaypointModel> waypoints;
  final ValueChanged<WaypointModel> onWaypointTap;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: waypoints.map((waypoint) {
        return Marker(
          point: waypoint.location,
          width: 140,
          height: 72,
          child: _WaypointMarker(
            waypoint: waypoint,
            onTap: () => onWaypointTap(waypoint),
          ),
        );
      }).toList(),
    );
  }
}

class _WaypointMarker extends StatelessWidget {
  const _WaypointMarker({required this.waypoint, required this.onTap});

  final WaypointModel waypoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: waypoint.completed
                    ? Colors.white54
                    : waypoint.categoryColor.withValues(alpha: .75),
              ),
            ),
            child: Text(
              waypoint.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_pin,
                color: waypoint.completed
                    ? Colors.white70
                    : waypoint.categoryColor,
                size: 34,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Icon(
                  waypoint.completed ? Icons.check : waypoint.categoryIcon,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
