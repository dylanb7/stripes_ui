import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class DatasetPainter {
  static void paintBarChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    BarChartData<T, D> data,
    ChartAxis<D> xAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    int maxBarsInDataset,
    ChartStyle style, {
    Map<double, double>? stackBottoms,
  }) {
    double widthToUse;
    if (geometry.bounds.minDataStep > 0) {
      widthToUse =
          (geometry.bounds.minDataStep / geometry.xRange) * geometry.drawWidth;
    } else {
      widthToUse =
          geometry.drawWidth / (maxBarsInDataset == 0 ? 1 : maxBarsInDataset);
    }

    final double barWidth = min(
      widthToUse * style.barChartStyle.barWidthRatio,
      style.barChartStyle.barMaxWidth,
    );

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final x = xAxis.toDouble(data.getPointX(item, i));
      final rawY = data.getPointY(item, i);
      final yValue = getAnimatedY(datasetIndex, i, rawY);
      final color = data.getPointColor(item, i);

      // Determine vertical stack position
      double bottomY = 0;
      if (stackBottoms != null) {
        bottomY = stackBottoms[x] ?? 0;
      }
      final topY = bottomY + yValue;

      // Update stack top for next dataset
      if (stackBottoms != null) {
        stackBottoms[x] = topY;
      }

      final bottomOffset = geometry.dataToScreen(x, bottomY);
      final topOffset = geometry.dataToScreen(x, topY);

      // dataToScreen: Y=0 is at bottom (high dy). Y=Max is at top (low dy).
      // So TopY (higher value) -> lower dy.
      // Rect Top should be min(dy), Bottom max(dy).

      final rect = Rect.fromCenter(
        center: Offset(bottomOffset.dx, (topOffset.dy + bottomOffset.dy) / 2),
        width: barWidth,
        height: (bottomOffset.dy - topOffset.dy).abs(),
      );

      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  static void paintLineChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    LineChartData<T, D> data,
    ChartAxis<D> xAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    ChartStyle style,
  ) {
    if (data.data.isEmpty) return;

    final paint = Paint()
      ..color = data.getPointColor(data.data.first, 0)
      ..strokeWidth = style.lineStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final x = xAxis.toDouble(data.getPointX(item, i));
      final rawY = data.getPointY(item, i);
      final y = getAnimatedY(datasetIndex, i, rawY);

      final pos = geometry.dataToScreen(x, y);

      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final x = xAxis.toDouble(data.getPointX(item, i));
      final rawY = data.getPointY(item, i);
      final y = getAnimatedY(datasetIndex, i, rawY);
      final color = data.getPointColor(item, i);

      final pos = geometry.dataToScreen(x, y);
      canvas.drawCircle(
        pos,
        style.pointRadius,
        Paint()..color = color,
      );
    }
  }

  static void paintScatterChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    ScatterChartData<T, D> data,
    ChartAxis<D> xAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
  ) {
    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final double x = xAxis.toDouble(data.getPointX(item, i));
      final double rawY = data.getPointY(item, i);
      final double y = getAnimatedY(datasetIndex, i, rawY);
      final color = data.getPointColor(item, i);
      final radius = data.getRadius(item);

      final center = geometry.dataToScreen(x, y);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  static void paint<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    ChartSeriesData<T, D> data,
    ChartAxis<D> xAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    int maxBarsInDataset,
    ChartStyle style, {
    Map<double, double>? stackBottoms,
  }) {
    if (data is BarChartData<T, D>) {
      paintBarChart(canvas, geometry, data, xAxis, datasetIndex, getAnimatedY,
          maxBarsInDataset, style,
          stackBottoms: stackBottoms);
    } else if (data is LineChartData<T, D>) {
      paintLineChart(
          canvas, geometry, data, xAxis, datasetIndex, getAnimatedY, style);
    } else if (data is ScatterChartData<T, D>) {
      paintScatterChart(
          canvas, geometry, data, xAxis, datasetIndex, getAnimatedY);
    }
  }
}
