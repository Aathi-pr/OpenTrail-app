import 'package:flutter/material.dart';

class RideSummaryGrid extends StatelessWidget {
  const RideSummaryGrid({
    super.key,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.onlineRiders,
    required this.totalRiders,
  });

  final String distance;
  final String duration;
  final String averageSpeed;
  final int onlineRiders;
  final int totalRiders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(title: "DISTANCE", value: distance),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(title: "DURATION", value: duration),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(title: "AVG SPEED", value: averageSpeed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                title: "RIDERS",
                value: "$onlineRiders / $totalRiders",
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
