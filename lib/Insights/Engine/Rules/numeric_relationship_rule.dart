import 'package:stripes_ui/Insights/Engine/Blocks/numeric_blocks.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Util/Helpers/stats.dart';

class NumericRelationshipPolicy {
  final int minimumSharedDays;
  final int minimumUniqueValues;
  final int minimumSpanDays;
  final double minimumAbsoluteCorrelation;

  const NumericRelationshipPolicy({
    this.minimumSharedDays = 14,
    this.minimumUniqueValues = 3,
    this.minimumSpanDays = 14,
    this.minimumAbsoluteCorrelation = 0.5,
  }) : assert(minimumSharedDays >= 3),
       assert(minimumUniqueValues >= 2),
       assert(minimumSpanDays > 0),
       assert(
         minimumAbsoluteCorrelation >= 0 && minimumAbsoluteCorrelation <= 1,
       );
}

/// An exploratory association. It remains observational until uncertainty,
/// stability, and multiple-comparison controls support an inferential claim.
final class NumericRelationshipFinding extends ObservationFinding {
  final String leftQuestionId;
  final String rightQuestionId;
  final double rho;
  final List<InsightDailyNumericPair> pairs;

  NumericRelationshipFinding({
    required super.findingId,
    required super.ruleId,
    required this.leftQuestionId,
    required this.rightQuestionId,
    required this.rho,
    required Iterable<InsightDailyNumericPair> pairs,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : pairs = List.unmodifiable(pairs);
}

/// Evaluates exploratory same-day numeric relationships.
///
/// This rule emits pure findings and evidence only. It deliberately does not
/// produce user-facing causal language or wire itself into the legacy cards.
class NumericRelationshipRule implements FindingRule {
  @override
  final String id;
  final NumericRelationshipPolicy policy;

  const NumericRelationshipRule({
    this.id = 'numeric_relationship',
    this.policy = const NumericRelationshipPolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final dataset = context.dataset;
    final questionIds = <String>[];
    for (final spec in dataset.catalog.questions.values) {
      if (!spec.enabled || !spec.supportsNumericAnalysis) continue;
      final prepared = context.use(
        NumericObservationsBlock(
          questionId: spec.questionId,
          eligibleForGenericAnalysis: true,
        ),
      );
      if (prepared.value.isNotEmpty) questionIds.add(spec.questionId);
    }
    questionIds.sort();

    for (var leftIndex = 0; leftIndex < questionIds.length - 1; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < questionIds.length;
        rightIndex++
      ) {
        yield _evaluatePair(
          context,
          questionIds[leftIndex],
          questionIds[rightIndex],
        );
      }
    }
  }

  FindingEvaluation _evaluatePair(
    InsightBlockContext context,
    String leftId,
    String rightId,
  ) {
    final dataset = context.dataset;
    final subjectId = '$leftId|$rightId';
    final leftSpec = dataset.catalog.question(leftId)!;
    final rightSpec = dataset.catalog.question(rightId)!;
    final emptyEvidence = const FindingEvidence(
      observations: 0,
      independentUnits: 0,
      unit: EvidenceUnit.day,
      spanDays: 0,
    );

    if (!_isNumericDailyAggregation(leftSpec.aggregation) ||
        !_isNumericDailyAggregation(rightSpec.aggregation)) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: emptyEvidence,
        code: FindingRejectionCode.incompatibleAggregation,
      );
    }

    final prepared = context.use(
      PairedDailyNumericBlock(
        leftQuestionId: leftId,
        rightQuestionId: rightId,
        leftAggregation: leftSpec.aggregation,
        rightAggregation: rightSpec.aggregation,
        eligibleForGenericAnalysis: true,
      ),
    );
    final pairs = prepared.value;
    var evidence = prepared.evidence;

    if (pairs.length < policy.minimumSharedDays) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientOverlap,
        detail: 'Requires ${policy.minimumSharedDays} shared days.',
      );
    }
    if (evidence.spanDays < policy.minimumSpanDays) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientSpan,
        detail: 'Requires a ${policy.minimumSpanDays}-day span.',
      );
    }

    final leftValues = pairs.map((pair) => pair.left.value).toList();
    final rightValues = pairs.map((pair) => pair.right.value).toList();
    if (leftValues.toSet().length < policy.minimumUniqueValues ||
        rightValues.toSet().length < policy.minimumUniqueValues) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientVariance,
      );
    }

    final correlation = spearmanCorrelation(leftValues, rightValues);
    if (correlation == null) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.analysisFailed,
      );
    }
    evidence = evidence.copyWith(effectSize: correlation.rho);
    if (correlation.rho.abs() < policy.minimumAbsoluteCorrelation) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.effectTooSmall,
      );
    }

    return AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: NumericRelationshipFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: [
            leftId,
            leftSpec.aggregation.name,
            rightId,
            rightSpec.aggregation.name,
            InsightDatasetScope.focus.name,
          ],
        ),
        ruleId: id,
        leftQuestionId: leftId,
        rightQuestionId: rightId,
        rho: correlation.rho,
        pairs: pairs,
        evidence: evidence,
        sourceEntryIds: prepared.sourceEntryIds,
        contributingEntryIds: prepared.contributingEntryIds,
        exclusions: prepared.exclusions,
      ),
    );
  }
}

bool _isNumericDailyAggregation(InsightAggregation aggregation) =>
    switch (aggregation) {
      InsightAggregation.latest ||
      InsightAggregation.mean ||
      InsightAggregation.maximum ||
      InsightAggregation.minimum ||
      InsightAggregation.sum ||
      InsightAggregation.observationCount => true,
      InsightAggregation.any ||
      InsightAggregation.distribution ||
      InsightAggregation.perEvent => false,
    };
