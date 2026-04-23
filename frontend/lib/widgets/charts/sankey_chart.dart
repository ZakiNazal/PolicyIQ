import 'package:flutter/material.dart';
import 'dart:math' as math;

class SankeyChart extends StatelessWidget {
  final List<SankeyData> data;
  final double width;
  final double height;

  const SankeyChart({
    super.key,
    required this.data,
    this.width = 300,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: SankeyPainter(data),
    );
  }
}

class SankeyData {
  final String source;
  final String target;
  final double value;
  final Color color;

  SankeyData({
    required this.source,
    required this.target,
    required this.value,
    required this.color,
  });
}

class SankeyPainter extends CustomPainter {
  final List<SankeyData> data;
  
  SankeyPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Simple Sankey diagram implementation
    const nodeWidth = 20.0;
    final nodeSpacing = size.width / 4;
    
    // Draw nodes and connections
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      
      // Calculate positions
      final sourceX = nodeSpacing;
      final targetX = size.width - nodeSpacing - nodeWidth;
      final sourceY = 50.0 + (i * 30.0);
      final targetY = 50.0 + ((i + 1) * 30.0);
      
      // Draw connection path
      final path = Path();
      path.moveTo(sourceX + nodeWidth, sourceY);
      
      // Create curved path
      final controlPoint1 = Offset(sourceX + nodeWidth + 50, sourceY);
      final controlPoint2 = Offset(targetX - 50, targetY);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        targetX, targetY,
      );
      
      // Draw flow with gradient effect
      final flowPaint = Paint()
        ..color = item.color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, item.value / 10)
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path, flowPaint);
      
      // Draw source node
      paint.color = item.color.withOpacity(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sourceX, sourceY - 10, nodeWidth, 20),
          const Radius.circular(4),
        ),
        paint,
      );
      
      // Draw target node
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(targetX, targetY - 10, nodeWidth, 20),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
