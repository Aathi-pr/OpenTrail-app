import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowPainter extends CustomPainter {
  final double progress;
  final bool isSun;

  GlowPainter({required this.progress, required this.isSun});

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = math.sin(progress * 2 * math.pi);
    final double baseRadius = isSun ? 130.0 : 95.0;
    final double currentRadius = baseRadius + (pulse * 12.0);

    final Offset center = isSun
        ? Offset(size.width * 0.8, size.height * 0.12)
        : Offset(size.width * 0.2, size.height * 0.15);

    final Color primaryColor = isSun
        ? const Color(0xFFFF9100) // Amber
        : const Color(0xFF90CAF9); // Soft Ice Blue

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isSun ? 0.20 : 0.12),
          primaryColor.withValues(alpha: 0.04),
          primaryColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isSun != isSun;
  }
}
