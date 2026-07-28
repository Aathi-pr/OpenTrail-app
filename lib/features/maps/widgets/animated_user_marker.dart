import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';

class AnimatedUserMarker extends StatelessWidget {
  const AnimatedUserMarker({
    super.key,
    required this.position,
    required this.heading,
    required this.userName,
    required this.isLeader,
  });

  final LatLng position;
  final double heading;
  final String userName;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Transform.rotate(
          angle: heading * math.pi / 180,
          child: FaIcon(
            FontAwesomeIcons.locationArrow,
            size: 30,
            color: isLeader ? Colors.orangeAccent : const Color(0xFF4DA3FF),
          ),
        ),
      ],
    );
  }
}
