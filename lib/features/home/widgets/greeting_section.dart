import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key, required this.name});

  final String name;

  String get greeting {
    final hour = DateTime.now().hour;

    if (hour >= 23 || hour < 5) {
      return "LATE NIGHT";
    }
    if (hour < 12) {
      return "GOOD MORNING";
    }
    if (hour < 17) {
      return "GOOD AFTERNOON";
    }

    return "GOOD EVENING";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time Indicator Subtitle
        Text(
          greeting,
          style: const TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.5,
          ),
        ),

        const SizedBox(height: 8),

        // Display Name Heading
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 36,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
