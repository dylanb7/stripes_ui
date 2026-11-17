import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_study_records_provider.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_step_records.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_progress.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

BMTestLog _bm(String id) {
  final response = DetailResponse(
    id: id,
    detailType: 'category.BM',
    stamp: dateToStamp(DateTime.utc(2026, 1, 1, 13)),
    responses: [
      MultiResponse(
        question: const MultipleChoice(
          id: 'BlueDyeQuestion',
          prompt: 'Blue?',
          type: 'category.BM',
          choices: ['Yes', 'No'],
        ),
        index: 0,
        stamp: dateToStamp(DateTime.utc(2026, 1, 1, 13)),
      ),
    ],
  );
  return BMTestLog(
    response: response,
    isBlue: true,
    id: id,
    group: response.group,
  );
}

void main() {
  testWidgets(
    'expanded steps show saved meal and BM details for the matching run',
    (tester) async {
      final data = {
        0: BlueDyeStudyRunRecords(
          meal: BlueDyeMealState(
            startTime: DateTime.utc(2026, 1, 1, 12),
            finishedEating: const Duration(minutes: 15),
            finishedEatingTime: DateTime.utc(2026, 1, 1, 12, 15),
            amountConsumed: AmountConsumed.all,
          ),
          bowelMovements: [_bm('first')],
        ),
        1: BlueDyeStudyRunRecords(
          meal: BlueDyeMealState(
            startTime: DateTime.utc(2026, 1, 10, 12),
            finishedEating: const Duration(minutes: 45),
            amountConsumed: AmountConsumed.half,
          ),
          bowelMovements: [_bm('second')],
        ),
      };
      await _pump(tester, () async => data);
      await _expand(tester, 0);
      expect(find.text('15 minutes or less'), findsOneWidget);
      expect(find.text('All of blue meal'), findsOneWidget);
      expect(find.text('Meal finished'), findsOneWidget);
      await _expand(tester, 1);
      expect(
        tester.widget<EntryDisplay>(find.byType(EntryDisplay)).event.id,
        'first',
      );
      await _expand(tester, 3);
      expect(find.text('30 minutes to 1 hour'), findsOneWidget);
      expect(find.text('Half of blue meal'), findsOneWidget);
      await _expand(tester, 4);
      final secondRecords = find.byWidgetPredicate(
        (widget) => widget is BlueDyeStepRecords && widget.stepIndex == 4,
      );
      final entry = tester.widget<EntryDisplay>(
        find.descendant(of: secondRecords, matching: find.byType(EntryDisplay)),
      );
      expect(entry.event.id, 'second');
      expect(entry.hasControls, isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BlueDyeStudyProgress)),
      );
      expect(container.read(isSheetOpenProvider), isFalse);
    },
  );

  testWidgets(
    'tube record shows its start without inventing an amount or finish',
    (tester) async {
      await _pump(
        tester,
        () async => {
          0: BlueDyeStudyRunRecords(
            meal: const BlueDyeMealState().withTubeFeedingStart(
              DateTime.utc(2026, 1, 1),
            ),
            bowelMovements: const [],
          ),
        },
      );
      await _expand(tester, 0);
      expect(find.text('Blue Formula (for tube feeding)'), findsOneWidget);
      expect(find.textContaining('Start Time:'), findsOneWidget);
      expect(find.text('Meal finished'), findsNothing);
      expect(find.text('Meal Amount'), findsNothing);
      expect(find.text('Time Taken'), findsNothing);
      expect(find.byType(EntryDisplay), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('future steps have instructions without invented records', (
    tester,
  ) async {
    await _pump(tester, () async => const {});
    await _expand(tester, 3);
    expect(find.text('Recorded meal'), findsNothing);
    expect(find.byType(BlueDyeStepRecords), findsNothing);
    expect(find.textContaining('Record how long it takes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'record loading failure leaves instructions available and can retry',
    (tester) async {
      var fail = true;
      await _pump(tester, () async {
        if (fail) throw StateError('offline');
        return const {};
      });
      expect(find.text('Unable to load saved recordings.'), findsOneWidget);
      await _expand(tester, 0);
      expect(find.textContaining('Record how long it takes'), findsOneWidget);
      fail = false;
      await tester.ensureVisible(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load saved recordings.'), findsNothing);
      expect(find.textContaining('Record how long it takes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _expand(WidgetTester tester, int index) async {
  final row = find.byKey(PageStorageKey('blue-meal-study-step-$index'));
  final scrollable = find.descendant(
    of: find.byType(BlueDyeStudyStepsSheet),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(row, 150, scrollable: scrollable);
  final title = find.descendant(of: row, matching: find.byType(ListTile)).first;
  await tester.ensureVisible(title);
  await tester.pumpAndSettle();
  await tester.tap(title);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  Future<Map<int, BlueDyeStudyRunRecords>> Function() records,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
        activeProtocolProvider.overrideWith((ref) async => null),
        blueDyeStudyRecordsProvider.overrideWith((ref) => records()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BlueDyeStudyProgress(progression: BlueDyeProgression.stepFive),
        ),
      ),
    ),
  );
  await tester.tap(find.text('View Steps'));
  await tester.pumpAndSettle();
}
