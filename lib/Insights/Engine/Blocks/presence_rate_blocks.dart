import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Insights/Engine/prepared_feature.dart';

class PresenceRate {
  final int positives;
  final int opportunities;
  final int coverageCandidates;
  final DateTime? firstOpportunityAt;
  final DateTime? lastOpportunityAt;

  const PresenceRate({
    required this.positives,
    required this.opportunities,
    int? coverageCandidates,
    this.firstOpportunityAt,
    this.lastOpportunityAt,
  }) : coverageCandidates = coverageCandidates ?? opportunities,
       assert(positives >= 0),
       assert(opportunities >= positives),
       assert((coverageCandidates ?? opportunities) >= opportunities);

  const PresenceRate.empty()
    : positives = 0,
      opportunities = 0,
      coverageCandidates = 0,
      firstOpportunityAt = null,
      lastOpportunityAt = null;

  double? get rate => opportunities == 0 ? null : positives / opportunities;

  int get spanDays {
    final first = firstOpportunityAt;
    final last = lastOpportunityAt;
    if (first == null || last == null) return 0;
    return _spanDays([first, last]);
  }
}

class PresenceRateComparison {
  final PresenceRate focus;
  final PresenceRate reference;

  const PresenceRateComparison({required this.focus, required this.reference});

  double? get absoluteDifference {
    final focusRate = focus.rate;
    final referenceRate = reference.rate;
    if (focusRate == null || referenceRate == null) return null;
    return focusRate - referenceRate;
  }

  double? get relativeRisk {
    final focusRate = focus.rate;
    final referenceRate = reference.rate;
    if (focusRate == null || referenceRate == null || referenceRate == 0) {
      return null;
    }
    return focusRate / referenceRate;
  }
}

/// Prepares positive/negative rates only from authoritative completion data.
final class PresenceRateBlock implements InsightBlock<PresenceRate> {
  final String questionId;
  final String categoryId;
  final InsightDatasetScope scope;
  final bool eligibleForGenericAnalysis;

  const PresenceRateBlock({
    required this.questionId,
    required this.categoryId,
    required this.scope,
    this.eligibleForGenericAnalysis = true,
  });

  @override
  InsightBlockKey<PresenceRate> get key => InsightBlockKey(
    PresenceRateBlock,
    'presence-rate',
    [questionId, categoryId, scope, eligibleForGenericAnalysis],
  );

  @override
  PreparedFeature<PresenceRate> compute(InsightBlockContext context) {
    final entries = context.dataset.entriesForCategory(
      categoryId,
      scope: scope,
    );
    final semantics = context.dataset.catalog.resolve(
      questionId: questionId,
      categoryId: categoryId,
    );
    if (semantics == null) {
      return _unavailable(entries, FeatureExclusionCode.metadataMissing);
    }
    if (!semantics.enabled) {
      return _unavailable(entries, FeatureExclusionCode.metadataDisabled);
    }
    if (eligibleForGenericAnalysis && !semantics.eligibleForGenericPatterns) {
      return _unavailable(entries, FeatureExclusionCode.genericPatternExcluded);
    }
    if (semantics.question.measurement != InsightMeasurement.binary) {
      return _unavailable(
        entries,
        FeatureExclusionCode.incompatibleMeasurement,
      );
    }
    if (semantics.question.aggregation != InsightAggregation.any) {
      return _unavailable(
        entries,
        FeatureExclusionCode.incompatibleAggregation,
      );
    }
    if (semantics.question.absenceSemantics !=
        InsightAbsenceSemantics.unselectedMeansFalse) {
      return _unavailable(
        entries,
        FeatureExclusionCode.absenceNotInterpretable,
      );
    }
    if ((semantics.timeSemantics ?? InsightTimeSemantics.occurredAt) !=
        InsightTimeSemantics.occurredAt) {
      return _unavailable(
        entries,
        FeatureExclusionCode.incompatibleTimeSemantics,
      );
    }

    var positives = 0;
    var coverageDenominator = 0;
    final opportunities = <InsightEntry>[];
    final exclusions = <FeatureExclusion>[];
    for (final entry in entries) {
      if (entry.kind == InsightEntryKind.baseline ||
          entry.kind == InsightEntryKind.scheduledReview ||
          entry.kind == InsightEntryKind.landmark) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleEntryKind,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      if (entry.timePrecision == InsightTimePrecision.week ||
          (entry.timePrecision == InsightTimePrecision.unknown &&
              entry.kind != InsightEntryKind.legacy)) {
        coverageDenominator++;
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleTimePrecision,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      final completion = entry.completion;
      if (completion == null) {
        coverageDenominator++;
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.opportunityUnknown,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      if (!completion.applicableQuestionIds.contains(questionId)) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.notApplicable,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      coverageDenominator++;

      final targetObservations = entry.observations
          .where((observation) => observation.questionId == questionId)
          .toList();
      if (targetObservations.any(
        (observation) => observation.value is! PresenceInsightValue,
      )) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleValue,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      final presenceValues = targetObservations
          .map((observation) => observation.value as PresenceInsightValue)
          .map((value) => value.present)
          .toSet();
      if (completion.answeredQuestionIds.contains(questionId) &&
          presenceValues.isEmpty) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleValue,
            count: 1,
            unit: EvidenceUnit.entry,
          ),
        );
        continue;
      }
      if (!completion.answeredQuestionIds.contains(questionId) &&
          targetObservations.any(
            (observation) =>
                (observation.value as PresenceInsightValue).present ||
                observation.provenance !=
                    InsightObservationProvenance.inferredUnselectedCheck,
          )) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleValue,
            count: 1,
            unit: EvidenceUnit.entry,
            detail: 'Presence value conflicts with completion snapshot.',
          ),
        );
        continue;
      }
      if (presenceValues.length > 1) {
        exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.incompatibleValue,
            count: 1,
            unit: EvidenceUnit.entry,
            detail: 'Conflicting presence values in one entry.',
          ),
        );
        continue;
      }

      opportunities.add(entry);
      if (presenceValues.singleOrNull ?? false) positives++;
    }

    if (opportunities.isEmpty) {
      exclusions.add(
        const FeatureExclusion(
          code: FeatureExclusionCode.noEligibleOpportunities,
          count: 1,
          unit: EvidenceUnit.entry,
        ),
      );
    }
    return PreparedFeature(
      value: PresenceRate(
        positives: positives,
        opportunities: opportunities.length,
        coverageCandidates: coverageDenominator,
        firstOpportunityAt: opportunities.isEmpty
            ? null
            : opportunities.first.occurredAt,
        lastOpportunityAt: opportunities.isEmpty
            ? null
            : opportunities.last.occurredAt,
      ),
      evidence: FindingEvidence(
        observations: opportunities.length,
        independentUnits: opportunities.length,
        unit: EvidenceUnit.entry,
        spanDays: _spanDays(opportunities.map((entry) => entry.occurredAt)),
        coverage: coverageDenominator == 0
            ? null
            : opportunities.length / coverageDenominator,
        coverageUnit: EvidenceUnit.entry,
      ),
      sourceEntryIds: entries.map((entry) => entry.entryId),
      contributingEntryIds: opportunities.map((entry) => entry.entryId),
      exclusions: combineFeatureExclusions([exclusions]),
    );
  }

  PreparedFeature<PresenceRate> _unavailable(
    List<InsightEntry> entries,
    FeatureExclusionCode code,
  ) => PreparedFeature(
    value: const PresenceRate.empty(),
    evidence: const FindingEvidence(
      observations: 0,
      independentUnits: 0,
      unit: EvidenceUnit.entry,
      spanDays: 0,
    ),
    sourceEntryIds: entries.map((entry) => entry.entryId),
    exclusions: [
      FeatureExclusion(
        code: code,
        count: entries.isEmpty ? 1 : entries.length,
        unit: entries.isEmpty ? null : EvidenceUnit.entry,
      ),
    ],
  );
}

final class PresenceRateComparisonBlock
    implements InsightBlock<PresenceRateComparison> {
  final String questionId;
  final String categoryId;
  final bool eligibleForGenericAnalysis;

  const PresenceRateComparisonBlock({
    required this.questionId,
    required this.categoryId,
    this.eligibleForGenericAnalysis = true,
  });

  PresenceRateBlock get focusBlock => PresenceRateBlock(
    questionId: questionId,
    categoryId: categoryId,
    scope: InsightDatasetScope.focus,
    eligibleForGenericAnalysis: eligibleForGenericAnalysis,
  );

  PresenceRateBlock get referenceBlock => PresenceRateBlock(
    questionId: questionId,
    categoryId: categoryId,
    scope: InsightDatasetScope.reference,
    eligibleForGenericAnalysis: eligibleForGenericAnalysis,
  );

  @override
  InsightBlockKey<PresenceRateComparison> get key => InsightBlockKey(
    PresenceRateComparisonBlock,
    'presence-rate-comparison',
    [questionId, categoryId, eligibleForGenericAnalysis],
  );

  @override
  PreparedFeature<PresenceRateComparison> compute(InsightBlockContext context) {
    final referenceWindow = context.dataset.referenceWindow;
    if (referenceWindow == null) {
      return _unavailableComparison(
        FeatureExclusionCode.referenceWindowMissing,
      );
    }
    if (referenceWindow.endExclusive.isAfter(
      context.dataset.focusWindow.start,
    )) {
      return _unavailableComparison(FeatureExclusionCode.invalidWindow);
    }

    final focusRequest = focusBlock;
    final referenceRequest = referenceBlock;
    final focus = context.use(focusRequest);
    final reference = context.use(referenceRequest);
    final value = PresenceRateComparison(
      focus: focus.value,
      reference: reference.value,
    );
    final totalUnits =
        focus.evidence.independentUnits + reference.evidence.independentUnits;
    final coverageCandidates =
        value.focus.coverageCandidates + value.reference.coverageCandidates;
    final coverage = coverageCandidates == 0
        ? null
        : totalUnits / coverageCandidates;

    return PreparedFeature(
      value: value,
      evidence: FindingEvidence(
        observations:
            focus.evidence.observations + reference.evidence.observations,
        independentUnits: totalUnits,
        unit: EvidenceUnit.entry,
        spanDays: _combinedSpanDays(value),
        coverage: coverage,
        coverageUnit: EvidenceUnit.entry,
        effectSize: value.absoluteDifference,
      ),
      sourceEntryIds: {...focus.sourceEntryIds, ...reference.sourceEntryIds},
      contributingEntryIds: {
        ...focus.contributingEntryIds,
        ...reference.contributingEntryIds,
      },
      dependencyKeys: {
        focusRequest.key,
        referenceRequest.key,
        ...focus.dependencyKeys,
        ...reference.dependencyKeys,
      },
      exclusions: combineFeatureExclusions([
        focus.exclusions,
        reference.exclusions,
      ]),
    );
  }

  PreparedFeature<PresenceRateComparison> _unavailableComparison(
    FeatureExclusionCode code,
  ) => PreparedFeature(
    value: const PresenceRateComparison(
      focus: PresenceRate.empty(),
      reference: PresenceRate.empty(),
    ),
    evidence: const FindingEvidence(
      observations: 0,
      independentUnits: 0,
      unit: EvidenceUnit.entry,
      spanDays: 0,
    ),
    exclusions: [FeatureExclusion(code: code, count: 1)],
  );
}

int _combinedSpanDays(PresenceRateComparison comparison) {
  final dates = <DateTime>[
    if (comparison.reference.firstOpportunityAt case final DateTime value)
      value,
    if (comparison.reference.lastOpportunityAt case final DateTime value) value,
    if (comparison.focus.firstOpportunityAt case final DateTime value) value,
    if (comparison.focus.lastOpportunityAt case final DateTime value) value,
  ];
  return _spanDays(dates);
}

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
