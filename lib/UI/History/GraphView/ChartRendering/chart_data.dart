import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';

@immutable
class DataBounds extends Equatable {
  final double minX, maxX, minY, maxY;

  final double labelMinX, labelMaxX;
  final double yAxisTickSize, xAxisTickSize;
  final double minDataStep;

  const DataBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    double? labelMinX,
    double? labelMaxX,
    this.yAxisTickSize = 1.0,
    this.xAxisTickSize = 1.0,
    this.minDataStep = 0.0,
  })  : labelMinX = labelMinX ?? minX,
        labelMaxX = labelMaxX ?? maxX;

  DataBounds withNormalizedYRange({required int ticks}) {
    final YAxisRange range =
        calculateYAxisRange(ticks: ticks, max: maxY, min: minY);
    return DataBounds(
      minX: minX,
      maxX: maxX,
      minY: range.lowerBound,
      maxY: range.upperBound,
      yAxisTickSize: range.tickSize,
    );
  }

  static DataBounds combined(Iterable<DataBounds> dataBounds) {
    if (dataBounds.isEmpty) {
      return const DataBounds(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0);
    }
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    double minStep = double.infinity;

    for (var item in dataBounds) {
      if (item.minX < minX) minX = item.minX;
      if (item.maxX > maxX) maxX = item.maxX;
      if (item.minY < minY) minY = item.minY;
      if (item.maxY > maxY) maxY = item.maxY;
      if (item.minDataStep > 0 && item.minDataStep < minStep) {
        minStep = item.minDataStep;
      }
    }

    return DataBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      minDataStep: minStep == double.infinity ? 0.0 : minStep,
    );
  }

  @override
  List<Object?> get props => [minX, maxX, minY, maxY, minDataStep];
}

sealed class ChartSeriesData<T, D> extends Equatable {
  final List<T> data;
  final double Function(T, int index) getPointY;
  final D Function(T, int index) getPointX;
  final Color Function(T, int index) getPointColor;

  const ChartSeriesData({
    required this.data,
    required this.getPointY,
    required this.getPointX,
    required this.getPointColor,
  });

  DataBounds calculateRanges(ChartAxis<D> axis) {
    if (data.isEmpty) {
      return const DataBounds(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0);
    }
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < data.length; i++) {
      final D pointX = getPointX(data[i], i);
      final x = axis.toDouble(pointX);
      final y = getPointY(data[i], i);
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    return DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  @override
  List<Object?> get props => [data];
}

class BarChartData<T, D> extends ChartSeriesData<T, D> {
  const BarChartData({
    required super.data,
    required super.getPointY,
    required super.getPointX,
    required super.getPointColor,
  });

  @override
  DataBounds calculateRanges(ChartAxis<D> axis) {
    final DataBounds bounds = super.calculateRanges(axis);
    final DataBounds withY = bounds.withNormalizedYRange(ticks: data.length);

    double minStep = double.infinity;
    if (data.length > 1) {
      for (int i = 0; i < data.length - 1; i++) {
        final diff = (axis.toDouble(getPointX(data[i + 1], i + 1)) -
                axis.toDouble(getPointX(data[i], i)))
            .abs();
        if (diff < minStep && diff > 0) minStep = diff;
      }
    }
    if (minStep == double.infinity) minStep = 1.0;

    return DataBounds(
      minX: withY.minX,
      maxX: withY.maxX,
      minY: withY.minY,
      maxY: withY.maxY,
      yAxisTickSize: withY.yAxisTickSize,
      xAxisTickSize: withY.xAxisTickSize,
      minDataStep: minStep,
    );
  }
}

class LineChartData<T, D> extends ChartSeriesData<T, D> {
  const LineChartData({
    required super.data,
    required super.getPointY,
    required super.getPointX,
    required super.getPointColor,
  });

  @override
  DataBounds calculateRanges(ChartAxis<D> axis) {
    return super.calculateRanges(axis).withNormalizedYRange(ticks: data.length);
  }
}

class ScatterChartData<T, D> extends ChartSeriesData<T, D> {
  final double Function(T) getRadius;

  const ScatterChartData({
    required super.data,
    required super.getPointY,
    required super.getPointX,
    required super.getPointColor,
    required this.getRadius,
  });

  @override
  List<Object?> get props => [data]; // getRadius excluded as it is a function
}

@immutable
class YAxisRange {
  final double upperBound, lowerBound, tickSize;
  const YAxisRange(
      {required this.lowerBound,
      required this.upperBound,
      required this.tickSize});
}

calculateYAxisRange({required int ticks, required num max, num min = 0}) {
  if (min == max) {
    return YAxisRange(
        lowerBound: 0, upperBound: (min * 2), tickSize: min.toDouble());
  }
  final num range = max - min;
  final double unroundedTickSize = range.toDouble() / ticks;
  final double x = ((log(unroundedTickSize) / ln10) - 1).ceilToDouble();
  final double pow10x = pow(10, x).toDouble();
  final double roundedTick = (unroundedTickSize / pow10x).ceil() * pow10x;
  return YAxisRange(
      lowerBound: (min.toDouble() / roundedTick).round() * roundedTick,
      upperBound: (max.toDouble() / roundedTick).ceil() * roundedTick,
      tickSize: roundedTick);
}

double getEfficientInterval(
  double axisViewSize,
  double diffInAxis, {
  double pixelPerInterval = 40,
}) {
  final allowedCount = max(axisViewSize ~/ pixelPerInterval, 1);
  if (diffInAxis == 0) {
    return 1;
  }
  final accurateInterval =
      diffInAxis == 0 ? axisViewSize : diffInAxis / allowedCount;
  if (allowedCount <= 2) {
    return accurateInterval;
  }
  return roundInterval(accurateInterval);
}

double roundInterval(double input) {
  if (input < 1) {
    return _roundIntervalBelowOne(input);
  }
  return _roundIntervalAboveOne(input);
}

double _roundIntervalBelowOne(double input) {
  assert(input < 1.0);

  if (input < 0.000001) {
    return input;
  }

  final inputString = input.toString();
  var precisionCount = inputString.length - 2;

  var zeroCount = 0;
  for (var i = 2; i <= inputString.length; i++) {
    if (inputString[i] != '0') {
      break;
    }
    zeroCount++;
  }

  final afterZerosNumberLength = precisionCount - zeroCount;
  if (afterZerosNumberLength > 2) {
    final numbersToRemove = afterZerosNumberLength - 2;
    precisionCount -= numbersToRemove;
  }

  final pow10onPrecision = pow(10, precisionCount);
  input *= pow10onPrecision;
  return _roundIntervalAboveOne(input) / pow10onPrecision;
}

double _roundIntervalAboveOne(double input) {
  assert(input >= 1.0);
  final decimalCount = input.toInt().toString().length - 1;
  input /= pow(10, decimalCount);

  final scaled = input >= 10 ? input.round() / 10 : input;

  if (scaled >= 7.6) {
    return 10 * pow(10, decimalCount).toInt().toDouble();
  } else if (scaled >= 2.6) {
    return 5 * pow(10, decimalCount).toInt().toDouble();
  } else if (scaled >= 1.6) {
    return 2 * pow(10, decimalCount).toInt().toDouble();
  } else {
    return 1 * pow(10, decimalCount).toInt().toDouble();
  }
}
