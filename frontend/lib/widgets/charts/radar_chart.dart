import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/sim_models.dart';
import '../../theme/app_theme.dart';

class RadarChart extends StatelessWidget {
  final List<SimKnob> knobs;

  const RadarChart({super.key, required this.knobs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 160),
      painter: RadarPainter(knobs),
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<SimKnob> knobs;
  final int sides = 8;
  final double radius = 70;

  RadarPainter(this.knobs);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid
    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * 3.14159 / sides) - 3.14159 / 2;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw axes
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * 3.14159 / sides) - 3.14159 / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Draw data
    if (knobs.length >= sides) {
      final dataPaint = Paint()
        ..color = AppTheme.accentCyan.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final dataStrokePaint = Paint()
        ..color = AppTheme.accentCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final dataPath = Path();
      for (int i = 0; i < sides; i++) {
        final knob = knobs[i];
        final denom = (knob.max - knob.min);
        final normalizedValue =
            denom == 0 ? 0.0 : (knob.value - knob.min) / denom;
        final angle = (i * 2 * 3.14159 / sides) - 3.14159 / 2;
        final x = center.dx + radius * normalizedValue * math.cos(angle);
        final y = center.dy + radius * normalizedValue * math.sin(angle);
        if (i == 0) {
          dataPath.moveTo(x, y);
        } else {
          dataPath.lineTo(x, y);
        }
      }
      dataPath.close();
      canvas.drawPath(dataPath, dataPaint);
      canvas.drawPath(dataPath, dataStrokePaint);

      // Draw points
      for (int i = 0; i < sides; i++) {
        final knob = knobs[i];
        final denom = (knob.max - knob.min);
        final normalizedValue =
            denom == 0 ? 0.0 : (knob.value - knob.min) / denom;
        final angle = (i * 2 * 3.14159 / sides) - 3.14159 / 2;
        final x = center.dx + radius * normalizedValue * math.cos(angle);
        final y = center.dy + radius * normalizedValue * math.sin(angle);
        
        final pointPaint = Paint()
          ..color = knob.accentColor
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

