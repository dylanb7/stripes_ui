import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Insights/Engine/Blocks/numeric_blocks.dart';
import 'package:stripes_ui/Insights/Engine/Rules/numeric_relationship_rule.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

void main() {
  group('NumericRelationshipRule', () {
    test('emits an observational finding when evidence thresholds are met', () {
      final dataset = _relationshipDataset(
        days: 14,
        leftValue: (day) => day.toDouble(),
        rightValue: (day) => day * 3.0,
      );

      final result = FindingEngine(
        rules: const [NumericRelationshipRule()],
      ).evaluate(dataset);

      expect(result.rejected, isEmpty);
      expect(result.accepted, hasLength(1));
      final finding =
          result.accepted.single.finding as NumericRelationshipFinding;
      expect(
        finding.findingId,
        FindingIdentity.build(
          ruleId: 'numeric_relationship',
          components: const ['a', 'mean', 'b', 'maximum', 'focus'],
        ),
      );
      expect(finding.kind, FindingKind.observation);
      expect(finding.rho, closeTo(1, 0.0001));
      expect(finding.pairs, hasLength(14));
      expect(finding.evidence.observations, 28);
      expect(finding.evidence.independentUnits, 14);
      expect(finding.evidence.unit, EvidenceUnit.day);
      expect(finding.evidence.spanDays, 14);
      expect(finding.evidence.coverage, 1);
      expect(finding.evidence.effectSize, closeTo(1, 0.0001));
      expect(finding.contributingEntryIds, hasLength(28));
    });

    test('explains rejection when too few dates overlap', () {
      final dataset = _relationshipDataset(
        days: 7,
        leftValue: (day) => day.toDouble(),
        rightValue: (day) => day * 2.0,
      );

      final evaluations = const NumericRelationshipRule().evaluate(
        InsightBlockContext(dataset: dataset),
      );
      final rejected = evaluations.single as RejectedFindingEvaluation;

      expect(rejected.subjectId, 'a|b');
      expect(rejected.code, FindingRejectionCode.insufficientOverlap);
      expect(rejected.evidence.independentUnits, 7);
      expect(rejected.detail, contains('14 shared days'));
    });

    test('rejects a pair whose daily values have no variance', () {
      final dataset = _relationshipDataset(
        days: 14,
        leftValue: (_) => 5,
        rightValue: (day) => day.toDouble(),
      );

      final evaluation = const NumericRelationshipRule()
          .evaluate(InsightBlockContext(dataset: dataset))
          .single;

      expect(evaluation, isA<RejectedFindingEvaluation>());
      expect(
        (evaluation as RejectedFindingEvaluation).code,
        FindingRejectionCode.insufficientVariance,
      );
    });

    test('does not infer relationships for questions absent from catalog', () {
      final dataset = _relationshipDataset(
        days: 14,
        leftValue: (day) => day.toDouble(),
        rightValue: (day) => day * 2.0,
        includeUnknownQuestion: true,
      );

      final evaluations = const NumericRelationshipRule()
          .evaluate(InsightBlockContext(dataset: dataset))
          .toList();

      expect(evaluations, hasLength(1));
      expect(evaluations.single.subjectId, 'a|b');
      expect(dataset.numericObservationsFor('unknown'), hasLength(14));
    });

    test('honors category exclusions for generic patterns', () {
      final dataset = _relationshipDataset(
        days: 14,
        leftValue: (day) => day.toDouble(),
        rightValue: (day) => day * 2.0,
        categoryAnalysis: {
          'mode': 'baseline',
          'includeInGenericPatterns': false,
        },
      );

      final evaluations = const NumericRelationshipRule()
          .evaluate(InsightBlockContext(dataset: dataset))
          .toList();

      expect(evaluations, isEmpty);
      expect(dataset.numericObservationsFor('a'), hasLength(14));
      expect(
        dataset.numericObservationsFor('a', eligibleForGenericAnalysis: true),
        isEmpty,
      );
    });

    test('isolates a throwing rule as an analysis failure', () {
      final dataset = _relationshipDataset(
        days: 3,
        leftValue: (day) => day,
        rightValue: (day) => day,
      );

      final result = FindingEngine(rules: [_ThrowingRule()]).evaluate(dataset);

      expect(result.accepted, isEmpty);
      expect(result.rejected, hasLength(1));
      expect(result.rejected.single.code, FindingRejectionCode.analysisFailed);
      expect(result.rejected.single.ruleId, 'throwing');
    });

    test('shares prepared numeric work across discovery and pairing', () {
      final dataset = _relationshipDataset(
        days: 14,
        leftValue: (day) => day.toDouble(),
        rightValue: (day) => day * 3.0,
      );
      final context = InsightBlockContext(dataset: dataset);

      final result = FindingEngine(
        rules: const [NumericRelationshipRule()],
      ).evaluate(dataset, blockContext: context);

      expect(result.accepted, hasLength(1));
      for (final questionId in ['a', 'b']) {
        expect(
          context.computationsFor(
            NumericObservationsBlock(
              questionId: questionId,
              eligibleForGenericAnalysis: true,
            ).key,
          ),
          1,
        );
        expect(
          context.computationsFor(
            DailyNumericSeriesBlock(
              questionId: questionId,
              aggregation: questionId == 'a'
                  ? InsightAggregation.mean
                  : InsightAggregation.maximum,
              eligibleForGenericAnalysis: true,
            ).key,
          ),
          1,
        );
      }
    });
  });
}

InsightDataset _relationshipDataset({
  required int days,
  required num Function(int day) leftValue,
  required num Function(int day) rightValue,
  bool includeUnknownQuestion = false,
  Map<String, Object?>? categoryAnalysis,
}) {
  const left = Numeric(
    id: 'a',
    prompt: 'questions.a',
    type: 'category.SYMPTOM',
    min: 0,
    max: 1000,
  );
  const right = Numeric(
    id: 'b',
    prompt: 'questions.b',
    type: 'category.SYMPTOM',
    min: 0,
    max: 1000,
  );
  const unknown = Numeric(
    id: 'unknown',
    prompt: 'questions.unknown',
    type: 'category.SYMPTOM',
    min: 0,
    max: 1000,
  );
  final responses = <Response>[];
  for (var day = 1; day <= days; day++) {
    final at = DateTime(2025, 1, day, 9);
    responses.add(_entry('a-$day', at, left, leftValue(day)));
    responses.add(_entry('b-$day', at, right, rightValue(day)));
    if (includeUnknownQuestion) {
      responses.add(_entry('unknown-$day', at, unknown, day));
    }
  }

  final catalog = InsightAnalysisCatalog.fromMap({
    'schemaVersion': 1,
    if (categoryAnalysis != null)
      'categories': {'category.SYMPTOM': categoryAnalysis},
    'questions': {
      'a': {'measurement': 'continuous', 'aggregation': 'mean'},
      'b': {'measurement': 'ordinal', 'aggregation': 'maximum'},
    },
  });
  return InsightDataset.fromResponses(
    responses.reversed,
    focusWindow: InsightTimeWindow(
      start: DateTime(2025, 1, 1),
      endExclusive: DateTime(2025, 2, 1),
    ),
    catalog: catalog,
  );
}

DetailResponse _entry(String id, DateTime at, Numeric question, num value) =>
    DetailResponse(
      id: id,
      stamp: dateToStamp(at),
      detailType: question.type,
      responses: [
        NumericResponse(
          question: question,
          stamp: dateToStamp(at),
          response: value,
        ),
      ],
    );

class _ThrowingRule implements FindingRule {
  @override
  String get id => 'throwing';

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) {
    throw StateError('deliberate test failure');
  }
}
