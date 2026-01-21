import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Helpers/history_reducer.dart';

export 'package:stripes_ui/Util/Helpers/history_reducer.dart';

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

      state.putIfAbsent(dayOnly, () => {});
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
        if (r
            case NumericResponse(
              :Numeric question,
              :num response,
            )) {
          final String symptom =
              question.prompt.isNotEmpty ? question.prompt : question.id;
          state[dayOnly]!
              .putIfAbsent(symptom, () => [])
              .add(response.toDouble());
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
