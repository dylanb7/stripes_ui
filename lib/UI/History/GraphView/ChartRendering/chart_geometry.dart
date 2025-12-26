import 'package:flutter/painting.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_animation_state.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class ChartGeometry {
  final DataBounds bounds;
  final Size size;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double bottomMargin;

  ChartGeometry({
    required this.bounds,
    required this.size,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.bottomMargin,
  });

  double get drawWidth => size.width - leftMargin - rightMargin;
  double get drawHeight => size.height - topMargin - bottomMargin;

  double get xRange {
    final range = bounds.maxX - bounds.minX;
    return range == 0 ? 1.0 : range;
  }

  double get yRange {
    final range = bounds.maxY - bounds.minY;
    return range == 0 ? 1.0 : range;
  }

  Offset dataToScreen(double x, double y) {
    final normalizedX = (x - bounds.minX) / xRange;
    final normalizedY = (y - bounds.minY) / yRange;

    return Offset(
      leftMargin + normalizedX * drawWidth,
      size.height - bottomMargin - normalizedY * drawHeight,
    );
  }

  double normalizedXToScreen(double normalizedX) {
    return leftMargin + normalizedX * drawWidth;
  }

  double normalizedYToScreen(double normalizedY) {
    return size.height - bottomMargin - normalizedY * drawHeight;
  }

  static ChartGeometry compute({
    required Size size,
    required DataBounds bounds,
    required AxisLabelsState yAxisState,
    required bool showYAxis,
    required bool showXAxis,
    required ChartStyle style,
    String? xAxisLabel,
    String? yAxisLabel,
  }) {
    double leftMargin = 0.0;
    if (showYAxis && bounds.yAxisTickSize > 0) {
      double maxWidth = 0.0;
      for (final label in yAxisState.current) {
        final tp = TextPainter(
          text: TextSpan(text: label.text, style: style.axisLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        if (tp.width > maxWidth) maxWidth = tp.width;
      }
      leftMargin = maxWidth + style.axisLabelPadding;

      if (yAxisLabel != null) {
        final tp = TextPainter(
          text: TextSpan(text: yAxisLabel, style: style.axisTitleStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        leftMargin += tp.height + style.axisLabelPadding;
      }
    }

    double bottomMargin = 0.0;
    if (showXAxis && bounds.xAxisTickSize > 0) {
      final tp = TextPainter(
        text: TextSpan(text: 'Xy', style: style.axisLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      bottomMargin = tp.height + style.axisLabelPadding;

      if (xAxisLabel != null) {
        final tp = TextPainter(
          text: TextSpan(text: xAxisLabel, style: style.axisTitleStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        bottomMargin += tp.height + style.axisLabelPadding;
      }
    }

    return ChartGeometry(
      bounds: bounds,
      size: size,
      leftMargin: leftMargin,
      rightMargin: style.chartPadding.right,
      topMargin: style.chartPadding.top,
      bottomMargin: bottomMargin,
    );
  }
}
