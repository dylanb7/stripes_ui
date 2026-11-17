import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_study_records_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_progress.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  test(
    'blue dye redesign can be enabled independently or with the beta UI',
    () {
      expect(const BetaUiConfig.disabled().blueDyeTest, isFalse);
      expect(const BetaUiConfig.enabled().blueDyeTest, isTrue);
      expect(
        const BetaUiConfig.enabled(blueDyeTest: false).blueDyeTest,
        isFalse,
      );
      const individual = BetaUiConfig.disabled(blueDyeTest: true);
      expect(individual.blueDyeTest, isTrue);
      expect(individual.multiSessionFlow, isFalse);
      expect(individual.onboardingTerms, isFalse);
    },
  );

  for (final enabled in [false, true]) {
    testWidgets('flag $enabled selects the study progress UI', (tester) async {
      await _pumpStudy(tester, enabled: enabled);
      expect(
        find.byType(BlueDyeStudyProgress),
        enabled ? findsOneWidget : findsNothing,
      );
      expect(find.byType(PageView), enabled ? findsNothing : findsOneWidget);
      expect(find.byType(MealStatsEntry), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(1600, 1000),
    const Size(844, 390),
  ]) {
    testWidgets('steps use the shared sheet presentation at $size', (
      tester,
    ) async {
      await _pumpHeader(tester, size: size);
      await tester.tap(find.text('View Steps'));
      await tester.pumpAndSettle();

      final dialog = size.width > 1000 || size.height < 650;
      expect(find.byType(BottomSheet), dialog ? findsNothing : findsOneWidget);
      expect(find.byType(Dialog), dialog ? findsOneWidget : findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BlueDyeStudyStepsSheet)),
      );
      expect(container.read(isSheetOpenProvider), isTrue);
      final sheet = find.byType(BlueDyeStudyStepsSheet);
      final firstStep = find.descendant(
        of: sheet,
        matching: find.text('Step 1: Eat Blue Meal'),
      );
      final secondStep = find.descendant(
        of: sheet,
        matching: find.text('Step 2: Record Bowel Movements'),
      );
      await tester.tap(firstStep);
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: sheet,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(secondStep, 100, scrollable: scrollable);
      await tester.pumpAndSettle();
      await tester.tap(secondStep);
      await tester.pumpAndSettle();

      // Both accordions remain open, without navigating to either step.
      final firstInstruction = find.text(
        'Record how long it takes the participant to eat the (2) muffins',
      );
      await tester.scrollUntilVisible(
        find.text('Continue until a brown BM occurs after a blue one.'),
        100,
        scrollable: scrollable,
      );
      expect(
        find.text('Continue until a brown BM occurs after a blue one.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(firstStep, -100, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(firstInstruction, findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(container.read(isSheetOpenProvider), isFalse);
      expect(find.text('View Steps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opening and closing steps preserves the active meal answer', (
    tester,
  ) async {
    await _pumpStudy(tester);
    final oral = find.text('Blue Muffins (for oral feeding)');
    await tester.ensureVisible(oral);
    await tester.tap(oral);
    await tester.pumpAndSettle();
    final before = tester.state(find.byType(MealStatsEntry));
    final viewSteps = find.text('View Steps');
    await tester.ensureVisible(viewSteps);
    await tester.pumpAndSettle();
    await tester.tap(viewSteps);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(tester.state(find.byType(MealStatsEntry)), same(before));
    final selected = tester.widget<BlueDyeStudyChoice<FeedingMethod>>(
      find.ancestor(
        of: oral,
        matching: find.byType(BlueDyeStudyChoice<FeedingMethod>),
      ),
    );
    expect(selected.selected, FeedingMethod.oral);
    await tester.ensureVisible(find.byTooltip('Study information'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Study information'));
    await tester.pumpAndSettle();
    expect(find.byType(BlueDyeStudyInformation), findsOneWidget);
    expect(find.text('help@simplifysolutions.com'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(MealStatsEntry)), same(before));
    expect(tester.takeException(), isNull);
  });

  for (final stage in [
    ('awaiting_transit', BlueDyeProgression.stepTwo, RecordingsInProgress),
    ('waiting', BlueDyeProgression.stepThree, WaitingTime),
    ('eat_meal_2', BlueDyeProgression.stepFour, MealStatsEntry),
    ('awaiting_transit_2', BlueDyeProgression.stepFive, RecordingsInProgress),
    ('completed', BlueDyeProgression.completed, RecordingsView),
  ]) {
    testWidgets('progress and content follow ${stage.$1}', (tester) async {
      await _pumpStudy(tester, stageId: stage.$1);
      expect(
        tester
            .widget<BlueDyeStudyProgress>(find.byType(BlueDyeStudyProgress))
            .progression,
        stage.$2,
      );
      expect(find.byType(stage.$3), findsOneWidget);
      if (stage.$2 == BlueDyeProgression.completed) {
        expect(
          find.descendant(
            of: find.byType(BlueDyeStudyProgress),
            matching: find.text('Study complete'),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in ['en', 'es', 'de']) {
    testWidgets('narrow progress and steps support large $locale text', (
      tester,
    ) async {
      await _pumpHeader(
        tester,
        size: const Size(320, 740),
        scale: 2,
        locale: Locale(locale),
      );
      await tester.ensureVisible(find.byType(TextButton));
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Size size,
  double scale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blueDyeStudyRecordsProvider.overrideWith((ref) async => const {}),
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
        home: const Scaffold(
          body: SingleChildScrollView(
            child: BlueDyeStudyProgress(
              progression: BlueDyeProgression.stepOne,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStudy(
  WidgetTester tester, {
  bool enabled = true,
  String stageId = 'eat_meal',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(blueDyeTest: enabled),
          ),
        ),
        authStream.overrideWith(
          (ref) => Stream.value(const AuthUser.uid(uid: 'account')),
        ),
        testProvider.overrideWith((ref) async => null),
        blueDyeMealStateProvider.overrideWith(
          (ref) async => BlueDyeMealState(startTime: DateTime(2026, 1, 1)),
        ),
        blueDyeBmTestLogsProvider.overrideWith((ref) async => []),
        blueDyeTestProgressProvider.overrideWith(
          (ref) async => BlueDyeTestProgress(
            stage: BlueDyeTestStage.started,
            orderedTests: const [],
            testIteration: 0,
            protocolStageId: stageId,
            isCompleted: stageId == 'completed',
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: StudyOngoing()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
