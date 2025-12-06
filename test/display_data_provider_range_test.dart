import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';

void main() {
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
