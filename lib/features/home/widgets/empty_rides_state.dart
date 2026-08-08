import 'package:flutter/material.dart';

class EmptyRidesState extends StatelessWidget {
  final String message;
  const EmptyRidesState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.explore_outlined, color: Color(0xFF242424), size: 48),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
