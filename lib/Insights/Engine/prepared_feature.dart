import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_block_key.dart';

/// A reusable computed value together with its evidence and data lineage.
class PreparedFeature<T> {
  final T value;
  final FindingEvidence evidence;

  /// Every persisted entry considered while preparing this value, including
  /// entries later represented by an exclusion.
  final Set<String> sourceEntryIds;

  /// Entries that contributed to [value], including denominator entries.
  final Set<String> contributingEntryIds;
  final Set<InsightBlockKeyBase> dependencyKeys;
  final List<FeatureExclusion> exclusions;

  PreparedFeature({
    required this.value,
    required this.evidence,
    Iterable<String> sourceEntryIds = const [],
    Iterable<String> contributingEntryIds = const [],
    Iterable<InsightBlockKeyBase> dependencyKeys = const [],
    Iterable<FeatureExclusion> exclusions = const [],
  }) : sourceEntryIds = Set.unmodifiable(sourceEntryIds),
       contributingEntryIds = Set.unmodifiable(contributingEntryIds),
       dependencyKeys = Set.unmodifiable(dependencyKeys),
       exclusions = List.unmodifiable(exclusions);

  /// A raw total is meaningful only when all exclusions use the same unit.
  int? get excludedCount {
    if (exclusions.isEmpty) return 0;
    if (exclusions.map((item) => item.unit).toSet().length > 1) return null;
    return exclusions.fold<int>(
      0,
      (total, exclusion) => total + exclusion.count,
    );
  }

  Map<EvidenceUnit?, int> get excludedCountsByUnit {
    final result = <EvidenceUnit?, int>{};
    for (final exclusion in exclusions) {
      result[exclusion.unit] = (result[exclusion.unit] ?? 0) + exclusion.count;
    }
    return Map.unmodifiable(result);
  }

  /// Changes only the representation of [value]. Use a new block when a
  /// transform changes evidence, exclusions, or which entries contributed.
  PreparedFeature<R> map<R>(R Function(T value) transform) =>
      PreparedFeature<R>(
        value: transform(value),
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: contributingEntryIds,
        dependencyKeys: dependencyKeys,
        exclusions: exclusions,
      );
}

List<FeatureExclusion> combineFeatureExclusions(
  Iterable<Iterable<FeatureExclusion>> groups,
) {
  final totals =
      <
        ({FeatureExclusionCode code, EvidenceUnit? unit, String? detail}),
        int
      >{};
  for (final group in groups) {
    for (final exclusion in group) {
      final key = (
        code: exclusion.code,
        unit: exclusion.unit,
        detail: exclusion.detail,
      );
      totals[key] = (totals[key] ?? 0) + exclusion.count;
    }
  }

  final result = [
    for (final entry in totals.entries)
      FeatureExclusion(
        code: entry.key.code,
        count: entry.value,
        unit: entry.key.unit,
        detail: entry.key.detail,
      ),
  ];
  result.sort((left, right) {
    final codeComparison = left.code.index.compareTo(right.code.index);
    if (codeComparison != 0) return codeComparison;
    final unitComparison = (left.unit?.index ?? -1).compareTo(
      right.unit?.index ?? -1,
    );
    if (unitComparison != 0) return unitComparison;
    return (left.detail ?? '').compareTo(right.detail ?? '');
  });
  return List.unmodifiable(result);
}
