import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Insights/Engine/Rules/aggregate_summary_rules.dart';
import 'package:stripes_ui/Insights/Engine/Rules/numeric_relationship_rule.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Insights/finding_presentation.dart';
import 'package:stripes_ui/UI/History/Insights/finding_widgets.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/config.dart';

void main() {
  group('FindingPresenterRegistry', () {
    test('presents co-logging as a summary rather than a relationship', () {
      final finding = CategoryCoOccurrenceFinding(
        findingId: 'co-occurrence',
        ruleId: 'category_co_occurrence',
        leftCategoryId: 'pain',
        rightCategoryId: 'sleep',
        leftDays: [_day(1), _day(2), _day(3)],
        rightDays: [_day(2), _day(3), _day(4)],
        sharedDays: [_day(2), _day(3)],
        eligibleDays: [_day(1), _day(2), _day(3), _day(4)],
        evidence: const FindingEvidence(
          observations: 6,
          independentUnits: 4,
          unit: EvidenceUnit.day,
          spanDays: 4,
          overlap: 2,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.eyebrow, 'Summary');
      expect(presentation.title, 'Logged on the same days');
      expect(presentation.metricValue, '50%');
      expect(presentation.metricLabel, '2 of 4 active days');
      expect(presentation.highlights.map((item) => item.label), [
        'Pain',
        'Sleep',
      ]);
      expect(presentation.qualification, contains('Logging overlap'));
      expect(presentation.qualification, isNot(contains('associated')));
      expect(presentation.graphic, isA<CoOccurrenceGraphicData>());
      final graphic = presentation.graphic as CoOccurrenceGraphicData;
      expect(graphic.days, hasLength(4));
      expect(graphic.overlapDays, 2);
      expect(
        graphic.days.map((day) => (day.leftLogged, day.rightLogged)).toList(),
        [(true, false), (true, true), (true, true), (false, true)],
      );
    });

    test('strip presentations retain the full selected period', () {
      final days = [
        for (var index = 0; index < 60; index++) DateTime(2025, 1, 1 + index),
      ];
      final leftDays = [
        for (var index = 0; index < days.length; index++)
          if (index.isEven) days[index],
      ];
      final coOccurrence = CategoryCoOccurrenceFinding(
        findingId: 'long-co-occurrence',
        ruleId: 'category_co_occurrence',
        leftCategoryId: 'pain',
        rightCategoryId: 'sleep',
        leftDays: leftDays,
        rightDays: days,
        sharedDays: leftDays,
        eligibleDays: days,
        evidence: const FindingEvidence(
          observations: 90,
          independentUnits: 60,
          unit: EvidenceUnit.day,
          spanDays: 60,
          overlap: 30,
        ),
      );
      final consistency = RecordingConsistencyFinding(
        findingId: 'long-consistency',
        ruleId: 'recording_consistency',
        totalEntries: 20,
        windowDays: days,
        activeDays: [
          for (var index = 0; index < days.length; index++)
            if (index % 3 == 0) days[index],
        ],
        evidence: const FindingEvidence(
          observations: 20,
          independentUnits: 20,
          unit: EvidenceUnit.day,
          spanDays: 60,
          coverage: 1 / 3,
          coverageUnit: EvidenceUnit.day,
        ),
      );
      final registry = FindingPresenterRegistry.standard();

      final coOccurrencePresentation = registry.present(coOccurrence, _labels);
      final consistencyPresentation = registry.present(consistency, _labels);

      final coOccurrenceGraphic =
          coOccurrencePresentation.graphic as CoOccurrenceGraphicData;
      final consistencyGraphic =
          consistencyPresentation.graphic as ActivityStripGraphicData;
      expect(coOccurrenceGraphic.days, hasLength(60));
      expect(coOccurrenceGraphic.days.first.leftLogged, isTrue);
      expect(coOccurrenceGraphic.days.last.rightLogged, isTrue);
      expect(consistencyGraphic.activeDays, hasLength(60));
      expect(consistencyGraphic.activeDays.first, isTrue);
      expect(consistencyGraphic.activeDays.last, isFalse);
      expect(
        coOccurrencePresentation.qualification,
        isNot(contains('last 28')),
      );
      expect(consistencyPresentation.qualification, isNot(contains('last 28')));
    });

    test('qualifies multi-select choice percentages', () {
      final finding = ChoiceDistributionFinding(
        findingId: 'choices',
        ruleId: 'choice_distribution',
        questionId: 'meal-type',
        promptKey: 'meal_prompt',
        categoryIds: const ['meal'],
        answerOccasions: 10,
        choiceSelections: 22,
        allowsMultiple: true,
        choiceCounts: const {
          'breakfast': 7,
          'snack': 6,
          'lunch': 4,
          'dinner': 3,
          'other': 2,
        },
        evidence: const FindingEvidence(
          observations: 10,
          independentUnits: 10,
          unit: EvidenceUnit.answerOccasion,
          spanDays: 7,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.metricValue, '70%');
      expect(presentation.metricLabel, 'Breakfast • 7 of 10');
      expect(presentation.title, 'What meal type was provided?');
      expect(presentation.highlights, isEmpty);
      expect(presentation.qualification, contains('more than 100%'));
      final graphic = presentation.graphic as DistributionGraphicData;
      expect(graphic.values, hasLength(4));
      expect(graphic.values.first.label, 'Breakfast');
      expect(graphic.values.first.emphasized, isTrue);
    });

    test('summarizes the most recorded category', () {
      final finding = CategoryDistributionFinding(
        findingId: 'category-distribution',
        ruleId: 'category_distribution',
        totalEntries: 12,
        categoryCounts: const {
          'pain': 5,
          'sleep': 3,
          'meal': 2,
          'mood': 1,
          'stress': 1,
        },
        evidence: const FindingEvidence(
          observations: 12,
          independentUnits: 7,
          unit: EvidenceUnit.day,
          spanDays: 7,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.eyebrow, 'Summary');
      expect(presentation.title, 'Most tracked category');
      expect(
        presentation.description,
        'Pain had the most entries in this period.',
      );
      expect(presentation.metricValue, '42%');
      expect(presentation.metricLabel, '5 of 12 entries');
      expect(presentation.highlights.single.label, 'Pain');
      expect(presentation.highlights.single.categoryId, 'pain');
      expect(presentation.qualification, contains('not symptom severity'));
      expect(presentation.qualification, contains('4 most recorded of 5'));
      final graphic = presentation.graphic as DistributionGraphicData;
      expect(graphic.values, hasLength(4));
      expect(graphic.values.map((value) => value.label), [
        'Pain',
        'Sleep',
        'Meal',
        'Mood',
      ]);
      expect(graphic.values.map((value) => value.count), [5, 3, 2, 1]);
      expect(graphic.values.first.emphasized, isTrue);
    });

    test('summarizes active-day coverage and longest streak', () {
      final finding = RecordingConsistencyFinding(
        findingId: 'recording-consistency',
        ruleId: 'recording_consistency',
        totalEntries: 9,
        windowDays: [for (var day = 1; day <= 7; day++) _day(day)],
        activeDays: [_day(1), _day(2), _day(4), _day(5), _day(6)],
        evidence: const FindingEvidence(
          observations: 9,
          independentUnits: 5,
          unit: EvidenceUnit.day,
          spanDays: 7,
          coverage: 5 / 7,
          coverageUnit: EvidenceUnit.day,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.eyebrow, 'Summary');
      expect(presentation.title, 'Recording consistency');
      expect(
        presentation.description,
        'Your longest logging streak was 3 consecutive days.',
      );
      expect(presentation.metricValue, '71%');
      expect(presentation.metricLabel, '5 of 7 days');
      expect(presentation.evidenceText, '9 recorded entries • 7-day period');
      expect(presentation.qualification, contains('A day counts once'));
      final graphic = presentation.graphic as ActivityStripGraphicData;
      expect(graphic.activeDays, [true, true, false, true, true, true, false]);
    });

    test('summarizes daily volume and marks tied busiest dates', () {
      final finding = DailyVolumeFinding(
        findingId: 'daily-volume',
        ruleId: 'daily_volume',
        totalEntries: 11,
        dailyCounts: {_day(1): 1, _day(2): 4, _day(3): 2, _day(4): 4},
        busiestDays: [_day(2), _day(4)],
        evidence: const FindingEvidence(
          observations: 11,
          independentUnits: 4,
          unit: EvidenceUnit.day,
          spanDays: 4,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.eyebrow, 'Summary');
      expect(presentation.title, 'One of your busiest dates');
      expect(
        presentation.description,
        'You averaged 2.8 entries per active day.',
      );
      expect(presentation.metricValue, 'Jan 4');
      expect(presentation.metricLabel, '4 entries');
      expect(presentation.evidenceText, '11 recorded entries • 4 active days');
      expect(presentation.qualification, contains('not symptom severity'));
      final graphic = presentation.graphic as HistogramGraphicData;
      expect(graphic.values.map((value) => value.label), [
        '1/1',
        '1/2',
        '1/3',
        '1/4',
      ]);
      expect(graphic.values.map((value) => value.count), [1, 4, 2, 4]);
      expect(graphic.values.map((value) => value.emphasized), [
        false,
        true,
        false,
        true,
      ]);
    });

    test('uses cautious language for a numeric association', () {
      final finding = NumericRelationshipFinding(
        findingId: 'relationship',
        ruleId: 'numeric_relationship',
        leftQuestionId: 'pain-level',
        rightQuestionId: 'sleep-quality',
        rho: -0.8,
        pairs: [_pair(1, 1, 3), _pair(2, 2, 2), _pair(3, 3, 1)],
        evidence: const FindingEvidence(
          observations: 6,
          independentUnits: 3,
          unit: EvidenceUnit.day,
          spanDays: 3,
          overlap: 3,
          effectSize: -0.8,
        ),
      );

      final presentation = FindingPresenterRegistry.standard().present(
        finding,
        _labels,
      );

      expect(presentation.eyebrow, 'Pattern');
      expect(presentation.title, startsWith('Possible'));
      expect(presentation.description, contains('On days when'));
      expect(presentation.qualification, contains('does not show'));
      expect(presentation.evidenceText, contains('3 shared days'));
    });

    test('does not invent copy for an unknown finding type', () {
      final presentation = FindingPresenterRegistry.standard().present(
        _UnknownFinding(),
        _labels,
      );

      expect(presentation.title, 'Additional finding');
      expect(presentation.description, contains('not supported'));
    });

    test('rhythm summaries show every hour and weekday bucket', () {
      const evidence = FindingEvidence(
        observations: 10,
        independentUnits: 7,
        unit: EvidenceUnit.day,
        spanDays: 7,
      );
      final peakHour = PeakHourFinding(
        findingId: 'hour',
        ruleId: 'peak_hour',
        peakHour: 17,
        totalEntries: 10,
        hourCounts: const {9: 2, 17: 4, 20: 4},
        categoryIds: const ['category.PAIN'],
        evidence: evidence,
      );
      final commonDay = MostCommonDayFinding(
        findingId: 'day',
        ruleId: 'most_common_day',
        weekday: DateTime.monday,
        totalEntries: 10,
        weekdayCounts: const {1: 3, 2: 2, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1},
        categoryIds: const ['category.PAIN'],
        evidence: evidence,
      );
      final registry = FindingPresenterRegistry.standard();

      final hourGraphic =
          registry.present(peakHour, _labels).graphic as HistogramGraphicData;
      final dayGraphic =
          registry.present(commonDay, _labels).graphic as HistogramGraphicData;

      expect(hourGraphic.values, hasLength(24));
      expect(hourGraphic.values[17].count, 4);
      expect(dayGraphic.values, hasLength(7));
      expect(dayGraphic.values.first.label, 'M');
    });
  });

  testWidgets('list separates patterns from summaries', (tester) async {
    const pattern = FindingPresentation(
      findingId: 'pattern',
      kind: FindingKind.observation,
      eyebrow: 'Pattern',
      title: 'Possible pattern',
      description: 'Description',
      evidenceText: '14 shared days',
      qualification: 'Association only.',
    );
    final summary = FindingPresentation(
      findingId: 'summary',
      kind: FindingKind.aggregate,
      eyebrow: 'Summary',
      title: 'Response summary',
      description: 'Description',
      evidenceText: '10 answers',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FindingsList(findings: [pattern, summary], compact: true),
          ),
        ),
      ),
    );

    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Summaries'), findsOneWidget);
    expect(find.text('Association only.'), findsOneWidget);
  });

  testWidgets('low-sample periods explain that more data is needed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EngineFindingsNotice(state: FindingFeedState.stillLearning),
        ),
      ),
    );

    expect(find.text('Not enough data for patterns'), findsOneWidget);
    expect(find.textContaining('more repeated logs'), findsOneWidget);
  });

  testWidgets('category theme highlights labels and paints stacked day cells', (
    tester,
  ) async {
    final summary = FindingPresentation(
      findingId: 'themed-summary',
      kind: FindingKind.aggregate,
      eyebrow: 'Summary',
      title: 'Logged on the same days',
      description: 'Same-day logging',
      evidenceText: '7-day period',
      metricValue: '75%',
      metricLabel: '3 of 4 active days',
      highlights: [
        FindingHighlight('Meal Time', categoryId: 'category.Meal-Time'),
        FindingHighlight('Pain', categoryId: 'category.PAIN'),
      ],
      categoryIds: ['category.Meal-Time', 'category.PAIN'],
      graphic: CoOccurrenceGraphicData(
        days: const [
          CoOccurrenceDayDatum(leftLogged: true, rightLogged: true),
          CoOccurrenceDayDatum(leftLogged: true, rightLogged: true),
          CoOccurrenceDayDatum(leftLogged: true, rightLogged: true),
          CoOccurrenceDayDatum(leftLogged: true, rightLogged: false),
        ],
        leftCategoryId: 'category.Meal-Time',
        rightCategoryId: 'category.PAIN',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(
            const StripesConfig.sandbox(
              betaUi: BetaUiConfig.disabled(useCategoryTheme: true),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: FindingsList(
                findings: [summary],
                showGroupHeadings: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CategoryIcon &&
            widget.appearance.svgAsset?.endsWith('/meal.svg') == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CategoryIcon &&
            widget.appearance.svgAsset?.endsWith('/pain.svg') == true,
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('co-occurrence-days')), findsOneWidget);
    expect(find.byKey(const Key('co-occurrence-day-0-left')), findsOneWidget);
    expect(find.byKey(const Key('co-occurrence-day-0-right')), findsOneWidget);
    expect(find.byKey(const Key('co-occurrence-day-3-left')), findsOneWidget);
    expect(find.byKey(const Key('co-occurrence-day-3-right')), findsOneWidget);
    final strip = find.byKey(const Key('co-occurrence-days'));
    final stripClips = find.descendant(
      of: strip,
      matching: find.byType(ClipRRect),
    );
    expect(stripClips, findsOneWidget);
    expect(
      tester.widget<ClipRRect>(stripClips).borderRadius,
      BorderRadius.circular(AppRounding.tiny),
    );
    expect(
      find.descendant(
        of: stripClips,
        matching: find.byKey(const Key('co-occurrence-day-0-left')),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('co-occurrence-day-0-left'))).height,
      greaterThan(0),
    );
  });

  testWidgets('distribution bars have a visible proportional fill', (
    tester,
  ) async {
    final summary = FindingPresentation(
      findingId: 'answers',
      kind: FindingKind.aggregate,
      eyebrow: 'Summary',
      title: 'What meal type was provided?',
      description: 'Recorded response distribution',
      evidenceText: '10 answers',
      metricValue: '70%',
      metricLabel: 'Breakfast • 7 of 10',
      graphic: DistributionGraphicData([
        FindingBarDatum(
          label: 'Breakfast',
          count: 7,
          total: 10,
          emphasized: true,
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: FindingsList(findings: [summary], showGroupHeadings: false),
          ),
        ),
      ),
    );

    final fill = tester.getSize(
      find.byKey(const Key('distribution-fill-Breakfast')),
    );
    expect(fill.width, greaterThan(100));
    expect(fill.height, 8);
  });

  testWidgets('long strips group the full period to the available width', (
    tester,
  ) async {
    Finder groupedSegments(String prefix) => find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          RegExp('^$prefix-group-[0-9]+\$').hasMatch(key.value);
    });

    final activity = FindingPresentation(
      findingId: 'long-activity',
      kind: FindingKind.aggregate,
      eyebrow: 'Summary',
      title: 'Recording consistency',
      description: 'Full period',
      evidenceText: '120-day period',
      graphic: ActivityStripGraphicData([
        for (var index = 0; index < 120; index++) index % 3 == 0,
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: FindingCard(finding: activity, compact: true),
          ),
        ),
      ),
    );

    final activityGroups = groupedSegments('activity');
    expect(activityGroups, findsWidgets);
    expect(activityGroups.evaluate().length, lessThan(120));
    expect(find.text('All 120 days · grouped to fit'), findsOneWidget);
    expect(find.textContaining('days per block'), findsOneWidget);
    expect(find.textContaining('darker = more days logged'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final coOccurrence = FindingPresentation(
      findingId: 'long-overlap',
      kind: FindingKind.aggregate,
      eyebrow: 'Summary',
      title: 'Logged on the same days',
      description: 'Full period',
      evidenceText: '120 active days',
      graphic: CoOccurrenceGraphicData(
        days: [
          for (var index = 0; index < 120; index++)
            CoOccurrenceDayDatum(
              leftLogged: index.isEven,
              rightLogged: !index.isEven || index % 5 == 0,
            ),
        ],
        leftCategoryId: 'pain',
        rightCategoryId: 'sleep',
        leftLabel: 'Pain',
        rightLabel: 'Sleep',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: FindingCard(finding: coOccurrence, compact: true),
          ),
        ),
      ),
    );

    final overlapGroups = groupedSegments('co-occurrence');
    expect(overlapGroups, findsWidgets);
    expect(overlapGroups.evaluate().length, lessThan(120));
    expect(find.text('All 120 active days · grouped to fit'), findsOneWidget);
    expect(find.textContaining('darker = logged more often'), findsOneWidget);
    final strip = find.byKey(const Key('co-occurrence-days'));
    expect(
      find.descendant(of: strip, matching: find.byType(ClipRRect)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

final _labels = FindingLabels(
  questionPromptKeys: const {
    'meal-type': 'meal_prompt',
    'pain-level': 'pain_prompt',
    'sleep-quality': 'sleep_prompt',
  },
  translate: (key) => const {
    'pain': 'Pain',
    'sleep': 'Sleep',
    'meal_prompt': 'What meal type was provided?',
    'pain_prompt': 'Pain level',
    'sleep_prompt': 'Sleep quality',
    'breakfast': 'Breakfast',
    'snack': 'Snack',
  }[key],
);

DateTime _day(int day) => DateTime(2025, 1, day);

InsightDailyNumericPair _pair(int day, double left, double right) =>
    InsightDailyNumericPair(
      day: _day(day),
      left: InsightDailyNumericValue(
        day: _day(day),
        value: left,
        observationCount: 1,
      ),
      right: InsightDailyNumericValue(
        day: _day(day),
        value: right,
        observationCount: 1,
      ),
    );

final class _UnknownFinding extends ObservationFinding {
  _UnknownFinding()
    : super(
        findingId: 'unknown',
        ruleId: 'unknown',
        evidence: const FindingEvidence(
          observations: 1,
          independentUnits: 1,
          unit: EvidenceUnit.entry,
          spanDays: 1,
        ),
      );
}
