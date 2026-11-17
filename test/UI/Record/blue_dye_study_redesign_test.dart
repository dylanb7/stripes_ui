import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_progress.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('meal answers scroll to the next question and action', (
    tester,
  ) async {
    await _pump(
      tester,
      const MealStatsEntry(clicked: BlueDyeProgression.stepOne),
      fixture: _Fixture(),
      size: const Size(390, 640),
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.tap(find.text('Blue Muffins (for oral feeding)'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    expect(find.text('Yes').hitTestable(), findsOneWidget);
    final beforeNo = scroll.position.pixels;
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, beforeNo);
    expect(
      find.textContaining('must complete the fast').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Feed Blue Meal').hitTestable(), findsOneWidget);
    // Scroll through the instructions and amount choices as a participant would.
    await Scrollable.ensureVisible(
      tester.element(find.text('All of blue meal')),
      alignment: 0.9,
    );
    await tester.pumpAndSettle();
    final beforeAmount = scroll.position.pixels;
    await tester.tap(find.text('All of blue meal'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(beforeAmount));
    expect(find.text('Time Taken').hitTestable(), findsOneWidget);
    await tester.tap(find.text('15 minutes or less'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Next: Step 2').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('study acknowledgement stays visible while reading', (
    tester,
  ) async {
    await _pump(
      tester,
      BlueDyeStudyIntroduction(onStart: () {}, isLoading: false),
      fullScreen: true,
      size: const Size(390, 640),
    );
    final reading = find.byKey(
      const ValueKey('blue-meal-introduction-reading'),
    );
    final consent = find.byType(CheckboxListTile);
    final start = find.widgetWithText(FilledButton, 'Start Study');
    expect(consent.hitTestable(), findsOneWidget);
    expect(start.hitTestable(), findsOneWidget);
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    final originalPosition = tester.getTopLeft(consent);
    expect(tester.getBottomLeft(reading).dy, lessThan(originalPosition.dy));
    await tester.drag(reading, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(consent), originalPosition);
    await tester.tap(consent);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(consent, findsNothing);
    expect(find.text('Before you begin').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study footer keeps controls above the floating navigation', (
    tester,
  ) async {
    final navigation = FloatingNavBarController();
    addTearDown(navigation.dispose);
    await _pump(
      tester,
      FloatingNavBarScope(
        controller: navigation,
        barHeight: 96,
        child: BlueDyeStudyIntroduction(onStart: () {}, isLoading: false),
      ),
      fullScreen: true,
      size: const Size(390, 640),
    );
    final consent = find.byType(CheckboxListTile);
    final start = find.widgetWithText(FilledButton, 'Start Study');
    expect(consent.hitTestable(), findsOneWidget);
    expect(start.hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(start).dy, lessThan(640 - 96));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 740), const Size(844, 390)]) {
    testWidgets('large text footer leaves reading space at $size', (
      tester,
    ) async {
      await _pump(
        tester,
        BlueDyeStudyIntroduction(onStart: () {}, isLoading: false),
        fullScreen: true,
        scale: 3,
        size: size,
      );
      final reading = find.byKey(
        const ValueKey('blue-meal-introduction-reading'),
      );
      expect(tester.getSize(reading).height, greaterThan(size.height / 2));
      await _tap(tester, find.byType(Checkbox));
      await _tap(tester, find.widgetWithText(FilledButton, 'Start Study'));
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('current step is orange, completed navy, and future neutral', (
    tester,
  ) async {
    await _pump(
      tester,
      const BlueDyeStudyProgress(progression: BlueDyeProgression.stepTwo),
    );
    Color color(int step) =>
        (tester
                    .widget<Container>(
                      find.byKey(ValueKey('blue-meal-progress-$step')),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;
    expect(color(1), BlueDyeStudyStyle.orange);
    expect(color(0), BlueDyeStudyStyle.navy);
    expect(color(2), isNot(color(0)));
    expect(color(2), isNot(color(1)));
  });

  for (final size in [
    const Size(390, 844),
    const Size(1600, 1000),
    const Size(844, 390),
  ]) {
    testWidgets(
      'study information is organized and preserves multiple open sections at $size',
      (tester) async {
        await _pump(
          tester,
          const BlueDyeStudyHeader(subtitle: 'Transit Time 1'),
          size: size,
        );
        await tester.tap(find.byTooltip('Study information'));
        await tester.pumpAndSettle();
        final dialog = size.width > 1000 || size.height < 650;
        expect(
          find.byType(BottomSheet),
          dialog ? findsNothing : findsOneWidget,
        );
        expect(find.byType(Dialog), dialog ? findsOneWidget : findsNothing);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(BlueDyeStudyInformation)),
        );
        expect(container.read(isSheetOpenProvider), isTrue);
        expect(find.text(blueMealSupportEmail), findsOneWidget);
        await _tap(tester, find.text('About the Blue Meal Study').last);
        expect(
          find.textContaining('people with neurodevelopmental disorders'),
          findsOneWidget,
        );
        await _tap(tester, find.text('Eligibility'));
        expect(find.text('Have a neurodevelopmental disorder'), findsOneWidget);
        await _tap(tester, find.text('Study Flow'));
        expect(
          find.textContaining(
            'Wait 7 days after completing steps 1 and 2 before starting Step 3.',
          ),
          findsOneWidget,
        );
        await _tap(tester, find.text('Terms to know'));
        expect(
          find.textContaining('Motility:', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('people with neurodevelopmental disorders'),
          findsOneWidget,
        );
        expect(find.text('Have a neurodevelopmental disorder'), findsOneWidget);
        expect(find.textContaining('Phelan-McDermid'), findsNothing);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(BlueDyeStudyInformation), findsNothing);
        expect(container.read(isSheetOpenProvider), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final stage in [
    BlueDyeProgression.stepOne,
    BlueDyeProgression.stepFour,
  ]) {
    testWidgets(
      'oral meal at $stage requires fasting, amount and duration before saving',
      (tester) async {
        final fixture = _Fixture(
          secondRun: stage == BlueDyeProgression.stepFour,
        );
        await _pump(tester, MealStatsEntry(clicked: stage), fixture: fixture);
        final label = stage == BlueDyeProgression.stepOne
            ? 'Next: Step 2'
            : 'Next: Step 4';
        final next = find.widgetWithText(FilledButton, label);
        bool enabled() => tester.widget<FilledButton>(next).onPressed != null;
        expect(enabled(), isFalse);
        await _tap(tester, find.text('Blue Muffins (for oral feeding)'));
        await _tap(tester, find.text('No'));
        expect(
          find.text(
            'The participant must complete the fast before moving on to the next step.',
          ),
          findsOneWidget,
        );
        expect(enabled(), isFalse);
        await _tap(tester, find.text('Yes'));
        await _tap(tester, find.text('All of blue meal'));
        expect(enabled(), isFalse);
        await _tap(tester, find.text('15 minutes or less'));
        expect(enabled(), isTrue);
        await _tap(tester, next);
        final saved = BlueDyeMealState.fromContext(
          fixture.repo.saved.single.testContext,
        );
        expect(saved.amountConsumed, AmountConsumed.all);
        expect(saved.finishedEating, const Duration(minutes: 15));
        expect(saved.finishedEatingTime, isNotNull);
        expect(fixture.repo.saved.single.testContext['unrelated'], 'keep');
        expect(fixture.repo.advances, ['protocol']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'tube feeding uses the start field and does not require oral answers',
    (tester) async {
      final fixture = _Fixture();
      await _pump(
        tester,
        const MealStatsEntry(clicked: BlueDyeProgression.stepOne),
        fixture: fixture,
      );
      await _tap(tester, find.text('Blue Formula (for tube feeding)'));
      expect(find.text('6–8 Hour Fast'), findsNothing);
      final next = find.widgetWithText(FilledButton, 'Next: Step 2');
      expect(tester.widget<FilledButton>(next).onPressed, isNull);
      await _tap(tester, find.text('Use current time'));
      await _tap(tester, next);
      final saved = BlueDyeMealState.fromContext(
        fixture.repo.saved.single.testContext,
      );
      expect(saved.startTime, isNotNull);
      expect(saved.finishedEatingTime, isNull);
      expect(saved.amountConsumed, AmountConsumed.undetermined);
      expect(fixture.repo.advances, ['protocol']);
    },
  );

  testWidgets('failed save keeps meal answers and allows retry', (
    tester,
  ) async {
    final fixture = _Fixture();
    fixture.repo.failSave = true;
    await _pump(
      tester,
      const MealStatsEntry(clicked: BlueDyeProgression.stepOne),
      fixture: fixture,
    );
    await _tap(tester, find.text('Blue Formula (for tube feeding)'));
    await _tap(tester, find.text('Use current time'));
    final next = find.widgetWithText(FilledButton, 'Next: Step 2');
    await _tap(tester, next);
    expect(
      find.text('Unable to save your meal details. Please try again.'),
      findsOneWidget,
    );
    expect(fixture.repo.advances, isEmpty);
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    fixture.repo.failSave = false;
    await _tap(tester, next);
    expect(fixture.repo.saved, hasLength(1));
    expect(fixture.repo.advances, ['protocol']);
  });

  for (final remaining in [
    const Duration(days: 1, hours: 2),
    const Duration(hours: 2, minutes: 5),
    const Duration(minutes: -1),
  ]) {
    testWidgets(
      'waiting countdown uses appropriate units and gates next at $remaining',
      (tester) async {
        final finish = DateTime.now()
            .subtract(const Duration(days: 7))
            .add(remaining);
        await _pump(
          tester,
          WaitingTime(next: () {}),
          progress: BlueDyeTestProgress(
            stage: BlueDyeTestStage.initial,
            testIteration: 1,
            protocolStageId: 'waiting',
            orderedTests: [
              TestDate(
                finishTime: finish,
                test: BlueDyeResp(
                  id: 'run',
                  startEating: finish.subtract(const Duration(days: 1)),
                  eatingDuration: const Duration(minutes: 15),
                  normalBowelMovements: 1,
                  blueBowelMovements: 1,
                  logs: const [],
                  amountConsumed: AmountConsumed.all,
                  firstBlue: finish.subtract(const Duration(hours: 1)),
                  lastBlue: finish,
                ),
              ),
            ],
          ),
        );
        final next = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Next: Step 3'),
        );
        if (remaining.isNegative) {
          expect(find.text('You can begin now'), findsOneWidget);
          expect(next.onPressed, isNotNull);
        } else {
          expect(next.onPressed, isNull);
          expect(
            find.textContaining(
              remaining.inDays > 0 ? 'days and' : 'hours and',
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final locale in ['en', 'es', 'de']) {
    testWidgets('introduction and meal form fit at 3x text in $locale', (
      tester,
    ) async {
      await _pump(
        tester,
        const MealStatsEntry(clicked: BlueDyeProgression.stepOne),
        fixture: _Fixture(),
        scale: 3,
        locale: Locale(locale),
        size: const Size(320, 740),
      );
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        BlueDyeStudyIntroduction(onStart: () {}, isLoading: false),
        fullScreen: true,
        scale: 3,
        locale: Locale(locale),
        size: const Size(320, 740),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  _Fixture? fixture,
  Size size = const Size(390, 844),
  double scale = 1,
  Locale locale = const Locale('en'),
  bool fullScreen = false,
  BlueDyeTestProgress? progress,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        if (progress != null)
          blueDyeTestProgressProvider.overrideWith((ref) async => progress),
        configProvider.overrideWith(
          (ref) => const StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(blueDyeTest: true),
          ),
        ),
        if (fixture != null) ...[
          blueDyeMealStateProvider.overrideWith((ref) async => fixture.state),
          activeProtocolProvider.overrideWith((ref) async => fixture.protocol),
          testProvider.overrideWith((ref) async => fixture.repo),
        ],
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: fullScreen
              ? child
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Fixture {
  final repo = _Repo();
  final state = BlueDyeMealState(startTime: DateTime(2026, 1, 1));
  final bool secondRun;
  _Fixture({this.secondRun = false});
  late final protocol = ActiveTestProtocol(
    id: 'protocol',
    testId: 'blue',
    currentStageId: secondRun ? 'eat_meal_2' : 'eat_meal',
    testContext: {...state.toContext(), 'unrelated': 'keep'},
  );
}

class _Repo implements ModularTestsRepo {
  final saved = <ActiveTestProtocol>[];
  final advances = <String>[];
  bool failSave = false;
  @override
  Future<void> updateProtocol(ActiveTestProtocol protocol) async {
    if (failSave) throw StateError('offline');
    saved.add(protocol);
  }

  @override
  Future<TestEvaluationResult?> advanceStage({
    required String activeTestId,
    String? targetStageId,
  }) async {
    advances.add(activeTestId);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
