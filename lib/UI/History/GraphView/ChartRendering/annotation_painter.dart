import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_annotation.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class AnnotationPainter {
  static void paint<D>(
    Canvas canvas,
    ChartGeometry geometry,
    ChartAxis<D> xAxis,
    ChartAxis<dynamic> yAxis,
    List<ChartAnnotation<D>> verticalAnnotations,
    List<ChartAnnotation<dynamic>> horizontalAnnotations,
    ChartStyle style,
  ) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw VERTICAL annotations (X-axis)
    for (final annotation in verticalAnnotations) {
      final double? x = xAxis.toDouble(annotation.value);
      if (x == null || x < geometry.bounds.minX || x > geometry.bounds.maxX) {
        continue;
      }

      final double xPos = geometry
          .normalizedXToScreen((x - geometry.bounds.minX) / geometry.xRange);

      paint.color = annotation.color.withValues(alpha: 0.5);
      _drawDashedLine(
        canvas,
        paint,
        Offset(xPos, geometry.topMargin),
        Offset(xPos, geometry.size.height - geometry.bottomMargin),
        isVertical: true,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: annotation.label,
          style: (annotation.textStyle ?? style.annotationLabelStyle).copyWith(
            color: annotation.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(xPos + 4, geometry.topMargin + 4),
      );
    }

    // Draw HORIZONTAL annotations (Y-axis)
    for (final annotation in horizontalAnnotations) {
      final double y = yAxis.toDouble(annotation.value);
      if (y < geometry.bounds.minY || y > geometry.bounds.maxY) {
        continue;
      }

      final double yPos = geometry
          .normalizedYToScreen((y - geometry.bounds.minY) / geometry.yRange);

      paint.color = annotation.color.withValues(alpha: 0.5);
      _drawDashedLine(
        canvas,
        paint,
        Offset(geometry.leftMargin, yPos),
        Offset(geometry.size.width - geometry.rightMargin, yPos),
        isVertical: false,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: annotation.label,
          style: (annotation.textStyle ?? style.annotationLabelStyle).copyWith(
            color: annotation.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw label on the left, slightly above line
      tp.paint(
        canvas,
        Offset(geometry.leftMargin + 4, yPos - tp.height - 2),
      );
    }
  }

  static void _drawDashedLine(Canvas canvas, Paint paint, Offset p1, Offset p2,
      {required bool isVertical}) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;

    if (isVertical) {
      double startY = p1.dy;
      final double endY = p2.dy;
      while (startY < endY) {
        canvas.drawLine(
          Offset(p1.dx, startY),
          Offset(p1.dx, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    } else {
      double startX = p1.dx;
      final double endX = p2.dx;
      while (startX < endX) {
        canvas.drawLine(
          Offset(startX, p1.dy),
          Offset(startX + dashWidth, p1.dy),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  static ChartAnnotation? hitTest<D>({
    required Offset position,
    required ChartGeometry geometry,
    required ChartAxis<D> xAxis,
    required ChartAxis<dynamic> yAxis,
    required List<ChartAnnotation<D>> verticalAnnotations,
    required List<ChartAnnotation<dynamic>> horizontalAnnotations,
  }) {
    const double hitThreshold = 10.0;

    // Check VERTICAL annotations
    for (final annotation in verticalAnnotations) {
      final double x = xAxis.toDouble(annotation.value);
      if (x < geometry.bounds.minX || x > geometry.bounds.maxX) {
        continue;
      }
      final double xPos = geometry
          .normalizedXToScreen((x - geometry.bounds.minX) / geometry.xRange);

      if ((position.dx - xPos).abs() <= hitThreshold &&
          position.dy >= geometry.topMargin &&
          position.dy <= geometry.size.height - geometry.bottomMargin) {
        return annotation;
      }
    }

    // Check HORIZONTAL annotations
    for (final annotation in horizontalAnnotations) {
      final double y = yAxis.toDouble(annotation.value);
      if (y < geometry.bounds.minY || y > geometry.bounds.maxY) {
        continue;
      }
      final double yPos = geometry
          .normalizedYToScreen((y - geometry.bounds.minY) / geometry.yRange);

      if ((position.dy - yPos).abs() <= hitThreshold &&
          position.dx >= geometry.leftMargin &&
          position.dx <= geometry.size.width - geometry.rightMargin) {
        return annotation;
      }
    }

    return null;
  }
}
