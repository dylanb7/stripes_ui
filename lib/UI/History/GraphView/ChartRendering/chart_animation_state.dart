import 'dart:ui' as ui;

import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class AnimatedAxisLabel {
  final double normalizedPosition;
  final String text;
  final double value;

  const AnimatedAxisLabel({
    required this.normalizedPosition,
    required this.text,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      other is AnimatedAxisLabel &&
      normalizedPosition == other.normalizedPosition &&
      text == other.text &&
      value == other.value;

  @override
  int get hashCode => Object.hash(normalizedPosition, text, value);
}

class AxisLabelsState {
  List<AnimatedAxisLabel> previous;
  List<AnimatedAxisLabel> current;

  bool useCrossfade;

  AxisLabelsState()
      : previous = [],
        current = [],
        useCrossfade = false;

  void update(List<AnimatedAxisLabel> newLabels) {
    previous = current;
    current = newLabels;
    useCrossfade = previous.length != current.length;
  }
}

class ChartAnimationState<T, D> {
  final Map<(int, int), double> _previousYValues = {};
  final Map<(int, int), double> _currentYValues = {};

  final AxisLabelsState xAxis = AxisLabelsState();
  final AxisLabelsState yAxis = AxisLabelsState();

  DataBounds? _lastBounds;

  void initializeFromDatasets(List<ChartSeriesData<T, D>> datasets) {
    _currentYValues.clear();
    for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
      final ChartSeriesData<T, D> data = datasets[dsIndex];
      for (int i = 0; i < data.data.length; i++) {
        _currentYValues[(dsIndex, i)] = data.getPointY(data.data[i], i);
      }
    }
  }

  void updateFromDatasets(List<ChartSeriesData<T, D>> datasets) {
    _previousYValues.clear();
    _previousYValues.addAll(_currentYValues);
    initializeFromDatasets(datasets);
  }

  void updateAxisLabels<Axis>(
    DataBounds bounds,
    ChartAxis<D> xAxisConfig,
    ChartAxis<dynamic> yAxisConfig, {
    LabelAlignment alignment = LabelAlignment.start,
  }) {
    if (_lastBounds == bounds) return;

    xAxis.update(_generateXLabels(bounds, xAxisConfig, alignment));
    yAxis.update(_generateYLabels(bounds, yAxisConfig));
    _lastBounds = bounds;
  }

  double getAnimatedY(int dsIndex, int pointIndex, double targetY, double t) {
    final startY = _previousYValues[(dsIndex, pointIndex)] ?? 0.0;
    return ui.lerpDouble(startY, targetY, t) ?? targetY;
  }

  List<AnimatedAxisLabel> _generateXLabels(
      DataBounds bounds, ChartAxis<D> axis, LabelAlignment alignment) {
    final labels = <AnimatedAxisLabel>[];
    if (!axis.showing || (bounds.xAxisTickSize ?? 0) <= 0) return labels;

    final xRange = bounds.maxX - bounds.minX;
    if (xRange <= 0) return labels;

    // For center alignment (bar charts), offset labels to align with bucket centers
    final double halfStep =
        alignment == LabelAlignment.center ? bounds.xAxisTickSize! / 2 : 0;

    double value;
    if (axis is DateTimeAxis) {
      double anchor = 0.0;
      // Use epsilon to prevent floating point issues from skipping the first label
      const double epsilon = 0.001;
      final int multiple =
          ((bounds.labelMinX - anchor - epsilon) / bounds.xAxisTickSize!)
              .ceil();
      value = anchor + (multiple * bounds.xAxisTickSize!) + halfStep;
    } else {
      value = bounds.labelMinX + halfStep;
    }

    while (value <= bounds.labelMaxX + bounds.xAxisTickSize! * 0.5 + 0.0001) {
      if (value < bounds.labelMinX) {
        value += bounds.xAxisTickSize!;
        continue;
      }

      final text = axis.formatFromDouble(value);

      if (text.isNotEmpty) {
        final normalizedPos = (value - bounds.minX) / xRange;
        labels.add(AnimatedAxisLabel(
          normalizedPosition: normalizedPos,
          text: text,
          value: value,
        ));
      }
      value += bounds.xAxisTickSize!;
    }
    return labels;
  }

  List<AnimatedAxisLabel> _generateYLabels(
      DataBounds bounds, ChartAxis<dynamic> axis) {
    final labels = <AnimatedAxisLabel>[];
    if (!axis.showing || (bounds.yAxisTickSize ?? 0) <= 0) return labels;

    final yRange = bounds.maxY - bounds.minY;
    if (yRange <= 0) return labels;

    double value = bounds.minY;
    while (value <= bounds.maxY + 0.0001) {
      final text = axis.formatFromDouble(value);
      final normalizedPos = (value - bounds.minY) / yRange;
      labels.add(AnimatedAxisLabel(
        normalizedPosition: normalizedPos,
        text: text,
        value: value,
      ));
      value += bounds.yAxisTickSize!;
    }
    return labels;
  }
}
