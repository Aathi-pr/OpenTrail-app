import 'dart:math' as math;
import 'package:flutter/material.dart';

class WindPainter extends CustomPainter {
  final double progress;

  WindPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF80CBC4).withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = math.Random(60);
    const lineCount = 12;

    for (int i = 0; i < lineCount; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = 0.7 + random.nextDouble() * 0.5;
      final lineLength = 50.0 + random.nextDouble() * 70.0;

      final currentX =
          (startX + (progress * size.width * speed)) %
              (size.width + lineLength) -
          lineLength;
      final waveY = startY + math.sin((progress * 2 * math.pi) + i) * 5.0;

      final path = Path()
        ..moveTo(currentX, waveY)
        ..quadraticBezierTo(
          currentX + (lineLength * 0.5),
          waveY - 6.0,
          currentX + lineLength,
          waveY,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WindPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
