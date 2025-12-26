import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class ChartHitTestResult<T, D> {
  final T item;
  final int datasetIndex;
  final int itemIndex;
  final D xValue;
  final double yValue;
  final Offset screenPosition;
  final Rect? hitRect;

  const ChartHitTestResult({
    required this.item,
    required this.datasetIndex,
    required this.itemIndex,
    required this.xValue,
    required this.yValue,
    required this.screenPosition,
    this.hitRect,
  });
}

class ChartHitTester {
  static List<ChartHitTestResult<T, D>> hitTest<T, D>({
    required Offset position,
    required ChartGeometry geometry,
    required List<ChartSeriesData<T, D>> datasets,
    required ChartAxis<D> xAxis,
    required ChartStyle style,
  }) {
    if (datasets.isEmpty) return const [];

    final Map<double, double> stackBottoms = {};

    for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
      final data = datasets[dsIndex];

      if (data is BarChartData<T, D>) {
        final result = _hitTestBarSingle(
          position: position,
          geometry: geometry,
          data: data,
          datasets: datasets,
          xAxis: xAxis,
          datasetIndex: dsIndex,
          style: style,
          stackBottoms: style.barChartStyle.stackBars ? stackBottoms : null,
        );
        if (result != null) {
          return _collectAllAtX(
            targetXValue: result.xValue,
            geometry: geometry,
            datasets: datasets,
            xAxis: xAxis,
            style: style,
          );
        }
      } else {
        final result = _hitTestPointSingle(
          position: position,
          geometry: geometry,
          data: data,
          xAxis: xAxis,
          datasetIndex: dsIndex,
        );
        if (result != null) {
          return _collectAllAtX(
            targetXValue: result.xValue,
            geometry: geometry,
            datasets: datasets,
            xAxis: xAxis,
            style: style,
          );
        }
      }
    }

    return const [];
  }

  static List<ChartHitTestResult<T, D>> _collectAllAtX<T, D>({
    required D targetXValue,
    required ChartGeometry geometry,
    required List<ChartSeriesData<T, D>> datasets,
    required ChartAxis<D> xAxis,
    required ChartStyle style,
  }) {
    final List<ChartHitTestResult<T, D>> results = [];
    final double targetX = xAxis.toDouble(targetXValue);
    final Map<double, double> stackBottoms = {};


    for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
      final data = datasets[dsIndex];
      for (int i = 0; i < data.data.length; i++) {
        final item = data.data[i];
        final xValue = data.getPointX(item, i);
        final x = xAxis.toDouble(xValue);

        final y = data.getPointY(item, i);
        double currentYBottom = 0;
        if (style.barChartStyle.stackBars) {
          currentYBottom = stackBottoms[x] ?? 0;
          stackBottoms[x] = currentYBottom + y;
        }

        if (x == targetX) {
          final centerOffset = geometry.dataToScreen(x, currentYBottom);
          final top = geometry.dataToScreen(x, currentYBottom + y);

          results.add(ChartHitTestResult(
            item: item,
            datasetIndex: dsIndex,
            itemIndex: i,
            xValue: xValue,
            yValue: y,
            screenPosition: Offset(centerOffset.dx, top.dy),
          ));
        }
      }
    }
    return results;
  }

  static ChartHitTestResult<T, D>? _hitTestBarSingle<T, D>({
    required Offset position,
    required ChartGeometry geometry,
    required BarChartData<T, D> data,
    required List<ChartSeriesData<T, D>> datasets,
    required ChartAxis<D> xAxis,
    required int datasetIndex,
    required ChartStyle style,
    Map<double, double>? stackBottoms,
  }) {
    final maxBarsInDataset = datasets
        .whereType<BarChartData<T, D>>()
        .map((ds) => ds.data.length)
        .fold(0, (a, b) => a > b ? a : b);

    final double barWidth = min(
      (geometry.drawWidth / (maxBarsInDataset == 0 ? 1 : maxBarsInDataset)) *
          style.barChartStyle.barWidthRatio,
      style.barChartStyle.barMaxWidth,
    );

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final xValue = data.getPointX(item, i);
      final x = xAxis.toDouble(xValue);
      final y = data.getPointY(item, i);

      double currentYBottom = 0;
      if (stackBottoms != null) {
        currentYBottom = stackBottoms[x] ?? 0;
        stackBottoms[x] = currentYBottom + y;
      }

      final centerOffset = geometry.dataToScreen(x, currentYBottom);
      final top = geometry.dataToScreen(x, currentYBottom + y);
      final bottom = centerOffset;

      final rect = Rect.fromCenter(
        center: Offset(centerOffset.dx, (top.dy + bottom.dy) / 2),
        width: barWidth,
        height: (bottom.dy - top.dy).abs(),
      );

      if (rect.inflate(4.0).contains(position)) {
        return ChartHitTestResult(
          item: item,
          datasetIndex: datasetIndex,
          itemIndex: i,
          xValue: xValue,
          yValue: y,
          screenPosition: Offset(centerOffset.dx, top.dy),
          hitRect: rect,
        );
      }
    }

    return null;
  }

  static ChartHitTestResult<T, D>? _hitTestPointSingle<T, D>({
    required Offset position,
    required ChartGeometry geometry,
    required ChartSeriesData<T, D> data,
    required ChartAxis<D> xAxis,
    required int datasetIndex,
    double hitRadius = 5.0,
  }) {
    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final xValue = data.getPointX(item, i);
      final x = xAxis.toDouble(xValue);
      final y = data.getPointY(item, i);

      final point = geometry.dataToScreen(x, y);
      if ((point - position).distance <= hitRadius) {
        return ChartHitTestResult(
          item: item,
          datasetIndex: datasetIndex,
          itemIndex: i,
          xValue: xValue,
          yValue: y,
          screenPosition: point,
        );
      }
    }

    return null;
  }
}
