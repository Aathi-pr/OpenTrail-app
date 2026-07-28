import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/widgets/feedback/glass_progress_indicator.dart';

class RideProgressCard extends StatelessWidget {
  const RideProgressCard({
    super.key,
    required this.progress,
    required this.completedDistance,
    required this.totalDistance,
    required this.remainingDistance,
    required this.remainingDuration,
  });

  final double progress;
  final double completedDistance;
  final double totalDistance;
  final double remainingDistance;
  final double remainingDuration;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.toStringAsFixed(0)} m";
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    }
    return "${duration.inMinutes} min";
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "RIDE PROGRESS",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                "${percent.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: GlassProgressIndicator.linear(
              value: progress,
              backgroundColor: Colors.white12,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _ProgressMetric(
                title: "COMPLETED",
                value: "${_formatDistance(completedDistance)} / ${_formatDistance(totalDistance)}",
              )),
              Expanded(child: _ProgressMetric(
                title: "REMAINING",
                value: _formatDistance(remainingDistance),
              )),
              Expanded(child: _ProgressMetric(
                title: 'ETA',
                value: _formatDuration(remainingDuration),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.title,
    required this.value,
    });
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            letterSpacing: 1,
          ),
          ),

          const SizedBox(height: 6,),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          )
      ],
    );
  }
}
