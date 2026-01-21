import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_stats.dart';
import 'package:stripes_ui/Providers/Dashboard/insight_provider.dart';
import 'package:stripes_ui/Providers/history/stamps_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

final dashboardResponsesProvider =
    FutureProvider.autoDispose<List<Response>>((ref) async {
  final state = ref.watch(dashboardStateProvider);
  final stamps = await ref.watch(stampsStreamProvider.future);

  DateTimeRange effectiveRange = state.range;
  if (state.cycle == TimeCycle.all && stamps.isNotEmpty) {
    final dates = stamps.map((s) => dateFromStamp(s.stamp)).toList()..sort();
    final earliest =
        DateTime(dates.first.year, dates.first.month, dates.first.day);
    final today = DateTime.now();
    effectiveRange = DateTimeRange(
      start: earliest,
      end: DateTime(today.year, today.month, today.day),
    );
  }

  return stamps.whereType<Response>().where((r) {
    final date = dateFromStamp(r.stamp);
    return !date.isBefore(effectiveRange.start) &&
        date.isBefore(effectiveRange.end);
  }).toList();
});

final dashboardContextProvider = Provider.autoDispose<DashboardContext>((ref) {
  final responses = ref.watch(dashboardResponsesProvider).valueOrNull ?? [];
  if (responses.isEmpty) return DashboardContext.empty;
  return DashboardContext.build(responses);
});

final dashboardStatsProvider = Provider.autoDispose<List<DashboardStat>>((ref) {
  final ctx = ref.watch(dashboardContextProvider);
  return DashboardStat.build(ctx);
});
final dashboardInsightsProvider = Provider.autoDispose<List<Insight>>((ref) {
  final responses = ref.watch(dashboardResponsesProvider).valueOrNull ?? [];
  if (responses.isEmpty) return [];

  final state = ref.watch(dashboardStateProvider);
  return Insight.fromResponses(
    responses,
    timeCycle: state.cycle,
    range: state.range,
  );
});

final dashboardWeekdayCountsProvider =
    Provider.autoDispose<Map<int, int>>((ref) {
  final ctx = ref.watch(dashboardContextProvider);
  return ctx.weekdayCounts;
});

final dashboardDailyCountsProvider =
    Provider.autoDispose<Map<DateTime, int>>((ref) {
  final ctx = ref.watch(dashboardContextProvider);
  return ctx.dailyCounts;
});
