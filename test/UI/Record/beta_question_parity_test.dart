import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';

void main() {
  testWidgets('short integer scales keep every value and allow clearing', (
    tester,
  ) async {
    const question = Numeric(
      id: 'short-scale',
      prompt: 'How severe?',
      type: 'Severity',
      min: 2,
      max: 6,
    );
    final session = _session(question);
    await _pumpEntry(tester, session, question);

    expect(session.fromQuestion(question), isNull);
    expect(find.byType(Slider), findsNothing);
    for (var value = 2; value <= 6; value++) {
      final choice = find.byKey(ValueKey('bowel-short-scale-value-$value'));
      await tester.tap(choice);
      await tester.pump();
      expect(
        (session.fromQuestion(question) as NumericResponse).response,
        value,
      );
    }

    await tester.tap(find.byKey(const ValueKey('bowel-short-scale-value-6')));
    await tester.pump();
    expect((session.fromQuestion(question) as NumericResponse).response, 6);
    await tester.tap(find.byKey(const ValueKey('bowel-short-scale-clear')));
    await tester.pump();
    expect(session.fromQuestion(question), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide integer scales retain their upper values', (tester) async {
    const question = Numeric(
      id: 'wide-scale',
      prompt: 'How severe?',
      type: 'Severity',
      min: 0,
      max: 10,
    );
    final session = _session(question);
    await _pumpEntry(tester, session, question);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 0);
    expect(slider.max, 10);
    expect(slider.divisions, 10);
    expect(session.fromQuestion(question), isNull);
    // Select the high end that the previous seven-choice renderer omitted.
    await tester.tapAt(
      tester.getTopRight(find.byType(Slider)) + const Offset(-24, 24),
    );
    await tester.pumpAndSettle();

    expect((session.fromQuestion(question) as NumericResponse).response, 10);
    await tester.tap(find.byKey(const ValueKey('bowel-wide-scale-clear')));
    await tester.pump();
    expect(session.fromQuestion(question), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fractional ranges and existing answers are never rounded', (
    tester,
  ) async {
    const question = Numeric(
      id: 'fractional-scale',
      prompt: 'How much?',
      type: 'Amount',
      min: 0.25,
      max: 3.75,
    );
    final session = _session(question);
    session.setResponse(
      question,
      response: NumericResponse(question: question, stamp: 1, response: 1.25),
    );
    await _pumpEntry(tester, session, question);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 0.25);
    expect(slider.max, 3.75);
    expect(slider.value, 1.25);
    expect(slider.divisions, isNull);
    expect(find.text('1.25'), findsOneWidget);

    slider.onChanged!(2.625);
    await tester.pump();
    expect((session.fromQuestion(question) as NumericResponse).response, 2.625);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 2.625);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing fractional answer on integer bounds stays exact', (
    tester,
  ) async {
    const question = Numeric(
      id: 'saved-fraction',
      prompt: 'How much?',
      type: 'Amount',
      min: 1,
      max: 5,
    );
    final session = _session(question);
    session.setResponse(
      question,
      response: NumericResponse(question: question, stamp: 1, response: 2.5),
    );
    await _pumpEntry(tester, session, question);

    expect(tester.widget<Slider>(find.byType(Slider)).value, 2.5);
    expect((session.fromQuestion(question) as NumericResponse).response, 2.5);
    expect(find.text('2.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpEntry(
  WidgetTester tester,
  SessionGraph session,
  Numeric question,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: BowelMovementNumericEntry(graph: session, question: question),
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
