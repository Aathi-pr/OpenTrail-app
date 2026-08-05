import 'dart:math' as math;

import 'package:flutter/material.dart';

class RainPainter extends CustomPainter {
  final double progress;
  final bool isHeavy;

  RainPainter({required this.progress, this.isHeavy = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8BB4CE).withValues(alpha: isHeavy ? 0.3 : 0.18)
      ..strokeWidth = isHeavy ? 1.6 : 1.2
      ..strokeCap = StrokeCap.round;

    final dropCount = isHeavy ? 55 : 35;
    final random = math.Random(42);

    for (int i = 0; i < dropCount; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = 0.6 + random.nextDouble() * 0.6;

      final currentY =
          (startY + (progress * size.height * speed)) % size.height;
      final dropLength = isHeavy ? 22.0 : 15.0;

      canvas.drawLine(
        Offset(startX, currentY),
        Offset(startX - 3.5, currentY + dropLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isHeavy != isHeavy;
  }
}
