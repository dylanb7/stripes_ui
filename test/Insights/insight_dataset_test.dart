import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

void main() {
  group('InsightDataset', () {
    test('retains an empty completed parent with unknown completion', () {
      final occurredAt = DateTime(2025, 1, 3, 9);
      final dataset = _dataset([
        _detailEntry(
          id: 'empty-entry',
          at: occurredAt,
          responses: const [],
          categoryId: 'category.SYMPTOMS',
        ),
      ]);

      final entries = dataset.entries(scope: InsightDatasetScope.all);

      expect(entries, hasLength(1));
      expect(entries.single.entryId, 'empty-entry');
      expect(entries.single.categoryId, 'category.SYMPTOMS');
      expect(entries.single.occurredAt, occurredAt);
      expect(entries.single.kind, InsightEntryKind.legacy);
      expect(entries.single.observations, isEmpty);
      expect(entries.single.completion, isNull);
      expect(entries.single.hasKnownOpportunities, isFalse);
      expect(dataset.observations(scope: InsightDatasetScope.all), isEmpty);
    });

    test(
      'fromEntries preserves authoritative completion and inferred absence',
      () {
        final occurredAt = DateTime(2025, 1, 4, 10);
        final completion = InsightCompletionSnapshot(
          questionSetRevision: 'questions-2025-01',
          consideredQuestionIds: const {'symptom-flag', 'conditional-flag'},
          applicableQuestionIds: const {'symptom-flag'},
          answeredQuestionIds: const {},
        );
        final absence = InsightObservation(
          entryId: 'normalized-entry',
          questionId: 'symptom-flag',
          promptKey: 'questions.symptom_flag',
          categoryId: 'category.SYMPTOMS',
          occurredAt: occurredAt,
          value: const PresenceInsightValue(false),
          provenance: InsightObservationProvenance.inferredUnselectedCheck,
        );
        final dataset = InsightDataset.fromEntries(
          [
            InsightEntry(
              entryId: 'normalized-entry',
              categoryId: 'category.SYMPTOMS',
              occurredAt: occurredAt,
              kind: InsightEntryKind.event,
              observations: [absence],
              completion: completion,
            ),
          ],
          focusWindow: InsightTimeWindow(
            start: DateTime(2025, 1, 1),
            endExclusive: DateTime(2025, 2, 1),
          ),
        );

        final entry = dataset.entries().single;
        expect(entry.completion, same(completion));
        expect(entry.hasKnownOpportunities, isTrue);
        expect(entry.isQuestionApplicable('symptom-flag'), isTrue);
        expect(entry.isQuestionApplicable('conditional-flag'), isFalse);
        expect(entry.answeredQuestionIds, isEmpty);

        final observation = dataset.observationsFor('symptom-flag').single;
        expect(
          observation.provenance,
          InsightObservationProvenance.inferredUnselectedCheck,
        );
        expect((observation.value as PresenceInsightValue).present, isFalse);
      },
    );

    test('does not synthesize false values for legacy response entries', () {
      final catalog = _catalog({
        'symptom-flag': {
          'measurement': 'binary',
          'aggregation': 'any',
          'absenceSemantics': 'unselectedMeansFalse',
        },
      });
      final dataset = _dataset([
        _detailEntry(
          id: 'legacy-entry',
          at: DateTime(2025, 1, 5, 11),
          responses: const [],
          categoryId: 'category.SYMPTOMS',
        ),
      ], catalog: catalog);

      expect(dataset.entries(), hasLength(1));
      expect(dataset.entries().single.completion, isNull);
      expect(dataset.observationsFor('symptom-flag'), isEmpty);
      expect(
        dataset.observations().where(
          (observation) =>
              observation.value is PresenceInsightValue &&
              !(observation.value as PresenceInsightValue).present,
        ),
        isEmpty,
      );
    });

    test('rejects duplicate stable entry IDs even when timestamps differ', () {
      expect(
        () => InsightDataset.fromEntries(
          [
            InsightEntry(
              entryId: 'same-entry',
              categoryId: 'category.SYMPTOMS',
              occurredAt: DateTime(2025, 1, 1),
            ),
            InsightEntry(
              entryId: 'same-entry',
              categoryId: 'category.SYMPTOMS',
              occurredAt: DateTime(2025, 1, 2),
            ),
          ],
          focusWindow: InsightTimeWindow(
            start: DateTime(2025, 1, 1),
            endExclusive: DateTime(2025, 2, 1),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('uses one canonical observation view for normalized entries', () {
      final at = DateTime(2025, 1, 2, 9);
      InsightObservation observation() => InsightObservation(
        entryId: 'entry',
        questionId: 'pain',
        promptKey: 'questions.pain',
        categoryId: 'category.SYMPTOMS',
        occurredAt: at,
        value: const NumericInsightValue(4),
      );
      final dataset = InsightDataset.fromEntries(
        [
          InsightEntry(
            entryId: 'entry',
            categoryId: 'category.SYMPTOMS',
            occurredAt: at,
            observations: [observation(), observation()],
          ),
        ],
        focusWindow: InsightTimeWindow(
          start: DateTime(2025, 1, 1),
          endExclusive: DateTime(2025, 2, 1),
        ),
      );

      expect(dataset.entries().single.observations, hasLength(1));
      expect(dataset.observationsFor('pain'), hasLength(1));
    });

    test('validates completion schema and inferred-absence provenance', () {
      expect(
        () => InsightCompletionSnapshot(
          schemaVersion: 2,
          consideredQuestionIds: const {},
          applicableQuestionIds: const {},
          answeredQuestionIds: const {},
        ),
        throwsArgumentError,
      );
      expect(
        () => InsightObservation(
          entryId: 'entry',
          questionId: 'symptom',
          promptKey: 'questions.symptom',
          categoryId: 'category.SYMPTOMS',
          occurredAt: DateTime(2025, 1, 1),
          value: const PresenceInsightValue(true),
          provenance: InsightObservationProvenance.inferredUnselectedCheck,
        ),
        throwsArgumentError,
      );
    });

    test('is deterministic and keys observations by stable question ID', () {
      final oldPain = _numericQuestion(
        id: 'pain',
        prompt: 'questions.pain.old',
      );
      final renamedPain = _numericQuestion(
        id: 'pain',
        prompt: 'questions.pain.renamed',
      );
      final samePromptDifferentId = _numericQuestion(
        id: 'fatigue',
        prompt: 'questions.pain.renamed',
      );
      final first = _numericEntry(
        id: 'entry-1',
        at: DateTime(2025, 1, 1, 9),
        question: oldPain,
        value: 2,
      );
      final second = _detailEntry(
        id: 'entry-2',
        at: DateTime(2025, 1, 2, 9),
        responses: [
          NumericResponse(
            question: renamedPain,
            stamp: dateToStamp(DateTime(2025, 1, 2, 8)),
            response: 4,
          ),
          NumericResponse(
            question: samePromptDifferentId,
            stamp: dateToStamp(DateTime(2025, 1, 2, 8)),
            response: 7,
          ),
        ],
      );
      final reversedChildren = _detailEntry(
        id: 'entry-2',
        at: DateTime(2025, 1, 2, 9),
        responses: second.responses.reversed.toList(),
      );

      final chronological = _dataset([first, second]);
      final reversed = _dataset([reversedChildren, first]);

      expect(
        _observationSignatures(chronological),
        _observationSignatures(reversed),
      );
      expect(
        chronological.numericObservationsFor('pain').map((item) => item.value),
        [2.0, 4.0],
      );
      expect(
        chronological
            .numericObservationsFor('fatigue')
            .map((item) => item.value),
        [7.0],
      );
      expect(
        chronological.observationsFor('pain').map((item) => item.promptKey),
        ['questions.pain.old', 'questions.pain.renamed'],
      );
    });

    test('filters missing sentinels before daily aggregation', () {
      final pain = _numericQuestion(id: 'pain', prompt: 'questions.pain');
      final catalog = _catalog({
        'pain': {
          'measurement': 'ordinal',
          'aggregation': 'mean',
          'validRange': [0, 10],
          'missingValues': [-1],
        },
      });
      final responses = [
        _numericEntry(
          id: 'missing-only',
          at: DateTime(2025, 1, 1, 9),
          question: pain,
          value: -1,
        ),
        _numericEntry(
          id: 'valid-4',
          at: DateTime(2025, 1, 2, 9),
          question: pain,
          value: 4,
        ),
        _numericEntry(
          id: 'missing-mixed',
          at: DateTime(2025, 1, 2, 10),
          question: pain,
          value: -1,
        ),
        _numericEntry(
          id: 'valid-8',
          at: DateTime(2025, 1, 2, 11),
          question: pain,
          value: 8,
        ),
      ];

      final dataset = _dataset(responses, catalog: catalog);
      final series = dataset.dailyNumericSeries(
        'pain',
        aggregation: InsightAggregation.mean,
      );

      expect(dataset.numericObservationsFor('pain').map((item) => item.value), [
        4.0,
        8.0,
      ]);
      expect(series, hasLength(1));
      expect(series.single.day, DateTime(2025, 1, 2));
      expect(series.single.value, 6.0);
      expect(series.single.observationCount, 2);
      expect(
        dataset.issues.where(
          (issue) => issue.code == InsightDataIssueCode.missingValue,
        ),
        hasLength(2),
      );
    });

    test('pairs numeric series only on shared calendar days', () {
      final left = _numericQuestion(id: 'a', prompt: 'questions.a', max: 100);
      final right = _numericQuestion(id: 'b', prompt: 'questions.b', max: 100);
      final catalog = _catalog({
        'a': {'measurement': 'continuous', 'aggregation': 'maximum'},
        'b': {'measurement': 'continuous', 'aggregation': 'mean'},
      });
      final responses = [
        _numericEntry(
          id: 'a-1',
          at: DateTime(2025, 1, 1, 9),
          question: left,
          value: 1,
        ),
        _numericEntry(
          id: 'a-2',
          at: DateTime(2025, 1, 2, 9),
          question: left,
          value: 2,
        ),
        _numericEntry(
          id: 'a-4-low',
          at: DateTime(2025, 1, 4, 9),
          question: left,
          value: 4,
        ),
        _numericEntry(
          id: 'a-4-high',
          at: DateTime(2025, 1, 4, 10),
          question: left,
          value: 8,
        ),
        _numericEntry(
          id: 'b-1',
          at: DateTime(2025, 1, 1, 10),
          question: right,
          value: 10,
        ),
        _numericEntry(
          id: 'b-3',
          at: DateTime(2025, 1, 3, 10),
          question: right,
          value: 30,
        ),
        _numericEntry(
          id: 'b-4',
          at: DateTime(2025, 1, 4, 10),
          question: right,
          value: 40,
        ),
      ];

      final dataset = _dataset(responses, catalog: catalog);
      final pairs = dataset.pairedDailyNumeric(
        'a',
        'b',
        leftAggregation: InsightAggregation.maximum,
        rightAggregation: InsightAggregation.mean,
      );

      expect(pairs.map((pair) => pair.day), [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 4),
      ]);
      expect(pairs.map((pair) => pair.left.value), [1.0, 8.0]);
      expect(pairs.map((pair) => pair.right.value), [10.0, 40.0]);
      expect(pairs.last.left.observationCount, 2);
    });

    test('uses explicit half-open focus and reference windows', () {
      final pain = _numericQuestion(id: 'pain', prompt: 'questions.pain');
      final responses = [
        _numericEntry(
          id: 'reference-start',
          at: DateTime(2025, 1, 1),
          question: pain,
          value: 1,
        ),
        _numericEntry(
          id: 'focus-start',
          at: DateTime(2025, 1, 8),
          question: pain,
          value: 2,
        ),
        _numericEntry(
          id: 'focus-end',
          at: DateTime(2025, 1, 15),
          question: pain,
          value: 3,
        ),
      ];
      final dataset = InsightDataset.fromResponses(
        responses.reversed,
        focusWindow: InsightTimeWindow(
          start: DateTime(2025, 1, 8),
          endExclusive: DateTime(2025, 1, 15),
        ),
        referenceWindow: InsightTimeWindow(
          start: DateTime(2025, 1, 1),
          endExclusive: DateTime(2025, 1, 8),
        ),
      );

      expect(
        dataset
            .numericObservationsFor(
              'pain',
              scope: InsightDatasetScope.reference,
            )
            .map((item) => item.value),
        [1.0],
      );
      expect(dataset.numericObservationsFor('pain').map((item) => item.value), [
        2.0,
      ]);
      expect(
        dataset
            .numericObservationsFor('pain', scope: InsightDatasetScope.all)
            .map((item) => item.value),
        [1.0, 2.0, 3.0],
      );
    });

    test('keeps all-that-apply selections as one set-valued observation', () {
      const question = AllThatApply(
        id: 'symptoms',
        prompt: 'questions.symptoms',
        type: 'category.SYMPTOMS',
        choices: ['nausea', 'bloating', 'pain'],
      );
      final entry = _detailEntry(
        id: 'symptoms-1',
        at: DateTime(2025, 1, 2, 9),
        responses: [
          AllResponse(
            question: question,
            stamp: dateToStamp(DateTime(2025, 1, 2, 9)),
            responses: [0, 2],
          ),
        ],
        categoryId: 'category.SYMPTOMS',
      );

      final dataset = _dataset([entry]);
      final observations = dataset.observationsFor('symptoms');

      expect(observations, hasLength(1));
      final value = observations.single.value as ChoiceInsightValue;
      expect(value.choices, ['nausea', 'pain']);
      expect(value.allowsMultiple, isTrue);
    });

    test(
      'uses nested detail identity and time and removes wrapper duplicates',
      () {
        final pain = _numericQuestion(id: 'pain', prompt: 'questions.pain');
        final bowelMovement = _numericEntry(
          id: 'bowel-movement-1',
          at: DateTime(2025, 1, 10, 14),
          question: pain,
          value: 6,
        );
        final log = BMTestLog(response: bowelMovement, isBlue: true);
        final test = BlueDyeResp(
          id: 'blue-dye-1',
          startEating: DateTime(2025, 1, 1, 8),
          eatingDuration: const Duration(minutes: 20),
          normalBowelMovements: 0,
          blueBowelMovements: 1,
          logs: [log],
          amountConsumed: AmountConsumed.all,
          firstBlue: DateTime(2025, 1, 10, 14),
          lastBlue: DateTime(2025, 1, 10, 14),
        );
        final dataset = InsightDataset.fromResponses(
          [test, bowelMovement],
          focusWindow: InsightTimeWindow(
            start: DateTime(2025, 1, 8),
            endExclusive: DateTime(2025, 1, 15),
          ),
        );

        final observations = dataset.observationsFor('pain');

        expect(observations, hasLength(1));
        expect(observations.single.entryId, 'bowel-movement-1');
        expect(observations.single.occurredAt, DateTime(2025, 1, 10, 14));
      },
    );
  });
}

InsightDataset _dataset(
  Iterable<Response> responses, {
  InsightAnalysisCatalog catalog = const InsightAnalysisCatalog.empty(),
}) => InsightDataset.fromResponses(
  responses,
  focusWindow: InsightTimeWindow(
    start: DateTime(2025, 1, 1),
    endExclusive: DateTime(2025, 2, 1),
  ),
  catalog: catalog,
);

InsightAnalysisCatalog _catalog(Map<String, Object?> questions) =>
    InsightAnalysisCatalog.fromMap({
      'schemaVersion': 1,
      'questions': questions,
    });

Numeric _numericQuestion({
  required String id,
  required String prompt,
  num min = 0,
  num max = 10,
}) =>
    Numeric(id: id, prompt: prompt, type: 'category.PAIN', min: min, max: max);

DetailResponse _numericEntry({
  required String id,
  required DateTime at,
  required Numeric question,
  required num value,
}) => _detailEntry(
  id: id,
  at: at,
  responses: [
    NumericResponse(
      question: question,
      stamp: dateToStamp(at),
      response: value,
    ),
  ],
  categoryId: question.type,
);

DetailResponse _detailEntry({
  required String id,
  required DateTime at,
  required List<Response> responses,
  String categoryId = 'category.PAIN',
}) => DetailResponse(
  id: id,
  stamp: dateToStamp(at),
  detailType: categoryId,
  responses: responses,
);

List<String> _observationSignatures(InsightDataset dataset) => dataset
    .observations(scope: InsightDatasetScope.all)
    .map(
      (observation) => [
        observation.occurredAt.toIso8601String(),
        observation.entryId,
        observation.questionId,
        observation.promptKey,
        observation.value.toString(),
      ].join('|'),
    )
    .toList();
