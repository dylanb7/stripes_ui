import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
export 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

abstract class HistoryFeature<T> {
  const HistoryFeature();
  T getValue(HistoryContext ctx);
}

abstract class ReducibleFeature<T> extends HistoryFeature<T> {
  const ReducibleFeature();

  T createInitialState();
  T reduce(T state, Response response);

  @override
  T getValue(HistoryContext ctx) => ctx.use(this);
}

class HistoryContext {
  final Map<Type, dynamic> _featureResults;
  final TimeCycle timeCycle;
  final DateTimeRange range;

  HistoryContext._({
    required Map<Type, dynamic> featureResults,
    required this.timeCycle,
    required this.range,
  }) : _featureResults = featureResults;

  T use<T>(HistoryFeature<T> feature) {
    if (feature is ReducibleFeature<T>) {
      final res = _featureResults[feature.runtimeType];
      if (res != null) return res as T;
    }
    return feature.getValue(this);
  }

  factory HistoryContext.build({
    required List<Response> responses,
    required List<ReducibleFeature> features,
    TimeCycle timeCycle = TimeCycle.custom,
    DateTimeRange? range,
  }) {
    final effectiveRange = range ??
        (responses.isEmpty
            ? DateTimeRange(start: DateTime.now(), end: DateTime.now())
            : DateTimeRange(
                start: dateFromStamp(responses.last.stamp),
                end: dateFromStamp(responses.first.stamp),
              ));

    final now = DateTime.now();
    DateTime effectiveEnd = effectiveRange.end;
    if (effectiveEnd.isAfter(now)) {
      effectiveEnd = now;
    }
    final finalRange =
        DateTimeRange(start: effectiveRange.start, end: effectiveEnd);

    final states = <Type, dynamic>{};
    for (final feature in features) {
      states[feature.runtimeType] = feature.createInitialState();
    }

    for (final response in responses) {
      final date = dateFromStamp(response.stamp);
      // Ensure we only process data within the final range
      if (date.isBefore(finalRange.start) || date.isAfter(finalRange.end)) {
        continue;
      }
      for (final feature in features) {
        final type = feature.runtimeType;
        states[type] = feature.reduce(states[type], response);
      }
    }

    return HistoryContext._(
      featureResults: states,
      timeCycle: timeCycle,
      range: finalRange,
    );
  }

  int get totalResponses => use(const TotalResponsesFeature());

  int get totalDaysInRange => DateRangeUtils.calendarDays(range);

  int get daysWithData => use(const DailyCountFeature()).length;
}

class TotalResponsesFeature extends ReducibleFeature<int> {
  const TotalResponsesFeature();
  @override
  int createInitialState() => 0;
  @override
  int reduce(int state, Response response) => state + 1;
}

class AllCategoriesFeature extends ReducibleFeature<Set<String>> {
  const AllCategoriesFeature();
  @override
  Set<String> createInitialState() => {};
  @override
  Set<String> reduce(Set<String> state, Response response) {
    if (response is DetailResponse) {
      state.add(response.type);
    } else if (response is BlueDyeResp) {
      state.add(response.type);
    }

    return state;
  }
}

class DailyCountFeature extends ReducibleFeature<Map<DateTime, int>> {
  const DailyCountFeature();
  @override
  Map<DateTime, int> createInitialState() => {};
  @override
  Map<DateTime, int> reduce(Map<DateTime, int> state, Response response) {
    final date = dateFromStamp(response.stamp);
    final dayOnly = DateTime(date.year, date.month, date.day);
    state[dayOnly] = (state[dayOnly] ?? 0) + 1;
    return state;
  }
}
