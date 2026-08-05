import 'package:flutter/material.dart';

class CloudsPainter extends CustomPainter {
  final double progress;

  CloudsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    for (int i = 0; i < 3; i++) {
      final double speed = (i + 1) * 0.15;
      final double offsetProgress = (progress * speed + (i * 0.33)) % 1.0;
      final double x = size.width * offsetProgress * 1.4 - (size.width * 0.2);
      final double y = size.height * (0.08 + (i * 0.1));

      canvas.drawCircle(Offset(x, y), 80 + (i * 20), cloudPaint);
      canvas.drawCircle(Offset(x + 50, y - 10), 60 + (i * 15), cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CloudsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
