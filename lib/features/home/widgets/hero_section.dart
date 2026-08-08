import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Muted Minimal Keyline Accent
        Container(width: 24, height: 1, color: const Color(0xFF333333)),

        const SizedBox(height: 20),

        // Streamlined Headline
        const Text(
          "Begin a shared journey.",
          style: TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 28,
            fontWeight: FontWeight.w200,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Minimal Subtitle
        const Text(
          "Create a group and explore together in real time.",
          style: TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
