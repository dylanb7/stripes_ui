import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';

/// A controller that manages the selection/hover state of a chart.
/// This allows external widgets (like headers or legends) to react to
/// interactions within the chart.
class ChartSelectionState<T, D> {
  final List<ChartHitTestResult<T, D>> results;
  final Offset? hoverPosition;

  ChartSelectionState({this.results = const [], this.hoverPosition});
}

/// A controller that manages the selection/hover state of a chart.
/// This allows external widgets (like headers or legends) to react to
/// interactions within the chart.
class ChartSelectionController<T, D>
    extends ValueNotifier<ChartSelectionState<T, D>> {
  ChartSelectionController([ChartSelectionState<T, D>? value])
      : super(value ?? ChartSelectionState());

  void select(List<ChartHitTestResult<T, D>> results, {Offset? position}) {
    value = ChartSelectionState(results: results, hoverPosition: position);
  }

  void clear() {
    value = ChartSelectionState();
  }
}
