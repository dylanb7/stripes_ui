import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';

import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';

enum Loc {
  day,
  graph;
}

enum GraphChoice {
  day,
  week,
  month,
  year;
}

enum DayChoice {
  day,
  month,
  all;
}

const Duration dayDuration = Duration(days: 1);
const Duration weekDuration = Duration(days: 7);
const Duration monthDuration = Duration(days: 30);
const Duration yearDuration = Duration(days: 365);

enum ShiftAmount {
  day(dayDuration),
  week(weekDuration),
  month(monthDuration),
  year(yearDuration);

  const ShiftAmount(this.amount);

  final Duration amount;
}

enum ShiftDirection { future, past }

@immutable
class HistoryLocation {
  final Loc loc;
  final GraphChoice graph;
  final DayChoice day;
  const HistoryLocation({
    required this.loc,
    required this.graph,
    required this.day,
  });

  HistoryLocation copyWith({
    Loc? location,
    GraphChoice? graphChoice,
    DayChoice? dayChoice,
  }) =>
      HistoryLocation(
        loc: location ?? loc,
        graph: graphChoice ?? graph,
        day: dayChoice ?? day,
      );

  List<Enum> get selectedValues =>
      loc == Loc.day ? DayChoice.values : GraphChoice.values;

  Enum get selectedValue => loc == Loc.day ? day : graph;
}

const initialLoc =
    HistoryLocation(loc: Loc.day, day: DayChoice.day, graph: GraphChoice.day);

const Map<GraphChoice, Duration> graphToDuration = {
  GraphChoice.day: dayDuration,
  GraphChoice.week: weekDuration,
  GraphChoice.month: monthDuration,
  GraphChoice.year: yearDuration,
};

const Map<GraphChoice, ShiftAmount> graphToShift = {
  GraphChoice.day: ShiftAmount.day,
  GraphChoice.week: ShiftAmount.week,
  GraphChoice.month: ShiftAmount.month,
  GraphChoice.year: ShiftAmount.year,
};

class Available {
  late final List<Response<Question>> _filteredInRange;

  late final List<Response<Question>> _visible;

  late final List<Response<Question>> _filteredVisible;

  late final List<Response<Question>> _all;

  final Filters filters;

  Available(
      {required List<Response<Question>> allStamps, required this.filters}) {
    _all = allStamps;
    _filteredInRange = _filter(_getStamps(_all, null, null, null, true));
    _visible = _getStamps(allStamps, filters.selectedDate, filters.rangeStart,
        filters.rangeEnd, false);
    _filteredVisible = _filter(_visible);
  }

  List<Response> get all => _all;

  List<Response> get filteredInRange => _filteredInRange;

  List<Response> get visible => _visible;

  List<Response> get filteredVisible => _filteredVisible;

  List<Response> _filter(List<Response> stamps) {
    if (filters.stampFilters == null || filters.stampFilters!.isEmpty) {
      return stamps;
    }
    return stamps.where((element) {
      for (final LabeledFilter stampFilter in filters.stampFilters!) {
        if (stampFilter.filter(element)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  List<Response<Question>> _getStamps(
      List<Response<Question>> allStamps,
      DateTime? selected,
      DateTime? rangeStart,
      DateTime? rangeEnd,
      bool includeTotalRange) {
    if (selected != null) {
      return allStamps.where((element) => _sameDay(selected, element)).toList();
    }
    if (rangeStart != null && rangeEnd != null) {
      return allStamps
          .where((element) => inRange(rangeStart, rangeEnd, element))
          .toList();
    }
    if (rangeStart != null) {
      return allStamps
          .where((element) => _sameDay(rangeStart, element))
          .toList();
    }
    final DateTime? earliest = filters.earliestRequired;
    final DateTime? latest = filters.latestRequired;
    if (!includeTotalRange || earliest == null || latest == null) return [];
    return allStamps
        .where((element) => inRange(earliest, latest, element))
        .toList();
  }

  bool _sameDay(DateTime day, Response test) {
    final DateTime testDate = dateFromStamp(test.stamp);
    return day.year == testDate.year &&
        day.month == testDate.month &&
        day.day == testDate.day;
  }

  @override
  String toString() {
    return '\nIn Range: \n$filteredInRange \n\nVisible: \n$visible \n\nFiltered Visible: \n$filteredVisible';
  }
}

bool inRange(DateTime rangeStart, DateTime rangeEnd, Response test) {
  final DateTime testDate = dateFromStamp(test.stamp);
  return rangeStart.isBefore(testDate) && rangeEnd.isAfter(testDate) ||
      sameDay(rangeStart, testDate) ||
      sameDay(rangeEnd, testDate);
}

class CalendarEvent {
  final Response res;

  final DateTime date;

  CalendarEvent(this.res, this.date);

  DateTime getDate() => date;

  String? getTitle() => res.type;

  Response get response => res;
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

Map<DateTime, List<Response>> generateEventMap(List<Response> responses) {
  LinkedHashMap<DateTime, List<Response>> eventMap =
      LinkedHashMap(equals: sameDay, hashCode: getHashCode);

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

typedef StampFilter = bool Function(Stamp);

@immutable
class LabeledFilter with EquatableMixin {
  final String name;
  final StampFilter filter;

  const LabeledFilter({required this.name, required this.filter});

  @override
  List<Object?> get props => [name, filter];
}

@immutable
class Filters with EquatableMixin {
  final DateTime? selectedDate;

  final DateTime? earliestRequired, latestRequired;

  final DateTime? rangeStart, rangeEnd;

  final List<LabeledFilter>? stampFilters;

  const Filters(
      {required this.rangeStart,
      required this.rangeEnd,
      this.latestRequired,
      this.earliestRequired,
      this.selectedDate,
      this.stampFilters});

  factory Filters.reset({
    HistoryLocation location = const HistoryLocation(
        day: DayChoice.day, loc: Loc.day, graph: GraphChoice.day),
  }) =>
      const Filters(
        rangeStart: null,
        rangeEnd: null,
        earliestRequired: null,
        latestRequired: null,
        selectedDate: null,
      );

  Filters copyWith(
          {DateTime? selectedDate,
          DateTime? rangeStart,
          DateTime? rangeEnd,
          DateTime? earliestRequired,
          DateTime? latestRequired,
          List<LabeledFilter>? stampFilters}) =>
      Filters(
          rangeStart: rangeStart ?? this.rangeStart,
          rangeEnd: rangeEnd ?? this.rangeEnd,
          selectedDate: selectedDate ?? this.selectedDate,
          earliestRequired: earliestRequired ?? this.earliestRequired,
          latestRequired: latestRequired ?? this.latestRequired,
          stampFilters: stampFilters ?? this.stampFilters);

  String toRange(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    final DateFormat yearFormat = DateFormat.yMMMd(locale);
    if (selectedDate != null) {
      return yearFormat.format(selectedDate!);
    }
    if (rangeStart != null && rangeEnd == null) {
      return yearFormat.format(rangeStart!);
    }
    if (rangeStart == null && rangeEnd == null) return '';
    final bool sameYear = rangeEnd!.year == rangeStart!.year;
    final bool sameMonth = sameYear && rangeEnd!.month == rangeStart!.month;
    final String firstPortion = sameYear
        ? DateFormat.MMMd(locale).format(rangeStart!)
        : yearFormat.format(rangeStart!);
    final String lastPortion = sameMonth
        ? '${DateFormat.d(locale).format(rangeEnd!)}, ${DateFormat.y(locale).format(rangeEnd!)}'
        : yearFormat.format(rangeEnd!);
    return '$firstPortion - $lastPortion';
  }

  @override
  List<Object?> get props => [selectedDate, rangeStart, rangeEnd, stampFilters];
}

final historyLocationProvider =
    StateProvider<HistoryLocation>((_) => initialLoc);

final filtersProvider = StateProvider<Filters>((_) => Filters.reset());

final availibleStampsProvider =
    FutureProvider.autoDispose<Available>((ref) async {
  final StampNotifier notifier = ref.watch(stampHolderProvider.notifier);
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);
  final Filters filters = ref.watch(filtersProvider);
  if (filters.earliestRequired != null) {
    notifier.changeEarliest(filters.earliestRequired!);
  }
  return Available(allStamps: _convertStamps(stamps), filters: filters);
});

final eventsMapProvider =
    FutureProvider.autoDispose<Map<DateTime, List<Response>>>((ref) async {
  final Available available = await ref.watch(availibleStampsProvider.future);
  return generateEventMap(available.filteredInRange);
});

List<Response> _convertStamps(List<Stamp> stamps) {
  return stamps is List<Response>
      ? stamps
      : stamps.whereType<Response>().toList();
}
