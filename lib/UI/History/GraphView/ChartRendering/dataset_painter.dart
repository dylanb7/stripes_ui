import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/range_painter.dart';

class DatasetPainter {
  static void paintBarChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    BarChartData<T, D> data,
    ChartAxis<D> xAxis,
    ChartAxis<dynamic> yAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    int maxBarsInDataset,
    ChartStyle style, {
    Map<double, double>? stackBottoms,
    Set<int>? selectedIndices,
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

      final bottomOffset = geometry.dataToScreen(x, bottomY, xAxis, yAxis);
      final topOffset = geometry.dataToScreen(x, topY, xAxis, yAxis);

      double height = (bottomOffset.dy - topOffset.dy).abs();
      double drawBottomY = bottomOffset.dy;

      // Add 1px gap between stacked bars
      if (datasetIndex > 0 && height > 1) {
        height -= 1.0;
        drawBottomY -= 1.0;
      }

      final rect = Rect.fromLTRB(
        bottomOffset.dx - barWidth / 2,
        topOffset.dy,
        bottomOffset.dx + barWidth / 2,
        drawBottomY,
      );

      final isSelected = selectedIndices?.contains(i) ?? false;

      // Draw neutral background highlight for selected column
      // Only draw it for the first dataset to avoid overlapping highlights darken too much
      if (isSelected && datasetIndex == 0) {
        final highlightRect = Rect.fromLTWH(
          bottomOffset.dx - widthToUse / 2,
          geometry.topMargin,
          widthToUse,
          geometry.drawHeight,
        );
        canvas.drawRect(
          highlightRect,
          Paint()..color = style.barChartStyle.effectiveHighlightColor,
        );
      }

      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      if (rect.height > 0) {
        canvas.drawRect(rect, paint);
      }
    }
  }

  static void paintBars<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    List<BarChartData<T, D>> datasets,
    List<int> originalIndices,
    ChartAxis<D> xAxis,
    ChartAxis<dynamic> yAxis,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    ChartStyle style, {
    Map<int, Set<int>>? selectedIndices,
  }) {
    if (datasets.isEmpty) return;

    // 1. Group by X-coordinate
    final Map<double, List<_BarToPaint<T, D>>> groups = {};
    int maxBarsInAnyDataset = 0;

    for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
      final data = datasets[dsIndex];
      maxBarsInAnyDataset = max(maxBarsInAnyDataset, data.data.length);
      final int originalIdx = originalIndices[dsIndex];
      for (int i = 0; i < data.data.length; i++) {
        final item = data.data[i];
        final x = xAxis.toDouble(data.getPointX(item, i));
        final rawY = data.getPointY(item, i);
        final yValue = getAnimatedY(originalIdx, i, rawY);

        groups.putIfAbsent(x, () => []).add(_BarToPaint(
              dsIndex: originalIdx,
              itemIndex: i,
              x: x,
              y: yValue,
              color: data.getPointColor(item, i),
            ));
      }
    }

    // 2. Determine width parameters
    double widthToUse;
    if (geometry.bounds.minDataStep > 0) {
      widthToUse =
          (geometry.bounds.minDataStep / geometry.xRange) * geometry.drawWidth;
    } else {
      widthToUse = geometry.drawWidth /
          (maxBarsInAnyDataset == 0 ? 1 : maxBarsInAnyDataset);
    }

    final double baseBarWidth = min(
      widthToUse * style.barChartStyle.barWidthRatio,
      style.barChartStyle.barMaxWidth,
    );

    // 3. Paint each group
    for (final x in groups.keys) {
      final bars = groups[x]!;

      // Sort: tallest first
      bars.sort((a, b) => b.y.compareTo(a.y));

      // Group by height for horizontal division
      final Map<double, List<_BarToPaint<T, D>>> heightGroups = {};
      for (final bar in bars) {
        // Round to avoid floating point comparison issues
        final roundedY = (bar.y * 10000).round() / 10000.0;
        heightGroups.putIfAbsent(roundedY, () => []).add(bar);
      }

      for (int i = 0; i < bars.length; i++) {
        final bar = bars[i];
        final roundedY = (bar.y * 10000).round() / 10000.0;
        final tiedBars = heightGroups[roundedY]!;
        final int tieIndex = tiedBars.indexOf(bar);
        final int tieCount = tiedBars.length;

        // For ties, divide the bar width evenly
        double currentBarWidth;
        double xOffset;
        if (tieCount > 1) {
          // Divide the bar space evenly among tied bars
          currentBarWidth = baseBarWidth / tieCount;
          // Calculate offset from center: position each bar side-by-side
          final double totalWidth = baseBarWidth;
          final double startOffset = -totalWidth / 2 + currentBarWidth / 2;
          xOffset = startOffset + (tieIndex * currentBarWidth);
        } else {
          currentBarWidth = baseBarWidth;
          xOffset = 0;
        }

        final bottomOffset = geometry.dataToScreen(bar.x, 0, xAxis, yAxis);
        final topOffset = geometry.dataToScreen(bar.x, bar.y, xAxis, yAxis);

        final rect = Rect.fromLTRB(
          bottomOffset.dx + xOffset - currentBarWidth / 2,
          topOffset.dy,
          bottomOffset.dx + xOffset + currentBarWidth / 2,
          bottomOffset.dy,
        );

        final isSelected =
            selectedIndices?[bar.dsIndex]?.contains(bar.itemIndex) ?? false;
        if (isSelected && i == 0) {
          final highlightRect = Rect.fromLTWH(
            bottomOffset.dx - widthToUse / 2,
            geometry.topMargin,
            widthToUse,
            geometry.drawHeight,
          );
          canvas.drawRect(
            highlightRect,
            Paint()..color = style.barChartStyle.effectiveHighlightColor,
          );
        }

        final Paint paint = Paint()
          ..color = bar.color
          ..style = PaintingStyle.fill;

        if (rect.height > 0) {
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  static void paintLineChart<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    LineChartData<T, D> data,
    ChartAxis<D> xAxis,
    ChartAxis<dynamic> yAxis,
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

      final pos = geometry.dataToScreen(x, y, xAxis, yAxis);

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

      final pos = geometry.dataToScreen(x, y, xAxis, yAxis);
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
    ChartAxis<dynamic> yAxis,
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

      final center = geometry.dataToScreen(x, y, xAxis, yAxis);

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
    ChartAxis<dynamic> yAxis,
    int datasetIndex,
    double Function(int dsIndex, int pointIndex, double targetY) getAnimatedY,
    int maxBarsInDataset,
    ChartStyle style, {
    Map<double, double>? stackBottoms,
    Set<int>? selectedIndices,
  }) {
    if (data is BarChartData<T, D>) {
      paintBarChart(canvas, geometry, data, xAxis, yAxis, datasetIndex,
          getAnimatedY, maxBarsInDataset, style,
          stackBottoms: stackBottoms, selectedIndices: selectedIndices);
    } else if (data is LineChartData<T, D>) {
      paintLineChart(canvas, geometry, data, xAxis, yAxis, datasetIndex,
          getAnimatedY, style);
    } else if (data is ScatterChartData<T, D>) {
      paintScatterChart(
          canvas, geometry, data, xAxis, yAxis, datasetIndex, getAnimatedY);
    } else if (data is RangeChartData<T, D>) {
      RangePainter.paintRangeChart(
        canvas,
        geometry,
        data,
        xAxis,
        yAxis,
        datasetIndex,
        getAnimatedY,
        style,
        selectedIndices: selectedIndices,
      );
    }
  }
}

class _BarToPaint<T, D> {
  final int dsIndex;
  final int itemIndex;
  final double x;
  final double y;
  final Color color;

  _BarToPaint({
    required this.dsIndex,
    required this.itemIndex,
    required this.x,
    required this.y,
    required this.color,
  });
}
