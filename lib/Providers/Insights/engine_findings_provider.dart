import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Insights/insights.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

/// The focus and optional personal-reference windows for one engine run.
///
/// Both windows use the engine's `[start, endExclusive)` convention.
@immutable
class FindingWindows {
  final InsightTimeWindow focus;
  final InsightTimeWindow? reference;

  const FindingWindows({required this.focus, this.reference});

  DateTime get earliestRequired => reference?.start ?? focus.start;
}

/// Controls how the period immediately before a focus window is selected.
@immutable
class FindingReferencePolicy {
  final int minimumDays;
  final int focusWindowMultiplier;
  final int maximumDays;

  const FindingReferencePolicy({
    this.minimumDays = 30,
    this.focusWindowMultiplier = 3,
    this.maximumDays = 180,
  }) : assert(minimumDays > 0),
       assert(focusWindowMultiplier > 0),
       assert(maximumDays >= minimumDays);

  int daysFor(InsightTimeWindow focus) =>
      (focus.calendarDays * focusWindowMultiplier)
          .clamp(minimumDays, maximumDays)
          .toInt();
}

/// Converts an already end-exclusive history range to engine windows.
///
/// History's day/week/month/custom ranges normally already end at the first
/// instant outside the selected period. Set [inclusiveEnd] for all-time ranges,
/// whose final date is inclusive. A zero-width range is treated as one day for
/// defensive compatibility with older callers.
FindingWindows findingWindowsForHistoryRange(
  DateTimeRange range, {
  FindingReferencePolicy referencePolicy = const FindingReferencePolicy(),
  bool includeReference = true,
  bool inclusiveEnd = false,
}) {
  final endExclusive = inclusiveEnd
      ? _nextCalendarDay(range.end)
      : range.start.isBefore(range.end)
      ? range.end
      : _nextCalendarDay(range.start);
  return _findingWindows(
    start: range.start,
    endExclusive: endExclusive,
    referencePolicy: referencePolicy,
    includeReference: includeReference,
  );
}

/// Converts the dashboard's inclusive date range to engine windows.
FindingWindows findingWindowsForDashboardRange(
  DateTimeRange range, {
  FindingReferencePolicy referencePolicy = const FindingReferencePolicy(),
  bool includeReference = true,
}) => _findingWindows(
  start: _calendarDay(range.start),
  endExclusive: _nextCalendarDay(range.end),
  referencePolicy: referencePolicy,
  includeReference: includeReference,
);

FindingWindows _findingWindows({
  required DateTime start,
  required DateTime endExclusive,
  required FindingReferencePolicy referencePolicy,
  required bool includeReference,
}) {
  final focus = InsightTimeWindow(start: start, endExclusive: endExclusive);
  if (!includeReference) return FindingWindows(focus: focus);

  final referenceDays = referencePolicy.daysFor(focus);
  return FindingWindows(
    focus: focus,
    reference: InsightTimeWindow(
      start: _addCalendarDays(focus.start, -referenceDays),
      endExclusive: focus.start,
    ),
  );
}

DateTime _calendarDay(DateTime value) => value.isUtc
    ? DateTime.utc(value.year, value.month, value.day)
    : DateTime(value.year, value.month, value.day);

DateTime _nextCalendarDay(DateTime value) =>
    _addCalendarDays(_calendarDay(value), 1);

DateTime _addCalendarDays(DateTime value, int days) => value.isUtc
    ? DateTime.utc(
        value.year,
        value.month,
        value.day + days,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      )
    : DateTime(
        value.year,
        value.month,
        value.day + days,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );

/// One complete, inspectable execution of the finding engine.
@immutable
class FindingRun {
  final InsightDataset dataset;
  final FindingEngineResult result;

  const FindingRun({required this.dataset, required this.result});

  List<AcceptedFindingEvaluation> get accepted => result.accepted;
  List<RejectedFindingEvaluation> get rejected => result.rejected;
}

/// An accepted finding together with its deterministic presentation rank.
@immutable
class RankedFinding {
  final AcceptedFindingEvaluation evaluation;
  final double score;

  const RankedFinding({required this.evaluation, required this.score});

  Finding get finding => evaluation.finding;
}

/// A compact user-facing state derived from a complete engine run.
enum FindingFeedState {
  ready,
  noData,
  stillLearning,
  noNotablePattern,
  unavailable,
}

/// UI-facing filtering and result-limit policy.
@immutable
class FindingFeedPolicy {
  final int? maximumFindings;
  final int? maximumAggregateFindings;
  final int? maximumPatternFindings;
  final int? maximumFindingsPerRule;
  final int minimumIndependentUnits;
  final double? minimumCoverage;
  final Set<FindingKind> allowedKinds;

  FindingFeedPolicy({
    this.maximumFindings,
    this.maximumAggregateFindings,
    this.maximumPatternFindings,
    this.maximumFindingsPerRule,
    this.minimumIndependentUnits = 1,
    this.minimumCoverage,
    Set<FindingKind> allowedKinds = const {
      FindingKind.aggregate,
      FindingKind.observation,
      FindingKind.anomaly,
      FindingKind.inferential,
    },
  }) : assert(maximumFindings == null || maximumFindings >= 0),
       assert(
         maximumAggregateFindings == null || maximumAggregateFindings >= 0,
       ),
       assert(maximumPatternFindings == null || maximumPatternFindings >= 0),
       assert(maximumFindingsPerRule == null || maximumFindingsPerRule >= 0),
       assert(minimumIndependentUnits >= 0),
       assert(
         minimumCoverage == null ||
             (minimumCoverage >= 0 && minimumCoverage <= 1),
       ),
       allowedKinds = Set.unmodifiable(allowedKinds);

  bool includes(Finding finding) {
    if (!allowedKinds.contains(finding.kind)) return false;
    if (finding.evidence.independentUnits < minimumIndependentUnits) {
      return false;
    }
    final threshold = minimumCoverage;
    final coverage = finding.evidence.coverage;
    if (threshold != null && (coverage == null || coverage < threshold)) {
      return false;
    }
    return true;
  }
}

/// Ranked accepted findings plus all rejection diagnostics from the same run.
@immutable
class FindingFeed {
  final FindingRun run;
  final List<RankedFinding> ranked;

  FindingFeed({required this.run, required Iterable<RankedFinding> ranked})
    : ranked = List.unmodifiable(ranked);

  List<Finding> get findings =>
      List.unmodifiable(ranked.map((item) => item.finding));

  FindingFeedState get state {
    if (ranked.isNotEmpty) return FindingFeedState.ready;
    if (run.accepted.isNotEmpty) return FindingFeedState.ready;
    if (run.dataset.entries().isEmpty) return FindingFeedState.noData;

    final rejections = run.rejected;
    const unavailableCodes = {
      FindingRejectionCode.metadataMissing,
      FindingRejectionCode.metadataDisabled,
      FindingRejectionCode.incompatibleMeasurement,
      FindingRejectionCode.incompatibleTimeSemantics,
      FindingRejectionCode.incompatibleEntryKind,
      FindingRejectionCode.incompatibleAggregation,
      FindingRejectionCode.opportunityUnknown,
      FindingRejectionCode.analysisFailed,
    };
    if (rejections.isNotEmpty &&
        rejections.every(
          (rejection) => unavailableCodes.contains(rejection.code),
        )) {
      return FindingFeedState.unavailable;
    }

    const learningCodes = {
      FindingRejectionCode.insufficientObservations,
      FindingRejectionCode.insufficientFocusObservations,
      FindingRejectionCode.insufficientReferenceObservations,
      FindingRejectionCode.insufficientIndependentUnits,
      FindingRejectionCode.insufficientSpan,
      FindingRejectionCode.insufficientOverlap,
    };
    if (rejections.any((rejection) => learningCodes.contains(rejection.code))) {
      return FindingFeedState.stillLearning;
    }

    if (rejections.any(
      (rejection) =>
          rejection.code == FindingRejectionCode.effectTooSmall ||
          rejection.code == FindingRejectionCode.insufficientVariance,
    )) {
      return FindingFeedState.noNotablePattern;
    }
    return FindingFeedState.stillLearning;
  }
}

/// Builds an engine dataset from the complete response collection.
///
/// Do not pre-trim [responses] to the focus range: blocks may also need the
/// reference period, and the dataset applies both scopes itself.
FindingRun runFindingsFromResponses({
  required Iterable<Response> responses,
  required FindingWindows windows,
  required InsightAnalysisCatalog catalog,
  required Iterable<FindingRule> rules,
}) {
  final dataset = InsightDataset.fromResponses(
    responses,
    focusWindow: windows.focus,
    referenceWindow: windows.reference,
    catalog: catalog,
    timingResolver: (response) => InsightResponseTiming(
      occurredAt: occurrenceTimeForResponse(response),
      precision: hasApproximateRecordTime(response)
          ? InsightTimePrecision.day
          : switch (entryForResponse(response)?.entityType) {
              'form' || 'baseline' => InsightTimePrecision.week,
              _ => InsightTimePrecision.exact,
            },
    ),
  );
  return FindingRun(
    dataset: dataset,
    result: FindingEngine(rules: rules).evaluate(dataset),
  );
}

FindingFeed buildFindingFeed(FindingRun run, {FindingFeedPolicy? policy}) {
  final effectivePolicy = policy ?? FindingFeedPolicy();
  final ranked = <RankedFinding>[
    for (final evaluation in run.accepted)
      if (effectivePolicy.includes(evaluation.finding))
        RankedFinding(
          evaluation: evaluation,
          score: findingPresentationScore(evaluation.finding),
        ),
  ]..sort(_compareRankedFindings);

  if (effectivePolicy.maximumFindings == 0) {
    return FindingFeed(run: run, ranked: const []);
  }
  final selected = <RankedFinding>[];
  var aggregateCount = 0;
  var patternCount = 0;
  final selectedByRule = <String, int>{};
  for (final item in ranked) {
    final isAggregate = item.finding.kind == FindingKind.aggregate;
    if (isAggregate &&
        aggregateCount >=
            (effectivePolicy.maximumAggregateFindings ?? ranked.length)) {
      continue;
    }
    if (!isAggregate &&
        patternCount >=
            (effectivePolicy.maximumPatternFindings ?? ranked.length)) {
      continue;
    }
    final perRuleMaximum = effectivePolicy.maximumFindingsPerRule;
    if (perRuleMaximum != null &&
        (selectedByRule[item.finding.ruleId] ?? 0) >= perRuleMaximum) {
      continue;
    }
    selected.add(item);
    selectedByRule[item.finding.ruleId] =
        (selectedByRule[item.finding.ruleId] ?? 0) + 1;
    if (isAggregate) {
      aggregateCount++;
    } else {
      patternCount++;
    }
    final maximum = effectivePolicy.maximumFindings;
    if (maximum != null && selected.length >= maximum) break;
  }
  return FindingFeed(run: run, ranked: selected);
}

/// A stable display rank. Rules remain responsible for acceptance thresholds;
/// this only orders already-accepted results for limited UI surfaces. Exact
/// aggregate rates are treated as display relevance, never as confidence.
double findingPresentationScore(Finding finding) {
  final evidence = finding.evidence;
  final kindBase = switch (finding.kind) {
    FindingKind.aggregate => 100.0,
    FindingKind.observation => 200.0,
    FindingKind.anomaly => 300.0,
    FindingKind.inferential => 400.0,
  };
  final displaySignal = switch (finding) {
    CategoryCoOccurrenceFinding() => finding.coOccurrenceRate,
    ChoiceDistributionFinding() => finding.leadingChoiceRate,
    CategoryDistributionFinding() => finding.leadingCategoryRate,
    PeakHourFinding() => finding.peakRate,
    MostCommonDayFinding() => finding.commonDayRate,
    RecordingConsistencyFinding() => finding.coverageRate,
    DailyVolumeFinding() => (finding.averagePerActiveDay / 5).clamp(0.0, 1.0),
    _ => evidence.effectSize?.abs() ?? 0,
  };
  // Aggregate percentages have different denominators and are not comparable
  // effect sizes. This small, explicit presentation priority favors distinct,
  // immediately legible summaries over a feed of category-pair permutations.
  final aggregatePresentationPriority = switch (finding) {
    PeakHourFinding() => 35.0,
    RecordingConsistencyFinding() => 32.0,
    MostCommonDayFinding() => 30.0,
    CategoryDistributionFinding() => 27.0,
    DailyVolumeFinding() => 25.0,
    ChoiceDistributionFinding() => 15.0,
    _ => 0.0,
  };
  final effect = displaySignal.clamp(0.0, 1.0).toDouble();
  final coverage = evidence.coverage ?? 0.5;
  final stability = evidence.stability ?? 0.0;
  final independentUnits = (evidence.independentUnits / 30)
      .clamp(0.0, 1.0)
      .toDouble();
  final span = (evidence.spanDays / 30).clamp(0.0, 1.0).toDouble();
  final intervalBonus = evidence.interval?.excludesZero ?? false ? 5.0 : 0.0;

  return kindBase +
      aggregatePresentationPriority +
      effect * 35 +
      stability * 20 +
      coverage * 15 +
      independentUnits * 15 +
      span * 10 +
      intervalBonus;
}

int _compareRankedFindings(RankedFinding left, RankedFinding right) {
  final scoreComparison = right.score.compareTo(left.score);
  if (scoreComparison != 0) return scoreComparison;
  return left.finding.findingId.compareTo(right.finding.findingId);
}

/// Analysis semantics are host-owned and deliberately empty by default.
/// Override this with a sparse, versioned catalog loaded alongside the host's
/// question set before injecting any metadata-driven rules.
final insightAnalysisCatalogProvider = Provider<InsightAnalysisCatalog>(
  (ref) => const InsightAnalysisCatalog.empty(),
);

/// Safe default rules. Observational rules are intentionally opt-in until
/// their production uncertainty and opportunity requirements are satisfied.
final insightFindingRulesProvider = Provider<List<FindingRule>>(
  (ref) => const [
    PeakHourRule(),
    RecordingConsistencyRule(),
    MostCommonDayRule(),
    CategoryDistributionRule(),
    DailyVolumeRule(),
    CategoryCoOccurrenceRule(),
    ChoiceDistributionRule(),
  ],
);

final findingReferencePolicyProvider = Provider<FindingReferencePolicy>(
  (ref) => const FindingReferencePolicy(),
);

final historyFindingFeedPolicyProvider = Provider<FindingFeedPolicy>(
  (ref) => FindingFeedPolicy(
    maximumFindings: 7,
    maximumPatternFindings: 2,
    maximumAggregateFindings: 7,
    maximumFindingsPerRule: 1,
  ),
);

final dashboardFindingFeedPolicyProvider = Provider<FindingFeedPolicy>(
  (ref) => FindingFeedPolicy(
    maximumFindings: 4,
    maximumPatternFindings: 2,
    maximumAggregateFindings: 4,
    maximumFindingsPerRule: 1,
  ),
);

/// Engine findings for the History screen. Existing legacy insight providers
/// remain available during migration.
final historyFindingsProvider = FutureProvider.autoDispose<FindingFeed>((
  ref,
) async {
  final settings = ref.watch(displayDataProvider);
  final windows = findingWindowsForHistoryRange(
    settings.range,
    referencePolicy: ref.watch(findingReferencePolicyProvider),
    includeReference: settings.cycle != TimeCycle.all,
    inclusiveEnd: settings.cycle == TimeCycle.all,
  );

  await _ensureEarliestLoaded(ref, windows.earliestRequired);
  final stamps = await ref.watch(stampsStreamProvider.future);
  final responses = _applyHistoryFilters(
    stamps.whereType<Response>(),
    settings.filters,
  );
  final run = runFindingsFromResponses(
    responses: responses,
    windows: windows,
    catalog: ref.watch(insightAnalysisCatalogProvider),
    rules: ref.watch(insightFindingRulesProvider),
  );
  return buildFindingFeed(
    run,
    policy: ref.watch(historyFindingFeedPolicyProvider),
  );
});

/// Engine findings for the selected Dashboard period.
final dashboardFindingsProvider = FutureProvider.autoDispose<FindingFeed>((
  ref,
) async {
  final state = ref.watch(dashboardStateProvider);
  final windows = findingWindowsForDashboardRange(
    state.range,
    referencePolicy: ref.watch(findingReferencePolicyProvider),
    includeReference: state.cycle != TimeCycle.all,
  );

  await _ensureEarliestLoaded(ref, windows.earliestRequired);
  final stamps = await ref.watch(stampsStreamProvider.future);
  final run = runFindingsFromResponses(
    responses: stamps.whereType<Response>(),
    windows: windows,
    catalog: ref.watch(insightAnalysisCatalogProvider),
    rules: ref.watch(insightFindingRulesProvider),
  );
  return buildFindingFeed(
    run,
    policy: ref.watch(dashboardFindingFeedPolicyProvider),
  );
});

Future<void> _ensureEarliestLoaded(Ref ref, DateTime earliest) async {
  final repo = await ref.watch(stampProvider.future);
  if (repo != null &&
      (repo.earliest == null || earliest.isBefore(repo.earliest!))) {
    repo.earliestDate = earliest;
  }
}

List<Response> _applyHistoryFilters(
  Iterable<Response> responses,
  List<LabeledFilter> filters,
) {
  if (filters.isEmpty) return List.unmodifiable(responses);

  final grouped = <String, List<LabeledFilter>>{};
  for (final filter in filters) {
    grouped.putIfAbsent(filter.filterType.name, () => []).add(filter);
  }
  return List.unmodifiable(
    responses.where(
      (response) => grouped.values.every(
        (group) => group.any((filter) => filter.filter(response)),
      ),
    ),
  );
}
