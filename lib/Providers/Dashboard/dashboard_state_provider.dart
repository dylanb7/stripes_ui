import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

@immutable
class DashboardState extends Equatable {
  final TimeWindow window;
  final int periodDays;
  final int offset;

  const DashboardState({
    required this.window,
    this.periodDays = 7,
    this.offset = 0,
  });

  DateTimeRange get range => window.range;
  TimeCycle get cycle => window.cycle;

  DashboardState copyWith({
    TimeWindow? window,
    DateTimeRange? range,
    TimeCycle? cycle,
    int? periodDays,
    int? offset,
  }) {
    return DashboardState(
      window: window ?? this.window.copyWith(range: range, cycle: cycle),
      periodDays: periodDays ?? this.periodDays,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [window, periodDays, offset];

  bool get canGoPrev => window.canGoPrev;

  bool get canGoNext => window.canGoNext;

  String getRangeString({String locale = 'en'}) {
    return DateRangeUtils.formatRange(range, cycle, locale);
  }
}

class DashboardStateNotifier extends Notifier<DashboardState> {
  DashboardStateNotifier();

  void setCycle(TimeCycle cycle) {
    state = state.copyWith(window: TimeWindow.forCycle(cycle));
  }

  void setRange(DateTimeRange range) {
    state = state.copyWith(range: range, cycle: TimeCycle.custom);
  }

  void setPeriodDays(int days) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    state = state.copyWith(
      range: DateTimeRange(
        start: DateRangeUtils.shiftCalendarDays(end, -(days - 1)),
        end: end,
      ),
      cycle: days == 7 ? TimeCycle.week : TimeCycle.custom,
      periodDays: days,
      offset: 0,
    );
  }

  void shiftPeriod({required bool forward}) {
    final nextOffset = state.offset + (forward ? 1 : -1);
    if (nextOffset > 0 || nextOffset < -10) return;
    final today = DateTime.now();
    final end = DateRangeUtils.shiftCalendarDays(
      DateTime(today.year, today.month, today.day),
      nextOffset * state.periodDays,
    );
    state = state.copyWith(
      range: DateTimeRange(
        start: DateRangeUtils.shiftCalendarDays(end, -(state.periodDays - 1)),
        end: end,
      ),
      offset: nextOffset,
    );
  }

  void shift({required bool forward}) {
    final next = state.window.shift(forward: forward);

    if (forward && next.range.start.isAfter(DateTime.now())) return;

    state = state.copyWith(window: next);
  }

  String getPreviewString({required bool forward, String locale = 'en'}) {
    final next = state.window.shift(forward: forward);
    return DateRangeUtils.formatRange(next.range, next.cycle, locale);
  }

  @override
  DashboardState build() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    return DashboardState(
      window: TimeWindow(
        range: DateTimeRange(
          start: DateRangeUtils.shiftCalendarDays(end, -6),
          end: end,
        ),
        cycle: TimeCycle.week,
      ),
    );
  }
}

final dashboardStateProvider =
    NotifierProvider<DashboardStateNotifier, DashboardState>(
      DashboardStateNotifier.new,
    );
