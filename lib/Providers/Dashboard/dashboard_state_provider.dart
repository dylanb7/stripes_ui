import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

/// Dashboard state containing range and cycle.
@immutable
class DashboardState extends Equatable {
  final DateTimeRange range;
  final TimeCycle cycle;

  const DashboardState({
    required this.range,
    required this.cycle,
  });

  DashboardState copyWith({
    DateTimeRange? range,
    TimeCycle? cycle,
  }) {
    return DashboardState(
      range: range ?? this.range,
      cycle: cycle ?? this.cycle,
    );
  }

  @override
  List<Object?> get props => [range, cycle];

  bool get canGoPrev => DateRangeUtils.canGoPrev(cycle, range);

  bool get canGoNext => DateRangeUtils.canGoNext(cycle, range);

  String getRangeString({String locale = 'en'}) {
    return DateRangeUtils.formatRange(range, cycle, locale);
  }
}

class DashboardStateNotifier extends StateNotifier<DashboardState> {
  DashboardStateNotifier()
      : super(DashboardState(
          range: DateRangeUtils.calculateRange(TimeCycle.month, DateTime.now()),
          cycle: TimeCycle.month,
        ));

  void setCycle(TimeCycle cycle) {
    final range = DateRangeUtils.calculateRange(cycle, DateTime.now());
    state = state.copyWith(cycle: cycle, range: range);
  }

  void setRange(DateTimeRange range) {
    state = state.copyWith(range: range, cycle: TimeCycle.custom);
  }

  void shift({required bool forward}) {
    final newRange =
        DateRangeUtils.shiftRange(state.range, state.cycle, forward);

    if (forward && newRange.start.isAfter(DateTime.now())) return;

    state = state.copyWith(range: newRange);
  }

  String getPreviewString({required bool forward, String locale = 'en'}) {
    final nextRange =
        DateRangeUtils.shiftRange(state.range, state.cycle, forward);
    return DateRangeUtils.formatRange(nextRange, state.cycle, locale);
  }
}

final dashboardStateProvider =
    StateNotifierProvider<DashboardStateNotifier, DashboardState>((ref) {
  return DashboardStateNotifier();
});
