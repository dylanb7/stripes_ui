import 'package:flutter/widgets.dart';
import 'package:stripes_ui/Insights/Engine/Rules/aggregate_summary_rules.dart';
import 'package:stripes_ui/Insights/Engine/Rules/numeric_relationship_rule.dart';
import 'package:stripes_ui/Insights/Engine/Rules/recent_vs_usual_presence_rate_rule.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// Localized, UI-ready copy for an engine [Finding].
///
/// Engine rules deliberately return facts and evidence rather than prose. This
/// type keeps localization and claim-strength wording at the presentation
/// boundary, where it can evolve without changing an analysis rule.
class FindingPresentation {
  final String findingId;
  final FindingKind kind;
  final String eyebrow;
  final String title;
  final String description;
  final String evidenceText;
  final String? qualification;
  final FindingGraphicData? graphic;
  final String? metricValue;
  final String? metricLabel;
  final List<FindingHighlight> highlights;
  final List<String> categoryIds;

  const FindingPresentation({
    required this.findingId,
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.evidenceText,
    this.qualification,
    this.graphic,
    this.metricValue,
    this.metricLabel,
    this.highlights = const [],
    this.categoryIds = const [],
  });

  bool get isSummary => kind == FindingKind.aggregate;
}

class FindingHighlight {
  final String label;
  final String? categoryId;

  const FindingHighlight(this.label, {this.categoryId});
}

sealed class FindingGraphicData {
  const FindingGraphicData();
}

/// Two independently normalized series. Values stay raw here so rendering can
/// adapt to its available size without affecting the finding itself.
final class RelationshipGraphicData extends FindingGraphicData {
  final String leftLabel;
  final String rightLabel;
  final List<double> leftValues;
  final List<double> rightValues;

  RelationshipGraphicData({
    required this.leftLabel,
    required this.rightLabel,
    required Iterable<double> leftValues,
    required Iterable<double> rightValues,
  }) : leftValues = List.unmodifiable(leftValues),
       rightValues = List.unmodifiable(rightValues),
       assert(
         leftValues.length == rightValues.length,
         'Relationship series must be paired.',
       );
}

class FindingBarDatum {
  final String label;
  final int count;
  final int total;
  final bool emphasized;

  const FindingBarDatum({
    required this.label,
    required this.count,
    required this.total,
    this.emphasized = false,
  }) : assert(count >= 0),
       assert(total >= count);

  double get fraction => total == 0 ? 0 : count / total;
}

final class DistributionGraphicData extends FindingGraphicData {
  final List<FindingBarDatum> values;

  DistributionGraphicData(Iterable<FindingBarDatum> values)
    : values = List.unmodifiable(values);
}

class FindingHistogramDatum {
  final String label;
  final int count;
  final bool emphasized;

  const FindingHistogramDatum({
    required this.label,
    required this.count,
    this.emphasized = false,
  }) : assert(count >= 0);
}

final class HistogramGraphicData extends FindingGraphicData {
  final List<FindingHistogramDatum> values;

  HistogramGraphicData(Iterable<FindingHistogramDatum> values)
    : values = List.unmodifiable(values);
}

final class CoOccurrenceGraphicData extends FindingGraphicData {
  final List<CoOccurrenceDayDatum> days;
  final String leftCategoryId;
  final String rightCategoryId;
  final String? leftLabel;
  final String? rightLabel;

  CoOccurrenceGraphicData({
    required Iterable<CoOccurrenceDayDatum> days,
    required this.leftCategoryId,
    required this.rightCategoryId,
    this.leftLabel,
    this.rightLabel,
  }) : days = List.unmodifiable(days);

  int get overlapDays =>
      days.where((day) => day.leftLogged && day.rightLogged).length;

  int get eligibleDays => days.length;
}

/// Calendar-day presence rendered as one compact segmented strip.
final class ActivityStripGraphicData extends FindingGraphicData {
  final List<bool> activeDays;

  ActivityStripGraphicData(Iterable<bool> activeDays)
    : activeDays = List.unmodifiable(activeDays);
}

class CoOccurrenceDayDatum {
  final bool leftLogged;
  final bool rightLogged;

  const CoOccurrenceDayDatum({
    required this.leftLogged,
    required this.rightLogged,
  }) : assert(leftLogged || rightLogged);
}

typedef FindingTranslation = String? Function(String key);

/// Resolves engine identifiers at the UI boundary.
///
/// The engine uses stable question/category IDs. Question labels are recovered
/// from dataset prompt keys, then translated only when the finding is shown.
class FindingLabels {
  final Map<String, String> _questionPromptKeys;
  final Map<String, String> _questionCategoryIds;
  final FindingTranslation? _translate;

  FindingLabels({
    Map<String, String> questionPromptKeys = const {},
    Map<String, String> questionCategoryIds = const {},
    this._translate,
  }) : _questionPromptKeys = Map.unmodifiable(questionPromptKeys),
       _questionCategoryIds = Map.unmodifiable(questionCategoryIds);

  factory FindingLabels.fromDataset(
    InsightDataset dataset, {
    FindingTranslation? translate,
  }) {
    final promptKeys = <String, String>{};
    final categoryIds = <String, String>{};
    for (final observation in dataset.observations(
      scope: InsightDatasetScope.all,
    )) {
      promptKeys.putIfAbsent(
        observation.questionId,
        () => observation.promptKey,
      );
      categoryIds.putIfAbsent(
        observation.questionId,
        () => observation.categoryId,
      );
    }
    return FindingLabels(
      questionPromptKeys: promptKeys,
      questionCategoryIds: categoryIds,
      translate: translate,
    );
  }

  factory FindingLabels.fromContext(
    BuildContext context,
    InsightDataset dataset,
  ) => FindingLabels.fromDataset(
    dataset,
    translate: (key) => _translatedValue(context, key),
  );

  String question(String questionId, {String? promptKey}) => _resolve(
    promptKey ?? _questionPromptKeys[questionId] ?? questionId,
    fallback: questionId,
  );

  String category(String categoryId) =>
      _resolve(categoryId, fallback: categoryId);

  String choice(String choiceKey) => _resolve(choiceKey, fallback: choiceKey);

  String? categoryIdForQuestion(String questionId) =>
      _questionCategoryIds[questionId];

  String _resolve(String key, {required String fallback}) {
    final translated = _translate?.call(key)?.trim();
    if (translated != null && translated.isNotEmpty) return translated;
    return _humanize(key.isEmpty ? fallback : key);
  }

  static String? _translatedValue(BuildContext context, String key) {
    try {
      final value = QuestionsLocalizations.of(context)?.value(key);
      return value is String ? value : null;
    } on Object {
      // A missing localization must never stop a finding from rendering.
      return null;
    }
  }
}

abstract interface class FindingPresenter {
  bool supports(Finding finding);

  FindingPresentation present(Finding finding, FindingLabels labels);
}

class TypedFindingPresenter<T extends Finding> implements FindingPresenter {
  final FindingPresentation Function(T finding, FindingLabels labels) builder;

  const TypedFindingPresenter(this.builder);

  @override
  bool supports(Finding finding) => finding is T;

  @override
  FindingPresentation present(Finding finding, FindingLabels labels) =>
      builder(finding as T, labels);
}

/// Ordered registry that makes support for new finding types explicit.
///
/// Unknown findings use a deliberately non-interpretive fallback. This avoids
/// accidentally turning a new engine result into a stronger user-facing claim.
class FindingPresenterRegistry {
  final List<FindingPresenter> presenters;

  FindingPresenterRegistry({Iterable<FindingPresenter> presenters = const []})
    : presenters = List.unmodifiable(presenters);

  factory FindingPresenterRegistry.standard({
    Iterable<FindingPresenter> additionalPresenters = const [],
  }) => FindingPresenterRegistry(
    presenters: [
      ...additionalPresenters,
      const TypedFindingPresenter<CategoryCoOccurrenceFinding>(
        _presentCategoryCoOccurrence,
      ),
      const TypedFindingPresenter<ChoiceDistributionFinding>(
        _presentChoiceDistribution,
      ),
      const TypedFindingPresenter<CategoryDistributionFinding>(
        _presentCategoryDistribution,
      ),
      const TypedFindingPresenter<PeakHourFinding>(_presentPeakHour),
      const TypedFindingPresenter<MostCommonDayFinding>(_presentMostCommonDay),
      const TypedFindingPresenter<RecordingConsistencyFinding>(
        _presentRecordingConsistency,
      ),
      const TypedFindingPresenter<DailyVolumeFinding>(_presentDailyVolume),
      const TypedFindingPresenter<NumericRelationshipFinding>(
        _presentNumericRelationship,
      ),
      const TypedFindingPresenter<RecentVsUsualPresenceRateFinding>(
        _presentRecentVsUsual,
      ),
    ],
  );

  FindingPresentation present(Finding finding, FindingLabels labels) {
    for (final presenter in presenters) {
      if (presenter.supports(finding)) {
        return presenter.present(finding, labels);
      }
    }
    return _presentUnknown(finding);
  }

  List<FindingPresentation> presentAll(
    Iterable<Finding> findings,
    FindingLabels labels,
  ) => List.unmodifiable(findings.map((finding) => present(finding, labels)));
}

FindingPresentation _presentCategoryCoOccurrence(
  CategoryCoOccurrenceFinding finding,
  FindingLabels labels,
) {
  final left = labels.category(finding.leftCategoryId);
  final right = labels.category(finding.rightCategoryId);
  final percent = (finding.coOccurrenceRate * 100).round();
  final eligibleDays = finding.eligibleDays.length;
  final leftDays = finding.leftDays.toSet();
  final rightDays = finding.rightDays.toSet();

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: 'Logged on the same days',
    description: 'Same-day logging',
    evidenceText: '${finding.evidence.spanDays}-day period',
    qualification: 'Logging overlap only — not a symptom relationship.',
    metricValue: '$percent%',
    metricLabel: '${finding.overlapDays} of $eligibleDays active days',
    highlights: [
      FindingHighlight(left, categoryId: finding.leftCategoryId),
      FindingHighlight(right, categoryId: finding.rightCategoryId),
    ],
    categoryIds: [finding.leftCategoryId, finding.rightCategoryId],
    graphic: CoOccurrenceGraphicData(
      days: finding.eligibleDays.map(
        (day) => CoOccurrenceDayDatum(
          leftLogged: leftDays.contains(day),
          rightLogged: rightDays.contains(day),
        ),
      ),
      leftCategoryId: finding.leftCategoryId,
      rightCategoryId: finding.rightCategoryId,
      leftLabel: left,
      rightLabel: right,
    ),
  );
}

FindingPresentation _presentChoiceDistribution(
  ChoiceDistributionFinding finding,
  FindingLabels labels,
) {
  final question = labels.question(
    finding.questionId,
    promptKey: finding.promptKey,
  );
  final leadingChoiceKey = finding.leadingChoice;
  final leadingChoice = leadingChoiceKey == null
      ? 'No recorded choice'
      : labels.choice(leadingChoiceKey);
  final percent = (finding.leadingChoiceRate * 100).round();
  final counts = finding.choiceCounts.entries.toList()
    ..sort((left, right) {
      final countComparison = right.value.compareTo(left.value);
      return countComparison != 0
          ? countComparison
          : left.key.compareTo(right.key);
    });
  const maximumVisibleChoices = 4;
  final visibleCounts = counts.take(maximumVisibleChoices);
  final qualificationParts = <String>[
    if (finding.allowsMultiple) 'More than one option could be selected, so percentages may add to more than 100%.',
    if (counts.length > maximumVisibleChoices)
      'The chart shows the $maximumVisibleChoices most selected of ${counts.length} recorded options.',
  ];

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: question,
    description: 'Recorded response distribution',
    evidenceText: _evidenceText(
      finding.evidence,
      preferredUnits:
          '${finding.answerOccasions} recorded ${_plural(finding.answerOccasions, 'answer')}',
    ),
    qualification: qualificationParts.isEmpty
        ? null
        : qualificationParts.join(' '),
    metricValue: '$percent%',
    metricLabel:
        '$leadingChoice • ${finding.leadingChoiceCount} of ${finding.answerOccasions}',
    categoryIds: finding.categoryIds,
    graphic: DistributionGraphicData([
      for (final entry in visibleCounts)
        FindingBarDatum(
          label: labels.choice(entry.key),
          count: entry.value,
          total: finding.answerOccasions,
          emphasized: entry.key == leadingChoiceKey,
        ),
    ]),
  );
}

FindingPresentation _presentCategoryDistribution(
  CategoryDistributionFinding finding,
  FindingLabels labels,
) {
  final leadingCategoryId = finding.leadingCategoryId;
  final leadingCategory = labels.category(leadingCategoryId);
  final percent = (finding.leadingCategoryRate * 100).round();
  final counts = finding.categoryCounts.entries.toList()
    ..sort((left, right) {
      final countComparison = right.value.compareTo(left.value);
      return countComparison != 0
          ? countComparison
          : left.key.compareTo(right.key);
    });
  const maximumVisibleCategories = 4;
  final visibleCounts = counts.take(maximumVisibleCategories);

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: finding.hasTiedLead
        ? 'One of your most tracked categories'
        : 'Most tracked category',
    description: '$leadingCategory had the most entries in this period.',
    evidenceText: _evidenceText(
      finding.evidence,
      preferredUnits: '${finding.totalEntries} recorded entries',
    ),
    qualification: [
      'This counts entries, not symptom severity.',
      if (counts.length > maximumVisibleCategories)
        'The chart shows the $maximumVisibleCategories most recorded of ${counts.length} categories.',
    ].join(' '),
    metricValue: '$percent%',
    metricLabel:
        '${finding.leadingCategoryCount} of ${finding.totalEntries} entries',
    highlights: [
      FindingHighlight(leadingCategory, categoryId: leadingCategoryId),
    ],
    categoryIds: [leadingCategoryId],
    graphic: DistributionGraphicData([
      for (final entry in visibleCounts)
        FindingBarDatum(
          label: labels.category(entry.key),
          count: entry.value,
          total: finding.totalEntries,
          emphasized: entry.key == leadingCategoryId,
        ),
    ]),
  );
}

FindingPresentation _presentPeakHour(
  PeakHourFinding finding,
  FindingLabels labels,
) {
  final count = finding.peakEntryCount;
  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: finding.hasTiedPeak ? 'One of your busiest hours' : 'Busiest hour',
    description: 'Among entries with exact times, the most events occurred during this hour.',
    evidenceText: _evidenceText(
      finding.evidence,
      preferredUnits: '${finding.totalEntries} entries with exact times',
    ),
    qualification: 'Based on event times. Approximate times and check-in periods are excluded.',
    metricValue: _hourLabel(finding.peakHour),
    metricLabel: '$count of ${finding.totalEntries} entries',
    categoryIds: finding.categoryIds,
    graphic: HistogramGraphicData([
      for (var hour = 0; hour < 24; hour++)
        FindingHistogramDatum(
          label: _hourAxisLabel(hour),
          count: finding.hourCounts[hour] ?? 0,
          emphasized: (finding.hourCounts[hour] ?? 0) == count,
        ),
    ]),
  );
}

FindingPresentation _presentMostCommonDay(
  MostCommonDayFinding finding,
  FindingLabels labels,
) {
  final count = finding.commonDayEntryCount;
  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: finding.hasTiedPeak ? 'One of your busiest days' : 'Busiest day',
    description: 'You recorded the most entries on this day of the week.',
    evidenceText: _evidenceText(
      finding.evidence,
      preferredUnits: '${finding.totalEntries} recorded entries',
    ),
    qualification: 'This reflects your recorded logs in this period.',
    metricValue: _weekdayLabel(finding.weekday),
    metricLabel: '$count of ${finding.totalEntries} entries',
    categoryIds: finding.categoryIds,
    graphic: HistogramGraphicData([
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        FindingHistogramDatum(
          label: _weekdayShortLabel(weekday),
          count: finding.weekdayCounts[weekday] ?? 0,
          emphasized: (finding.weekdayCounts[weekday] ?? 0) == count,
        ),
    ]),
  );
}

FindingPresentation _presentRecordingConsistency(
  RecordingConsistencyFinding finding,
  FindingLabels labels,
) {
  final percent = (finding.coverageRate * 100).round();
  final activeDays = finding.activeDays.toSet();
  final presence = [
    for (final day in finding.windowDays) activeDays.contains(day),
  ];
  final streak = finding.longestStreak;

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: finding.activeDayCount == finding.windowDays.length
        ? 'Logged every day'
        : 'Recording consistency',
    description:
        'Your longest logging streak was $streak consecutive ${_plural(streak, 'day')}.',
    evidenceText:
        '${finding.totalEntries} recorded ${_plural(finding.totalEntries, 'entry')} • ${finding.windowDays.length}-day period',
    qualification: 'A day counts once when it contains one or more entries.',
    metricValue: '$percent%',
    metricLabel:
        '${finding.activeDayCount} of ${finding.windowDays.length} days',
    graphic: ActivityStripGraphicData(presence),
  );
}

FindingPresentation _presentDailyVolume(
  DailyVolumeFinding finding,
  FindingLabels labels,
) {
  final days = finding.dailyCounts.keys.toList()..sort();
  const maximumVisibleDays = 21;
  final busiestDay = finding.featuredBusiestDay;
  final displayedDays =
      days.length <= maximumVisibleDays
            ? days
            : <DateTime>{
                busiestDay,
                ...days.skip(days.length - (maximumVisibleDays - 1)),
              }.toList()
        ..sort();
  final average = _compactDecimal(finding.averagePerActiveDay);

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Summary',
    title: finding.hasTiedBusiestDay
        ? 'One of your busiest dates'
        : 'Busiest date',
    description:
        'You averaged $average ${_pluralForValue(finding.averagePerActiveDay, 'entry')} per active day.',
    evidenceText:
        '${finding.totalEntries} recorded ${_plural(finding.totalEntries, 'entry')} • ${finding.activeDayCount} active ${_plural(finding.activeDayCount, 'day')}',
    qualification: [
      'This reflects logging volume, not symptom severity.',
      if (days.length > maximumVisibleDays)
        'The chart shows the busiest date and the most recent active days.',
    ].join(' '),
    metricValue: _monthDayLabel(busiestDay),
    metricLabel:
        '${finding.busiestEntryCount} ${_plural(finding.busiestEntryCount, 'entry')}',
    graphic: HistogramGraphicData([
      for (var index = 0; index < displayedDays.length; index++)
        FindingHistogramDatum(
          label:
              displayedDays.length <= 7 ||
                  index == 0 ||
                  index == displayedDays.length - 1
              ? '${displayedDays[index].month}/${displayedDays[index].day}'
              : '',
          count: finding.dailyCounts[displayedDays[index]]!,
          emphasized:
              finding.dailyCounts[displayedDays[index]] ==
              finding.busiestEntryCount,
        ),
    ]),
  );
}

FindingPresentation _presentNumericRelationship(
  NumericRelationshipFinding finding,
  FindingLabels labels,
) {
  final left = labels.question(finding.leftQuestionId);
  final right = labels.question(finding.rightQuestionId);
  final sameDirection = finding.rho >= 0;
  final description = sameDirection
      ? '$left and $right tended to be higher or lower on the same days.'
      : 'On days when $left was higher, $right tended to be lower, and vice versa.';

  final leftCategoryId = labels.categoryIdForQuestion(finding.leftQuestionId);
  final rightCategoryId = labels.categoryIdForQuestion(finding.rightQuestionId);

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Pattern',
    title: 'Possible same-day pattern',
    description: description,
    evidenceText: _evidenceText(
      finding.evidence,
      preferredUnits:
          '${finding.pairs.length} shared ${_plural(finding.pairs.length, 'day')}',
    ),
    qualification: 'This is an association in your logs. It does not show that one caused the other.',
    metricValue: sameDirection ? 'Move together' : 'Move opposite',
    metricLabel:
        '${finding.pairs.length} shared ${_plural(finding.pairs.length, 'day')}',
    highlights: [
      FindingHighlight(left, categoryId: leftCategoryId),
      FindingHighlight(right, categoryId: rightCategoryId),
    ],
    categoryIds: {?leftCategoryId, ?rightCategoryId}.toList(),
    graphic: RelationshipGraphicData(
      leftLabel: left,
      rightLabel: right,
      leftValues: finding.pairs.map((pair) => pair.left.value),
      rightValues: finding.pairs.map((pair) => pair.right.value),
    ),
  );
}

FindingPresentation _presentRecentVsUsual(
  RecentVsUsualPresenceRateFinding finding,
  FindingLabels labels,
) {
  final question = labels.question(finding.questionId);
  final direction = finding.increased ? 'more' : 'less';
  final recentRate = ((finding.focus.rate ?? 0) * 100).round();
  final usualRate = ((finding.reference.rate ?? 0) * 100).round();
  final difference = (recentRate - usualRate).abs();
  final categoryId = labels.categoryIdForQuestion(finding.questionId);

  return FindingPresentation(
    findingId: finding.findingId,
    kind: finding.kind,
    eyebrow: 'Pattern',
    title: 'Different from your comparison period',
    description:
        '$question appeared $direction often in recent completed check-ins ($recentRate% vs $usualRate%).',
    evidenceText:
        '${finding.focus.opportunities} recent and ${finding.reference.opportunities} comparison ${_plural(finding.reference.opportunities, 'check-in')}',
    qualification:
        'Only completed check-ins where this question was shown are compared.',
    metricValue: '$difference pts $direction',
    metricLabel: '$recentRate% recent • $usualRate% comparison',
    highlights: [FindingHighlight(question, categoryId: categoryId)],
    categoryIds: [?categoryId],
    graphic: DistributionGraphicData([
      FindingBarDatum(
        label: 'Recent',
        count: finding.focus.positives,
        total: finding.focus.opportunities,
        emphasized: true,
      ),
      FindingBarDatum(
        label: 'Comparison',
        count: finding.reference.positives,
        total: finding.reference.opportunities,
      ),
    ]),
  );
}

FindingPresentation _presentUnknown(Finding finding) => FindingPresentation(
  findingId: finding.findingId,
  kind: finding.kind,
  eyebrow: _eyebrowFor(finding.kind),
  title: finding.kind == FindingKind.aggregate
      ? 'Additional summary'
      : 'Additional finding',
  description: 'This finding is available, but its details are not supported by this app version.',
  evidenceText: _evidenceText(finding.evidence),
);

String _eyebrowFor(FindingKind kind) => switch (kind) {
  FindingKind.aggregate => 'Summary',
  FindingKind.observation => 'Pattern',
  FindingKind.anomaly => 'Unusual change',
  FindingKind.inferential => 'Relationship',
};

String _evidenceText(FindingEvidence evidence, {String? preferredUnits}) {
  final parts = <String>[];
  if (preferredUnits != null) {
    parts.add(preferredUnits);
  } else if (evidence.independentUnits > 0) {
    parts.add(
      '${evidence.independentUnits} ${_unitLabel(evidence.unit, evidence.independentUnits)}',
    );
  } else if (evidence.observations > 0) {
    parts.add(
      '${evidence.observations} ${_plural(evidence.observations, 'observation')}',
    );
  }
  if (evidence.spanDays > 1) {
    parts.add('${evidence.spanDays}-day span');
  }
  return parts.isEmpty ? 'Evidence details unavailable' : parts.join(' • ');
}

String _unitLabel(EvidenceUnit unit, int count) => switch (unit) {
  EvidenceUnit.entry => _plural(count, 'entry'),
  EvidenceUnit.day => _plural(count, 'day'),
  EvidenceUnit.week => _plural(count, 'week'),
  EvidenceUnit.event => _plural(count, 'event'),
  EvidenceUnit.eventPair => _plural(count, 'event pair'),
  EvidenceUnit.answerOccasion => _plural(count, 'answer'),
};

String _plural(int count, String singular) =>
    count == 1 ? singular : _pluralForm(singular);

String _pluralForValue(double value, String singular) =>
    value == 1 ? singular : _pluralForm(singular);

String _pluralForm(String singular) =>
    singular == 'entry' ? 'entries' : '${singular}s';

String _compactDecimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _monthDayLabel(DateTime day) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[day.month - 1]} ${day.day}';
}

String _hourLabel(int hour) {
  final normalized = hour % 24;
  final displayHour = normalized == 0
      ? 12
      : normalized > 12
      ? normalized - 12
      : normalized;
  return '$displayHour ${normalized < 12 ? 'AM' : 'PM'}';
}

String _hourAxisLabel(int hour) => switch (hour) {
  0 => '12a',
  6 => '6a',
  12 => '12p',
  18 => '6p',
  _ => '',
};

String _weekdayLabel(int weekday) =>
    const {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    }[weekday] ??
    'Day';

String _weekdayShortLabel(int weekday) =>
    const {
      DateTime.monday: 'M',
      DateTime.tuesday: 'T',
      DateTime.wednesday: 'W',
      DateTime.thursday: 'T',
      DateTime.friday: 'F',
      DateTime.saturday: 'S',
      DateTime.sunday: 'S',
    }[weekday] ??
    '';

String _humanize(String value) {
  final displayValue = value.contains('.') ? value.split('.').last : value;
  final withSpaces = displayValue
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .trim();
  if (withSpaces.isEmpty) return value;
  return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
}
