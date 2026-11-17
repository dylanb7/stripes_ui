import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/tube_feeding_start_field.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final mealStats in [false, true]) {
    testWidgets(
      '${mealStats ? 'meal details' : 'amount entry'} saves a previous-day tube start without inventing an end',
      (tester) async {
        final fixture = _Fixture();
        await _pumpEntry(tester, fixture, mealStats: mealStats);
        await _tap(tester, find.text('Blue Formula (for tube feeding)'));

        final next = find.widgetWithText(FilledButton, 'Next');
        expect(tester.widget<FilledButton>(next).onPressed, isNull);
        expect(find.text('Feeding started at:'), findsOneWidget);
        expect(find.text('Feeding ended at:'), findsNothing);
        expect(find.text('Tube Feeding Complete'), findsNothing);

        final now = DateTime.now();
        final previousDay = DateTime(now.year, now.month, now.day - 1, 23, 15);
        await _pickStart(tester, previousDay);

        if (mealStats) {
          await tester.restartAndRestore();
          await tester.pumpAndSettle();
        }
        final field = tester.widget<TubeFeedingStartField>(
          find.byType(TubeFeedingStartField),
        );
        expect(field.start!.toUtc(), previousDay.toUtc());
        await _tap(tester, next);

        final saved = fixture.repo.saved.single;
        final restored = BlueDyeMealState.fromContext(saved.testContext);
        expect(restored.startTime, previousDay.toUtc());
        expect(
          saved.testContext[BlueDyeContextKeys.startTime],
          previousDay.toUtc().toIso8601String(),
        );
        expect(restored.finishedEating, Duration.zero);
        expect(restored.amountConsumed, AmountConsumed.undetermined);
        expect(restored.finishedEatingTime, isNull);
        expect(restored.timerStart, isNull);
        expect(restored.pauseTime, isNull);
        expect(
          saved.testContext,
          isNot(contains(BlueDyeContextKeys.finishedEatingTime)),
        );
        expect(saved.testContext['unrelated'], 'keep');
        expect(fixture.repo.events, ['save', 'advance:protocol']);
        // Entering a new start must not mutate an existing legacy record.
        expect(fixture.state.finishedEatingTime, fixture.legacyEnd);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('current-time action saves the feeding start directly', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _pumpEntry(tester, fixture, mealStats: false);
    await _tap(tester, find.text('Blue Formula (for tube feeding)'));
    final before = DateTime.now().toUtc();
    await _tap(tester, find.text('Use current time'));
    final after = DateTime.now().toUtc();
    await _tap(tester, find.widgetWithText(FilledButton, 'Next'));

    final saved = BlueDyeMealState.fromContext(
      fixture.repo.saved.single.testContext,
    );
    expect(saved.startTime!.isBefore(before), isFalse);
    expect(saved.startTime!.isAfter(after), isFalse);
    expect(saved.finishedEatingTime, isNull);
    expect(fixture.repo.events, ['save', 'advance:protocol']);
  });

  testWidgets('old restored feeding end is not reused as a feeding start', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _pumpEntry(
      tester,
      fixture,
      child: _LegacyTubeDraft(end: fixture.legacyEnd),
    );
    final legacyData = await tester.getRestorationData();
    await tester.pumpWidget(const SizedBox());
    await _pumpEntry(tester, fixture, mealStats: true);
    await tester.restoreFrom(legacyData);
    await tester.pumpAndSettle();

    expect(find.byType(TubeFeedingStartField), findsOneWidget);
    expect(
      tester
          .widget<TubeFeedingStartField>(find.byType(TubeFeedingStartField))
          .start,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNull,
    );
    expect(fixture.repo.saved, isEmpty);
    expect(fixture.state.finishedEatingTime, fixture.legacyEnd);
  });

  testWidgets(
    'switching back to oral keeps the existing completed meal timing',
    (tester) async {
      final fixture = _Fixture();
      await _pumpEntry(tester, fixture, mealStats: false);
      await _tap(tester, find.text('Blue Formula (for tube feeding)'));
      await _tap(tester, find.text('Use current time'));
      await _tap(tester, find.text('Blue Muffins (for oral feeding)'));
      expect(find.byType(TubeFeedingStartField), findsNothing);
      await _tap(tester, find.text('All of blue meal'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Next'));

      final saved = BlueDyeMealState.fromContext(
        fixture.repo.saved.single.testContext,
      );
      expect(saved.startTime, fixture.state.startTime);
      expect(saved.finishedEatingTime, fixture.legacyEnd);
      expect(saved.finishedEating, const Duration(minutes: 15));
      expect(saved.amountConsumed, AmountConsumed.all);
      expect(fixture.repo.events, ['save', 'advance:protocol']);
    },
  );

  testWidgets('future date cannot be accepted as a feeding start', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _pumpEntry(tester, fixture, mealStats: true);
    await _tap(tester, find.text('Blue Formula (for tube feeding)'));
    await _tap(tester, find.byKey(const ValueKey('tube-feeding-start-picker')));
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    await tester.enterText(
      find.byType(TextFormField),
      '${tomorrow.month}/${tomorrow.day}/${tomorrow.year}',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(fixture.repo.saved, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TubeFeedingStartField>(find.byType(TubeFeedingStartField))
          .start,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNull,
    );
  });
}

Future<void> _pumpEntry(
  WidgetTester tester,
  _Fixture fixture, {
  bool mealStats = false,
  Widget? child,
}) async {
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        testProvider.overrideWith((ref) async => fixture.repo),
        activeProtocolProvider.overrideWith((ref) async => fixture.protocol),
        blueDyeMealStateProvider.overrideWith((ref) async => fixture.state),
        blueDyeTestProgressProvider.overrideWith(
          (ref) async => const BlueDyeTestProgress(
            stage: BlueDyeTestStage.amountConsumed,
            orderedTests: [],
            testIteration: 0,
            isCompleted: false,
            protocolStageId: 'eat_meal',
          ),
        ),
      ],
      child: MaterialApp(
        restorationScopeId: 'test-app',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child:
                child ??
                (mealStats
                    ? const MealStatsEntry(clicked: BlueDyeProgression.stepOne)
                    : const AmountConsumedEntry()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickStart(WidgetTester tester, DateTime selected) async {
  await _tap(tester, find.byKey(const ValueKey('tube-feeding-start-picker')));
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextFormField),
    '${selected.month}/${selected.day}/${selected.year}',
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  expect(find.byType(TimePickerDialog), findsOneWidget);
  await tester.tap(find.byTooltip('Switch to text input mode'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), '${selected.hour}');
  await tester.enterText(fields.at(1), '${selected.minute}');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _Fixture {
  final repo = _RecordingTestsRepo();
  final legacyEnd = DateTime.utc(2026, 1, 1, 12, 15);
  late final state = BlueDyeMealState(
    startTime: DateTime.utc(2026, 1, 1, 12),
    finishedEating: const Duration(minutes: 15),
    finishedEatingTime: legacyEnd,
    amountConsumed: AmountConsumed.all,
    timerStart: DateTime.utc(2026, 1, 1, 12),
    pauseTime: DateTime.utc(2026, 1, 1, 12, 5),
  );
  late final protocol = ActiveTestProtocol(
    id: 'protocol',
    testId: 'blue',
    currentStageId: 'eat_meal',
    testContext: {...state.toContext(), 'unrelated': 'keep'},
  );
}

class _RecordingTestsRepo implements ModularTestsRepo {
  final saved = <ActiveTestProtocol>[];
  final events = <String>[];

  @override
  Future<void> updateProtocol(ActiveTestProtocol protocol) async {
    events.add('save');
    saved.add(protocol);
  }

  @override
  Future<TestEvaluationResult?> advanceStage({
    required String activeTestId,
    String? targetStageId,
  }) async {
    events.add('advance:$activeTestId');
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Recreates the old restoration schema so migration is tested through Flutter.
class _LegacyTubeDraft extends StatefulWidget {
  final DateTime end;
  const _LegacyTubeDraft({required this.end});

  @override
  State<_LegacyTubeDraft> createState() => _LegacyTubeDraftState();
}

class _LegacyTubeDraftState extends State<_LegacyTubeDraft>
    with RestorationMixin {
  late final end = RestorableStringN(widget.end.toUtc().toIso8601String());
  final method = RestorableEnumN(
    FeedingMethod.tubeFed,
    values: FeedingMethod.values,
  );

  @override
  String? get restorationId => 'meal-stats-entry';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(method, 'feeding-method-entry');
    registerForRestoration(end, 'tube-feed-end-time-entry');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  void dispose() {
    end.dispose();
    method.dispose();
    super.dispose();
  }
}
