import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

/// Presentation threshold for an exact same-day category summary.
class CategoryCoOccurrencePolicy {
  final int minimumOverlapDays;

  const CategoryCoOccurrencePolicy({this.minimumOverlapDays = 3})
    : assert(minimumOverlapDays > 0);
}

/// An exact summary of days on which two categories were recorded.
///
/// This describes co-logging only. It does not imply that the categories or
/// the health events they represent are associated.
final class CategoryCoOccurrenceFinding extends AggregateFinding {
  final String leftCategoryId;
  final String rightCategoryId;
  final List<DateTime> leftDays;
  final List<DateTime> rightDays;
  final List<DateTime> sharedDays;
  final List<DateTime> eligibleDays;

  CategoryCoOccurrenceFinding({
    required super.findingId,
    required super.ruleId,
    required this.leftCategoryId,
    required this.rightCategoryId,
    required Iterable<DateTime> leftDays,
    required Iterable<DateTime> rightDays,
    required Iterable<DateTime> sharedDays,
    required Iterable<DateTime> eligibleDays,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : leftDays = List.unmodifiable(leftDays),
       rightDays = List.unmodifiable(rightDays),
       sharedDays = List.unmodifiable(sharedDays),
       eligibleDays = List.unmodifiable(eligibleDays);

  int get leftDayCount => leftDays.length;
  int get rightDayCount => rightDays.length;
  int get overlapDays => sharedDays.length;

  /// The fraction of days with either category that contain both categories.
  double get coOccurrenceRate =>
      eligibleDays.isEmpty ? 0 : overlapDays / eligibleDays.length;
}

/// Produces one exact co-logging summary for every category pair in focus.
class CategoryCoOccurrenceRule implements FindingRule {
  @override
  final String id;
  final CategoryCoOccurrencePolicy policy;

  const CategoryCoOccurrenceRule({
    this.id = 'category_co_occurrence',
    this.policy = const CategoryCoOccurrencePolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset.entries();
    final categoryIds =
        entries.map((entry) => entry.categoryId).toSet().toList()..sort();
    final entriesByCategory = <String, List<InsightEntry>>{};
    for (final entry in entries) {
      entriesByCategory.putIfAbsent(entry.categoryId, () => []).add(entry);
    }

    for (var leftIndex = 0; leftIndex < categoryIds.length - 1; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < categoryIds.length;
        rightIndex++
      ) {
        final leftId = categoryIds[leftIndex];
        final rightId = categoryIds[rightIndex];
        yield _evaluatePair(
          leftId,
          rightId,
          entriesByCategory[leftId]!,
          entriesByCategory[rightId]!,
        );
      }
    }
  }

  FindingEvaluation _evaluatePair(
    String leftId,
    String rightId,
    List<InsightEntry> leftEntries,
    List<InsightEntry> rightEntries,
  ) {
    final leftDays = leftEntries.map((entry) => entry.localDay).toSet();
    final rightDays = rightEntries.map((entry) => entry.localDay).toSet();
    final sharedDays = leftDays.intersection(rightDays).toList()..sort();
    final eligibleDays = leftDays.union(rightDays).toList()..sort();
    final sortedLeftDays = leftDays.toList()..sort();
    final sortedRightDays = rightDays.toList()..sort();
    final pairEntries = [...leftEntries, ...rightEntries];
    final sourceEntryIds = pairEntries.map((entry) => entry.entryId).toSet();
    final evidence = FindingEvidence(
      observations: pairEntries.length,
      independentUnits: eligibleDays.length,
      unit: EvidenceUnit.day,
      spanDays: _calendarSpan(eligibleDays),
      overlap: sharedDays.length,
    );
    final subjectId = '$leftId|$rightId';

    if (sharedDays.length < policy.minimumOverlapDays) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientOverlap,
        detail: 'Requires ${policy.minimumOverlapDays} shared days.',
      );
    }

    return AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: CategoryCoOccurrenceFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: [leftId, rightId, InsightDatasetScope.focus.name],
        ),
        ruleId: id,
        leftCategoryId: leftId,
        rightCategoryId: rightId,
        leftDays: sortedLeftDays,
        rightDays: sortedRightDays,
        sharedDays: sharedDays,
        eligibleDays: eligibleDays,
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: sourceEntryIds,
      ),
    );
  }
}

/// Presentation threshold for an exact per-question response distribution.
class ChoiceDistributionPolicy {
  final int minimumAnswerOccasions;

  const ChoiceDistributionPolicy({this.minimumAnswerOccasions = 5})
    : assert(minimumAnswerOccasions > 0);
}

/// An exact distribution of recorded choices for one question.
///
/// [choiceCounts] counts answer occasions on which each choice was selected.
/// A multi-select answer can therefore contribute to more than one choice,
/// while duplicate copies of a choice within one answer count only once.
final class ChoiceDistributionFinding extends AggregateFinding {
  final String questionId;
  final String promptKey;
  final List<String> categoryIds;
  final int answerOccasions;
  final int choiceSelections;
  final bool allowsMultiple;
  final Map<String, int> choiceCounts;

  ChoiceDistributionFinding({
    required super.findingId,
    required super.ruleId,
    required this.questionId,
    required this.promptKey,
    required Iterable<String> categoryIds,
    required this.answerOccasions,
    required this.choiceSelections,
    required this.allowsMultiple,
    required Map<String, int> choiceCounts,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : categoryIds = List.unmodifiable(categoryIds),
       choiceCounts = Map.unmodifiable(choiceCounts);

  String? get leadingChoice {
    String? leader;
    var leadingCount = -1;
    for (final entry in choiceCounts.entries) {
      if (entry.value > leadingCount ||
          (entry.value == leadingCount &&
              (leader == null || entry.key.compareTo(leader) < 0))) {
        leader = entry.key;
        leadingCount = entry.value;
      }
    }
    return leader;
  }

  int get leadingChoiceCount {
    final choice = leadingChoice;
    return choice == null ? 0 : choiceCounts[choice]!;
  }

  /// The fraction of answer occasions on which the leading choice appeared.
  double get leadingChoiceRate =>
      answerOccasions == 0 ? 0 : leadingChoiceCount / answerOccasions;
}

/// Produces one exact recorded-choice distribution per question in focus.
class ChoiceDistributionRule implements FindingRule {
  @override
  final String id;
  final ChoiceDistributionPolicy policy;

  const ChoiceDistributionRule({
    this.id = 'choice_distribution',
    this.policy = const ChoiceDistributionPolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final observationsByQuestion = <String, List<InsightObservation>>{};
    for (final observation in context.dataset.observations()) {
      if (observation.value is! ChoiceInsightValue) continue;
      observationsByQuestion
          .putIfAbsent(observation.questionId, () => [])
          .add(observation);
    }
    final questionIds = observationsByQuestion.keys.toList()..sort();

    for (final questionId in questionIds) {
      yield _evaluateQuestion(questionId, observationsByQuestion[questionId]!);
    }
  }

  FindingEvaluation _evaluateQuestion(
    String questionId,
    List<InsightObservation> observations,
  ) {
    final counts = <String, int>{};
    var allowsMultiple = false;
    for (final observation in observations) {
      final value = observation.value as ChoiceInsightValue;
      allowsMultiple = allowsMultiple || value.allowsMultiple;
      for (final choice in value.choices.toSet()) {
        counts[choice] = (counts[choice] ?? 0) + 1;
      }
    }
    final choiceKeys = counts.keys.toList()..sort();
    final sortedCounts = <String, int>{
      for (final choice in choiceKeys) choice: counts[choice]!,
    };
    final categoryIds =
        observations
            .map((observation) => observation.categoryId)
            .toSet()
            .toList()
          ..sort();
    final sourceEntryIds = observations
        .map((observation) => observation.entryId)
        .toSet();
    final days = observations
        .map((observation) => observation.localDay)
        .toSet();
    final choiceSelections = counts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final evidence = FindingEvidence(
      observations: observations.length,
      independentUnits: observations.length,
      unit: EvidenceUnit.answerOccasion,
      spanDays: _calendarSpan(days),
    );

    if (observations.length < policy.minimumAnswerOccasions) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: questionId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientObservations,
        detail: 'Requires ${policy.minimumAnswerOccasions} answer occasions.',
      );
    }
    if (sortedCounts.isEmpty) {
      return RejectedFindingEvaluation(
        ruleId: id,
        subjectId: questionId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientObservations,
        detail: 'Requires at least one recorded choice.',
      );
    }

    final latestObservation = observations.reduce((left, right) {
      final timeComparison = left.occurredAt.compareTo(right.occurredAt);
      if (timeComparison != 0) return timeComparison > 0 ? left : right;
      final entryComparison = left.entryId.compareTo(right.entryId);
      if (entryComparison != 0) return entryComparison > 0 ? left : right;
      return left.promptKey.compareTo(right.promptKey) >= 0 ? left : right;
    });
    return AcceptedFindingEvaluation(
      subjectId: questionId,
      finding: ChoiceDistributionFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: [questionId, InsightDatasetScope.focus.name],
        ),
        ruleId: id,
        questionId: questionId,
        promptKey: latestObservation.promptKey,
        categoryIds: categoryIds,
        answerOccasions: observations.length,
        choiceSelections: choiceSelections,
        allowsMultiple: allowsMultiple,
        choiceCounts: sortedCounts,
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: sourceEntryIds,
      ),
    );
  }
}

/// Presentation thresholds for an exact category-entry distribution.
class CategoryDistributionPolicy {
  final int minimumEntries;
  final int minimumCategories;

  const CategoryDistributionPolicy({
    this.minimumEntries = 5,
    this.minimumCategories = 2,
  }) : assert(minimumEntries > 0),
       assert(minimumCategories > 1);
}

/// An exact distribution of focus-period entries across categories.
final class CategoryDistributionFinding extends AggregateFinding {
  final int totalEntries;
  final Map<String, int> categoryCounts;

  CategoryDistributionFinding({
    required super.findingId,
    required super.ruleId,
    required this.totalEntries,
    required Map<String, int> categoryCounts,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : categoryCounts = Map.unmodifiable(categoryCounts);

  String get leadingCategoryId {
    var leader = categoryCounts.keys.first;
    for (final entry in categoryCounts.entries) {
      final leadingCount = categoryCounts[leader]!;
      if (entry.value > leadingCount ||
          (entry.value == leadingCount && entry.key.compareTo(leader) < 0)) {
        leader = entry.key;
      }
    }
    return leader;
  }

  int get leadingCategoryCount => categoryCounts[leadingCategoryId] ?? 0;
  double get leadingCategoryRate =>
      totalEntries == 0 ? 0 : leadingCategoryCount / totalEntries;
  bool get hasTiedLead =>
      categoryCounts.values
          .where((count) => count == leadingCategoryCount)
          .length >
      1;
}

/// Produces one exact category-entry distribution for the focus period.
class CategoryDistributionRule implements FindingRule {
  @override
  final String id;
  final CategoryDistributionPolicy policy;

  const CategoryDistributionRule({
    this.id = 'category_distribution',
    this.policy = const CategoryDistributionPolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset.entries();
    final counts = <String, int>{};
    for (final entry in entries) {
      counts[entry.categoryId] = (counts[entry.categoryId] ?? 0) + 1;
    }
    final sortedCounts = <String, int>{
      for (final categoryId in (counts.keys.toList()..sort()))
        categoryId: counts[categoryId]!,
    };
    final activeDays = entries.map((entry) => entry.localDay).toSet();
    final sourceEntryIds = entries.map((entry) => entry.entryId).toSet();
    final evidence = FindingEvidence(
      observations: entries.length,
      independentUnits: activeDays.length,
      unit: EvidenceUnit.day,
      spanDays: _calendarSpan(activeDays),
    );
    const subjectId = 'all_categories';

    if (entries.length < policy.minimumEntries) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientObservations,
        detail: 'Requires ${policy.minimumEntries} entries.',
      );
      return;
    }
    if (sortedCounts.length < policy.minimumCategories) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientVariance,
        detail: 'Requires ${policy.minimumCategories} recorded categories.',
      );
      return;
    }

    yield AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: CategoryDistributionFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: const [subjectId, 'focus'],
        ),
        ruleId: id,
        totalEntries: entries.length,
        categoryCounts: sortedCounts,
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: sourceEntryIds,
      ),
    );
  }
}

/// Presentation threshold for time-of-day and weekday logging summaries.
class LoggingRhythmPolicy {
  final int minimumEntries;
  final int minimumSpanDays;
  final int minimumFocusWindowDays;
  final double minimumPeakRate;

  const LoggingRhythmPolicy({
    this.minimumEntries = 10,
    this.minimumSpanDays = 3,
    this.minimumFocusWindowDays = 1,
    this.minimumPeakRate = 0.15,
  }) : assert(minimumEntries > 0),
       assert(minimumSpanDays > 0),
       assert(minimumFocusWindowDays > 0),
       assert(minimumPeakRate > 0 && minimumPeakRate <= 1);
}

/// An exact distribution of focus-period entries by local hour.
final class PeakHourFinding extends AggregateFinding {
  final int peakHour;
  final int totalEntries;
  final Map<int, int> hourCounts;
  final List<String> categoryIds;

  PeakHourFinding({
    required super.findingId,
    required super.ruleId,
    required this.peakHour,
    required this.totalEntries,
    required Map<int, int> hourCounts,
    required Iterable<String> categoryIds,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : hourCounts = Map.unmodifiable(hourCounts),
       categoryIds = List.unmodifiable(categoryIds);

  int get peakEntryCount => hourCounts[peakHour] ?? 0;
  double get peakRate => totalEntries == 0 ? 0 : peakEntryCount / totalEntries;
  bool get hasTiedPeak =>
      hourCounts.values.where((count) => count == peakEntryCount).length > 1;
}

/// Produces one exact distribution summary across local clock hours.
class PeakHourRule implements FindingRule {
  @override
  final String id;
  final LoggingRhythmPolicy policy;

  const PeakHourRule({
    this.id = 'peak_hour',
    this.policy = const LoggingRhythmPolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset
        .entries()
        .where((entry) => entry.timePrecision == InsightTimePrecision.exact)
        .toList();
    yield _evaluateLoggingRhythm(
      id: id,
      subjectId: 'all_entries',
      entries: entries,
      minimumEntries: policy.minimumEntries,
      minimumSpanDays: policy.minimumSpanDays,
      minimumFocusWindowDays: policy.minimumFocusWindowDays,
      minimumPeakRate: policy.minimumPeakRate,
      focusWindowDays: context.dataset.focusWindow.calendarDays,
      bucket: (entry) => entry.occurredAt.toLocal().hour,
      build: (counts, evidence, sourceEntryIds, categoryIds) {
        final peakHour = _leadingIntKey(counts);
        return PeakHourFinding(
          findingId: FindingIdentity.build(
            ruleId: id,
            components: const ['all_entries', 'focus'],
          ),
          ruleId: id,
          peakHour: peakHour,
          totalEntries: entries.length,
          hourCounts: counts,
          categoryIds: categoryIds,
          evidence: evidence,
          sourceEntryIds: sourceEntryIds,
          contributingEntryIds: sourceEntryIds,
        );
      },
    );
  }
}

/// An exact distribution of focus-period entries by local weekday.
final class MostCommonDayFinding extends AggregateFinding {
  final int weekday;
  final int totalEntries;
  final Map<int, int> weekdayCounts;
  final List<String> categoryIds;

  MostCommonDayFinding({
    required super.findingId,
    required super.ruleId,
    required this.weekday,
    required this.totalEntries,
    required Map<int, int> weekdayCounts,
    required Iterable<String> categoryIds,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : weekdayCounts = Map.unmodifiable(weekdayCounts),
       categoryIds = List.unmodifiable(categoryIds);

  int get commonDayEntryCount => weekdayCounts[weekday] ?? 0;
  double get commonDayRate =>
      totalEntries == 0 ? 0 : commonDayEntryCount / totalEntries;
  bool get hasTiedPeak =>
      weekdayCounts.values
          .where((count) => count == commonDayEntryCount)
          .length >
      1;
}

/// Produces one exact distribution summary across local weekdays.
class MostCommonDayRule implements FindingRule {
  @override
  final String id;
  final LoggingRhythmPolicy policy;

  const MostCommonDayRule({
    this.id = 'most_common_day',
    this.policy = const LoggingRhythmPolicy(
      minimumEntries: 7,
      minimumSpanDays: 7,
      minimumFocusWindowDays: 7,
      minimumPeakRate: 0.20,
    ),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset.entries().toList();
    yield _evaluateLoggingRhythm(
      id: id,
      subjectId: 'all_entries',
      entries: entries,
      minimumEntries: policy.minimumEntries,
      minimumSpanDays: policy.minimumSpanDays,
      minimumFocusWindowDays: policy.minimumFocusWindowDays,
      minimumPeakRate: policy.minimumPeakRate,
      focusWindowDays: context.dataset.focusWindow.calendarDays,
      bucket: (entry) => entry.occurredAt.toLocal().weekday,
      build: (counts, evidence, sourceEntryIds, categoryIds) {
        final weekday = _leadingIntKey(counts);
        return MostCommonDayFinding(
          findingId: FindingIdentity.build(
            ruleId: id,
            components: const ['all_entries', 'focus'],
          ),
          ruleId: id,
          weekday: weekday,
          totalEntries: entries.length,
          weekdayCounts: counts,
          categoryIds: categoryIds,
          evidence: evidence,
          sourceEntryIds: sourceEntryIds,
          contributingEntryIds: sourceEntryIds,
        );
      },
    );
  }
}

/// Presentation thresholds for exact focus-window logging coverage.
class RecordingConsistencyPolicy {
  final int minimumWindowDays;
  final int minimumActiveDays;

  const RecordingConsistencyPolicy({
    this.minimumWindowDays = 3,
    this.minimumActiveDays = 2,
  }) : assert(minimumWindowDays > 0),
       assert(minimumActiveDays > 0);
}

/// An exact summary of which calendar days contain at least one entry.
final class RecordingConsistencyFinding extends AggregateFinding {
  final int totalEntries;
  final List<DateTime> windowDays;
  final List<DateTime> activeDays;

  RecordingConsistencyFinding({
    required super.findingId,
    required super.ruleId,
    required this.totalEntries,
    required Iterable<DateTime> windowDays,
    required Iterable<DateTime> activeDays,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : windowDays = List.unmodifiable(windowDays),
       activeDays = List.unmodifiable(activeDays);

  int get activeDayCount => activeDays.length;
  double get coverageRate =>
      windowDays.isEmpty ? 0 : activeDayCount / windowDays.length;

  int get longestStreak {
    final active = activeDays.toSet();
    var longest = 0;
    var current = 0;
    for (final day in windowDays) {
      if (active.contains(day)) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }
}

/// Produces one exact active-day coverage and streak summary.
class RecordingConsistencyRule implements FindingRule {
  @override
  final String id;
  final RecordingConsistencyPolicy policy;

  const RecordingConsistencyRule({
    this.id = 'recording_consistency',
    this.policy = const RecordingConsistencyPolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset.entries();
    final windowDays = _calendarDaysIn(context.dataset.focusWindow);
    final windowDaySet = windowDays.toSet();
    final activeDays =
        entries
            .map((entry) => entry.localDay)
            .where(windowDaySet.contains)
            .toSet()
            .toList()
          ..sort();
    final sourceEntryIds = entries.map((entry) => entry.entryId).toSet();
    final coverage = windowDays.isEmpty
        ? 0.0
        : activeDays.length / windowDays.length;
    final evidence = FindingEvidence(
      observations: entries.length,
      independentUnits: activeDays.length,
      unit: EvidenceUnit.day,
      spanDays: windowDays.length,
      coverage: coverage,
      coverageUnit: EvidenceUnit.day,
    );
    const subjectId = 'all_entries';

    if (windowDays.length < policy.minimumWindowDays) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientSpan,
        detail: 'Requires a ${policy.minimumWindowDays}-day window.',
      );
      return;
    }
    if (activeDays.length < policy.minimumActiveDays) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientIndependentUnits,
        detail: 'Requires logs on ${policy.minimumActiveDays} days.',
      );
      return;
    }

    yield AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: RecordingConsistencyFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: const [subjectId, 'focus'],
        ),
        ruleId: id,
        totalEntries: entries.length,
        windowDays: windowDays,
        activeDays: activeDays,
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: sourceEntryIds,
      ),
    );
  }
}

/// Presentation thresholds for an exact per-calendar-day volume summary.
class DailyVolumePolicy {
  final int minimumEntries;
  final int minimumActiveDays;

  const DailyVolumePolicy({this.minimumEntries = 5, this.minimumActiveDays = 3})
    : assert(minimumEntries > 0),
      assert(minimumActiveDays > 0);
}

/// An exact distribution of focus-period entries across active calendar days.
final class DailyVolumeFinding extends AggregateFinding {
  final int totalEntries;
  final Map<DateTime, int> dailyCounts;
  final List<DateTime> busiestDays;

  DailyVolumeFinding({
    required super.findingId,
    required super.ruleId,
    required this.totalEntries,
    required Map<DateTime, int> dailyCounts,
    required Iterable<DateTime> busiestDays,
    required super.evidence,
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : dailyCounts = Map.unmodifiable(dailyCounts),
       busiestDays = List.unmodifiable(busiestDays);

  int get activeDayCount => dailyCounts.length;
  int get busiestEntryCount =>
      busiestDays.isEmpty ? 0 : dailyCounts[busiestDays.first] ?? 0;
  DateTime get featuredBusiestDay => busiestDays.last;
  bool get hasTiedBusiestDay => busiestDays.length > 1;
  double get averagePerActiveDay =>
      activeDayCount == 0 ? 0 : totalEntries / activeDayCount;
}

/// Produces one exact busiest-date and daily-volume summary.
class DailyVolumeRule implements FindingRule {
  @override
  final String id;
  final DailyVolumePolicy policy;

  const DailyVolumeRule({
    this.id = 'daily_volume',
    this.policy = const DailyVolumePolicy(),
  });

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    final entries = context.dataset.entries();
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      counts[entry.localDay] = (counts[entry.localDay] ?? 0) + 1;
    }
    final sortedDays = counts.keys.toList()..sort();
    final sortedCounts = <DateTime, int>{
      for (final day in sortedDays) day: counts[day]!,
    };
    final busiestCount = counts.isEmpty
        ? 0
        : counts.values.reduce((left, right) => left > right ? left : right);
    final busiestDays = sortedDays
        .where((day) => counts[day] == busiestCount)
        .toList();
    final sourceEntryIds = entries.map((entry) => entry.entryId).toSet();
    final evidence = FindingEvidence(
      observations: entries.length,
      independentUnits: sortedDays.length,
      unit: EvidenceUnit.day,
      spanDays: _calendarSpan(sortedDays),
    );
    const subjectId = 'all_entries';

    if (entries.length < policy.minimumEntries) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientObservations,
        detail: 'Requires ${policy.minimumEntries} entries.',
      );
      return;
    }
    if (sortedDays.length < policy.minimumActiveDays) {
      yield RejectedFindingEvaluation(
        ruleId: id,
        subjectId: subjectId,
        evidence: evidence,
        code: FindingRejectionCode.insufficientIndependentUnits,
        detail: 'Requires logs on ${policy.minimumActiveDays} days.',
      );
      return;
    }

    yield AcceptedFindingEvaluation(
      subjectId: subjectId,
      finding: DailyVolumeFinding(
        findingId: FindingIdentity.build(
          ruleId: id,
          components: const [subjectId, 'focus'],
        ),
        ruleId: id,
        totalEntries: entries.length,
        dailyCounts: sortedCounts,
        busiestDays: busiestDays,
        evidence: evidence,
        sourceEntryIds: sourceEntryIds,
        contributingEntryIds: sourceEntryIds,
      ),
    );
  }
}

FindingEvaluation _evaluateLoggingRhythm({
  required String id,
  required String subjectId,
  required List<InsightEntry> entries,
  required int minimumEntries,
  required int minimumSpanDays,
  required int minimumFocusWindowDays,
  required double minimumPeakRate,
  required int focusWindowDays,
  required int Function(InsightEntry entry) bucket,
  required AggregateFinding Function(
    Map<int, int> counts,
    FindingEvidence evidence,
    Set<String> sourceEntryIds,
    List<String> categoryIds,
  )
  build,
}) {
  final counts = <int, int>{};
  for (final entry in entries) {
    final key = bucket(entry);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final sortedCounts = <int, int>{
    for (final key in (counts.keys.toList()..sort())) key: counts[key]!,
  };
  final sourceEntryIds = entries.map((entry) => entry.entryId).toSet();
  final days = entries.map((entry) => entry.localDay).toSet();
  final categoryIds = entries.map((entry) => entry.categoryId).toSet().toList()
    ..sort();
  final evidence = FindingEvidence(
    observations: entries.length,
    independentUnits: days.length,
    unit: EvidenceUnit.day,
    spanDays: _calendarSpan(days),
  );
  if (entries.length < minimumEntries) {
    return RejectedFindingEvaluation(
      ruleId: id,
      subjectId: subjectId,
      evidence: evidence,
      code: FindingRejectionCode.insufficientObservations,
      detail: 'Requires $minimumEntries entries.',
    );
  }
  if (focusWindowDays < minimumFocusWindowDays ||
      evidence.spanDays < minimumSpanDays) {
    return RejectedFindingEvaluation(
      ruleId: id,
      subjectId: subjectId,
      evidence: evidence,
      code: FindingRejectionCode.insufficientSpan,
      detail:
          'Requires a $minimumFocusWindowDays-day window and logs spanning $minimumSpanDays days.',
    );
  }
  final peakRate =
      counts.values.reduce((left, right) => left > right ? left : right) /
      entries.length;
  if (peakRate < minimumPeakRate) {
    return RejectedFindingEvaluation(
      ruleId: id,
      subjectId: subjectId,
      evidence: evidence,
      code: FindingRejectionCode.effectTooSmall,
      detail: 'Peak share is below ${(minimumPeakRate * 100).round()}%.',
    );
  }
  return AcceptedFindingEvaluation(
    subjectId: subjectId,
    finding: build(sortedCounts, evidence, sourceEntryIds, categoryIds),
  );
}

int _leadingIntKey(Map<int, int> counts) {
  var leader = counts.keys.first;
  for (final entry in counts.entries) {
    if (entry.value > counts[leader]! ||
        (entry.value == counts[leader]! && entry.key < leader)) {
      leader = entry.key;
    }
  }
  return leader;
}

List<DateTime> _calendarDaysIn(InsightTimeWindow window) => List.generate(
  window.calendarDays,
  (index) =>
      DateTime(window.start.year, window.start.month, window.start.day + index),
  growable: false,
);

int _calendarSpan(Iterable<DateTime> days) {
  final sorted = days.toList()..sort();
  if (sorted.isEmpty) return 0;
  final first = sorted.first;
  final last = sorted.last;
  return DateTime.utc(
        last.year,
        last.month,
        last.day,
      ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
      1;
}
