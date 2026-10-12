import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:table_calendar/table_calendar.dart';

class _DisplayData extends DisplayDataProvider {
  @override
  void ensureDate(DateTime date) {}
}

Future<void> _pumpCalendar(
  WidgetTester tester,
  DateTime date, {
  bool reduceMotion = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayDataProvider.overrideWith(_DisplayData.new),
        eventsMapProvider.overrideWith((ref) async => {}),
        recordPaths.overrideWith((ref, arg) async => []),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: BottomSheetCalendar(
            initialRange: DateTimeRange(start: date, end: date),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets('large calendar text scrolls above reachable bottom actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCalendar(tester, DateTime(2024, 9, 15), textScale: 3);
    final apply = find.widgetWithText(FilledButton, 'Apply');
    final initialActionRect = tester.getRect(apply);
    expect(apply.hitTestable(), findsOneWidget);
    expect(find.text('Cancel').hitTestable(), findsOneWidget);
    expect(
      tester.widget<TableCalendar>(find.byType(TableCalendar)).daysOfWeekHeight,
      greaterThan(50),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(apply), initialActionRect);
    expect(apply.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final days in [
    [13],
    [15],
    [13, 17],
    [17, 13],
    [13, 17, 20],
  ]) {
    testWidgets('date taps $days apply one day or an inclusive range', (
      tester,
    ) async {
      DateTimeRange? applied;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayDataProvider.overrideWith(_DisplayData.new),
            eventsMapProvider.overrideWith((ref) async => {}),
            recordPaths.overrideWith((ref, arg) async => []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BottomSheetCalendar(
                        initialRange: DateTimeRange(
                          start: DateTime(2024, 2, 13),
                          end: DateTime(2024, 2, 14),
                        ),
                        onRangeSelected: (range) => applied = range,
                      ),
                    ),
                    child: const Text('Open calendar'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open calendar'));
      await tester.pumpAndSettle();
      for (final day in days) {
        await tester.tap(
          find.descendant(
            of: find.byType(TableCalendar),
            matching: find.text('$day'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
              .onPressed,
          isNotNull,
        );
      }
      final singleDay = days.length.isOdd;
      final start = singleDay ? days.last : 13;
      final end = singleDay ? days.last : 17;
      if (singleDay) {
        final cell = tester
            .widgetList<CalendarDay>(find.byType(CalendarDay))
            .singleWhere(
              (cell) => isSameDay(cell.day, DateTime(2024, 2, start)),
            );
        expect(cell.rangeStart, isTrue);
        expect(cell.rangeEnd, isTrue);
      }
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        applied,
        DateTimeRange(
          start: DateTime(2024, 2, start),
          end: DateTime(2024, 2, end + 1),
        ),
      );
      expect(find.byType(BottomSheetCalendar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'mode motion reverses mid-flight without replacing the calendar',
    (tester) async {
      await _pumpCalendar(tester, DateTime(2024, 2, 15));
      final calendarState = tester.state(find.byType(TableCalendar));
      final size = tester.getSize(find.byType(BottomSheetCalendar));
      final initialYearPosition = tester.getTopLeft(find.byType(YearPicker));
      final header = find.text('February 2024');
      await tester.tap(header);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        tester.getTopLeft(find.byType(YearPicker)).dy,
        lessThan(initialYearPosition.dy),
      );
      for (var i = 0; i < 4; i++) {
        await tester.tap(header);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.getSize(find.byType(BottomSheetCalendar)), size);
        expect(tester.state(find.byType(TableCalendar)), same(calendarState));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('2023'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TableCalendar>(find.byType(TableCalendar))
            .focusedDay
            .year,
        2023,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion switches modes immediately', (tester) async {
    await _pumpCalendar(tester, DateTime(2024, 2, 15), reduceMotion: true);
    await tester.tap(find.text('February 2024'));
    await tester.pump();
    final yearOpacity = tester.widgetList<Opacity>(
      find.ancestor(
        of: find.byType(YearPicker),
        matching: find.byType(Opacity),
      ),
    );
    expect(yearOpacity.every((widget) => widget.opacity == 1), isTrue);
    await tester.tap(find.text('2023'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TableCalendar>(find.byType(TableCalendar)).focusedDay.year,
      2023,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar grid can swipe repeatedly', (tester) async {
    await _pumpCalendar(tester, DateTime(2024, 2, 15));
    for (final dx in [-500.0, 500.0, -500.0, -500.0, 500.0]) {
      await tester.drag(find.byType(TableCalendar), Offset(dx, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('header ignores swipes and arrows respect the first month', (
    tester,
  ) async {
    await _pumpCalendar(tester, DateTime(2020, 2, 15));
    await tester.drag(find.text('February 2020'), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TableCalendar>(find.byType(TableCalendar)).focusedDay.month,
      2,
    );
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TableCalendar>(find.byType(TableCalendar)).focusedDay.month,
      1,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TableCalendar>(find.byType(TableCalendar)).focusedDay.month,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('year picker animates both ways and preserves leap-day month', (
    tester,
  ) async {
    await _pumpCalendar(tester, DateTime(2024, 2, 29));
    final initialSize = tester.getSize(find.byType(BottomSheetCalendar));
    await tester.tap(find.text('February 2024'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );
    expect(tester.getSize(find.byType(BottomSheetCalendar)), initialSize);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    final calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
    expect(isSameDay(calendar.focusedDay, DateTime(2023, 2, 28)), isTrue);
    expect(calendar.rangeStartDay, DateTime(2024, 2, 29));
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('February 2023'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('February 2023'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNotNull,
    );
    for (final dx in [-500.0, 500.0, -500.0]) {
      await tester.drag(find.byType(TableCalendar), Offset(dx, 0));
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
