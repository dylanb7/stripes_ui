/// The strength of claim a [Finding] is allowed to make.
enum FindingKind { aggregate, observation, anomaly, inferential }

/// The independent unit behind an evidence count.
enum EvidenceUnit { entry, day, week, event, eventPair, answerOccasion }

class EstimateInterval {
  final double lower;
  final double upper;
  final double level;

  const EstimateInterval({
    required this.lower,
    required this.upper,
    this.level = 0.95,
  }) : assert(lower <= upper),
       assert(level > 0 && level < 1);

  bool get excludesZero => lower > 0 || upper < 0;
}

/// Evidence shared by summaries, patterns, anomalies, and relationships.
class FindingEvidence {
  final int observations;
  final int independentUnits;
  final EvidenceUnit unit;
  final int spanDays;
  final int? overlap;
  final double? coverage;
  final EvidenceUnit? coverageUnit;
  final double? effectSize;
  final EstimateInterval? interval;
  final double? stability;

  const FindingEvidence({
    required this.observations,
    required this.independentUnits,
    required this.unit,
    required this.spanDays,
    this.overlap,
    this.coverage,
    this.coverageUnit,
    this.effectSize,
    this.interval,
    this.stability,
  }) : assert(observations >= 0),
       assert(independentUnits >= 0),
       assert(spanDays >= 0),
       assert(overlap == null || overlap >= 0),
       assert(coverage == null || (coverage >= 0 && coverage <= 1)),
       assert(stability == null || (stability >= 0 && stability <= 1));

  FindingEvidence copyWith({
    int? observations,
    int? independentUnits,
    EvidenceUnit? unit,
    int? spanDays,
    int? overlap,
    double? coverage,
    EvidenceUnit? coverageUnit,
    double? effectSize,
    EstimateInterval? interval,
    double? stability,
  }) => FindingEvidence(
    observations: observations ?? this.observations,
    independentUnits: independentUnits ?? this.independentUnits,
    unit: unit ?? this.unit,
    spanDays: spanDays ?? this.spanDays,
    overlap: overlap ?? this.overlap,
    coverage: coverage ?? this.coverage,
    coverageUnit: coverageUnit ?? this.coverageUnit,
    effectSize: effectSize ?? this.effectSize,
    interval: interval ?? this.interval,
    stability: stability ?? this.stability,
  );
}

enum FeatureExclusionCode {
  metadataMissing,
  metadataDisabled,
  genericPatternExcluded,
  incompatibleMeasurement,
  incompatibleAggregation,
  incompatibleTimeSemantics,
  incompatibleTimePrecision,
  incompatibleEntryKind,
  missingValue,
  outOfRange,
  incompatibleValue,
  opportunityUnknown,
  absenceNotInterpretable,
  notApplicable,
  noEligibleOpportunities,
  referenceWindowMissing,
  invalidWindow,
  unpairedUnit,
  unsupported,
}

class FeatureExclusion {
  final FeatureExclusionCode code;
  final int count;
  final EvidenceUnit? unit;
  final String? detail;

  const FeatureExclusion({
    required this.code,
    required this.count,
    this.unit,
    this.detail,
  }) : assert(count >= 0);
}

/// Engine result independent of localization and visualization.
sealed class Finding {
  final String findingId;
  final String ruleId;
  final FindingEvidence evidence;

  /// Every entry considered while producing the finding, including exclusions.
  final Set<String> sourceEntryIds;

  /// Entries that contributed to the finding's reported value or denominator.
  final Set<String> contributingEntryIds;
  final List<FeatureExclusion> exclusions;

  Finding({
    required this.findingId,
    required this.ruleId,
    required this.evidence,
    Iterable<String> sourceEntryIds = const [],
    Iterable<String> contributingEntryIds = const [],
    Iterable<FeatureExclusion> exclusions = const [],
  }) : sourceEntryIds = Set.unmodifiable(sourceEntryIds),
       contributingEntryIds = Set.unmodifiable(contributingEntryIds),
       exclusions = List.unmodifiable(exclusions);

  FindingKind get kind;
}

abstract base class AggregateFinding extends Finding {
  AggregateFinding({
    required super.findingId,
    required super.ruleId,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  });

  @override
  FindingKind get kind => FindingKind.aggregate;
}

abstract base class ObservationFinding extends Finding {
  ObservationFinding({
    required super.findingId,
    required super.ruleId,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  });

  @override
  FindingKind get kind => FindingKind.observation;
}

abstract base class AnomalyFinding extends Finding {
  AnomalyFinding({
    required super.findingId,
    required super.ruleId,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  });

  @override
  FindingKind get kind => FindingKind.anomaly;
}

abstract base class InferentialFinding extends Finding {
  InferentialFinding({
    required super.findingId,
    required super.ruleId,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  });

  @override
  FindingKind get kind => FindingKind.inferential;
}

/// Builds delimiter-safe, versioned IDs from semantic—not presentation—fields.
abstract final class FindingIdentity {
  static String build({
    required String ruleId,
    int version = 1,
    required Iterable<Object?> components,
  }) {
    final fields = ['v$version', ruleId, ...components.map((item) => '$item')];
    return fields.map((field) => '${field.length}:$field').join('|');
  }
}
