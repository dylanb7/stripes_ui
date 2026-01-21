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
    required ChartAxis<dynamic> yAxis,
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
          yAxis: yAxis,
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
            yAxis: yAxis,
            style: style,
          );
        }
      } else if (data is RangeChartData<T, D>) {
        final result = _hitTestRangeSingle(
          position: position,
          geometry: geometry,
          data: data,
          xAxis: xAxis,
          yAxis: yAxis,
          datasetIndex: dsIndex,
        );
        if (result != null) {
          return [result];
        }
      } else {
        final result = _hitTestPointSingle(
          position: position,
          geometry: geometry,
          data: data,
          xAxis: xAxis,
          yAxis: yAxis,
          datasetIndex: dsIndex,
        );
        if (result != null) {
          return _collectAllAtX(
            targetXValue: result.xValue,
            geometry: geometry,
            datasets: datasets,
            xAxis: xAxis,
            yAxis: yAxis,
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
    required ChartAxis<dynamic> yAxis,
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
          final centerOffset =
              geometry.dataToScreen(x, currentYBottom, xAxis, yAxis);
          final top =
              geometry.dataToScreen(x, currentYBottom + y, xAxis, yAxis);

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
    required ChartAxis<dynamic> yAxis,
    required int datasetIndex,
    required ChartStyle style,
    Map<double, double>? stackBottoms,
  }) {
    final maxBarsInDataset = datasets
        .whereType<BarChartData<T, D>>()
        .map((ds) => ds.data.length)
        .fold(0, (a, b) => a > b ? a : b);

    final double widthToUse;
    if (geometry.bounds.minDataStep > 0) {
      widthToUse =
          (geometry.bounds.minDataStep / geometry.xRange) * geometry.drawWidth;
    } else {
      widthToUse =
          geometry.drawWidth / (maxBarsInDataset == 0 ? 1 : maxBarsInDataset);
    }

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final xValue = data.getPointX(item, i);
      final x = xAxis.toDouble(xValue);
      final y = data.getPointY(
          item, i); // Y value is still needed for screen position calculation

      // Calculate screen X position for the bar
      final screenX = geometry
          .dataToScreen(x, 0, xAxis, yAxis)
          .dx; // Y doesn't matter for X-position check

      final double horizontalDist = (position.dx - screenX).abs();

      if (horizontalDist <= widthToUse / 2) {
        // We found a bar based on X-position.
        // Return a dummy hit result to trigger _collectAllAtX.
        // The actual screenPosition and hitRect will be calculated in _collectAllAtX.
        return ChartHitTestResult(
          item:
              item, // This item might not be the one actually hit in Y, but its X is correct
          datasetIndex: datasetIndex,
          itemIndex: i,
          xValue: xValue,
          yValue: y,
          screenPosition: Offset(screenX, 0), // Dummy Y, will be re-calculated
          hitRect: null, // Dummy rect, will be re-calculated
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
    required ChartAxis<dynamic> yAxis,
    required int datasetIndex,
    double hitRadius = 5.0,
  }) {
    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final xValue = data.getPointX(item, i);
      final x = xAxis.toDouble(xValue);
      final y = data.getPointY(item, i);

      final point = geometry.dataToScreen(x, y, xAxis, yAxis);
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

  /// Hit test for RangeChartData - checks if tap is within any range's X bounds.
  static ChartHitTestResult<T, D>? _hitTestRangeSingle<T, D>({
    required Offset position,
    required ChartGeometry geometry,
    required RangeChartData<T, D> data,
    required ChartAxis<D> xAxis,
    required ChartAxis<dynamic> yAxis,
    required int datasetIndex,
    double rangeHeight = 20.0,
    double verticalPadding = 4.0,
  }) {
    final double chartLeft = geometry.leftMargin;
    final double chartRight = geometry.size.width - geometry.rightMargin;
    final double chartTop = geometry.topMargin;

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      final D xStart = data.getPointX(item, i);
      final D xEnd = data.getPointXEnd(item, i);

      // Convert to screen X coordinates
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

      final double screenXStart = startPoint.dx.clamp(chartLeft, chartRight);
      final double screenXEnd = endPoint.dx.clamp(chartLeft, chartRight);

      // Calculate Y position
      final double baseY = data.getPointY(item, i);
      final double yPosition = chartTop +
          verticalPadding +
          (baseY * (rangeHeight + verticalPadding));

      // Hit rect
      final Rect hitRect = Rect.fromLTRB(
        screenXStart,
        yPosition,
        screenXEnd,
        yPosition + rangeHeight,
      );

      if (hitRect.contains(position)) {
        return ChartHitTestResult(
          item: item,
          datasetIndex: datasetIndex,
          itemIndex: i,
          xValue: xStart,
          yValue: baseY,
          screenPosition: Offset(hitRect.center.dx, hitRect.center.dy),
          hitRect: hitRect,
        );
      }
    }

    return null;
  }
}
