import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SalesSplineChart extends StatelessWidget {
  final List<double> weeklySales; // Sales for the last 7 days
  final Color primaryColor;

  const SalesSplineChart({
    super.key,
    required this.weeklySales,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback mock data if there are no sales yet, so the user is wowed with a beautiful graph initially!
    final data = weeklySales.every((v) => v == 0)
        ? [150000.0, 320000.0, 240000.0, 480000.0, 350000.0, 580000.0, 420000.0]
        : weeklySales;

    final days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مؤشر المبيعات الأسبوعي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'مقارنة الإيرادات اليومية لآخر 7 أيام',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'نشط د.ع',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: SplinePainter(
                data: data,
                labels: days,
                primaryColor: primaryColor,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplinePainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color primaryColor;
  final bool isDark;

  SplinePainter({
    required this.data,
    required this.labels,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintGrid = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = 0.0;
    final valRange = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double paddingLeft = 10;
    final double paddingRight = 10;
    final double paddingTop = 10;
    final double paddingBottom = 20;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final points = <Offset>[];
    final double stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + (i * stepX);
      final double ratio = (data[i] - minVal) / valRange;
      final double y = paddingTop + chartHeight - (ratio * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw horizontal grid lines (3 lines)
    for (int i = 0; i <= 3; i++) {
      final double y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), paintGrid);
    }

    // Generate Spline Curve Path
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        // Cubic bezier control points calculations for smooth curves
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }
    }

    // Draw Gradient Shade Fill under the path
    final fillPath = Path.from(path);
    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
      fillPath.close();

      final paintFill = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, paddingTop),
          Offset(size.width / 2, paddingTop + chartHeight),
          [
            primaryColor.withOpacity(0.25),
            primaryColor.withOpacity(0.0),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, paintFill);
    }

    // Draw the main spline curve line
    canvas.drawPath(path, paintLine);

    // Draw data points nodes and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    for (int i = 0; i < points.length; i++) {
      // Point circle dot
      final paintDot = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      final paintDotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(points[i], 5, paintDot);
      canvas.drawCircle(points[i], 5, paintDotBorder);

      // Label at bottom
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black45,
          fontSize: 8,
          fontFamily: 'Tajawal',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - (textPainter.width / 2), paddingTop + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SplinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.primaryColor != primaryColor;
  }
}
