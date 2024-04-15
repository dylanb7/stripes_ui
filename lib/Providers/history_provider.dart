import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';

import 'package:stripes_ui/Providers/stamps_provider.dart';

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
    _filteredInRange = _filter(_getStamps(_all, null, filters.range));
    _visible = _getStamps(allStamps, filters.selectedDate, filters.range);
    _filteredVisible = _filter(_visible);
  }

  List<Response> get all => _all;

  List<Response> get filteredInRange => _filteredInRange;

  List<Response> get visible => _visible;

  List<Response> get filteredVisible => _filteredVisible;

  List<Response> _filter(List<Response> stamps) {
    if (filters.filter == null) return stamps;
    return stamps.where((element) => filters.filter!.call(element)).toList();
  }

  List<Response<Question>> _getStamps(
    List<Response<Question>> allStamps,
    DateTime? selected,
    DateTimeRange? range,
  ) {
    if (selected != null) {
      return allStamps.where((element) => _sameDay(selected, element)).toList();
    }
    if (range != null) {
      return allStamps.where((element) => _inRange(range, element)).toList();
    }
    return allStamps;
  }

  bool _sameDay(DateTime day, Response test) {
    final DateTime testDate = dateFromStamp(test.stamp);
    return day.year == testDate.year &&
        day.month == testDate.month &&
        day.day == testDate.day;
  }

  bool _inRange(DateTimeRange range, Response test) {
    final DateTime testDate = dateFromStamp(test.stamp);
    return range.start.isBefore(testDate) && range.end.isAfter(testDate);
  }

  @override
  String toString() {
    // TODO: implement toString
    return '\nIn Range: \n$filteredInRange \n\nVisible: \n$visible \n\nFiltered Visible: \n$filteredVisible';
  }
}

class CalendarEvent extends EventInterface {
  final Response res;

  final DateTime date;

  CalendarEvent(this.res, this.date);

  @override
  DateTime getDate() => date;

  @override
  String? getDescription() => res.question.prompt;

  @override
  Widget? getDot() => null;

  @override
  Widget? getIcon() => null;

  @override
  int? getId() => null;

  @override
  String? getLocation() => null;

  @override
  String? getTitle() => res.type;

  Response get response => res;
}

Map<DateTime, List<Response>> generateEventMap(List<Response> responses) {
  Map<DateTime, List<Response>> eventMap = {};
  for (Response res in responses) {
    final DateTime resDate = dateFromStamp(res.stamp);
    final DateTime calDate =
        DateTime.utc(resDate.year, resDate.month, resDate.day, 0, 0, 0, 0, 0);
    if (eventMap.containsKey(calDate)) {
      eventMap[calDate]!.add(res);
    } else {
      eventMap[calDate] = [res];
    }
  }
  return eventMap;
}

@immutable
class Filters with EquatableMixin {
  final DateTime? selectedDate;

  final DateTimeRange? range;

  final bool Function(Stamp)? filter;

  const Filters({required this.range, this.selectedDate, this.filter});

  factory Filters.reset({
    HistoryLocation location = const HistoryLocation(
        day: DayChoice.day, loc: Loc.day, graph: GraphChoice.day),
  }) =>
      Filters(
        range: null,
        selectedDate: location.day == DayChoice.day ? DateTime.now() : null,
      );

  Filters copyWith(
          {DateTime? selectDate,
          DateTimeRange? range,
          bool Function(Stamp)? filt}) =>
      Filters(
          range: range ?? this.range,
          selectedDate: selectDate,
          filter: filt ?? filter);

  String toRange(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    final DateFormat yearFormat = DateFormat.yMMMd(locale);
    if (selectedDate != null) return yearFormat.format(selectedDate!);
    if (range == null) return '';
    final bool sameYear = range!.end.year == range!.start.year;
    final bool sameMonth = sameYear && range!.end.month == range!.start.month;
    final String firstPortion = sameYear
        ? DateFormat.MMMd(locale).format(range!.start)
        : yearFormat.format(range!.start);
    final String lastPortion = sameMonth
        ? '${DateFormat.d(locale).format(range!.end)}, ${DateFormat.y(locale).format(range!.end)}'
        : yearFormat.format(range!.end);
    return '$firstPortion - $lastPortion';
  }

  @override
  List<Object?> get props => [selectedDate, range, filter];
}

final historyLocationProvider =
    StateProvider<HistoryLocation>((_) => initialLoc);

final filtersProvider = StateProvider<Filters>((_) => Filters.reset());

final availibleStampsProvider =
    FutureProvider.autoDispose<Available>((ref) async {
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);
  final Filters filters = ref.watch(filtersProvider);
  return Available(allStamps: _convertStamps(stamps), filters: filters);
});

final eventsMapProvider =
    FutureProvider.autoDispose<Map<DateTime, List<Response>>>((ref) async {
  final Available available = await ref.watch(availibleStampsProvider.future);

  return generateEventMap(available.all);
});

List<Response> _convertStamps(List<Stamp> stamps) {
  return stamps is List<Response>
      ? stamps
      : stamps.whereType<Response>().toList();
}
