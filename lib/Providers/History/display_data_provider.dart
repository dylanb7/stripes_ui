import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';

import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

enum DisplayTimeCycle {
  day,
  week,
  month,
  custom;

  String get value {
    switch (this) {
      case DisplayTimeCycle.day:
        return "Day";
      case DisplayTimeCycle.week:
        return "Week";
      case DisplayTimeCycle.month:
        return "Month";
      case DisplayTimeCycle.custom:
        return "Custom";
    }
  }
}

enum ViewMode { events, graph }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.events);

@immutable
class DisplayDataSettings extends Equatable {
  final DateTimeRange range;
  final DisplayTimeCycle cycle;
  final List<LabeledFilter> filters;
  final GraphYAxis axis;
  final bool groupSymptoms, groupBars;

  const DisplayDataSettings({
    required this.range,
    required this.cycle,
    this.filters = const [],
    required this.axis,
    this.groupSymptoms = false,
    this.groupBars = false,
  });

  DisplayDataSettings copyWith({
    DateTimeRange? range,
    DisplayTimeCycle? cycle,
    List<LabeledFilter>? filters,
    GraphYAxis? axis,
    bool? groupSymptoms,
  }) {
    return DisplayDataSettings(
      range: range ?? this.range,
      cycle: cycle ?? this.cycle,
      filters: filters ?? this.filters,
      axis: axis ?? this.axis,
      groupSymptoms: groupSymptoms ?? this.groupSymptoms,
    );
  }

  bool isSingleDay() {
    return cycle == DisplayTimeCycle.day ||
        cycle == DisplayTimeCycle.custom && _sameDay(range.start, range.end);
  }

  String getRangeString(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;

    switch (cycle) {
      case DisplayTimeCycle.day:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMd(locale).format(range.start);
        }
        return DateFormat.yMMMd(locale).format(range.start);
      case DisplayTimeCycle.week:
        return getSmartRangeString(range, locale);

      case DisplayTimeCycle.month:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMM(locale).format(range.start);
        }
        return DateFormat.yMMM(locale).format(range.start);
      case DisplayTimeCycle.custom:
        return getSmartRangeString(range, locale);
    }
  }

  String getRangeStringFromCustom(DateTimeRange range, BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;

    switch (cycle) {
      case DisplayTimeCycle.day:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMd(locale).format(range.start);
        }
        return DateFormat.yMMMd(locale).format(range.start);
      case DisplayTimeCycle.week:
        return getSmartRangeString(range, locale);

      case DisplayTimeCycle.month:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMM(locale).format(range.start);
        }
        return DateFormat.yMMM(locale).format(range.start);
      case DisplayTimeCycle.custom:
        return getSmartRangeString(range, locale);
    }
  }

  Duration get duration {
    switch (cycle) {
      case DisplayTimeCycle.day:
        return const Duration(days: 1);
      case DisplayTimeCycle.week:
        return const Duration(days: 7);
      case DisplayTimeCycle.month:
        return const Duration(days: 30);
      case DisplayTimeCycle.custom:
        return range.end.difference(range.start);
    }
  }

  DateFormat getFormat() {
    switch (cycle) {
      case DisplayTimeCycle.day:
        return DateFormat.H();
      case DisplayTimeCycle.week:
        return DateFormat.E();
      case DisplayTimeCycle.month:
        return DateFormat.d();
      case DisplayTimeCycle.custom:
        return _getSmartLayout().format;
    }
  }

  int getBuckets() {
    switch (cycle) {
      case DisplayTimeCycle.day:
        return 24;
      case DisplayTimeCycle.week:
        return 7;
      case DisplayTimeCycle.month:
        return DateUtils.getDaysInMonth(range.start.year, range.start.month);
      case DisplayTimeCycle.custom:
        return _getSmartLayout().buckets;
    }
  }

  ({int buckets, DateFormat format}) _getSmartLayout() {
    final diff = range.duration;
    const int maxBars = 50;

    int calculateBuckets(int totalUnits, List<int> multiples) {
      if (totalUnits <= maxBars) return totalUnits;
      for (final m in multiples) {
        if (totalUnits / m <= maxBars) {
          return (totalUnits / m).ceil();
        }
      }
      return (totalUnits / multiples.last).ceil();
    }

    if (diff.inSeconds <= 120) {
      return (
        buckets: calculateBuckets(diff.inSeconds, [1, 2, 3, 5, 10, 15, 30]),
        format: DateFormat.Hms()
      );
    }
    if (diff.inMinutes <= 120) {
      return (
        buckets: calculateBuckets(diff.inMinutes, [1, 2, 3, 5, 10, 15, 30]),
        format: DateFormat.Hm()
      );
    }
    if (diff.inHours <= 48) {
      return (
        buckets: calculateBuckets(diff.inHours, [1, 2, 3, 4, 6, 8, 12]),
        format: DateFormat.j()
      );
    }
    if (diff.inDays <= 14) {
      return (
        buckets: calculateBuckets(diff.inDays, [1, 2, 7]),
        format: DateFormat.E()
      );
    }
    if (diff.inDays <= 365) {
      final weeks = (diff.inDays / 7).ceil();
      return (
        buckets: calculateBuckets(weeks, [1, 2, 4]),
        format: DateFormat.MMMd()
      );
    }
    if (diff.inDays <= 730) {
      final months = (diff.inDays / 30).ceil();
      return (
        buckets: calculateBuckets(months, [1, 2, 3, 4, 6]),
        format: DateFormat.MMM()
      );
    }

    final years = (diff.inDays / 365).ceil();
    return (
      buckets: calculateBuckets(years, [1, 2, 5, 10]),
      format: DateFormat.y()
    );
  }

  int getTitles() {
    switch (cycle) {
      case DisplayTimeCycle.day:
        return 4;
      case DisplayTimeCycle.week:
        return 7;
      case DisplayTimeCycle.month:
        return 4;
      case DisplayTimeCycle.custom:
        return 4;
    }
  }

  double getBarSpacing() {
    switch (cycle) {
      case DisplayTimeCycle.day:
        return 2.0;
      case DisplayTimeCycle.week:
        return 2.0;
      case DisplayTimeCycle.month:
        return 2.0;
      case DisplayTimeCycle.custom:
        return 2.0;
    }
  }

  @override
  List<Object?> get props => [range, cycle, filters, axis];

  bool get canGoNext => range.end.isBefore(DateTime.now());
  bool get canGoPrev => range.start.isAfter(SigDates.minDate);
}

class DisplayDataProvider extends StateNotifier<DisplayDataSettings> {
  DisplayDataProvider()
      : super(DisplayDataSettings(
          range: DateTimeRange(
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(days: 1))),
          cycle: DisplayTimeCycle.day,
          groupSymptoms: false,
          axis: GraphYAxis.number,
        )) {
    setCycle(DisplayTimeCycle.day);
  }

  void setCycle(DisplayTimeCycle cycle, {DateTime? seedStartTime}) {
    final DateTime seed = seedStartTime ?? DateTime.now();
    DateTimeRange newRange;
    switch (cycle) {
      case DisplayTimeCycle.day:
        final start = DateTime(seed.year, seed.month, seed.day);
        newRange = DateTimeRange(
          start: start,
          end: start.add(
            const Duration(days: 1),
          ),
        );
        break;
      case DisplayTimeCycle.week:
        final start = seed.subtract(Duration(days: seed.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        newRange = DateTimeRange(
            start: startDay, end: startDay.add(const Duration(days: 7)));
        break;
      case DisplayTimeCycle.month:
        final start = DateTime(seed.year, seed.month);
        final end = DateTime(seed.year, seed.month + 1, 0);
        newRange = DateTimeRange(start: start, end: end);
        break;
      case DisplayTimeCycle.custom:
        newRange = state.range;
        break;
    }
    state = state.copyWith(cycle: cycle, range: newRange);
  }

  void setRange(DateTimeRange range, {DisplayTimeCycle? cycle}) {
    state = state.copyWith(range: range, cycle: cycle ?? state.cycle);
  }

  void updateFilters(List<LabeledFilter> filters) {
    state = state.copyWith(filters: filters);
  }

  void setAxis(GraphYAxis axis) {
    state = state.copyWith(axis: axis);
  }

  void updateGroupSymptoms(bool group) {
    state = state.copyWith(groupSymptoms: group);
  }

  void shift({required bool forward}) {
    final DateTimeRange newRange = getNextRange(forward: forward);

    if (forward && newRange.start.isAfter(DateTime.now())) return;
    if (!forward && newRange.end.isBefore(SigDates.minDate)) return;

    state = state.copyWith(range: newRange);
  }

  DateTimeRange getNextRange({required bool forward}) {
    DateTime start = state.range.start;

    DateTime newStart;
    DateTime newEnd;

    switch (state.cycle) {
      case DisplayTimeCycle.day:
        const delta = Duration(days: 1);
        newStart = forward ? start.add(delta) : start.subtract(delta);
        newEnd = newStart.add(delta);
        break;
      case DisplayTimeCycle.week:
        const delta = Duration(days: 7);
        newStart = forward ? start.add(delta) : start.subtract(delta);
        newEnd = newStart.add(delta);
        break;
      case DisplayTimeCycle.month:
        if (forward) {
          newStart = DateTime(start.year, start.month + 1);
        } else {
          newStart = DateTime(start.year, start.month - 1);
        }
        newEnd = DateTime(newStart.year, newStart.month + 1, 0);
        break;
      case DisplayTimeCycle.custom:
        // Use the full duration of the custom range for shifting
        final duration = state.range.duration;
        // Ensure at least 1 day shift to prevent stuck ranges
        final shiftDuration =
            duration.inDays > 0 ? duration : const Duration(days: 1);
        newStart =
            forward ? start.add(shiftDuration) : start.subtract(shiftDuration);
        newEnd = newStart.add(shiftDuration);
        break;
    }

    return DateTimeRange(start: newStart, end: newEnd);
  }

  getNextRangeString({required bool forward, required BuildContext context}) {
    return state.getRangeStringFromCustom(
      getNextRange(forward: forward),
      context,
    );
  }
}

final displayDataProvider =
    StateNotifierProvider<DisplayDataProvider, DisplayDataSettings>((ref) {
  return DisplayDataProvider();
});

final inRangeProvider = FutureProvider.autoDispose<List<Response>>((ref) async {
  final DisplayDataSettings settings = ref.watch(displayDataProvider);
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);

  return stamps.whereType<Response>().where((response) {
    final date = dateFromStamp(response.stamp);
    if (date.isBefore(settings.range.start) ||
        date.isAfter(settings.range.end)) {
      return false;
    }
    return true;
  }).toList();
});

final availableStampsProvider =
    FutureProvider.autoDispose<List<Response>>((ref) async {
  final DisplayDataSettings settings = ref.watch(displayDataProvider);
  final List<Response> stamps = await ref.watch(inRangeProvider.future);

  final Map<String, List<LabeledFilter>> groupedFilters =
      settings.filters.groupBy((filter) => filter.filterType.name);

  return stamps.where((response) {
    if (settings.filters.isNotEmpty) {
      for (final filterGroup in groupedFilters.values) {
        bool matches = false;
        for (final filter in filterGroup) {
          if (filter.filter(response)) {
            matches = true;
            break;
          }
        }
        if (!matches) return false;
      }
    }
    return true;
  }).toList();
});

final graphStampsProvider =
    FutureProvider<Map<GraphKey, List<Response>>>((ref) async {
  final settings = ref.watch(displayDataProvider);
  final available = await ref.watch(availableStampsProvider.future);

  final SplayTreeMap<GraphKey, List<Response>> byType = SplayTreeMap(
    (a, b) => a.title.compareTo(b.title),
  );
  final SplayTreeMap<GraphKey, List<Response>> byQuestion = SplayTreeMap(
    (a, b) => a.title.compareTo(b.title),
  );

  for (final Response wrappedResponse in available) {
    final date = dateFromStamp(wrappedResponse.stamp);
    if (date.isBefore(settings.range.start) ||
        date.isAfter(settings.range.end)) {
      continue;
    }
    List<Response> flattened = _flattenedResponse(wrappedResponse);
    if (settings.axis == GraphYAxis.average) {
      flattened = flattened.whereType<NumericResponse>().toList();
    }
    for (final Response response in flattened) {
      final GraphKey key = GraphKey(
          title: response.question.prompt,
          isCategory: false,
          qid: response.question.id);
      if (byQuestion.containsKey(key)) {
        byQuestion[key]!.add(response);
      } else {
        byQuestion[key] = [response];
      }
      final GraphKey categoryKey = GraphKey(
        title: response.type,
        isCategory: true,
      );
      if (byType.containsKey(categoryKey)) {
        byType[categoryKey]!.add(response);
      } else {
        byType[categoryKey] = [response];
      }
    }
  }
  byType.addAll(byQuestion);
  return byType..addAll(byQuestion);
});

final eventsMapProvider =
    FutureProvider<Map<DateTime, List<Response>>>((ref) async {
  final settings = ref.watch(displayDataProvider);
  final stamps = await ref.watch(stampHolderProvider.future);

  // Group filters by type (same logic as availableStampsProvider)
  final Map<String, List<LabeledFilter>> groupedFilters =
      settings.filters.groupBy((filter) => filter.filterType.name);

  final filtered = stamps.whereType<Response>().where((response) {
    if (settings.filters.isNotEmpty) {
      // AND between filter groups, OR within each group
      for (final filterGroup in groupedFilters.values) {
        bool matches = false;
        for (final filter in filterGroup) {
          if (filter.filter(response)) {
            matches = true;
            break;
          }
        }
        if (!matches) return false;
      }
    }
    return true;
  }).toList();

  return generateEventMap(filtered);
});

List<Response> _flattenedResponses(Iterable<Response> input) {
  List<Response> flat = [];
  for (Response res in input) {
    if (res is DetailResponse) {
      flat.addAll(_flattenedResponses(res.responses));
    } else {
      flat.add(res);
    }
  }
  return flat;
}

List<Response> _flattenedResponse(Response input) {
  return _flattenedResponses([input]);
}

int _getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Map<DateTime, List<Response>> generateEventMap(List<Response> responses) {
  LinkedHashMap<DateTime, List<Response>> eventMap =
      LinkedHashMap(equals: _sameDay, hashCode: _getHashCode);

  for (Response res in responses) {
    final DateTime resDate = dateFromStamp(res.stamp);
    if (eventMap.containsKey(resDate)) {
      eventMap[resDate]!.add(res);
    } else {
      eventMap[resDate] = [res];
    }
  }
  return eventMap;
}

String getSmartRangeString(DateTimeRange range, String locale,
    {bool includeTime = false}) {
  final start = range.start;
  DateTime end = range.end;
  if (end.hour == 0 &&
      end.minute == 0 &&
      end.second == 0 &&
      end.millisecond == 0) {
    end = end.subtract(const Duration(milliseconds: 1));
  }

  final bool sameYear = start.year == end.year;
  final bool sameMonth = sameYear && start.month == end.month;
  final bool sameDay = sameMonth && start.day == end.day;

  final int currentYear = DateTime.now().year;

  final timeFormat = DateFormat.jm(locale);

  if (sameDay) {
    final datePart = DateFormat.yMMMd(locale).format(start);

    if (!includeTime) return datePart;
    if (start.hour == end.hour && start.minute == end.minute) {
      return '$datePart, ${timeFormat.format(start)}';
    }

    return '$datePart, ${timeFormat.format(start)} - ${timeFormat.format(end)}';
  }

  if (sameMonth) {
    String startPart = DateFormat.MMMd(locale).format(start);
    String endPart = DateFormat.d(locale).format(end);

    if (includeTime) {
      startPart = '$startPart, ${timeFormat.format(start)}';
      endPart = '$endPart, ${timeFormat.format(end)}';
    }

    if (end.year == currentYear) {
      return '$startPart - $endPart';
    }

    final year = DateFormat.y(locale).format(end);
    return '$startPart - $endPart, $year';
  }

  if (sameYear) {
    String startPart = DateFormat.MMMd(locale).format(start);
    String endPart = DateFormat.MMMd(locale).format(end);

    if (includeTime) {
      startPart = '$startPart, ${timeFormat.format(start)}';
      endPart = '$endPart, ${timeFormat.format(end)}';
    }

    if (end.year == currentYear) {
      return '$startPart - $endPart';
    }

    final year = DateFormat.y(locale).format(end);
    return '$startPart - $endPart, $year';
  }

  String startPart = DateFormat.yMMMd(locale).format(start);
  String endPart = DateFormat.yMMMd(locale).format(end);

  if (includeTime) {
    startPart = '$startPart, ${timeFormat.format(start)}';
    endPart = '$endPart, ${timeFormat.format(end)}';
  }

  return '$startPart - $endPart';
}

enum GraphYAxis {
  number("Number"),
  average("Average"),
  entrytime("Time");

  final String value;

  const GraphYAxis(this.value);
}

@immutable
class GraphKey extends Equatable {
  final bool isCategory;
  final String title;
  final String? qid;

  const GraphKey({required this.title, required this.isCategory, this.qid});

  String toLocalizedString(BuildContext context) {
    QuestionsLocalizations? localizations = QuestionsLocalizations.of(context);
    return "${isCategory ? "Category · " : ""} ${localizations?.value(title) ?? title}";
  }

  @override
  List<Object?> get props => [isCategory, title, qid];
}

typedef StampFilter = bool Function(Stamp);

@immutable
class LabeledFilter with EquatableMixin {
  final String name;
  final FilterType filterType;
  final StampFilter filter;

  const LabeledFilter(
      {required this.name, required this.filterType, required this.filter});

  @override
  List<Object?> get props => [name, filter, filterType];
}
