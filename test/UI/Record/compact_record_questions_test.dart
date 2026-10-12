import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';

void main() {
  const question = MultipleChoice(
    id: 'pain-frequency',
    prompt: 'How often did this happen?',
    type: 'Frequency',
    choices: ['Once', 'A few times', 'Often'],
    isRequired: true,
  );

  testWidgets(
    'compact questions remove repeated labels and preserve answer targets',
    (tester) async {
      final session = _session(question);
      final entry = BowelMovementMultipleChoiceEntry(
        graph: session,
        question: question,
      );

      await _pump(tester, entry, compact: false);
      final regularHeight = tester
          .getSize(find.byType(BowelMovementQuestionCard))
          .height;
      expect(find.text('Frequency'), findsOneWidget);

      await _pump(tester, entry);
      expect(find.text('Frequency'), findsNothing);
      expect(find.text(question.prompt), findsOneWidget);
      expect(
        tester.getSize(find.byType(BowelMovementQuestionCard)).height,
        lessThan(regularHeight),
      );
      for (var index = 0; index < question.choices.length; index++) {
        final choice = find.byKey(
          ValueKey('bowel-${question.id}-choice-$index'),
        );
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        await tester.tap(choice);
        await tester.pump();
        expect((session.fromQuestion(question) as MultiResponse).index, index);
      }
      await tester.tap(
        find.byKey(const ValueKey('bowel-pain-frequency-choice-2')),
      );
      await tester.pump();
      expect((session.fromQuestion(question) as MultiResponse).index, 2);
      expect(find.text('Choose one'), findsOneWidget);
      expect(find.text('Clear answer'), findsNothing);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'required validation stays next to unanswered question and clears',
    (tester) async {
      final session = _session(question);
      await _pump(
        tester,
        BowelMovementMultipleChoiceEntry(graph: session, question: question),
      );
      expect(find.byTooltip('Required'), findsOneWidget);
      expect(find.text('Check this answer before continuing.'), findsNothing);

      session.tried = true;
      await tester.pumpAndSettle();
      expect(find.text('Check this answer before continuing.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('bowel-pain-frequency-choice-0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Check this answer before continuing.'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional single choices clear only with the explicit action', (
    tester,
  ) async {
    const optional = MultipleChoice(
      id: 'optional-choice',
      prompt: 'Which applies?',
      type: 'Choice',
      choices: ['First', 'Second', 'Not sure'],
      isRequired: false,
      requirement: Requirement.nothing(),
    );
    final session = _session(optional);
    await _pump(
      tester,
      BowelMovementMultipleChoiceEntry(graph: session, question: optional),
    );
    final first = find.byKey(const ValueKey('bowel-optional-choice-choice-0'));
    await tester.tap(first);
    await tester.pump();
    final saved = session.fromQuestion(optional);
    await tester.tap(first);
    await tester.pump();
    expect(session.fromQuestion(optional), same(saved));
    expect(find.text('Not sure'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bowel-optional-choice-clear')));
    await tester.pump();
    expect(session.fromQuestion(optional), isNull);
  });

  testWidgets('multiple answers use checkboxes and toggle independently', (
    tester,
  ) async {
    const multiple = AllThatApply(
      id: 'multiple-choices',
      prompt: 'What did you notice?',
      type: 'Symptoms',
      choices: ['Pain', 'Nausea', 'Bloating'],
      requirement: Requirement.nothing(),
    );
    final session = _session(multiple);
    await _pump(
      tester,
      BowelMovementAllThatApplyEntry(graph: session, question: multiple),
    );
    expect(find.text('Select all that apply'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(3));
    for (final index in [0, 1]) {
      await tester.tap(
        find.byKey(ValueKey('bowel-multiple-choices-choice-$index')),
      );
      await tester.pump();
    }
    expect((session.fromQuestion(multiple) as AllResponse).responses, [0, 1]);
    expect(find.byIcon(Icons.check_box), findsNWidgets(2));
    await tester.tap(
      find.byKey(const ValueKey('bowel-multiple-choices-choice-0')),
    );
    await tester.pump();
    expect((session.fromQuestion(multiple) as AllResponse).responses, [1]);
    await tester.tap(
      find.byKey(const ValueKey('bowel-multiple-choices-choice-1')),
    );
    await tester.pump();
    expect(session.fromQuestion(multiple), isNull);
  });

  testWidgets('check questions show prompt once without a generic heading', (
    tester,
  ) async {
    const check = Check(
      id: 'ate-meal',
      prompt: 'I ate a meal',
      type: 'Meal',
      requirement: Requirement.nothing(),
    );
    final session = _session(check);
    await _pump(
      tester,
      BowelMovementCheckEntry(graph: session, question: check),
    );

    expect(find.text(check.prompt), findsOneWidget);
    expect(find.text(check.type), findsNothing);
    expect(find.text('Select if this applies.'), findsNothing);
    expect(find.byTooltip('Required'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bowel-ate-meal-check')));
    await tester.pump();
    expect(session.fromQuestion(check), isA<Selected>());
  });

  testWidgets('compact choices fit at phone width with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = _session(question);
    await _pump(
      tester,
      BowelMovementMultipleChoiceEntry(graph: session, question: question),
      textScale: 3,
    );
    expect(find.text(question.prompt), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('bowel-pain-frequency-choice-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('bowel-pain-frequency-choice-1')),
    );
    await tester.pump();
    expect((session.fromQuestion(question) as MultiResponse).index, 1);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool compact = true,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: compact
            ? CompactRecordQuestions(
                requiredLabel: 'Required',
                invalidLabel: 'Check this answer before continuing.',
                child: child,
              )
            : child,
      ),
    ),
  ),
);

SessionGraph _session(Question question) {
  final graph = QuestionGraphBuilder.build(
    home: _QuestionHome({question.id: question}),
    recordPaths: [
      RecordPath(
        name: 'record',
        pages: [
          PageLayout(questionIds: [question.id]),
        ],
      ),
    ],
  );
  final session = graph.createSession(recordPathName: 'record');
  addTearDown(() {
    session.dispose();
    graph.dispose();
  });
  return session;
}

class _QuestionHome extends QuestionHome {
  _QuestionHome(Map<String, Question> questions) {
    all = questions;
  }

  @override
  Map<String, List<Question>> byType() => const {};
}
