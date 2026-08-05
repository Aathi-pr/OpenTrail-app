import 'package:flutter/material.dart';

class FogPainter extends CustomPainter {
  final double progress;

  FogPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    for (int i = 0; i < 4; i++) {
      final speed = 0.06 + (i * 0.03);
      final offsetProgress = (progress * speed + (i * 0.25)) % 1.0;
      final x = (size.width * 1.6 * offsetProgress) - (size.width * 0.3);
      final y = size.height * (0.28 + (i * 0.16));

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * 0.95,
          height: 80 + (i * 22),
        ),
        fogPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
