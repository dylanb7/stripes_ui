import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/history/display_data_provider.dart';

void main() {
  group('DisplayDataSettings', () {
    test('getBarSpacing returns correct default values', () {
      final baseSettings = DisplayDataSettings(
        range: DateTimeRange(start: DateTime.now(), end: DateTime.now()),
        cycle: DisplayTimeCycle.day,
        axis: GraphYAxis.number,
      );

      // Test Day cycle
      expect(baseSettings.copyWith(cycle: DisplayTimeCycle.day).getBarSpacing(),
          2.0);

      // Test Week cycle
      expect(
          baseSettings.copyWith(cycle: DisplayTimeCycle.week).getBarSpacing(),
          2.0);

      // Test Month cycle
      expect(
          baseSettings.copyWith(cycle: DisplayTimeCycle.month).getBarSpacing(),
          2.0);

      // Test Custom cycle
      expect(
          baseSettings.copyWith(cycle: DisplayTimeCycle.custom).getBarSpacing(),
          2.0);
    });
  });
}
