import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThunderPainter extends CustomPainter {
  final double progress;

  ThunderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double flashOpacity = _getFlashOpacity(progress);
    if (flashOpacity <= 0) return;

    // Ambient background flash
    final flashPaint = Paint()
      ..color = const Color(0xFFB388FF).withValues(alpha: flashOpacity * 0.12);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);

    // Lightning bolt line when flash is intense
    if (flashOpacity > 0.4) {
      final boltPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashOpacity * 0.85)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

      final path = Path();
      final random = math.Random((progress * 100).toInt());
      double x = size.width * (0.35 + random.nextDouble() * 0.3);
      double y = size.height * 0.05;

      path.moveTo(x, y);
      while (y < size.height * 0.5) {
        x += (random.nextDouble() - 0.5) * 35;
        y += 15 + random.nextDouble() * 20;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, boltPaint);
    }
  }

  double _getFlashOpacity(double p) {
    // Double burst flash around p = 0.22, single burst around p = 0.72
    if (p >= 0.20 && p <= 0.24) {
      return math.sin((p - 0.20) / 0.04 * math.pi);
    } else if (p >= 0.26 && p <= 0.28) {
      return math.sin((p - 0.26) / 0.02 * math.pi) * 0.5;
    } else if (p >= 0.70 && p <= 0.74) {
      return math.sin((p - 0.70) / 0.04 * math.pi) * 0.75;
    }
    return 0.0;
  }

  @override
  bool shouldRepaint(covariant ThunderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
