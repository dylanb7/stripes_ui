import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Util/Helpers/history_reducer.dart';

export 'package:stripes_ui/Util/Helpers/history_reducer.dart';

class HourlyCountFeature extends ReducibleFeature<Map<int, int>> {
  const HourlyCountFeature();
  @override
  Map<int, int> createInitialState() => {};
  @override
  Map<int, int> reduce(Map<int, int> state, Response response) {
    if (!_hasExactEventTime(response)) return state;
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
    final dayOfWeek = occurrenceTimeForResponse(response).weekday;
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
    Map<DateTime, Map<String, int>> state,
    Response response,
  ) {
    if (response is DetailResponse) {
      final DateTime date = occurrenceTimeForResponse(response);
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
    Map<String, List<double>> state,
    Response response,
  ) {
    if (response is DetailResponse) {
      for (final r in response.responses) {
        if (r is NumericResponse) {
          final String symptom = r.question.prompt.isNotEmpty
              ? r.question.prompt
              : r.question.id;
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
    Map<DateTime, Map<String, List<double>>> state,
    Response response,
  ) {
    if (response is DetailResponse) {
      final date = occurrenceTimeForResponse(response);
      final dayOnly = DateTime(date.year, date.month, date.day);
      state.putIfAbsent(dayOnly, () => {});
      for (final r in response.responses) {
        if (r case NumericResponse(:Numeric question, :num response)) {
          final String symptom = question.prompt.isNotEmpty
              ? question.prompt
              : question.id;
          state[dayOnly]!
              .putIfAbsent(symptom, () => [])
              .add(response.toDouble());
        }
      }
    }
    return state;
  }
}

class SymptomCategoryFeature extends ReducibleFeature<Map<String, String>> {
  const SymptomCategoryFeature();
  @override
  Map<String, String> createInitialState() => {};
  @override
  Map<String, String> reduce(Map<String, String> state, Response response) {
    if (response is DetailResponse) {
      for (final r in response.responses) {
        if (r is NumericResponse) {
          final symptom = r.question.prompt.isNotEmpty
              ? r.question.prompt
              : r.question.id;
          state.putIfAbsent(symptom, () => response.type);
        }
      }
    }
    return state;
  }
}

class ChoiceDistributionFeature
    extends ReducibleFeature<Map<String, Map<String, int>>> {
  const ChoiceDistributionFeature();
  @override
  Map<String, Map<String, int>> createInitialState() => {};
  @override
  Map<String, Map<String, int>> reduce(
    Map<String, Map<String, int>> state,
    Response response,
  ) {
    if (response is DetailResponse) {
      for (final r in response.responses) {
        if (r is MultiResponse) {
          final questionId = r.question.prompt.isNotEmpty
              ? r.question.prompt
              : r.question.id;
          state.putIfAbsent(questionId, () => {});
          state[questionId]![r.choice] =
              (state[questionId]![r.choice] ?? 0) + 1;
        } else if (r is AllResponse) {
          final questionId = r.question.prompt.isNotEmpty
              ? r.question.prompt
              : r.question.id;
          state.putIfAbsent(questionId, () => {});
          for (final choice in r.choices) {
            state[questionId]![choice] = (state[questionId]![choice] ?? 0) + 1;
          }
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
    Map<String, List<DateTime>> state,
    Response response,
  ) {
    // Sorting anchors for uncertain times cannot establish temporal order,
    // delays, or bursts of activity.
    if (!_hasExactEventTime(response)) return state;
    final type = response is DetailResponse ? response.type : 'general';
    state.putIfAbsent(type, () => []).add(dateFromStamp(response.stamp));
    return state;
  }
}

bool _hasExactEventTime(Response response) {
  if (hasApproximateRecordTime(response)) return false;
  final category = entryForResponse(response)?.category;
  return category != InputCategory.form && category != InputCategory.baseline;
}
