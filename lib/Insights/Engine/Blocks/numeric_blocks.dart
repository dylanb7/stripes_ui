import 'dart:collection';

import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Insights/Engine/prepared_feature.dart';

final class NumericObservationsBlock
    implements InsightBlock<List<InsightNumericObservation>> {
  final String questionId;
  final InsightDatasetScope scope;
  final bool eligibleForGenericAnalysis;

  const NumericObservationsBlock({
    required this.questionId,
    this.scope = InsightDatasetScope.focus,
    this.eligibleForGenericAnalysis = false,
  });

  @override
  InsightBlockKey<List<InsightNumericObservation>> get key => InsightBlockKey(
    NumericObservationsBlock,
    'numeric-observations',
    [questionId, scope, eligibleForGenericAnalysis],
  );

  @override
  PreparedFeature<List<InsightNumericObservation>> compute(
    InsightBlockContext context,
  ) {
    final included = <InsightNumericObservation>[];
    final exclusions = <FeatureExclusion>[];
    final sourceEntryIds = <String>{};

    for (final observation in context.dataset.observationsFor(
      questionId,
      scope: scope,
    )) {
      sourceEntryIds.add(observation.entryId);
      final semantics =
          context.dataset.catalog.resolve(
            questionId: observation.questionId,
            categoryId: observation.categoryId,
          ) ??
          observation.semantics;
      if (eligibleForGenericAnalysis && semantics == null) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.metadataMissing,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
        continue;
      }
      if (eligibleForGenericAnalysis && !(semantics?.enabled ?? false)) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.metadataDisabled,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
        continue;
      }
      if (eligibleForGenericAnalysis &&
          !(semantics?.eligibleForGenericPatterns ?? false)) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.genericPatternExcluded,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
        continue;
      }
      if (eligibleForGenericAnalysis &&
          !(semantics?.question.supportsNumericAnalysis ?? false)) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleMeasurement,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
        continue;
      }
      if (eligibleForGenericAnalysis &&
          (semantics?.timeSemantics ?? InsightTimeSemantics.occurredAt) !=
              InsightTimeSemantics.occurredAt) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleTimeSemantics,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
        continue;
      }
      if (observation.value case NumericInsightValue(:final value)) {
        if (semantics?.question.isMissing(value) ?? false) {
          exclusions.add(
            const FeatureExclusion(
              code: FeatureExclusionCode.missingValue,
              count: 1,
              unit: EvidenceUnit.answerOccasion,
            ),
          );
          continue;
        }
        if (!value.isFinite ||
            !(semantics?.question.isInValidRange(value) ?? true)) {
          exclusions.add(
            const FeatureExclusion(
              code: FeatureExclusionCode.outOfRange,
              count: 1,
              unit: EvidenceUnit.answerOccasion,
            ),
          );
          continue;
        }
        included.add(
          InsightNumericObservation(observation: observation, value: value),
        );
      } else {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleValue,
            count: 1,
            unit: EvidenceUnit.answerOccasion,
          ),
        );
      }
    }

    for (final issue in context.dataset.issuesFor(questionId, scope: scope)) {
      sourceEntryIds.add(issue.entryId);
      exclusions.add(_exclusionForIssue(issue));
    }

    final combinedExclusions = combineFeatureExclusions([exclusions]);
    final contributingEntryIds = included
        .map((item) => item.observation.entryId)
        .toSet();
    return PreparedFeature(
      value: List.unmodifiable(included),
      evidence: FindingEvidence(
        observations: included.length,
        independentUnits: contributingEntryIds.length,
        unit: EvidenceUnit.entry,
        spanDays: _spanDays(
          included.map((item) => item.observation.occurredAt),
        ),
        coverage: sourceEntryIds.isEmpty
            ? null
            : contributingEntryIds.length / sourceEntryIds.length,
        coverageUnit: EvidenceUnit.entry,
      ),
      sourceEntryIds: sourceEntryIds,
      contributingEntryIds: contributingEntryIds,
      exclusions: combinedExclusions,
    );
  }
}

final class DailyNumericSeriesBlock
    implements InsightBlock<List<InsightDailyNumericValue>> {
  final String questionId;
  final InsightAggregation aggregation;
  final InsightDatasetScope scope;
  final bool eligibleForGenericAnalysis;

  const DailyNumericSeriesBlock({
    required this.questionId,
    required this.aggregation,
    this.scope = InsightDatasetScope.focus,
    this.eligibleForGenericAnalysis = false,
  });

  NumericObservationsBlock get observationsBlock => NumericObservationsBlock(
    questionId: questionId,
    scope: scope,
    eligibleForGenericAnalysis: eligibleForGenericAnalysis,
  );

  @override
  InsightBlockKey<List<InsightDailyNumericValue>> get key => InsightBlockKey(
    DailyNumericSeriesBlock,
    'daily-numeric-series',
    [questionId, aggregation, scope, eligibleForGenericAnalysis],
  );

  @override
  PreparedFeature<List<InsightDailyNumericValue>> compute(
    InsightBlockContext context,
  ) {
    final sourceBlock = observationsBlock;
    final source = context.use(sourceBlock);
    final grouped = SplayTreeMap<DateTime, List<InsightNumericObservation>>();
    for (final observation in source.value) {
      grouped
          .putIfAbsent(observation.observation.localDay, () => [])
          .add(observation);
    }
    final series = [
      for (final entry in grouped.entries)
        InsightDailyNumericValue(
          day: entry.key,
          value: InsightDataset.aggregateNumericObservations(
            entry.value,
            aggregation,
          ),
          observationCount: entry.value.length,
          sourceEntryIds: entry.value.map((item) => item.observation.entryId),
        ),
    ];

    return PreparedFeature(
      value: List.unmodifiable(series),
      evidence: FindingEvidence(
        observations: source.evidence.observations,
        independentUnits: series.length,
        unit: EvidenceUnit.day,
        spanDays: _spanDays(series.map((item) => item.day)),
        coverage: source.evidence.coverage,
        coverageUnit: source.evidence.coverageUnit,
      ),
      sourceEntryIds: source.sourceEntryIds,
      contributingEntryIds: source.contributingEntryIds,
      dependencyKeys: {sourceBlock.key, ...source.dependencyKeys},
      exclusions: source.exclusions,
    );
  }
}

final class PairedDailyNumericBlock
    implements InsightBlock<List<InsightDailyNumericPair>> {
  final String leftQuestionId;
  final String rightQuestionId;
  final InsightAggregation leftAggregation;
  final InsightAggregation rightAggregation;
  final InsightDatasetScope scope;
  final bool eligibleForGenericAnalysis;

  const PairedDailyNumericBlock({
    required this.leftQuestionId,
    required this.rightQuestionId,
    required this.leftAggregation,
    required this.rightAggregation,
    this.scope = InsightDatasetScope.focus,
    this.eligibleForGenericAnalysis = false,
  });

  DailyNumericSeriesBlock get leftBlock => DailyNumericSeriesBlock(
    questionId: leftQuestionId,
    aggregation: leftAggregation,
    scope: scope,
    eligibleForGenericAnalysis: eligibleForGenericAnalysis,
  );

  DailyNumericSeriesBlock get rightBlock => DailyNumericSeriesBlock(
    questionId: rightQuestionId,
    aggregation: rightAggregation,
    scope: scope,
    eligibleForGenericAnalysis: eligibleForGenericAnalysis,
  );

  @override
  InsightBlockKey<List<InsightDailyNumericPair>> get key =>
      InsightBlockKey(PairedDailyNumericBlock, 'paired-daily-numeric', [
        leftQuestionId,
        leftAggregation,
        rightQuestionId,
        rightAggregation,
        scope,
        eligibleForGenericAnalysis,
      ]);

  @override
  PreparedFeature<List<InsightDailyNumericPair>> compute(
    InsightBlockContext context,
  ) {
    final leftRequest = leftBlock;
    final rightRequest = rightBlock;
    final left = context.use(leftRequest);
    final right = context.use(rightRequest);
    final leftByDay = {for (final item in left.value) item.day: item};
    final rightByDay = {for (final item in right.value) item.day: item};
    final sharedDays = leftByDay.keys.where(rightByDay.containsKey).toList()
      ..sort();
    final pairs = [
      for (final day in sharedDays)
        InsightDailyNumericPair(
          day: day,
          left: leftByDay[day]!,
          right: rightByDay[day]!,
        ),
    ];
    final unionDays = {...leftByDay.keys, ...rightByDay.keys};
    final unpairedCount = unionDays.length - pairs.length;
    final contributingEntryIds = <String>{
      for (final pair in pairs) ...pair.left.sourceEntryIds,
      for (final pair in pairs) ...pair.right.sourceEntryIds,
    };
    final ownExclusions = [
      if (unpairedCount > 0)
        FeatureExclusion(
          code: FeatureExclusionCode.unpairedUnit,
          count: unpairedCount,
          unit: EvidenceUnit.day,
          detail: 'Calendar day present in only one series.',
        ),
    ];

    return PreparedFeature(
      value: List.unmodifiable(pairs),
      evidence: FindingEvidence(
        observations: pairs.fold(
          0,
          (total, pair) =>
              total + pair.left.observationCount + pair.right.observationCount,
        ),
        independentUnits: pairs.length,
        unit: EvidenceUnit.day,
        spanDays: _spanDays(pairs.map((pair) => pair.day)),
        overlap: pairs.length,
        coverage: unionDays.isEmpty ? null : pairs.length / unionDays.length,
        coverageUnit: EvidenceUnit.day,
      ),
      sourceEntryIds: {...left.sourceEntryIds, ...right.sourceEntryIds},
      contributingEntryIds: contributingEntryIds,
      dependencyKeys: {
        leftRequest.key,
        rightRequest.key,
        ...left.dependencyKeys,
        ...right.dependencyKeys,
      },
      exclusions: combineFeatureExclusions([
        left.exclusions,
        right.exclusions,
        ownExclusions,
      ]),
    );
  }
}

FeatureExclusion _exclusionForIssue(InsightDataIssue issue) => FeatureExclusion(
  code: switch (issue.code) {
    InsightDataIssueCode.missingValue => FeatureExclusionCode.missingValue,
    InsightDataIssueCode.outOfRange => FeatureExclusionCode.outOfRange,
    InsightDataIssueCode.invalidChoiceIndex =>
      FeatureExclusionCode.incompatibleValue,
    InsightDataIssueCode.unsupportedResponse =>
      FeatureExclusionCode.unsupported,
  },
  count: 1,
  unit: EvidenceUnit.answerOccasion,
);

int _spanDays(Iterable<DateTime> values) {
  final dates = values.toList()..sort();
  if (dates.isEmpty) return 0;
  final first = dates.first;
  final last = dates.last;
  return DateTime.utc(
        last.year,
        last.month,
        last.day,
      ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
      1;
}
