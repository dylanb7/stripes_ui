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

  /// Alias for label, for backward compatibility.
  String get value => label;
}

/// Shared utilities for date range calculations.
class DateRangeUtils {
  DateRangeUtils._();

  /// Calculate a date range for the given cycle, anchored to the seed date.
  static DateTimeRange calculateRange(TimeCycle cycle, DateTime seed) {
    final today = DateTime(seed.year, seed.month, seed.day);

    switch (cycle) {
      case TimeCycle.day:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );

      case TimeCycle.week:
        // ISO week: Monday = 1, Sunday = 7
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return DateTimeRange(start: start, end: end);

      case TimeCycle.month:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.quarter:
        final quarterIndex = (today.month - 1) ~/ 3;
        final startMonth = quarterIndex * 3 + 1;
        final start = DateTime(today.year, startMonth, 1);
        final end = DateTime(today.year, startMonth + 3, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.year:
        final start = DateTime(today.year, 1, 1);
        final end = DateTime(today.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);

      case TimeCycle.all:
        return DateTimeRange(
          start: SigDates.minDate,
          end: today,
        );

      case TimeCycle.custom:
        // Custom cycle returns the seed date as a single day
        return DateTimeRange(start: today, end: today);
    }
  }

  /// Shift a date range forward or backward by one cycle period.
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
        newEnd = DateTime(newStart.year, newStart.month + 1, 0);

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
        final duration = current.duration;
        final shiftDuration =
            duration.inDays > 0 ? duration : const Duration(days: 1);
        newStart =
            forward ? start.add(shiftDuration) : start.subtract(shiftDuration);
        newEnd = newStart.add(shiftDuration);
    }

    return DateTimeRange(start: newStart, end: newEnd);
  }

  /// Format a date range for display.
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

  /// Smart range string formatting.
  static String _getSmartRangeString(DateTimeRange range, String locale) {
    final start = range.start;
    DateTime end = range.end;

    // Adjust end if it's at midnight (exclusive end)
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
}
