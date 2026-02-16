import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';

/// Unified time cycle enum for both Timeline and Dashboard.
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

class DateRangeUtils {
  DateRangeUtils._();

  static DateTimeRange calculateRange(TimeCycle cycle, DateTime seed) {
    final seedDay = DateTime(seed.year, seed.month, seed.day);

    switch (cycle) {
      case TimeCycle.day:
        return DateTimeRange(
          start: seedDay,
          end: seedDay.add(const Duration(days: 1)),
        );

      case TimeCycle.week:
        // ISO week: Monday = 1, Sunday = 7
        final start = seedDay.subtract(Duration(days: seedDay.weekday - 1));
        final end = start.add(const Duration(days: 7));
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
        return DateTimeRange(
          start: SigDates.minDate,
          end: seedDay,
        );

      case TimeCycle.custom:
        return DateTimeRange(start: seedDay, end: seedDay);
    }
  }

  static DateTimeRange shiftRange(
    DateTimeRange current,
    TimeCycle cycle,
    bool forward,
  ) {
    final start = current.start;
    DateTime newStart;
    DateTime newEnd;

    switch (cycle) {
      case TimeCycle.day:
        const delta = Duration(days: 1);
        newStart = forward ? start.add(delta) : start.subtract(delta);
        newEnd = newStart.add(delta);

      case TimeCycle.week:
        const delta = Duration(days: 7);
        newStart = forward ? start.add(delta) : start.subtract(delta);
        newEnd = newStart.add(delta);

      case TimeCycle.month:
        newStart = forward
            ? DateTime(start.year, start.month + 1, 1)
            : DateTime(start.year, start.month - 1, 1);
        newEnd = DateTime(newStart.year, newStart.month + 1, 1);

      case TimeCycle.quarter:
        newStart = forward
            ? DateTime(start.year, start.month + 3, 1)
            : DateTime(start.year, start.month - 3, 1);
        newEnd = DateTime(newStart.year, newStart.month + 3, 0);

      case TimeCycle.year:
        newStart = forward
            ? DateTime(start.year + 1, 1, 1)
            : DateTime(start.year - 1, 1, 1);
        newEnd = DateTime(newStart.year + 1, 1, 0);

      case TimeCycle.all:
        return current;

      case TimeCycle.custom:
        final totalDaysInRange = DateRangeUtils.calendarDays(current);
        final shiftDuration =
            Duration(days: totalDaysInRange > 0 ? totalDaysInRange : 1);
        newStart =
            forward ? start.add(shiftDuration) : start.subtract(shiftDuration);
        newEnd = newStart.add(shiftDuration);
    }

    return DateTimeRange(start: newStart, end: newEnd);
  }

  static String formatRange(
    DateTimeRange range,
    TimeCycle cycle,
    String locale,
  ) {
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

  /// Check if we can navigate to the previous period.
  static bool canGoPrev(TimeCycle cycle, DateTimeRange range) {
    if (cycle == TimeCycle.all) return false;
    return range.start.isAfter(SigDates.minDate);
  }

  /// Check if we can navigate to the next period.
  static bool canGoNext(TimeCycle cycle, DateTimeRange range) {
    if (cycle == TimeCycle.all) return false;
    return range.end.isBefore(DateTime.now());
  }

  /// Returns the number of calendar days spanned by the range.
  static int calendarDays(DateTimeRange range) {
    if (range.start == range.end) return 1;
    final startDay =
        DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);

    final count = endDay.difference(startDay).inDays;

    if (range.end.hour == 0 &&
        range.end.minute == 0 &&
        range.end.second == 0 &&
        range.end.millisecond == 0) {
      return count > 0 ? count : 1;
    }

    return count + 1;
  }

  /// Takes a date (e.g., 2023-01-31) and returns the start of the next day
  /// (2023-02-01 00:00:00). Ensures time is stripped before adding a day.
  /// This creates an exclusive end date for DateTimeRange.
  static DateTime exclusiveEndOfDay(DateTime date) {
    if (date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0) {
      return date.add(const Duration(days: 1));
    }
    return DateTime(date.year, date.month, date.day)
        .add(const Duration(days: 1));
  }

  /// Takes an exclusive end date (e.g., 2023-02-01 00:00:00) and returns the
  /// inclusive end date (2023-01-31 00:00:00) for display/selection.
  static DateTime inclusiveEndOfDay(DateTime date) {
    if (date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0) {
      return date.subtract(const Duration(days: 1));
    }
    return date;
  }

  /// Creates a range from a calendar selection (inclusive start and end)
  /// by converting the end date to an exclusive end date (next day at 00:00).
  static DateTimeRange rangeFromSelection(DateTime start, DateTime end) {
    return DateTimeRange(start: start, end: exclusiveEndOfDay(end));
  }
}
