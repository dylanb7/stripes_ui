import 'package:stripes_ui/Insights/Engine/Blocks/presence_rate_blocks.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';

class PresenceRateSubject {
  final String questionId;
  final String categoryId;

  const PresenceRateSubject({
    required this.questionId,
    required this.categoryId,
  });
}

class RecentVsUsualPresenceRatePolicy {
  final int minimumFocusOpportunities;
  final int minimumReferenceOpportunities;
  final int minimumFocusSpanDays;
  final int minimumReferenceSpanDays;
  final double minimumAbsoluteDifference;

  const RecentVsUsualPresenceRatePolicy({
    this.minimumFocusOpportunities = 10,
    this.minimumReferenceOpportunities = 30,
    this.minimumFocusSpanDays = 3,
    this.minimumReferenceSpanDays = 14,
    this.minimumAbsoluteDifference = 0.15,
  }) : assert(minimumFocusOpportunities > 0),
       assert(minimumReferenceOpportunities > 0),
       assert(minimumFocusSpanDays > 0),
       assert(minimumReferenceSpanDays > 0),
       assert(minimumAbsoluteDifference >= 0 && minimumAbsoluteDifference <= 1);
}

final class RecentVsUsualPresenceRateFinding extends ObservationFinding {
  final String questionId;
  final String categoryId;
  final PresenceRate focus;
  final PresenceRate reference;
  final double absoluteDifference;
  final double? relativeRisk;

  RecentVsUsualPresenceRateFinding({
    required super.findingId,
    required super.ruleId,
    required this.questionId,
    required this.categoryId,
    required this.focus,
    required this.reference,
    required this.absoluteDifference,
    required this.relativeRisk,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  });

  bool get increased => absoluteDifference > 0;
}

class RecentVsUsualPresenceRateRule implements FindingRule {
  @override
  final String id;
  final List<PresenceRateSubject> subjects;
  final RecentVsUsualPresenceRatePolicy policy;

  RecentVsUsualPresenceRateRule({
    this.id = 'recent_vs_usual_presence_rate',
    required Iterable<PresenceRateSubject> subjects,
    this.policy = const RecentVsUsualPresenceRatePolicy(),
  }) : subjects = List.unmodifiable(subjects);

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    for (final subject in subjects) {
      yield _evaluateSubject(context, subject);
    }
  }

  FindingEvaluation _evaluateSubject(
    InsightBlockContext context,
    PresenceRateSubject subject,
  ) {
    final prepared = context.use(
      PresenceRateComparisonBlock(
        questionId: subject.questionId,
        categoryId: subject.categoryId,
      ),
    );
    final comparison = prepared.value;
    final subjectId = '${subject.categoryId}|${subject.questionId}';

    final blockingCode = _blockingRejection(prepared.exclusions);
    if (blockingCode != null) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: blockingCode,
      );
    }
    if (comparison.focus.opportunities < policy.minimumFocusOpportunities) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.insufficientFocusObservations,
        detail:
            'Requires ${policy.minimumFocusOpportunities} recent opportunities.',
      );
    }
    if (comparison.reference.opportunities <
        policy.minimumReferenceOpportunities) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.insufficientReferenceObservations,
        detail:
            'Requires ${policy.minimumReferenceOpportunities} reference opportunities.',
      );
    }
    if (comparison.focus.spanDays < policy.minimumFocusSpanDays) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.insufficientSpan,
        detail:
            'Requires recent opportunities across '
            '${policy.minimumFocusSpanDays} days.',
      );
    }
    if (comparison.reference.spanDays < policy.minimumReferenceSpanDays) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.insufficientSpan,
        detail:
            'Requires reference opportunities across '
            '${policy.minimumReferenceSpanDays} days.',
      );
    }

    final difference = comparison.absoluteDifference;
    if (difference == null) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.opportunityUnknown,
      );
    }
    if (difference.abs() < policy.minimumAbsoluteDifference) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: prepared.evidence,
        code: FindingRejectionCode.effectTooSmall,
      );
    }

    final findingId = FindingIdentity.build(
      ruleId: id,
      components: [
        subject.categoryId,
        subject.questionId,
        'focus-vs-reference',
      ],
    );
    return AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: RecentVsUsualPresenceRateFinding(
        findingId: findingId,
        ruleId: id,
        questionId: subject.questionId,
        categoryId: subject.categoryId,
        focus: comparison.focus,
        reference: comparison.reference,
        absoluteDifference: difference,
        relativeRisk: comparison.relativeRisk,
        evidence: prepared.evidence.copyWith(effectSize: difference),
        sourceEntryIds: prepared.sourceEntryIds,
        contributingEntryIds: prepared.contributingEntryIds,
        exclusions: prepared.exclusions,
      ),
    );
  }
}

FindingRejectionCode? _blockingRejection(
  Iterable<FeatureExclusion> exclusions,
) {
  final codes = exclusions.map((item) => item.code).toSet();
  if (codes.contains(FeatureExclusionCode.referenceWindowMissing) ||
      codes.contains(FeatureExclusionCode.invalidWindow)) {
    return FindingRejectionCode.opportunityUnknown;
  }
  if (codes.contains(FeatureExclusionCode.metadataMissing)) {
    return FindingRejectionCode.metadataMissing;
  }
  if (codes.contains(FeatureExclusionCode.metadataDisabled) ||
      codes.contains(FeatureExclusionCode.genericPatternExcluded)) {
    return FindingRejectionCode.metadataDisabled;
  }
  if (codes.contains(FeatureExclusionCode.incompatibleMeasurement) ||
      codes.contains(FeatureExclusionCode.absenceNotInterpretable)) {
    return FindingRejectionCode.incompatibleMeasurement;
  }
  if (codes.contains(FeatureExclusionCode.incompatibleAggregation)) {
    return FindingRejectionCode.incompatibleAggregation;
  }
  if (codes.contains(FeatureExclusionCode.incompatibleTimeSemantics) ||
      codes.contains(FeatureExclusionCode.incompatibleTimePrecision)) {
    return FindingRejectionCode.incompatibleTimeSemantics;
  }
  if (codes.contains(FeatureExclusionCode.incompatibleEntryKind)) {
    return FindingRejectionCode.incompatibleEntryKind;
  }
  if (codes.contains(FeatureExclusionCode.opportunityUnknown) ||
      codes.contains(FeatureExclusionCode.incompatibleValue)) {
    return FindingRejectionCode.opportunityUnknown;
  }
  return null;
}
