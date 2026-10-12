import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Insights/Engine/Blocks/presence_rate_blocks.dart';
import 'package:stripes_ui/Insights/Engine/Rules/recent_vs_usual_presence_rate_rule.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

const _questionId = 'nausea';
const _categoryId = 'category.SYMPTOM';
const _subject = PresenceRateSubject(
  questionId: _questionId,
  categoryId: _categoryId,
);

void main() {
  group('PresenceRateBlock', () {
    test(
      'prepares 3/5 recent versus 2/10 usual and counts eligible unanswered as false',
      () {
        final dataset = _coreDataset();
        final context = InsightBlockContext(dataset: dataset);
        const comparisonRequest = PresenceRateComparisonBlock(
          questionId: _questionId,
          categoryId: _categoryId,
        );

        final prepared = context.use(comparisonRequest);
        final comparison = prepared.value;

        expect(comparison.focus.positives, 3);
        expect(comparison.focus.opportunities, 5);
        expect(comparison.focus.rate, closeTo(0.6, 0.000001));
        expect(comparison.reference.positives, 2);
        expect(comparison.reference.opportunities, 10);
        expect(comparison.reference.rate, closeTo(0.2, 0.000001));
        expect(comparison.absoluteDifference, closeTo(0.4, 0.000001));
        expect(comparison.relativeRisk, closeTo(3, 0.000001));

        expect(prepared.evidence.observations, 15);
        expect(prepared.evidence.independentUnits, 15);
        expect(prepared.evidence.unit, EvidenceUnit.entry);
        expect(prepared.evidence.spanDays, 15);
        expect(prepared.evidence.coverage, 1);
        expect(prepared.evidence.effectSize, closeTo(0.4, 0.000001));
        expect(prepared.exclusions, isEmpty);

        // Unanswered-but-applicable entries have no observations, so retaining
        // their IDs proves denominator lineage does not depend on positives.
        expect(prepared.sourceEntryIds, hasLength(15));
        expect(prepared.contributingEntryIds, hasLength(15));
        expect(prepared.sourceEntryIds, contains('focus-5'));
        expect(prepared.sourceEntryIds, contains('reference-10'));
        expect(
          prepared.dependencyKeys,
          contains(comparisonRequest.focusBlock.key),
        );
        expect(
          prepared.dependencyKeys,
          contains(comparisonRequest.referenceBlock.key),
        );
      },
    );

    test('excludes inapplicable and unknown entries from the denominator', () {
      final entries = [
        _entry(id: 'positive', at: DateTime(2025, 1, 11, 9), present: true),
        _entry(id: 'unanswered', at: DateTime(2025, 1, 12, 9)),
        _entry(
          id: 'inapplicable',
          at: DateTime(2025, 1, 13, 9),
          applicable: false,
        ),
        _entry(
          id: 'unknown',
          at: DateTime(2025, 1, 14, 9),
          completionKnown: false,
        ),
      ];
      final dataset = _dataset(entries);
      final prepared = InsightBlockContext(dataset: dataset).use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.focus,
        ),
      );

      expect(prepared.value.positives, 1);
      expect(prepared.value.opportunities, 2);
      expect(prepared.value.rate, 0.5);
      expect(prepared.evidence.observations, 2);
      expect(prepared.evidence.coverage, closeTo(2 / 3, 0.000001));
      expect(prepared.sourceEntryIds, {
        'positive',
        'unanswered',
        'inapplicable',
        'unknown',
      });
      expect(
        _exclusionCount(
          prepared.exclusions,
          FeatureExclusionCode.notApplicable,
        ),
        1,
      );
      expect(
        _exclusionCount(
          prepared.exclusions,
          FeatureExclusionCode.opportunityUnknown,
        ),
        1,
      );
    });

    test('does not silently convert incompatible answers into negatives', () {
      final invalidAt = DateTime(2025, 1, 13, 9);
      final invalid = InsightEntry(
        entryId: 'invalid',
        categoryId: _categoryId,
        occurredAt: invalidAt,
        timePrecision: InsightTimePrecision.exact,
        observations: [
          InsightObservation(
            entryId: 'invalid',
            questionId: _questionId,
            promptKey: 'questions.nausea',
            categoryId: _categoryId,
            occurredAt: invalidAt,
            value: const NumericInsightValue(4),
          ),
        ],
        completion: InsightCompletionSnapshot(
          consideredQuestionIds: const [_questionId],
          applicableQuestionIds: const [_questionId],
          answeredQuestionIds: const [_questionId],
        ),
      );
      final dataset = _dataset([
        _entry(id: 'positive', at: DateTime(2025, 1, 11, 9), present: true),
        _entry(id: 'negative', at: DateTime(2025, 1, 12, 9)),
        invalid,
      ]);
      final context = InsightBlockContext(dataset: dataset);
      final prepared = context.use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.focus,
        ),
      );

      expect(prepared.value.positives, 1);
      expect(prepared.value.opportunities, 2);
      expect(prepared.evidence.coverage, closeTo(2 / 3, 0.000001));
      expect(
        _exclusionCount(
          prepared.exclusions,
          FeatureExclusionCode.incompatibleValue,
        ),
        1,
      );

      final evaluation =
          RecentVsUsualPresenceRateRule(
                subjects: const [_subject],
              ).evaluate(context).single
              as RejectedFindingEvaluation;
      expect(evaluation.code, FindingRejectionCode.opportunityUnknown);
    });

    test('fails closed for unsupported time semantics and entry kinds', () {
      final recordedAtDataset = _dataset([
        _entry(id: 'recorded-time', at: DateTime(2025, 1, 11), present: true),
      ], catalog: _catalog(timeSemantics: 'recordedAt'));
      final recordedPrepared = InsightBlockContext(dataset: recordedAtDataset)
          .use(
            const PresenceRateBlock(
              questionId: _questionId,
              categoryId: _categoryId,
              scope: InsightDatasetScope.focus,
            ),
          );
      expect(
        _exclusionCount(
          recordedPrepared.exclusions,
          FeatureExclusionCode.incompatibleTimeSemantics,
        ),
        1,
      );

      final landmarkDataset = _dataset([
        _entry(
          id: 'landmark',
          at: DateTime(2025, 1, 11),
          present: true,
          kind: InsightEntryKind.landmark,
        ),
      ]);
      final landmarkContext = InsightBlockContext(dataset: landmarkDataset);
      final landmarkPrepared = landmarkContext.use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.focus,
        ),
      );
      expect(landmarkPrepared.value.opportunities, 0);
      expect(
        _exclusionCount(
          landmarkPrepared.exclusions,
          FeatureExclusionCode.incompatibleEntryKind,
        ),
        1,
      );
      final evaluation =
          RecentVsUsualPresenceRateRule(
                subjects: const [_subject],
              ).evaluate(landmarkContext).single
              as RejectedFindingEvaluation;
      expect(evaluation.code, FindingRejectionCode.incompatibleEntryKind);
    });

    test('uses half-open reference and focus windows', () {
      final dataset = _dataset([
        _entry(id: 'reference-start', at: DateTime(2025, 1, 1), present: true),
        _entry(id: 'focus-start', at: DateTime(2025, 1, 11)),
        _entry(id: 'focus-end', at: DateTime(2025, 1, 16), present: true),
      ]);
      final context = InsightBlockContext(dataset: dataset);
      final reference = context.use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.reference,
        ),
      );
      final focus = context.use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.focus,
        ),
      );

      expect(reference.value.positives, 1);
      expect(reference.value.opportunities, 1);
      expect(reference.sourceEntryIds, {'reference-start'});
      expect(focus.value.positives, 0);
      expect(focus.value.opportunities, 1);
      expect(focus.sourceEntryIds, {'focus-start'});
      expect(
        dataset
            .entries(scope: InsightDatasetScope.all)
            .map((entry) => entry.entryId),
        contains('focus-end'),
      );
    });

    test(
      'keeps a zero denominator explicit and rejects it at the rule layer',
      () {
        final dataset = _dataset(const []);
        final context = InsightBlockContext(dataset: dataset);
        final prepared = context.use(
          const PresenceRateBlock(
            questionId: _questionId,
            categoryId: _categoryId,
            scope: InsightDatasetScope.focus,
          ),
        );

        expect(prepared.value.positives, 0);
        expect(prepared.value.opportunities, 0);
        expect(prepared.value.rate, isNull);
        expect(prepared.evidence.coverage, isNull);
        expect(
          _exclusionCount(
            prepared.exclusions,
            FeatureExclusionCode.noEligibleOpportunities,
          ),
          1,
        );

        final evaluation =
            RecentVsUsualPresenceRateRule(
                  subjects: const [_subject],
                ).evaluate(context).single
                as RejectedFindingEvaluation;
        expect(
          evaluation.code,
          FindingRejectionCode.insufficientFocusObservations,
        );
      },
    );

    test('reports a missing reference window as an unknown opportunity', () {
      final dataset = _dataset([
        _entry(id: 'focus-positive', at: DateTime(2025, 1, 11), present: true),
      ], hasReferenceWindow: false);
      final context = InsightBlockContext(dataset: dataset);
      final prepared = context.use(
        const PresenceRateComparisonBlock(
          questionId: _questionId,
          categoryId: _categoryId,
        ),
      );

      expect(prepared.value.focus.rate, isNull);
      expect(prepared.value.reference.rate, isNull);
      expect(
        _exclusionCount(
          prepared.exclusions,
          FeatureExclusionCode.referenceWindowMissing,
        ),
        1,
      );

      final evaluation =
          RecentVsUsualPresenceRateRule(
                subjects: const [_subject],
              ).evaluate(context).single
              as RejectedFindingEvaluation;
      expect(evaluation.code, FindingRejectionCode.opportunityUnknown);
    });

    test('does not treat a legacy positive as a known opportunity', () {
      const question = Check(
        id: _questionId,
        prompt: 'questions.nausea',
        type: _categoryId,
      );
      final at = DateTime(2025, 1, 11, 9);
      final response = DetailResponse(
        id: 'legacy-positive',
        stamp: dateToStamp(at),
        detailType: _categoryId,
        responses: [Selected(question: question, stamp: dateToStamp(at))],
      );
      final dataset = InsightDataset.fromResponses(
        [response],
        focusWindow: _focusWindow(),
        referenceWindow: _referenceWindow(),
        catalog: _catalog(),
      );
      final context = InsightBlockContext(dataset: dataset);
      final prepared = context.use(
        const PresenceRateBlock(
          questionId: _questionId,
          categoryId: _categoryId,
          scope: InsightDatasetScope.focus,
        ),
      );

      expect(dataset.entries().single.kind, InsightEntryKind.legacy);
      expect(dataset.entries().single.completion, isNull);
      expect(dataset.observationsFor(_questionId), hasLength(1));
      expect(prepared.value.positives, 0);
      expect(prepared.value.opportunities, 0);
      expect(prepared.value.rate, isNull);
      expect(prepared.sourceEntryIds, {'legacy-positive'});
      expect(prepared.evidence.coverage, 0);
      expect(
        _exclusionCount(
          prepared.exclusions,
          FeatureExclusionCode.opportunityUnknown,
        ),
        1,
      );

      final evaluation =
          RecentVsUsualPresenceRateRule(
                subjects: const [_subject],
              ).evaluate(context).single
              as RejectedFindingEvaluation;
      expect(evaluation.code, FindingRejectionCode.opportunityUnknown);
    });
  });

  group('RecentVsUsualPresenceRateRule', () {
    test(
      'prepares low-sample rates before the default policy rejects them',
      () {
        final dataset = _coreDataset();
        final context = InsightBlockContext(dataset: dataset);
        const comparisonRequest = PresenceRateComparisonBlock(
          questionId: _questionId,
          categoryId: _categoryId,
        );
        final prepared = context.use(comparisonRequest);

        expect(prepared.value.focus.opportunities, 5);
        expect(prepared.value.reference.opportunities, 10);
        expect(prepared.value.absoluteDifference, closeTo(0.4, 0.000001));
        expect(prepared.exclusions, isEmpty);

        final result = FindingEngine(
          rules: [
            RecentVsUsualPresenceRateRule(subjects: const [_subject]),
          ],
        ).evaluate(dataset, blockContext: context);

        expect(result.accepted, isEmpty);
        expect(result.rejected, hasLength(1));
        expect(
          result.rejected.single.code,
          FindingRejectionCode.insufficientFocusObservations,
        );
        expect(context.computationsFor(comparisonRequest.key), 1);
      },
    );

    test('accepts an ObservationFinding under an explicit policy', () {
      final dataset = _coreDataset();
      final result = FindingEngine(
        rules: [
          RecentVsUsualPresenceRateRule(
            subjects: const [_subject],
            policy: const RecentVsUsualPresenceRatePolicy(
              minimumFocusOpportunities: 5,
              minimumReferenceOpportunities: 10,
              minimumFocusSpanDays: 5,
              minimumReferenceSpanDays: 10,
              minimumAbsoluteDifference: 0.35,
            ),
          ),
        ],
      ).evaluate(dataset);

      expect(result.rejected, isEmpty);
      expect(result.accepted, hasLength(1));
      final finding = result.findings.single;
      expect(finding, isA<ObservationFinding>());
      expect(finding.kind, FindingKind.observation);

      final rateFinding = finding as RecentVsUsualPresenceRateFinding;
      expect(rateFinding.questionId, _questionId);
      expect(rateFinding.categoryId, _categoryId);
      expect(rateFinding.focus.positives, 3);
      expect(rateFinding.focus.opportunities, 5);
      expect(rateFinding.reference.positives, 2);
      expect(rateFinding.reference.opportunities, 10);
      expect(rateFinding.absoluteDifference, closeTo(0.4, 0.000001));
      expect(rateFinding.relativeRisk, closeTo(3, 0.000001));
      expect(rateFinding.increased, isTrue);
      expect(rateFinding.evidence.effectSize, closeTo(0.4, 0.000001));
      expect(rateFinding.sourceEntryIds, hasLength(15));
      expect(rateFinding.contributingEntryIds, hasLength(15));
      expect(rateFinding.exclusions, isEmpty);
    });
  });
}

InsightDataset _coreDataset() => _dataset([
  for (var index = 0; index < 10; index++)
    _entry(
      id: 'reference-${index + 1}',
      at: DateTime(2025, 1, index + 1, 9),
      present: index < 2 ? true : null,
    ),
  for (var index = 0; index < 5; index++)
    _entry(
      id: 'focus-${index + 1}',
      at: DateTime(2025, 1, index + 11, 9),
      present: index < 3 ? true : null,
    ),
]);

InsightDataset _dataset(
  Iterable<InsightEntry> entries, {
  bool hasReferenceWindow = true,
  InsightAnalysisCatalog? catalog,
}) => InsightDataset.fromEntries(
  entries,
  focusWindow: _focusWindow(),
  referenceWindow: hasReferenceWindow ? _referenceWindow() : null,
  catalog: catalog ?? _catalog(),
);

InsightEntry _entry({
  required String id,
  required DateTime at,
  bool applicable = true,
  bool completionKnown = true,
  bool? present,
  InsightEntryKind kind = InsightEntryKind.form,
}) => InsightEntry(
  entryId: id,
  categoryId: _categoryId,
  occurredAt: at,
  kind: kind,
  timePrecision: InsightTimePrecision.exact,
  observations: [
    if (present != null)
      InsightObservation(
        entryId: id,
        questionId: _questionId,
        promptKey: 'questions.nausea',
        categoryId: _categoryId,
        occurredAt: at,
        value: PresenceInsightValue(present),
      ),
  ],
  completion: completionKnown
      ? InsightCompletionSnapshot(
          consideredQuestionIds: const [_questionId],
          applicableQuestionIds: applicable ? const [_questionId] : const [],
          answeredQuestionIds: applicable && present != null
              ? const [_questionId]
              : const [],
        )
      : null,
);

InsightAnalysisCatalog _catalog({String? timeSemantics}) {
  final question = <String, Object?>{
    'measurement': 'binary',
    'aggregation': 'any',
    'absenceSemantics': 'unselectedMeansFalse',
  };
  if (timeSemantics != null) question['timeSemantics'] = timeSemantics;
  return InsightAnalysisCatalog.fromMap({
    'schemaVersion': 1,
    'questions': {_questionId: question},
  });
}

InsightTimeWindow _referenceWindow() => InsightTimeWindow(
  start: DateTime(2025, 1, 1),
  endExclusive: DateTime(2025, 1, 11),
);

InsightTimeWindow _focusWindow() => InsightTimeWindow(
  start: DateTime(2025, 1, 11),
  endExclusive: DateTime(2025, 1, 16),
);

int _exclusionCount(
  Iterable<FeatureExclusion> exclusions,
  FeatureExclusionCode code,
) => exclusions
    .where((exclusion) => exclusion.code == code)
    .fold(0, (total, exclusion) => total + exclusion.count);
