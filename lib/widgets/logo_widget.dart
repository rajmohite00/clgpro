import 'dart:math';
import 'package:flutter/material.dart';

class DocVerifyLogo extends StatelessWidget {
  final double size;
  final Color color;
  final double glowOpacity;

  const DocVerifyLogo({
    super.key,
    required this.size,
    required this.color,
    this.glowOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(color: color, glowOpacity: glowOpacity),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  final double glowOpacity;

  _LogoPainter({required this.color, required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Glowing effect
    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3 * glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      // Draw a glowing hex
      _drawHexagon(canvas, center, radius * 0.9, glowPaint);
    }

    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Outer Hexagon
    _drawHexagon(canvas, center, radius * 0.85, paintStroke);

    // 2. Cyber Eye - Outer Leaf
    final eyeWidth = w * 0.6;
    final eyeHeight = h * 0.35;
    final pathEye = Path();
    pathEye.moveTo(center.dx - eyeWidth / 2, center.dy);
    pathEye.quadraticBezierTo(center.dx, center.dy - eyeHeight, center.dx + eyeWidth / 2, center.dy);
    pathEye.quadraticBezierTo(center.dx, center.dy + eyeHeight, center.dx - eyeWidth / 2, center.dy);

    canvas.drawPath(pathEye, paintStroke);

    // 3. Iris
    final irisRadius = w * 0.15;
    canvas.drawCircle(center, irisRadius, paintStroke);
    
    // 4. Pupil
    final pupilRadius = w * 0.06;
    canvas.drawCircle(center, pupilRadius, paintFill);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // Pointed at top: start at -90 degrees
      final double angle = (i * 60 - 30) * pi / 180;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glowOpacity != glowOpacity;
  }
}
