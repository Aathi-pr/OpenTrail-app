import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.distance,
    required this.duration,
  });

  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useOwnLayer: true,
      quality: GlassQuality.premium,
      settings: LiquidGlassSettings(
        thickness: 15,
        blur: 2,
        refractiveIndex: 15.12,
      ),
      shape: LiquidRoundedRectangle(borderRadius: 50),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RouteSummaryItem(
            icon: CupertinoIcons.map,
            value: distance,
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.white24,
          ),
          RouteSummaryItem(
            icon: CupertinoIcons.clock,
            value: duration,
            label: 'Time',
          ),
        ],
      ),
    );
  }
}

class RouteSummaryItem extends StatelessWidget {
  const RouteSummaryItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
