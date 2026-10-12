import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Insights/insights.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';

void main() {
  group('finding windows', () {
    test('History keeps an existing exclusive end unchanged', () {
      final windows = findingWindowsForHistoryRange(
        DateTimeRange(start: DateTime(2025, 1, 1), end: DateTime(2025, 1, 8)),
      );

      expect(windows.focus.start, DateTime(2025, 1, 1));
      expect(windows.focus.endExclusive, DateTime(2025, 1, 8));
      expect(windows.focus.calendarDays, 7);
      expect(windows.reference?.endExclusive, DateTime(2025, 1, 1));
      expect(windows.reference?.start, DateTime(2024, 12, 2));
    });

    test('Dashboard converts an inclusive final date to an exclusive end', () {
      final windows = findingWindowsForDashboardRange(
        DateTimeRange(start: DateTime(2025, 1, 1), end: DateTime(2025, 1, 7)),
      );

      expect(windows.focus.start, DateTime(2025, 1, 1));
      expect(windows.focus.endExclusive, DateTime(2025, 1, 8));
      expect(windows.focus.calendarDays, 7);
    });

    test('History can convert its inclusive all-time final date', () {
      final windows = findingWindowsForHistoryRange(
        DateTimeRange(start: DateTime(2025, 1, 1), end: DateTime(2025, 1, 7)),
        includeReference: false,
        inclusiveEnd: true,
      );

      expect(windows.focus.endExclusive, DateTime(2025, 1, 8));
      expect(windows.focus.calendarDays, 7);
      expect(windows.reference, isNull);
    });

    test('reference window scales with longer focus periods', () {
      final windows = findingWindowsForHistoryRange(
        DateTimeRange(start: DateTime(2025, 4, 1), end: DateTime(2025, 5, 1)),
      );

      expect(windows.reference?.endExclusive, DateTime(2025, 4, 1));
      expect(windows.reference?.calendarDays, 90);
    });
  });

  test('run retains full input while rules evaluate the focus scope', () {
    final windows = FindingWindows(
      reference: InsightTimeWindow(
        start: DateTime(2025, 1, 1),
        endExclusive: DateTime(2025, 1, 10),
      ),
      focus: InsightTimeWindow(
        start: DateTime(2025, 1, 10),
        endExclusive: DateTime(2025, 1, 20),
      ),
    );
    final run = runFindingsFromResponses(
      responses: [
        _choiceEntry('reference', DateTime(2025, 1, 5), 0),
        for (var day = 10; day < 15; day++)
          _choiceEntry(
            'focus-$day',
            DateTime(2025, 1, day),
            day.isEven ? 0 : 1,
          ),
      ],
      windows: windows,
      catalog: const InsightAnalysisCatalog.empty(),
      rules: const [ChoiceDistributionRule()],
    );

    expect(run.dataset.entries(scope: InsightDatasetScope.all), hasLength(6));
    expect(
      run.dataset.entries(scope: InsightDatasetScope.reference),
      hasLength(1),
    );
    expect(run.dataset.entries(), hasLength(5));
    final finding = run.result.findings.single as ChoiceDistributionFinding;
    expect(finding.answerOccasions, 5);
  });

  test('feed distinguishes no data from a low-sample learning state', () {
    final windows = FindingWindows(
      focus: InsightTimeWindow(
        start: DateTime(2025, 1, 1),
        endExclusive: DateTime(2025, 1, 8),
      ),
    );
    FindingFeed run(Iterable<Response> responses) => buildFindingFeed(
      runFindingsFromResponses(
        responses: responses,
        windows: windows,
        catalog: const InsightAnalysisCatalog.empty(),
        rules: const [ChoiceDistributionRule()],
      ),
    );

    expect(run(const []).state, FindingFeedState.noData);
    expect(
      run([_choiceEntry('one', DateTime(2025, 1, 2), 0)]).state,
      FindingFeedState.stillLearning,
    );
  });

  test('feed ranks accepted claim kinds and applies its result limit', () {
    final aggregate = _AggregateTestFinding(
      findingId: 'aggregate',
      evidence: _evidence(independentUnits: 30),
    );
    final observation = _ObservationTestFinding(
      findingId: 'observation',
      evidence: _evidence(independentUnits: 5),
    );
    final run = FindingRun(
      dataset: InsightDataset.fromEntries(
        const [],
        focusWindow: InsightTimeWindow(
          start: DateTime(2025, 1, 1),
          endExclusive: DateTime(2025, 1, 2),
        ),
      ),
      result: FindingEngineResult(
        accepted: [
          AcceptedFindingEvaluation(finding: aggregate),
          AcceptedFindingEvaluation(finding: observation),
        ],
        rejected: const [],
      ),
    );

    final feed = buildFindingFeed(
      run,
      policy: FindingFeedPolicy(maximumFindings: 1),
    );

    expect(feed.ranked, hasLength(1));
    expect(feed.findings.single.findingId, 'observation');
    expect(feed.run.result.accepted, hasLength(2));
  });

  test('feed caps summaries separately so they cannot crowd out patterns', () {
    final findings = <Finding>[
      _AggregateTestFinding(
        findingId: 'aggregate-a',
        evidence: _evidence(independentUnits: 30),
      ),
      _AggregateTestFinding(
        findingId: 'aggregate-b',
        evidence: _evidence(independentUnits: 20),
      ),
      _ObservationTestFinding(
        findingId: 'observation-a',
        evidence: _evidence(independentUnits: 10),
      ),
      _ObservationTestFinding(
        findingId: 'observation-b',
        evidence: _evidence(independentUnits: 8),
      ),
    ];
    final run = FindingRun(
      dataset: InsightDataset.fromEntries(
        const [],
        focusWindow: InsightTimeWindow(
          start: DateTime(2025, 1, 1),
          endExclusive: DateTime(2025, 1, 2),
        ),
      ),
      result: FindingEngineResult(
        accepted: findings.map(
          (finding) => AcceptedFindingEvaluation(finding: finding),
        ),
        rejected: const [],
      ),
    );

    final feed = buildFindingFeed(
      run,
      policy: FindingFeedPolicy(
        maximumFindings: 3,
        maximumPatternFindings: 2,
        maximumAggregateFindings: 1,
      ),
    );

    expect(feed.findings.map((finding) => finding.kind), [
      FindingKind.observation,
      FindingKind.observation,
      FindingKind.aggregate,
    ]);
  });

  test('default providers are overrideable and use aggregate-only rules', () {
    final replacementCatalog = InsightAnalysisCatalog.fromMap(const {
      'schemaVersion': 1,
      'questions': {
        'custom': {'measurement': 'continuous', 'aggregation': 'mean'},
      },
    });
    final container = ProviderContainer(
      overrides: [
        insightAnalysisCatalogProvider.overrideWithValue(replacementCatalog),
        insightFindingRulesProvider.overrideWithValue(const [
          ChoiceDistributionRule(),
        ]),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(insightAnalysisCatalogProvider), replacementCatalog);
    expect(
      container.read(insightFindingRulesProvider).single,
      isA<ChoiceDistributionRule>(),
    );
  });

  test('default feed exposes the expanded exact-summary rule set', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(insightFindingRulesProvider), [
      isA<PeakHourRule>(),
      isA<RecordingConsistencyRule>(),
      isA<MostCommonDayRule>(),
      isA<CategoryDistributionRule>(),
      isA<DailyVolumeRule>(),
      isA<CategoryCoOccurrenceRule>(),
      isA<ChoiceDistributionRule>(),
    ]);
    expect(container.read(historyFindingFeedPolicyProvider).maximumFindings, 7);
    expect(
      container.read(dashboardFindingFeedPolicyProvider).maximumFindings,
      4,
    );
  });
}

const _choiceQuestion = MultipleChoice(
  id: 'choice',
  prompt: 'questions.choice',
  type: 'category.TEST',
  choices: ['one', 'two'],
);

DetailResponse _choiceEntry(String id, DateTime at, int index) =>
    DetailResponse(
      id: id,
      stamp: dateToStamp(at),
      detailType: _choiceQuestion.type,
      responses: [
        MultiResponse(
          question: _choiceQuestion,
          stamp: dateToStamp(at),
          index: index,
        ),
      ],
    );

FindingEvidence _evidence({required int independentUnits}) => FindingEvidence(
  observations: independentUnits,
  independentUnits: independentUnits,
  unit: EvidenceUnit.day,
  spanDays: independentUnits,
  coverage: 1,
);

final class _AggregateTestFinding extends AggregateFinding {
  _AggregateTestFinding({required super.findingId, required super.evidence})
    : super(ruleId: 'aggregate-test');
}

final class _ObservationTestFinding extends ObservationFinding {
  _ObservationTestFinding({required super.findingId, required super.evidence})
    : super(ruleId: 'observation-test');
}
