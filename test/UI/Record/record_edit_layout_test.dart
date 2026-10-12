import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_entry.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

const _question = MultipleChoice(
  id: 'pain-frequency',
  prompt: 'How often did this happen?',
  type: 'Pain',
  choices: ['Once', 'A few times', 'Often'],
);
const _laterQuestion = MultipleChoice(
  id: 'pain-severity',
  prompt: 'How severe was it?',
  type: 'Pain',
  choices: ['Mild', 'Moderate', 'Severe'],
);

void main() {
  for (final beta in [true, false]) {
    testWidgets('short large-text form keeps its content usable, beta=$beta', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        beta: beta,
        size: const Size(320, 568),
        textScale: 3,
      );

      expect(find.byType(RecordEntryNavigationHeader), findsOneWidget);
      expect(tester.getSize(find.byType(PageView)).height, greaterThan(180));
      expect(
        find.ancestor(
          of: find.byType(RecordEntryHeader),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(SubmitScreen), findsOneWidget);
      expect(tester.getSize(find.byType(PageView)).height, greaterThan(180));
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit form aligns its controls at tablet width, beta=$beta', (
      tester,
    ) async {
      await _pumpEditor(tester, beta: beta);

      expect(
        tester.getSize(find.byType(RecordEntryShell)).width,
        beta ? 1200 : 1000,
      );
      expect(
        find.byType(CompactRecordQuestions),
        beta ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(_question.prompt),
        beta ? findsOneWidget : findsNWidgets(2),
      );
      expect(find.text(_laterQuestion.prompt), findsNothing);
      expect(
        find.widgetWithText(FilledButton, beta ? 'Continue' : 'Next'),
        findsOneWidget,
      );
      if (beta) {
        final body = tester.getRect(find.byType(RenderQuestions));
        final action = tester.getRect(find.byType(FilledButton));
        expect(body.width, 752);
        expect(action.left, body.left);
        expect(action.right, body.right);
        expect(tester.getSize(find.byType(RecordEntryBottomBar)).width, 1200);
      }
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text(_laterQuestion.prompt), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(SubmitScreen), findsOneWidget);
      expect(
        find.text(beta ? 'Anything else to add?' : 'Description'),
        findsOneWidget,
      );
      final notesField = find.descendant(
        of: find.byType(LongTextEntry),
        matching: find.byType(InkWell),
      );
      expect(notesField, findsOneWidget);
      final notes = tester.getRect(notesField);
      final action = tester.getRect(find.byType(FilledButton));
      if (beta) {
        expect(notes.width, 752);
        expect(notes.left, action.left);
        expect(notes.right, action.right);
      } else {
        expect(notes.width, lessThan(action.width));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('beta edit stays within a narrow screen with large text', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      beta: true,
      size: const Size(375, 812),
      textScale: 2,
    );
    final body = tester.getRect(find.byType(RenderQuestions));
    final action = tester.getRect(find.byType(FilledButton));
    expect(body.width, 327);
    expect(action.left, body.left);
    expect(action.right, body.right);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required bool beta,
  Size size = const Size(1200, 1000),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final home = _Home();
  final path = RecordPath(
    name: 'Pain',
    pages: [
      PageLayout(
        uid: 'first',
        header: _question.prompt,
        questionIds: [_question.id],
      ),
      PageLayout(uid: 'second', questionIds: [_laterQuestion.id]),
    ],
  );
  final graph = QuestionGraphBuilder.build(home: home, recordPaths: [path]);
  final container = ProviderContainer(
    overrides: [
      configProvider.overrideWithValue(
        StripesConfig.sandbox(
          betaUi: BetaUiConfig.disabled(multiSessionFlow: beta),
        ),
      ),
      questionHomeProvider.overrideWith((ref) => Stream.value(home)),
      questionGraphProvider.overrideWith((ref) async => graph),
      baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
      entriesStreamProvider.overrideWith((ref) => Stream.value([])),
      testProvider.overrideWith((ref) async => null),
      subHolderProvider.overrideWith(_Profile.new),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    graph.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: RecordSplitter(
              type: 'Pain',
              data: SessionData(editId: 'existing-symptom'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _Home extends QuestionHome {
  _Home() {
    all = {_question.id: _question, _laterQuestion.id: _laterQuestion};
  }

  @override
  Map<String, List<Question>> byType() => const {};
}

class _Profile extends SubNotifier {
  @override
  Future<SubState> build() async => SubState.empty();
}
