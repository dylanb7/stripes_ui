import 'package:flutter/material.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/transform.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/baseline_question_reference.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';

void main() {
  const source = AllThatApply(
    id: 'seizure-types',
    prompt: 'Seizure types',
    type: 'Seizures',
    choices: ['Absence', 'Tonic'],
  );
  const unrelated = FreeResponse(
    id: 'notes',
    prompt: 'Other notes',
    type: 'Notes',
  );
  final question = MultipleChoice(
    id: 'comparison',
    prompt: 'Change in {value}?',
    type: 'Change',
    choices: const ['Better', 'Same', 'Worse'],
    fromBaseline: 'baseline',
    transform: const GenerateForEach(sourceId: 'seizure-types').serialize(),
  );
  DetailResponse baseline(List<int> choices) => DetailResponse(
    id: BaselineId.create('baseline', 3),
    detailType: 'baseline',
    stamp: 1000,
    responses: [
      AllResponse(question: source, responses: choices, stamp: 1000),
      OpenResponse(question: unrelated, response: 'Other context', stamp: 1000),
    ],
  );

  SessionGraph session(DetailResponse saved) {
    final graph = QuestionGraphBuilder.build(
      home: _Home({question.id: question}),
      recordPaths: [
        RecordPath(
          name: 'check-in',
          pages: [
            PageLayout(questionIds: [question.id]),
          ],
        ),
      ],
    );
    final result = graph.createSession(
      recordPathName: 'check-in',
      baselines: [saved],
    );
    addTearDown(() {
      result.dispose();
      graph.dispose();
    });
    return result;
  }

  testWidgets(
    'default reference shows source answers and expands the full baseline',
    (tester) async {
      final saved = baseline([0, 1]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baselinesStreamProvider.overrideWith(
              (ref) => Stream.value(<Stamp>[]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: BaselineQuestionReference(
                  reference: BaselineQuestionContext(
                    baseline: saved,
                    question: question,
                    resolvedQuestions: [question],
                    sourceResponses: [saved.responses.first],
                  ),
                  child: const Text('Comparison controls'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compare with your baseline'), findsOneWidget);
      expect(find.text('Other context'), findsNothing);
      expect(find.text('Comparison controls'), findsOneWidget);
      await tester.tap(find.text('View all baseline answers'));
      await tester.pumpAndSettle();
      expect(find.text('Other context'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'groups generated comparisons with the exact session snapshot and source answers',
    (tester) async {
      final saved = baseline([0, 1]);
      final graph = session(saved);
      BaselineQuestionContext? captured;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuestionResolverWrapper(
                question: question,
                questionsListener: graph,
                // An explicit but unrelated snapshot must not override the graph.
                baseline: baseline([1]),
                baselineReferenceBuilder: (_, reference, child) {
                  captured = reference;
                  return child;
                },
                builder: (q) => Text(q.id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.baseline, same(saved));
      expect(captured!.sourceResponses, [saved.responses.first]);
      expect(captured!.resolvedQuestions.map((q) => q.id), [
        'comparison::absence::v3',
        'comparison::tonic::v3',
      ]);
      expect(find.text('comparison::absence::v3'), findsOneWidget);
      expect(find.text('comparison::tonic::v3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'already resolved single generated questions are not generated again',
    (tester) async {
      final saved = baseline([0]);
      final graph = session(saved);
      final resolved = graph
          .questionStateOf(question.id)!
          .value
          .resolvedQuestion;
      BaselineQuestionContext? captured;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuestionResolverWrapper(
                question: resolved,
                questionsListener: graph,
                baselineReferenceBuilder: (_, reference, child) {
                  captured = reference;
                  return child;
                },
                builder: (q) => Text(q.id),
              ),
            ),
          ),
        ),
      );
      expect(captured!.resolvedQuestions.single.id, 'comparison::absence::v3');
      expect(find.text('comparison::absence::v3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Home extends QuestionHome {
  _Home(Map<String, Question> questions) {
    all = questions;
  }
  @override
  Map<String, List<Question>> byType() => {};
}
