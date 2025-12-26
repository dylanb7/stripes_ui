import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

abstract class InsightFeature<T> {
  const InsightFeature();
  T getValue(InsightContext ctx);
}

abstract class ReducibleFeature<T> extends InsightFeature<T> {
  const ReducibleFeature();

  T createInitialState();
  T reduce(T state, Response response);

  @override
  T getValue(InsightContext ctx) => ctx.use(this);
}

class InsightContext {
  final Map<Type, dynamic> _featureResults;
  final TimeCycle timeCycle;
  final DateTimeRange range;

  InsightContext._({
    required Map<Type, dynamic> featureResults,
    required this.timeCycle,
    required this.range,
  }) : _featureResults = featureResults;

  T use<T>(InsightFeature<T> feature) {
    if (feature is ReducibleFeature<T>) {
      final res = _featureResults[feature.runtimeType];
      if (res != null) return res as T;
    }
    return feature.getValue(this);
  }

  factory InsightContext.build({
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
      for (final feature in features) {
        final type = feature.runtimeType;
        states[type] = feature.reduce(states[type], response);
      }
    }

    return InsightContext._(
      featureResults: states,
      timeCycle: timeCycle,
      range: finalRange,
    );
  }

  int get totalResponses => use(const TotalResponsesFeature());

  int get totalDaysInRange => range.duration.inDays;

  int get daysWithData => use(const DailyCountFeature()).length;
}

// =============================================================================
// Core Features
// =============================================================================

class TotalResponsesFeature extends ReducibleFeature<int> {
  const TotalResponsesFeature();
  @override
  int createInitialState() => 0;
  @override
  int reduce(int state, Response response) => state + 1;
}

class HourlyCountFeature extends ReducibleFeature<Map<int, int>> {
  const HourlyCountFeature();
  @override
  Map<int, int> createInitialState() => {};
  @override
  Map<int, int> reduce(Map<int, int> state, Response response) {
    final hour = dateFromStamp(response.stamp).hour;
    state[hour] = (state[hour] ?? 0) + 1;
    return state;
  }
}

class WeekdayCountFeature extends ReducibleFeature<Map<int, int>> {
  const WeekdayCountFeature();
  @override
  Map<int, int> createInitialState() => {};
  @override
  Map<int, int> reduce(Map<int, int> state, Response response) {
    final dayOfWeek = dateFromStamp(response.stamp).weekday;
    state[dayOfWeek] = (state[dayOfWeek] ?? 0) + 1;
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

class DayCategoryFeature
    extends ReducibleFeature<Map<DateTime, Map<String, int>>> {
  const DayCategoryFeature();
  @override
  Map<DateTime, Map<String, int>> createInitialState() => {};
  @override
  Map<DateTime, Map<String, int>> reduce(
      Map<DateTime, Map<String, int>> state, Response response) {
    if (response is DetailResponse) {
      final DateTime date = dateFromStamp(response.stamp);

      final DateTime dayOnly = DateUtils.dateOnly(date);

      state.putIfAbsent(dayOnly, () => {response.type: 0});
      state[dayOnly]![response.type] =
          (state[dayOnly]![response.type] ?? 0) + 1;
    }
    return state;
  }
}

class GlobalSymptomValueFeature
    extends ReducibleFeature<Map<String, List<double>>> {
  const GlobalSymptomValueFeature();
  @override
  Map<String, List<double>> createInitialState() => {};
  @override
  Map<String, List<double>> reduce(
      Map<String, List<double>> state, Response response) {
    if (response is DetailResponse) {
      for (final r in response.responses) {
        if (r is NumericResponse) {
          final String symptom =
              r.question.prompt.isNotEmpty ? r.question.prompt : r.question.id;
          state.putIfAbsent(symptom, () => []).add(r.response.toDouble());
        }
      }
    }
    return state;
  }
}

class DaySymptomFeature
    extends ReducibleFeature<Map<DateTime, Map<String, List<double>>>> {
  const DaySymptomFeature();
  @override
  Map<DateTime, Map<String, List<double>>> createInitialState() => {};
  @override
  Map<DateTime, Map<String, List<double>>> reduce(
      Map<DateTime, Map<String, List<double>>> state, Response response) {
    if (response is DetailResponse) {
      final date = dateFromStamp(response.stamp);
      final dayOnly = DateTime(date.year, date.month, date.day);
      state.putIfAbsent(dayOnly, () => {});
      for (final r in response.responses) {
        if (r is NumericResponse) {
          final String symptom =
              r.question.prompt.isNotEmpty ? r.question.prompt : r.question.id;
          state[dayOnly]!
              .putIfAbsent(symptom, () => [])
              .add(r.response.toDouble());
        }
      }
    }
    return state;
  }
}

class CategoryTimestampFeature
    extends ReducibleFeature<Map<String, List<DateTime>>> {
  const CategoryTimestampFeature();
  @override
  Map<String, List<DateTime>> createInitialState() => {};
  @override
  Map<String, List<DateTime>> reduce(
      Map<String, List<DateTime>> state, Response response) {
    final type = response is DetailResponse ? response.type : 'general';
    state.putIfAbsent(type, () => []).add(dateFromStamp(response.stamp));
    return state;
  }
}
