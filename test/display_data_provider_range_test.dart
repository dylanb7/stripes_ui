import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

void main() {
  group('TimeWindow', () {
    final window = TimeWindow(
      cycle: TimeCycle.custom,
      range: DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 2),
      ),
    );

    test('uses an inclusive start and exclusive end', () {
      expect(window.contains(DateTime(2024, 1, 1)), isTrue);
      expect(window.contains(DateTime(2024, 1, 1, 12)), isTrue);
      expect(window.contains(DateTime(2024, 1, 2)), isFalse);
      expect(window.contains(DateTime(2024, 1, 2, 0, 0, 1)), isFalse);
    });

    test('expands without losing the existing range', () {
      final expanded = window.expand(forward: true);

      expect(expanded.range.start, window.range.start);
      expect(expanded.range.end, DateTime(2024, 1, 3));
    });
  });

  group('getSmartRangeString', () {
    test('formats week range ending at midnight correctly', () {
      // Nov 24 2024 (Sun) to Dec 1 2024 (Sun) at midnight
      final start = DateTime(2024, 11, 24);
      final end = DateTime(2024, 12, 1);
      final range = DateTimeRange(start: start, end: end);

      // Should show Nov 24 - Nov 30
      final result = getSmartRangeString(range, 'en_US');
      expect(result, contains('Nov 24'));
      expect(result, contains('30'));
      expect(result, isNot(contains('Dec 1')));
    });

    test('formats custom range ending at 23:59 correctly', () {
      // Nov 24 2024 (Sun) to Nov 30 23:59:59
      final start = DateTime(2024, 11, 24);
      final end = DateTime(2024, 11, 30, 23, 59, 59);
      final range = DateTimeRange(start: start, end: end);

      // Should show Nov 24 - Nov 30
      final result = getSmartRangeString(range, 'en_US');
      expect(result, contains('Nov 24'));
      expect(result, contains('30'));
    });
  });
}
