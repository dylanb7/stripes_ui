import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';

enum TimeCycle {
  day('Day', 1),
  week('Week', 7),
  month('Month', null),
  quarter('3 Months', null),
  year('Year', null),
  all('All', null),
  custom('Custom', null);

  final String label;
  final int? fixedDays;
  const TimeCycle(this.label, this.fixedDays);

  String get value => label;
}

@immutable
class TimeWindow {
  final DateTimeRange range;
  final TimeCycle cycle;

  const TimeWindow({required this.range, required this.cycle});

  factory TimeWindow.forCycle(TimeCycle cycle, {DateTime? anchor}) {
    return TimeWindow(
      cycle: cycle,
      range: DateRangeUtils.calculateRange(cycle, anchor ?? DateTime.now()),
    );
  }

  TimeWindow copyWith({DateTimeRange? range, TimeCycle? cycle}) {
    return TimeWindow(range: range ?? this.range, cycle: cycle ?? this.cycle);
  }

  bool contains(DateTime value) {
    return !value.isBefore(range.start) && value.isBefore(range.end);
  }

  TimeWindow shift({required bool forward}) {
    return copyWith(range: DateRangeUtils.shiftRange(range, cycle, forward));
  }

  TimeWindow expand({required bool forward}) {
    final adjacent = DateRangeUtils.shiftRange(range, cycle, forward);
    return copyWith(
      range: forward
          ? DateTimeRange(start: range.start, end: adjacent.end)
          : DateTimeRange(start: adjacent.start, end: range.end),
    );
  }

  bool get canGoPrev => DateRangeUtils.canGoPrev(cycle, range);
  bool get canGoNext => DateRangeUtils.canGoNext(cycle, range);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeWindow && range == other.range && cycle == other.cycle;

  @override
  int get hashCode => Object.hash(range, cycle);
}

class DateRangeUtils {
  DateRangeUtils._();

  /// Move by local calendar days, not elapsed 24-hour periods across DST.
  static DateTime shiftCalendarDays(DateTime value, int days) {
    final local = value.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day + days,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  }

  static DateTimeRange calculateRange(TimeCycle cycle, DateTime seed) {
    seed = seed.toLocal();
    final seedDay = DateTime(seed.year, seed.month, seed.day);

    switch (cycle) {
      case TimeCycle.day:
        return DateTimeRange(
          start: seedDay,
          end: shiftCalendarDays(seedDay, 1),
        );

      case TimeCycle.week:
        // ISO week: Monday = 1, Sunday = 7
        final start = shiftCalendarDays(seedDay, -(seedDay.weekday - 1));
        final end = shiftCalendarDays(start, 7);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.month:
        final start = DateTime(seedDay.year, seedDay.month, 1);
        final end = DateTime(seedDay.year, seedDay.month + 1, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.quarter:
        final quarterIndex = (seedDay.month - 1) ~/ 3;
        final startMonth = quarterIndex * 3 + 1;
        final start = DateTime(seedDay.year, startMonth, 1);
        final end = DateTime(seedDay.year, startMonth + 3, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.year:
        final start = DateTime(seedDay.year, 1, 1);
        final end = DateTime(seedDay.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.all:
        return DateTimeRange(start: SigDates.minDate, end: seedDay);

      case TimeCycle.custom:
        return DateTimeRange(start: seedDay, end: seedDay);
    }
  }

  static DateTimeRange shiftRange(
    DateTimeRange current,
    TimeCycle cycle,
    bool forward,
  ) {
    final start = current.start.toLocal();
    DateTime newStart;
    DateTime newEnd;

    switch (cycle) {
      case TimeCycle.day:
        newStart = shiftCalendarDays(start, forward ? 1 : -1);
        newEnd = shiftCalendarDays(newStart, 1);

      case TimeCycle.week:
        newStart = shiftCalendarDays(start, forward ? 7 : -7);
        newEnd = shiftCalendarDays(newStart, 7);

      case TimeCycle.month:
        newStart = forward
            ? DateTime(start.year, start.month + 1, 1)
            : DateTime(start.year, start.month - 1, 1);
        newEnd = DateTime(newStart.year, newStart.month + 1, 1);

      case TimeCycle.quarter:
        newStart = forward
            ? DateTime(start.year, start.month + 3, 1)
            : DateTime(start.year, start.month - 3, 1);
        newEnd = DateTime(newStart.year, newStart.month + 3, 1);

      case TimeCycle.year:
        newStart = forward
            ? DateTime(start.year + 1, 1, 1)
            : DateTime(start.year - 1, 1, 1);
        newEnd = DateTime(newStart.year + 1, 1, 1);

      case TimeCycle.all:
        return current;

      case TimeCycle.custom:
        final totalDaysInRange = DateRangeUtils.calendarDays(current);
        final days = totalDaysInRange > 0 ? totalDaysInRange : 1;
        newStart = shiftCalendarDays(start, forward ? days : -days);
        newEnd = shiftCalendarDays(newStart, days);
    }

    return DateTimeRange(start: newStart, end: newEnd);
  }

  static String formatRange(
    DateTimeRange range,
    TimeCycle cycle,
    String locale,
  ) {
    range = DateTimeRange(
      start: range.start.toLocal(),
      end: range.end.toLocal(),
    );
    switch (cycle) {
      case TimeCycle.day:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMd(locale).format(range.start);
        }
        return DateFormat.yMMMd(locale).format(range.start);

      case TimeCycle.month:
        if (range.start.year == DateTime.now().year) {
          return DateFormat.MMMM(locale).format(range.start);
        }
        return DateFormat.yMMM(locale).format(range.start);

      case TimeCycle.year:
        return DateFormat.y(locale).format(range.start);

      case TimeCycle.all:
        return 'All Time';

      case TimeCycle.week:
      case TimeCycle.quarter:
      case TimeCycle.custom:
        return _getSmartRangeString(range, locale);
    }
  }

  static String _getSmartRangeString(DateTimeRange range, String locale) {
    final start = range.start.toLocal();
    DateTime end = range.end.toLocal();

    if (end.hour == 0 &&
        end.minute == 0 &&
        end.second == 0 &&
        end.millisecond == 0) {
      end = end.subtract(const Duration(milliseconds: 1));
    }

    final bool sameYear = start.year == end.year;
    final bool sameMonth = sameYear && start.month == end.month;
    final int currentYear = DateTime.now().year;

    if (sameMonth) {
      final startPart = DateFormat.MMMd(locale).format(start);
      final endPart = DateFormat.d(locale).format(end);

      if (end.year == currentYear) {
        return '$startPart – $endPart';
      }
      final year = DateFormat.y(locale).format(end);
      return '$startPart – $endPart, $year';
    }

    if (sameYear) {
      final startPart = DateFormat.MMMd(locale).format(start);
      final endPart = DateFormat.MMMd(locale).format(end);

      if (end.year == currentYear) {
        return '$startPart – $endPart';
      }
      final year = DateFormat.y(locale).format(end);
      return '$startPart – $endPart, $year';
    }

    return '${DateFormat.yMMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}';
  }

  static bool canGoPrev(TimeCycle cycle, DateTimeRange range) {
    if (cycle == TimeCycle.all) return false;
    return range.start.isAfter(SigDates.minDate);
  }

  static bool canGoNext(TimeCycle cycle, DateTimeRange range) {
    if (cycle == TimeCycle.all) return false;
    return range.end.isBefore(DateTime.now());
  }

  static int calendarDays(DateTimeRange range) {
    range = DateTimeRange(
      start: range.start.toLocal(),
      end: range.end.toLocal(),
    );
    if (range.start == range.end) return 1;
    final startDay = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endDay = DateTime.utc(range.end.year, range.end.month, range.end.day);

    final count = endDay.difference(startDay).inDays;

    if (range.end.hour == 0 &&
        range.end.minute == 0 &&
        range.end.second == 0 &&
        range.end.millisecond == 0) {
      return count > 0 ? count : 1;
    }

    return count + 1;
  }

  static DateTime exclusiveEndOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day + 1);
  }

  static DateTime inclusiveEndOfDay(DateTime date) {
    date = date.toLocal();
    if (date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0) {
      return shiftCalendarDays(date, -1);
    }
    return date;
  }

  static DateTimeRange rangeFromSelection(DateTime start, DateTime end) {
    return DateTimeRange(start: start.toLocal(), end: exclusiveEndOfDay(end));
  }
}
