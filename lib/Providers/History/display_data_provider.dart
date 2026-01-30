import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';

import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/UI/History/Timeline/review_period_data.dart';

// TimeCycle is now imported from date_range_utils.dart\n
enum ViewMode { events, graph }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.events);

@immutable
class DisplayDataSettings extends Equatable {
  final DateTimeRange range;
  final TimeCycle cycle;
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
    TimeCycle? cycle,
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
    return cycle == TimeCycle.day ||
        cycle == TimeCycle.custom && _sameDay(range.start, range.end);
  }

  String getRangeString(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;

    switch (cycle) {
      case TimeCycle.day:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMd(locale).format(range.start);
        }
        return DateFormat.yMMMd(locale).format(range.start);
      case TimeCycle.week:
        return getSmartRangeString(range, locale);

      case TimeCycle.month:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMM(locale).format(range.start);
        }
        return DateFormat.yMMM(locale).format(range.start);
      case TimeCycle.custom:
        return getSmartRangeString(range, locale);
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
        return DateRangeUtils.formatRange(range, cycle, locale);
    }
  }

  String getRangeStringFromCustom(DateTimeRange range, BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;

    switch (cycle) {
      case TimeCycle.day:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMd(locale).format(range.start);
        }
        return DateFormat.yMMMd(locale).format(range.start);
      case TimeCycle.week:
        return getSmartRangeString(range, locale);

      case TimeCycle.month:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMM(locale).format(range.start);
        }
        return DateFormat.yMMM(locale).format(range.start);
      case TimeCycle.custom:
        return getSmartRangeString(range, locale);
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
        return DateRangeUtils.formatRange(range, cycle, locale);
    }
  }

  Duration get duration {
    switch (cycle) {
      case TimeCycle.day:
        return const Duration(days: 1);
      case TimeCycle.week:
        return const Duration(days: 7);
      case TimeCycle.month:
        return const Duration(days: 30);
      case TimeCycle.custom:
        return range.end.difference(range.start);
      case TimeCycle.quarter:
        return const Duration(days: 90);
      case TimeCycle.year:
        return const Duration(days: 365);
      case TimeCycle.all:
        return range.end.difference(range.start);
    }
  }

  DateFormat getFormat() {
    switch (cycle) {
      case TimeCycle.day:
        return DateFormat.j();
      case TimeCycle.week:
        return DateFormat.E();
      case TimeCycle.month:
        return DateFormat.d();
      case TimeCycle.custom:
        return _getSmartLayout().format;
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
        return _getSmartLayout().format;
    }
  }

  int getBuckets() {
    switch (cycle) {
      case TimeCycle.day:
        return 24;
      case TimeCycle.week:
        return 7;
      case TimeCycle.month:
        return DateUtils.getDaysInMonth(range.start.year, range.start.month);
      case TimeCycle.custom:
        return _getSmartLayout().buckets;
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
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
      case TimeCycle.day:
        return 4;
      case TimeCycle.week:
        return 7;
      case TimeCycle.month:
        return 4;
      case TimeCycle.custom:
        return 4;
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
        return 4;
    }
  }

  double getBarSpacing() {
    switch (cycle) {
      case TimeCycle.day:
        return 2.0;
      case TimeCycle.week:
        return 2.0;
      case TimeCycle.month:
        return 2.0;
      case TimeCycle.custom:
        return 2.0;
      case TimeCycle.quarter:
      case TimeCycle.year:
      case TimeCycle.all:
        return 2.0;
    }
  }

  @override
  List<Object?> get props => [range, cycle, filters, axis];

  bool get canGoNext => range.end.isBefore(DateTime.now());
  bool get canGoPrev => range.start.isAfter(SigDates.minDate);
}

class DisplayDataProvider extends StateNotifier<DisplayDataSettings> {
  final Ref ref;

  DisplayDataProvider(this.ref)
      : super(DisplayDataSettings(
          range: DateTimeRange(
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(days: 1))),
          cycle: TimeCycle.day,
          groupSymptoms: false,
          axis: GraphYAxis.number,
        )) {
    setCycle(TimeCycle.day);
  }

  void setCycle(TimeCycle cycle, {DateTime? seedStartTime}) {
    final DateTime seed = seedStartTime ?? DateTime.now();
    DateTimeRange newRange;
    if (cycle == TimeCycle.custom) {
      newRange = state.range;
    } else {
      newRange = DateRangeUtils.calculateRange(cycle, seed);
    }

    changeEarliestDate(ref, newRange.start);
    state = state.copyWith(cycle: cycle, range: newRange);
  }

  void ensureDate(DateTime date) {
    changeEarliestDate(ref, date);
  }

  void setRange(DateTimeRange range, {TimeCycle? cycle}) {
    changeEarliestDate(ref, range.start);
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

    changeEarliestDate(ref, newRange.start);
    state = state.copyWith(range: newRange);
  }

  DateTimeRange getNextRange({required bool forward}) {
    return DateRangeUtils.shiftRange(
      state.range,
      state.cycle,
      forward,
    );
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
  return DisplayDataProvider(ref);
});

final inRangeProvider = FutureProvider.autoDispose<List<Response>>((ref) async {
  final DisplayDataSettings settings = ref.watch(displayDataProvider);
  final List<Stamp> stamps = await ref.watch(stampsStreamProvider.future);

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

  // Watch review paths to determine which types are reviews
  final reviewPathsMap = await ref.watch(reviewPathsByTypeProvider.future);

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
      // Check if this type is a review (has a period)
      final reviewPath = reviewPathsMap[response.type];
      final bool isReview = reviewPath?.period != null;

      final GraphKey key = GraphKey(
        title: response.question.prompt,
        isCategory: false,
        qid: response.question.id,
        type: response.type,
        isReview: isReview,
      );
      if (byQuestion.containsKey(key)) {
        byQuestion[key]!.add(response);
      } else {
        byQuestion[key] = [response];
      }
      final GraphKey categoryKey = GraphKey(
        title: response.type,
        isCategory: true,
        type: response.type,
        isReview: isReview,
      );
      if (byType.containsKey(categoryKey)) {
        byType[categoryKey]!.add(response);
      } else {
        byType[categoryKey] = [response];
      }
    }
  }
  // Create a combined map but avoid adding redundant category keys
  // if they only contain a single symptom with the same name/prompt.
  final Map<GraphKey, List<Response>> combined = {};

  // Group byCategory keys and see if they are redundant
  for (final catEntry in byType.entries) {
    final catKey = catEntry.key;
    final catResponses = catEntry.value;

    // Find if there's an exact matching question key
    final matchingQuestion = byQuestion.entries.firstWhereOrNull((q) =>
        q.key.title == catKey.title &&
        q.value.length == catResponses.length &&
        listEquals(q.value, catResponses));

    if (matchingQuestion == null) {
      combined[catKey] = catResponses;
    }
  }

  combined.addAll(byQuestion);
  return SplayTreeMap<GraphKey, List<Response>>.from(
    combined,
    (a, b) => a.title.compareTo(b.title),
  );
});

final eventsMapProvider =
    FutureProvider<Map<DateTime, List<Response>>>((ref) async {
  final settings = ref.watch(displayDataProvider);
  final stamps = ref.watch(stampsStreamProvider).valueOrNull ?? [];

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

final unfilteredEventsMapProvider =
    FutureProvider<Map<DateTime, List<Response>>>((ref) async {
  final stamps = await ref.watch(stampsStreamProvider.future);

  final allResponses = stamps.whereType<Response>().toList();

  return generateEventMap(allResponses);
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
  final String? type;
  final bool isReview;

  const GraphKey({
    required this.title,
    required this.isCategory,
    this.qid,
    this.type,
    this.isReview = false,
  });

  String toLocalizedString(BuildContext context) {
    QuestionsLocalizations? localizations = QuestionsLocalizations.of(context);
    return "${isCategory ? "Category · " : ""} ${localizations?.value(title) ?? title}";
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCategory': isCategory,
      'qid': qid,
      'type': type,
      'isReview': isReview,
    };
  }

  factory GraphKey.fromJson(Map<String, dynamic> map) {
    return GraphKey(
      title: map['title'] as String,
      isCategory: map['isCategory'] as bool,
      qid: map['qid'] as String?,
      type: map['type'] as String?,
      isReview: map['isReview'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [isCategory, title, qid, type, isReview];
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
