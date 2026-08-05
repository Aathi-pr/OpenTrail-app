import 'dart:math' as math;
import 'package:flutter/material.dart';

class SnowPainter extends CustomPainter {
  final double progress;

  SnowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    final random = math.Random(88);
    const flakeCount = 45;

    for (int i = 0; i < flakeCount; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = 0.25 + random.nextDouble() * 0.35;
      final radius = 1.2 + random.nextDouble() * 2.2;

      final currentY =
          (startY + (progress * size.height * speed)) % size.height;
      final sway = math.sin((progress * 2 * math.pi) + i) * 10.0;

      canvas.drawCircle(
        Offset((startX + sway) % size.width, currentY),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SnowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
