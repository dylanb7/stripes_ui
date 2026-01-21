import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

/// Painter for rendering horizontal range segments (review periods).
class RangePainter {
  /// Paints horizontal range bars for RangeChartData.
  ///
  /// Each range is drawn as a horizontal rectangle spanning from xStart to xEnd.
  /// The Y position is determined by getPointY (can be used for stacking/lanes).
  static void paintRangeChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    RangeChartData<T, D> data,
    ChartAxis<D> xAxis,
    ChartAxis<dynamic> yAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    ChartStyle style, {
    Set<int>? selectedIndices,
    double rangeHeight = 20.0,
    double verticalPadding = 4.0,
  }) {
    if (data.data.isEmpty) return;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Chart area bounds
    final double chartLeft = geometry.leftMargin;
    final double chartRight = geometry.size.width - geometry.rightMargin;
    final double chartTop = geometry.topMargin;
    final double chartBottom = geometry.size.height - geometry.bottomMargin;

    // Clip to chart area to prevent bleeding over axes or outside bounds
    canvas.save();
    canvas
        .clipRect(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final D xStart = data.getPointX(item, i);
      final D xEnd = data.getPointXEnd(item, i);
      final Color color = data.getPointColor(item, i);

      // Convert to screen X coordinates using geometry instance method
      final Offset startPoint = geometry.dataToScreen(
        xAxis.toDouble(xStart),
        0,
        xAxis,
        yAxis,
      );
      final Offset endPoint = geometry.dataToScreen(
        xAxis.toDouble(xEnd),
        0,
        xAxis,
        yAxis,
      );

      final double screenXStart = startPoint.dx;
      final double screenXEnd = endPoint.dx;

      // Clamp to chart bounds
      final double clampedXStart = screenXStart.clamp(chartLeft, chartRight);
      final double clampedXEnd = screenXEnd.clamp(chartLeft, chartRight);

      // Calculate Y position - center all ranges vertically in the chart area
      final double chartHeight = chartBottom - chartTop;
      final double yPosition = chartTop + (chartHeight - rangeHeight) / 2;

      final bool isSelected = selectedIndices?.contains(i) ?? false;

      // Draw the range rectangle
      final Rect rangeRect = Rect.fromLTRB(
        clampedXStart,
        yPosition,
        clampedXEnd,
        yPosition + rangeHeight,
      );

      // Fill with full opacity (or slight selection highlight)
      fillPaint.color = isSelected ? Colors.white : color;
      canvas.drawRect(rangeRect, fillPaint);

      // Border with full opacity and more prominence
      // Derive a darker version of the color for the border
      final HSLColor hsl = HSLColor.fromColor(color);
      final Color borderColor = isSelected
          ? color
          : hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

      borderPaint.color = borderColor;
      borderPaint.strokeWidth = 1.5;
      canvas.drawRect(rangeRect, borderPaint);

      // Draw separation gap if needed (though borders help)
      // If we want a physical gap, we could shrink the Rect slightly.

      // Draw label if provided and there's enough space
      final String? label = data.getRangeLabel?.call(item, i);
      if (label != null) {
        final double rectWidth = clampedXEnd - clampedXStart;
        if (rectWidth > 40) {
          // Only draw label if there's enough space
          _drawLabel(
            canvas,
            label,
            Offset(
              clampedXStart + (rectWidth / 2),
              yPosition + (rangeHeight / 2),
            ),
            color,
            rectWidth - 8, // Leave padding
          );
        }
      }
    }

    canvas.restore();
  }

  static void _drawLabel(
    Canvas canvas,
    String label,
    Offset center,
    Color textColor,
    double maxWidth,
  ) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    textPainter.layout(maxWidth: maxWidth);

    final Offset textOffset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, textOffset);
  }
}
