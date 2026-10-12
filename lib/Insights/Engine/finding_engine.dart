import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

enum FindingRejectionCode {
  metadataMissing,
  metadataDisabled,
  incompatibleMeasurement,
  incompatibleTimeSemantics,
  incompatibleEntryKind,
  incompatibleAggregation,
  insufficientObservations,
  insufficientFocusObservations,
  insufficientReferenceObservations,
  insufficientIndependentUnits,
  insufficientSpan,
  insufficientOverlap,
  insufficientVariance,
  opportunityUnknown,
  effectTooSmall,
  analysisFailed,
}

sealed class FindingEvaluation {
  final String ruleId;
  final String subjectId;
  final FindingEvidence evidence;

  const FindingEvaluation({
    required this.ruleId,
    required this.subjectId,
    required this.evidence,
  });
}

final class AcceptedFindingEvaluation extends FindingEvaluation {
  final Finding finding;

  AcceptedFindingEvaluation({required this.finding, String? subjectId})
    : super(
        ruleId: finding.ruleId,
        subjectId: subjectId ?? finding.findingId,
        evidence: finding.evidence,
      );
}

final class RejectedFindingEvaluation extends FindingEvaluation {
  final FindingRejectionCode code;
  final String? detail;

  const RejectedFindingEvaluation({
    required super.ruleId,
    required super.subjectId,
    required super.evidence,
    required this.code,
    this.detail,
  });
}

abstract interface class FindingRule {
  String get id;

  Iterable<FindingEvaluation> evaluate(InsightBlockContext context);
}

class FindingEngineResult {
  final List<AcceptedFindingEvaluation> accepted;
  final List<RejectedFindingEvaluation> rejected;

  FindingEngineResult({
    required Iterable<AcceptedFindingEvaluation> accepted,
    required Iterable<RejectedFindingEvaluation> rejected,
  }) : accepted = List.unmodifiable(accepted),
       rejected = List.unmodifiable(rejected);

  List<Finding> get findings =>
      List.unmodifiable(accepted.map((evaluation) => evaluation.finding));
}

class FindingEngine {
  final List<FindingRule> rules;

  FindingEngine({required Iterable<FindingRule> rules})
    : rules = List.unmodifiable(rules);

  FindingEngineResult evaluate(
    InsightDataset dataset, {
    InsightBlockContext? blockContext,
  }) {
    if (blockContext != null && !identical(blockContext.dataset, dataset)) {
      throw ArgumentError.value(
        blockContext,
        'blockContext',
        'must belong to the evaluated dataset',
      );
    }
    final context = blockContext ?? InsightBlockContext(dataset: dataset);
    final accepted = <AcceptedFindingEvaluation>[];
    final rejected = <RejectedFindingEvaluation>[];
    final findingIds = <String>{};

    for (final rule in rules) {
      try {
        final evaluations = rule.evaluate(context).toList(growable: false);
        final ruleAccepted = <AcceptedFindingEvaluation>[];
        final ruleRejected = <RejectedFindingEvaluation>[];
        final ruleFindingIds = <String>{};
        for (final evaluation in evaluations) {
          if (evaluation.ruleId != rule.id) {
            throw StateError(
              'Rule ${rule.id} returned an evaluation for '
              '${evaluation.ruleId}.',
            );
          }
          switch (evaluation) {
            case AcceptedFindingEvaluation():
              if (findingIds.contains(evaluation.finding.findingId) ||
                  !ruleFindingIds.add(evaluation.finding.findingId)) {
                throw StateError(
                  'Duplicate finding ID ${evaluation.finding.findingId}.',
                );
              }
              ruleAccepted.add(evaluation);
            case RejectedFindingEvaluation():
              ruleRejected.add(evaluation);
          }
        }
        findingIds.addAll(ruleFindingIds);
        accepted.addAll(ruleAccepted);
        rejected.addAll(ruleRejected);
      } on Object catch (error) {
        rejected.add(
          RejectedFindingEvaluation(
            ruleId: rule.id,
            subjectId: rule.id,
            evidence: const FindingEvidence(
              observations: 0,
              independentUnits: 0,
              unit: EvidenceUnit.entry,
              spanDays: 0,
            ),
            code: FindingRejectionCode.analysisFailed,
            detail: '$error',
          ),
        );
      }
    }

    return FindingEngineResult(accepted: accepted, rejected: rejected);
  }
}
