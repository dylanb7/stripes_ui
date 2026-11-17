import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Filters/filter_components.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

DetailResponse note(String? text) => DetailResponse(
  id: 'one',
  detailType: 'Pain',
  description: text,
  stamp: dateToStamp(DateTime(2026, 10, 5, 9)),
  responses: const [],
);

class _Settings extends DisplayDataProvider {
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(
      TimeCycle.month,
      anchor: DateTime(2026, 10, 14),
    ),
    axis: GraphYAxis.number,
  );
}

void main() {
  testWidgets(
    'beta filter sheet applies notes and time restrictions together',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWith(
              (ref) =>
                  StripesConfig.sandbox(betaUi: const BetaUiConfig.enabled()),
            ),
            displayDataProvider.overrideWith(_Settings.new),
            inRangeProvider.overrideWith((ref) async => [note('After dinner')]),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        const SizedBox(height: 550, child: FilterSheet()),
                  ),
                  child: const Text('Open filters'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open filters'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FilterSheet)),
      );
      await tester.tap(find.text('Advanced Filters'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Has a note'));
      await tester.tap(find.text('Has a note'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'dinner');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Morning'));
      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      final filters = container.read(displayDataProvider).filters;
      expect(
        filters.map((f) => f.filterType),
        unorderedEquals([FilterType.description, FilterType.timeOfDay]),
      );
      expect(filters.every((f) => f.filter(note('After dinner'))), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test('advanced filter availability is independent of overview and excludes numeric range', () {
    for (final enabled in [false, true]) {
      final container = ProviderContainer(
        overrides: [
          configProvider.overrideWith(
            (ref) => StripesConfig.sandbox(
              betaUi: BetaUiConfig.disabled(
                historyOverview: true,
                advancedHistoryFilters: enabled,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final types = container.read(availableFilterTypesProvider);
      expect(types.contains(FilterType.description), enabled);
      expect(types.contains(FilterType.timeOfDay), enabled);
      expect(types, isNot(contains(FilterType.numericRange)));
      expect(container.read(setsProvider).keys, unorderedEquals(types));
    }
  });

  test(
    'note search is trimmed, case insensitive, and excludes blank notes',
    () {
      final search = const DescriptionContext()
          .createFilters(
            DescriptionState(toggleValue: true, searchText: '  Dinner  '),
          )
          .single;
      expect(search.filter(note('After DINNER')), isTrue);
      expect(search.filter(note('Breakfast')), isFalse);
      expect(search.filter(note(null)), isFalse);
      final hasNote = const DescriptionContext()
          .createFilters(DescriptionState(toggleValue: true))
          .single;
      expect(hasNote.filter(note('  ')), isFalse);
      expect(hasNote.filter(note('Remember this')), isTrue);
    },
  );

  test('time filters respect uncertain times and night across midnight', () {
    bool matches(String name, Response record) => const TimeOfDayContext()
        .createFilters(TimeOfDayState(selectedItems: {name}))
        .single
        .filter(record);
    TimedDetailResponse timed(
      TimeOfDayEntry precision,
      String? part,
      int hour,
    ) => TimedDetailResponse(
      response: note(null),
      entry: Entry(
        id: 'one',
        subUserId: 'profile',
        stamp: DateTime(2026, 10, 5, hour),
        entityType: 'event',
        timeOfDay: precision,
        data: {
          recordTimeField: {'localDate': '2026-10-05', 'dayPart': part},
        },
      ),
    );
    expect(matches('Night', timed(TimeOfDayEntry.notSure, null, 0)), isFalse);
    expect(
      matches('Morning', timed(TimeOfDayEntry.morning, 'morning', 0)),
      isTrue,
    );
    expect(matches('Night', timed(TimeOfDayEntry.night, 'night', 0)), isTrue);
    expect(
      matches('Evening', timed(TimeOfDayEntry.night, 'night', 0)),
      isFalse,
    );
    expect(TimeOfDayFilter.night.matchesHour(23), isTrue);
    expect(TimeOfDayFilter.night.matchesHour(2), isTrue);
    expect(TimeOfDayFilter.evening.matchesHour(20), isTrue);
  });

  testWidgets('typing notes retains the controller and insertion point', (
    tester,
  ) async {
    var text = 'after dinner';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DescriptionFilterSection(
              hasDescriptionToggle: true,
              notesSearchText: text,
              onToggleChanged: (_) {},
              onTextChanged: (value) => setState(() => text = value),
            ),
          ),
        ),
      ),
    );
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    await tester.tap(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'after late dinner',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await tester.pump();
    expect(
      identical(
        tester.widget<TextField>(find.byType(TextField)).controller,
        controller,
      ),
      isTrue,
    );
    expect(controller.selection.baseOffset, 10);
    expect(text, 'after late dinner');
  });
}
