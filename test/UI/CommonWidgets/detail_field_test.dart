import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/Accessibility/display_settings_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/UI/AccountManagement/display_settings.dart';
import 'package:stripes_ui/UI/AccountManagement/account_management_screen.dart';
import 'package:stripes_ui/UI/CommonWidgets/detail_field.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_fixtures.dart';
import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('automatic responds to live text size and width changes', (
    tester,
  ) async {
    final scale = ValueNotifier(1.0);
    addTearDown(scale.dispose);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: light,
          home: ValueListenableBuilder(
            valueListenable: scale,
            builder: (context, factor, _) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(factor)),
              child: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(20),
                  child: DetailField(question: 'Pain with BM', answerText: '9'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InlineDetailField), findsOneWidget);
    scale.value = 2;
    await tester.pumpAndSettle();
    expect(find.byType(StackedDetailField), findsOneWidget);
    _expectQuestionAboveAnswer(tester, 'Pain with BM', '9');
    tester.view.physicalSize = const Size(812, 375);
    await tester.pumpAndSettle();
    expect(find.byType(InlineDetailField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long questions stack even at normal text size', (tester) async {
    const question =
        'How many bowel movements occurred during the previous '
        'seven days, including any recorded outside the study?';
    await _pump(tester, const DetailField(question: question, answerText: '4'));
    expect(find.byType(StackedDetailField), findsOneWidget);
    _expectQuestionAboveAnswer(tester, question, '4');
  });

  testWidgets('compact chips and pain answers do not split unnecessarily', (
    tester,
  ) async {
    final fixtures = AuditFixtures();
    await _pump(
      tester,
      Column(
        children: [
          ResponseDisplay(res: fixtures.answers[1]),
          ResponseDisplay(res: fixtures.answers[2]),
        ],
      ),
    );
    expect(tester.getSize(find.text('Yes')).height, lessThan(20));
    expect(tester.getSize(find.byType(PainSliderDisplay)).height, lessThan(35));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    fixtures.dispose();
  });

  testWidgets(
    'pain history keeps the stored score and uses the range descriptions',
    (tester) async {
      for (final (score, label) in [
        (0, '0 · No pain'),
        (2, '2 · Mild'),
        (5, '5 · Moderate'),
        (7, '7 · Severe'),
        (8, '8 · Severe'),
        (10, '10 · Worst possible'),
        (-1, 'Not sure'),
      ]) {
        await _pump(
          tester,
          PainSliderDisplay(
            response: NumericResponse(
              question: const Numeric(
                id: 'Pain-Rating',
                prompt: 'Pain level',
                type: 'Pain',
              ),
              stamp: 1,
              response: score,
            ),
          ),
        );
        expect(find.text(label), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('checked answers use an icon inline and text when stacked', (
    tester,
  ) async {
    final fixtures = AuditFixtures();
    addTearDown(fixtures.dispose);
    await _pump(tester, ResponseDisplay(res: fixtures.answers[4]));
    expect(find.byType(InlineDetailField), findsOneWidget);
    expect(find.text('Selected'), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Selected')), findsOneWidget);
    semantics.dispose();

    await tester.pumpWidget(const SizedBox());
    SharedPreferences.setMockInitialValues({
      detailLayoutPreferenceKey: DetailLayoutPreference.stacked.name,
    });
    await _pump(tester, ResponseDisplay(res: fixtures.answers[4]));
    expect(find.byType(StackedDetailField), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explicit preference updates a mounted detail and survives reopening',
    (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            DetailField(question: 'Pain', answerText: '9'),
            DisplaySettingsTile(),
          ],
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DetailField)),
      );
      expect(find.byType(InlineDetailField), findsOneWidget);
      await tester.tap(find.text('Display settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question above answer'));
      await tester.pumpAndSettle();
      expect(
        container.read(displaySettingsProvider).value?.detailLayout,
        DetailLayoutPreference.stacked,
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(StackedDetailField), findsOneWidget);
      _expectQuestionAboveAnswer(tester, 'Pain', '9');
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(
        (await reopened.read(displaySettingsProvider.future)).detailLayout,
        DetailLayoutPreference.stacked,
      );
    },
  );

  for (final width in [320.0, 375.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final preference in DetailLayoutPreference.values) {
        testWidgets(
          'answers stay readable at $width / $scale / ${preference.name}',
          (tester) async {
            SharedPreferences.setMockInitialValues({
              detailLayoutPreferenceKey: preference.name,
            });
            final fixtures = AuditFixtures();
            await _pump(
              tester,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final response in fixtures.answers)
                    ResponseDisplay(res: response),
                ],
              ),
              width: width,
              scale: scale,
            );
            if (scale >= 2 || preference == DetailLayoutPreference.stacked) {
              expect(find.byType(InlineDetailField), findsNothing);
              expect(find.byType(StackedDetailField), findsNWidgets(6));
            }
            for (final element in find.byType(RichText).evaluate()) {
              final paragraph = element.renderObject as RenderParagraph;
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: paragraph.text.toPlainText(),
              );
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            fixtures.dispose();
          },
        );
      }
    }
  }

  testWidgets('display settings remain usable with maximum stress text', (
    tester,
  ) async {
    await _pump(tester, const DisplaySettingsSheet(), width: 320, scale: 3);
    await tester.ensureVisible(find.text('Question above answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Question above answer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(detailLayoutPreferenceKey), 'stacked');
  });

  testWidgets('profile hides display settings until enabled', (tester) async {
    final fixtures = AuditFixtures();
    addTearDown(fixtures.dispose);
    final run = AuditRun(tester, 'account', auditDevices[1], 1);
    await tester.pumpWidget(
      fixtures.app(
        run,
        const Scaffold(body: AccountManagementScreen()),
        displaySettingsEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DisplaySettingsTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      fixtures.app(run, const Scaffold(body: AccountManagementScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DisplaySettingsTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('record flow editing can opt in without the redesign', (
    tester,
  ) async {
    final fixtures = AuditFixtures();
    addTearDown(fixtures.dispose);
    final run = AuditRun(tester, 'account', auditDevices[1], 1);
    await tester.pumpWidget(
      fixtures.app(
        run,
        const Scaffold(body: AccountManagementScreen()),
        symptomEditingEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Record flows'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      fixtures.app(run, const Scaffold(body: AccountManagementScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Record flows'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectQuestionAboveAnswer(
  WidgetTester tester,
  String question,
  String answer,
) {
  final q = tester.getRect(find.text(question));
  final a = tester.getRect(find.text(answer));
  expect(a.top, greaterThanOrEqualTo(q.bottom));
  expect(a.left, greaterThanOrEqualTo(q.left + 12));
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 375,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
