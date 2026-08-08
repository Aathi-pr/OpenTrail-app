import 'package:flutter/material.dart';

class WeatherSummary extends StatelessWidget {
  const WeatherSummary({
    super.key,
    required this.temperature,
    required this.description,
    required this.location,
    required this.isLoading,
  });

  final double? temperature;
  final String description;
  final String location;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Render skeleton placeholder if loading without cached temperature
    if (isLoading && temperature == null) {
      return const _WeatherSummarySkeleton();
    }

    final tempDisplay = temperature != null
        ? "${temperature!.round()}°"
        : "--°";
    final formattedDescription = description.trim().toUpperCase();
    final formattedLocation = location.trim().toUpperCase();

    // Safely assemble metadata without orphaned bullets
    final metaParts = [
      if (formattedDescription.isNotEmpty) formattedDescription,
      if (formattedLocation.isNotEmpty) formattedLocation,
    ];
    final metaText = metaParts.join("  •  ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Temperature Display
        Text(
          tempDisplay,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 76,
            fontWeight: FontWeight.w100,
            height: 0.9,
            letterSpacing: -3,
          ),
        ),

        const SizedBox(height: 10),

        // Tracked Weather Metadata
        if (metaText.isNotEmpty)
          Text(
            metaText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.0,
            ),
          ),
      ],
    );
  }
}

class _WeatherSummarySkeleton extends StatelessWidget {
  const _WeatherSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Temperature Block Skeleton
        Container(
          width: 120,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        const SizedBox(height: 12),

        // Subtitle Line Skeleton
        Container(
          width: 190,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
