import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_range_selector.dart';

void main() {
  testWidgets('rapidly revisiting a month keeps fading labels distinct', (
    tester,
  ) async {
    Future<void> showMonth(String month) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateRangeSelector(
              rangeText: month,
              canGoPrev: true,
              canGoNext: true,
              onPrev: () {},
              onNext: () {},
              onTap: () {},
            ),
          ),
        ),
      );
    }

    await showMonth('July');
    await showMonth('August');
    await tester.pump(const Duration(milliseconds: 50));
    await showMonth('July');
    await tester.pump(const Duration(milliseconds: 20));
    await showMonth('August');
    await tester.pump(const Duration(milliseconds: 20));
    await showMonth('July');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('July'), findsOneWidget);
  });
}
