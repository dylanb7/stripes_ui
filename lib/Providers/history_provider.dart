import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late List<Response<Question>> _stamps;

  late List<Response<Question>> _filtered;

  late List<Response<Question>> _all;

  Available(
      {required List<Response<Question>> allStamps,
      required HistoryLocation location,
      required DateTime? selected,
      required DateTime month,
      required DateTime? end,
      required bool Function(Stamp)? filter}) {
    _all = allStamps;
    _stamps = _getStamps(allStamps, location, selected, end, month);
    _filtered = filter == null
        ? _stamps
        : _stamps.where((element) => filter(element)).toList();
  }

  List<Response> get all => _all;

  List<Response> get stamps => _stamps;

  List<Response> get filtered => _filtered;

  List<Response<Question>> _getStamps(
    List<Response<Question>> allStamps,
    HistoryLocation location,
    DateTime? selected,
    DateTime? end,
    DateTime month,
  ) {
    end ??= DateTime.now();

    switch (location.loc) {
      case Loc.day:
        switch (location.day) {
          case DayChoice.day:
            return selected == null
                ? []
                : allStamps
                    .where((element) => _sameDay(selected, element))
                    .toList();
          case DayChoice.month:
            return selected == null
                ? allStamps
                    .where((element) => _sameMonth(month, element))
                    .toList()
                : allStamps
                    .where((element) => _sameDay(selected, element))
                    .toList();
          case DayChoice.all:
            return allStamps;
          default:
            return [];
        }
      case Loc.graph:
        final int time =
            dateToStamp(end.subtract(graphToDuration[location.graph]!));
        return allStamps
            .where((element) =>
                element.stamp >= time && element.stamp <= dateToStamp(end!))
            .toList();
    }
  }

  bool _sameDay(DateTime day, Response test) {
    final DateTime testDate = dateFromStamp(test.stamp);
    return day.year == testDate.year &&
        day.month == testDate.month &&
        day.day == testDate.day;
  }

  bool _sameMonth(DateTime day, Response test) {
    final DateTime testDate = dateFromStamp(test.stamp);
    return day.year == testDate.year && day.month == testDate.month;
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
        DateTime(resDate.year, resDate.month, resDate.day, 0, 0, 0, 0, 0);
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

  final DateTime selectedMonth;

  final DateTime? end;

  final bool Function(Stamp)? filter;

  const Filters(
      {required this.selectedMonth, this.selectedDate, this.filter, this.end});

  factory Filters.reset({
    HistoryLocation location = const HistoryLocation(
        day: DayChoice.day, loc: Loc.day, graph: GraphChoice.day),
  }) =>
      Filters(
          selectedMonth: DateTime.now(),
          selectedDate: location.day == DayChoice.day ? DateTime.now() : null,
          end: DateTime.now());

  Filters copyWith(
          {DateTime? selectDate,
          DateTime? selectMonth,
          bool Function(Stamp)? filt}) =>
      Filters(
          selectedMonth: selectMonth ?? selectedMonth,
          selectedDate: selectDate,
          filter: filt ?? filter);

  Filters shift(ShiftAmount shift, ShiftDirection direction) {
    DateTime? newEnd = direction == ShiftDirection.future
        ? end?.add(shift.amount)
        : end?.subtract(shift.amount);
    final DateTime now = DateTime.now();
    if (newEnd != null && newEnd.isAfter(now)) {
      newEnd = now;
    }
    return Filters(
        selectedMonth: selectedMonth,
        selectedDate: selectedDate,
        filter: filter,
        end: newEnd);
  }

  @override
  List<Object?> get props => [selectedDate, selectedMonth, filter];
}

final historyLocationProvider =
    StateProvider<HistoryLocation>((_) => initialLoc);

final filtersProvider = StateProvider<Filters>((_) => Filters.reset());

final availibleStampsProvider =
    FutureProvider.autoDispose<Available>((ref) async {
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);
  final HistoryLocation location = ref.watch(historyLocationProvider);
  final Filters filters = ref.watch(filtersProvider);
  return Available(
      allStamps: _convertStamps(stamps),
      location: location,
      selected: filters.selectedDate,
      month: filters.selectedMonth,
      filter: filters.filter,
      end: filters.end);
});

final eventsMapProvider =
    FutureProvider.autoDispose<Map<DateTime, List<Response>>>((ref) async {
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);

  return generateEventMap(_convertStamps(stamps));
});

List<Response> _convertStamps(List<Stamp> stamps) {
  return stamps is List<Response>
      ? stamps
      : stamps.whereType<Response>().toList();
}
