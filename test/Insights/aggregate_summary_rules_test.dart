import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Insights/Engine/Rules/aggregate_summary_rules.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

void main() {
  group('CategoryCoOccurrenceRule', () {
    test('emits an exact same-day co-logging summary', () {
      final dataset = _dataset([
        for (final day in [1, 2, 3, 4]) _emptyEntry('a-$day', 'a', day),
        for (final day in [2, 3, 4, 5]) _emptyEntry('b-$day', 'b', day),
      ]);

      final result = FindingEngine(rules: const [CategoryCoOccurrenceRule()])
          .evaluate(dataset);

      expect(result.rejected, isEmpty);
      final finding =
          result.accepted.single.finding as CategoryCoOccurrenceFinding;
      expect(finding.kind, FindingKind.aggregate);
      expect(finding.leftCategoryId, 'a');
      expect(finding.rightCategoryId, 'b');
      expect(finding.leftDayCount, 4);
      expect(finding.rightDayCount, 4);
      expect(finding.overlapDays, 3);
      expect(finding.sharedDays.map((day) => day.day), [2, 3, 4]);
      expect(finding.eligibleDays.map((day) => day.day), [1, 2, 3, 4, 5]);
      expect(finding.coOccurrenceRate, closeTo(0.6, 0.0001));
      expect(finding.evidence.observations, 8);
      expect(finding.evidence.independentUnits, 5);
      expect(finding.evidence.unit, EvidenceUnit.day);
      expect(finding.evidence.spanDays, 5);
      expect(finding.evidence.overlap, 3);
      expect(finding.evidence.coverage, isNull);
      expect(finding.evidence.coverageUnit, isNull);
      expect(finding.sourceEntryIds, hasLength(8));
      expect(finding.contributingEntryIds, finding.sourceEntryIds);
      expect(
        finding.findingId,
        FindingIdentity.build(
          ruleId: 'category_co_occurrence',
          components: const ['a', 'b', 'focus'],
        ),
      );
    });

    test('sorts pair output and IDs independently of input order', () {
      final entries = [
        for (final category in ['z', 'a', 'm'])
          for (var day = 1; day <= 3; day++)
            _emptyEntry('$category-$day', category, day),
      ];

      List<String> findingIds(Iterable<InsightEntry> input) =>
          FindingEngine(rules: const [CategoryCoOccurrenceRule()])
              .evaluate(_dataset(input))
              .findings
              .map((finding) => finding.findingId)
              .toList();

      expect(findingIds(entries.reversed), findingIds(entries));
      final findings = FindingEngine(rules: const [CategoryCoOccurrenceRule()])
          .evaluate(_dataset(entries.reversed))
          .findings
          .cast<CategoryCoOccurrenceFinding>();
      expect(
        findings.map(
          (finding) => '${finding.leftCategoryId}|${finding.rightCategoryId}',
        ),
        ['a|m', 'a|z', 'm|z'],
      );
    });

    test('returns a structured rejection below the overlap threshold', () {
      final dataset = _dataset([
        _emptyEntry('a-1', 'a', 1),
        _emptyEntry('a-2', 'a', 2),
        _emptyEntry('b-2', 'b', 2),
        _emptyEntry('b-3', 'b', 3),
      ]);

      final evaluation =
          const CategoryCoOccurrenceRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as RejectedFindingEvaluation;

      expect(evaluation.subjectId, 'a|b');
      expect(evaluation.code, FindingRejectionCode.insufficientOverlap);
      expect(evaluation.evidence.overlap, 1);
      expect(evaluation.evidence.independentUnits, 3);
      expect(evaluation.detail, contains('3 shared days'));
    });

    test('uses only focus-window entries', () {
      final dataset = _dataset([
        for (var day = 1; day <= 3; day++) ...[
          _emptyEntry('a-$day', 'a', day),
          _emptyEntry('b-$day', 'b', day),
        ],
        _emptyEntry('a-outside', 'a', 10),
        _emptyEntry('b-outside', 'b', 10),
      ], endExclusive: DateTime(2025, 1, 4));

      final finding =
          const CategoryCoOccurrenceRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as AcceptedFindingEvaluation;
      final value = finding.finding as CategoryCoOccurrenceFinding;

      expect(value.overlapDays, 3);
      expect(value.eligibleDays, hasLength(3));
      expect(value.sourceEntryIds, isNot(contains('a-outside')));
      expect(value.sourceEntryIds, isNot(contains('b-outside')));
    });
  });

  group('ChoiceDistributionRule', () {
    test('emits exact single-choice counts and a deterministic leader', () {
      final dataset = _choiceDataset([
        ['No'],
        ['Yes'],
        ['No'],
        ['Yes'],
        ['No'],
      ]);

      final result = FindingEngine(rules: const [ChoiceDistributionRule()])
          .evaluate(dataset);

      expect(result.rejected, isEmpty);
      final finding =
          result.accepted.single.finding as ChoiceDistributionFinding;
      expect(finding.kind, FindingKind.aggregate);
      expect(finding.questionId, 'blue-color');
      expect(finding.promptKey, 'questions.blue.latest');
      expect(finding.categoryIds, ['bowel-movement']);
      expect(finding.answerOccasions, 5);
      expect(finding.choiceSelections, 5);
      expect(finding.allowsMultiple, isFalse);
      expect(finding.choiceCounts.keys, ['No', 'Yes']);
      expect(finding.choiceCounts, {'No': 3, 'Yes': 2});
      expect(finding.leadingChoice, 'No');
      expect(finding.leadingChoiceCount, 3);
      expect(finding.leadingChoiceRate, closeTo(0.6, 0.0001));
      expect(finding.evidence.observations, 5);
      expect(finding.evidence.independentUnits, 5);
      expect(finding.evidence.unit, EvidenceUnit.answerOccasion);
      expect(finding.evidence.spanDays, 5);
      expect(
        finding.findingId,
        FindingIdentity.build(
          ruleId: 'choice_distribution',
          components: const ['blue-color', 'focus'],
        ),
      );
    });

    test(
      'counts each multi-select choice at most once per answer occasion',
      () {
        final dataset = _choiceDataset([
          ['A', 'A', 'B'],
          ['A', 'C'],
          ['B'],
          ['A', 'B'],
          ['C'],
        ], allowsMultiple: true);

        final evaluation =
            const ChoiceDistributionRule()
                    .evaluate(InsightBlockContext(dataset: dataset))
                    .single
                as AcceptedFindingEvaluation;
        final finding = evaluation.finding as ChoiceDistributionFinding;

        expect(finding.allowsMultiple, isTrue);
        expect(finding.answerOccasions, 5);
        expect(finding.choiceSelections, 8);
        expect(finding.choiceCounts, {'A': 3, 'B': 3, 'C': 2});
        expect(finding.leadingChoice, 'A');
        expect(finding.leadingChoiceRate, closeTo(0.6, 0.0001));
      },
    );

    test('sorts question findings and choice maps deterministically', () {
      final entries = <InsightEntry>[];
      for (final questionId in ['z-question', 'a-question']) {
        for (var day = 1; day <= 5; day++) {
          entries.add(
            _choiceEntry(
              entryId: '$questionId-$day',
              questionId: questionId,
              day: day,
              choices: day.isEven ? ['Zulu'] : ['Alpha'],
            ),
          );
        }
      }

      final findings = FindingEngine(rules: const [ChoiceDistributionRule()])
          .evaluate(_dataset(entries.reversed))
          .findings
          .cast<ChoiceDistributionFinding>();

      expect(findings.map((finding) => finding.questionId), [
        'a-question',
        'z-question',
      ]);
      expect(findings.first.choiceCounts.keys, ['Alpha', 'Zulu']);
    });

    test('returns a structured rejection below the answer threshold', () {
      final dataset = _choiceDataset([
        ['No'],
        ['Yes'],
        ['No'],
        ['Yes'],
      ]);

      final evaluation =
          const ChoiceDistributionRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as RejectedFindingEvaluation;

      expect(evaluation.subjectId, 'blue-color');
      expect(evaluation.code, FindingRejectionCode.insufficientObservations);
      expect(evaluation.evidence.independentUnits, 4);
      expect(evaluation.detail, contains('5 answer occasions'));
    });
  });

  group('CategoryDistributionRule', () {
    test('reports exact counts and resolves a tied lead alphabetically', () {
      final dataset = _dataset(
        [
          _emptyEntry('beta-1', 'beta', 1),
          _emptyEntry('alpha-1', 'alpha', 1),
          _emptyEntry('gamma-2', 'gamma', 2),
          _emptyEntry('beta-3', 'beta', 3),
          _emptyEntry('alpha-4', 'alpha', 4),
        ].reversed,
      );

      final evaluation =
          const CategoryDistributionRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as AcceptedFindingEvaluation;
      final finding = evaluation.finding as CategoryDistributionFinding;

      expect(finding.totalEntries, 5);
      expect(finding.categoryCounts.keys, ['alpha', 'beta', 'gamma']);
      expect(finding.categoryCounts, {'alpha': 2, 'beta': 2, 'gamma': 1});
      expect(finding.leadingCategoryId, 'alpha');
      expect(finding.leadingCategoryCount, 2);
      expect(finding.leadingCategoryRate, closeTo(0.4, 0.0001));
      expect(finding.hasTiedLead, isTrue);
      expect(finding.evidence.observations, 5);
      expect(finding.evidence.independentUnits, 4);
      expect(finding.evidence.spanDays, 4);
    });

    test('rejects below its entry and category thresholds', () {
      final tooFewEntries =
          const CategoryDistributionRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        _emptyEntry('a-1', 'a', 1),
                        _emptyEntry('b-1', 'b', 1),
                        _emptyEntry('a-2', 'a', 2),
                        _emptyEntry('b-2', 'b', 2),
                      ]),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;
      final oneCategory =
          const CategoryDistributionRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        for (var day = 1; day <= 5; day++)
                          _emptyEntry('a-$day', 'a', day),
                      ]),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;

      expect(tooFewEntries.code, FindingRejectionCode.insufficientObservations);
      expect(tooFewEntries.evidence.observations, 4);
      expect(oneCategory.code, FindingRejectionCode.insufficientVariance);
      expect(oneCategory.evidence.observations, 5);
    });
  });

  group('RecordingConsistencyRule', () {
    test('reports exact coverage and the longest ordered streak', () {
      final dataset = _dataset([
        _emptyEntry('day-6', 'a', 6),
        _emptyEntry('day-5-b', 'b', 5),
        _emptyEntry('day-5-a', 'a', 5),
        _emptyEntry('day-4', 'a', 4),
        _emptyEntry('day-2', 'a', 2),
        _emptyEntry('day-1', 'a', 1),
      ], endExclusive: DateTime(2025, 1, 8));

      final evaluation =
          const RecordingConsistencyRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as AcceptedFindingEvaluation;
      final finding = evaluation.finding as RecordingConsistencyFinding;

      expect(finding.totalEntries, 6);
      expect(finding.windowDays.map((day) => day.day), [1, 2, 3, 4, 5, 6, 7]);
      expect(finding.activeDays.map((day) => day.day), [1, 2, 4, 5, 6]);
      expect(finding.activeDayCount, 5);
      expect(finding.coverageRate, closeTo(5 / 7, 0.0001));
      expect(finding.longestStreak, 3);
      expect(finding.evidence.observations, 6);
      expect(finding.evidence.independentUnits, 5);
      expect(finding.evidence.spanDays, 7);
      expect(finding.evidence.coverage, closeTo(5 / 7, 0.0001));
    });

    test('rejects below its window and active-day thresholds', () {
      final shortWindow =
          const RecordingConsistencyRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        _emptyEntry('day-1', 'a', 1),
                        _emptyEntry('day-2', 'a', 2),
                      ], endExclusive: DateTime(2025, 1, 3)),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;
      final tooFewActiveDays =
          const RecordingConsistencyRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        _emptyEntry('day-1-a', 'a', 1),
                        _emptyEntry('day-1-b', 'b', 1),
                      ], endExclusive: DateTime(2025, 1, 5)),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;

      expect(shortWindow.code, FindingRejectionCode.insufficientSpan);
      expect(shortWindow.evidence.spanDays, 2);
      expect(
        tooFewActiveDays.code,
        FindingRejectionCode.insufficientIndependentUnits,
      );
      expect(tooFewActiveDays.evidence.independentUnits, 1);
    });
  });

  group('DailyVolumeRule', () {
    test('reports exact volume and features the latest tied busiest day', () {
      final dataset = _dataset([
        _emptyEntry('day-3-b', 'b', 3),
        _emptyEntry('day-1-b', 'b', 1),
        _emptyEntry('day-2', 'a', 2),
        _emptyEntry('day-3-a', 'a', 3),
        _emptyEntry('day-1-a', 'a', 1),
      ]);

      final evaluation =
          const DailyVolumeRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as AcceptedFindingEvaluation;
      final finding = evaluation.finding as DailyVolumeFinding;

      expect(finding.totalEntries, 5);
      expect(finding.dailyCounts.keys.map((day) => day.day), [1, 2, 3]);
      expect(finding.dailyCounts, {_day(1): 2, _day(2): 1, _day(3): 2});
      expect(finding.activeDayCount, 3);
      expect(finding.busiestDays, [_day(1), _day(3)]);
      expect(finding.busiestEntryCount, 2);
      expect(finding.featuredBusiestDay, _day(3));
      expect(finding.hasTiedBusiestDay, isTrue);
      expect(finding.averagePerActiveDay, closeTo(5 / 3, 0.0001));
      expect(finding.evidence.observations, 5);
      expect(finding.evidence.independentUnits, 3);
      expect(finding.evidence.spanDays, 3);
    });

    test('rejects below its entry and active-day thresholds', () {
      final tooFewEntries =
          const DailyVolumeRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        _emptyEntry('day-1-a', 'a', 1),
                        _emptyEntry('day-1-b', 'b', 1),
                        _emptyEntry('day-2', 'a', 2),
                        _emptyEntry('day-3', 'a', 3),
                      ]),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;
      final tooFewActiveDays =
          const DailyVolumeRule()
                  .evaluate(
                    InsightBlockContext(
                      dataset: _dataset([
                        _emptyEntry('day-1-a', 'a', 1),
                        _emptyEntry('day-1-b', 'b', 1),
                        _emptyEntry('day-1-c', 'c', 1),
                        _emptyEntry('day-2-a', 'a', 2),
                        _emptyEntry('day-2-b', 'b', 2),
                      ]),
                    ),
                  )
                  .single
              as RejectedFindingEvaluation;

      expect(tooFewEntries.code, FindingRejectionCode.insufficientObservations);
      expect(tooFewEntries.evidence.observations, 4);
      expect(
        tooFewActiveDays.code,
        FindingRejectionCode.insufficientIndependentUnits,
      );
      expect(tooFewActiveDays.evidence.independentUnits, 2);
    });
  });

  group('logging rhythm summaries', () {
    test('PeakHourRule reports the exact busiest local hour', () {
      final dataset = _dataset([
        _emptyEntry('one', 'a', 1, hour: 9),
        _emptyEntry('two', 'b', 1, hour: 9),
        _emptyEntry('three', 'a', 2, hour: 9),
        _emptyEntry('four', 'a', 3, hour: 9),
        _emptyEntry('five', 'a', 4, hour: 9),
        _emptyEntry('six', 'a', 4, hour: 14),
        _emptyEntry('seven', 'a', 5, hour: 14),
        _emptyEntry('eight', 'a', 5, hour: 14),
        _emptyEntry('nine', 'a', 6, hour: 18),
        _emptyEntry('ten', 'a', 6, hour: 20),
      ]);

      final evaluation =
          const PeakHourRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as AcceptedFindingEvaluation;
      final finding = evaluation.finding as PeakHourFinding;

      expect(finding.peakHour, 9);
      expect(finding.peakEntryCount, 5);
      expect(finding.totalEntries, 10);
      expect(finding.hourCounts, {9: 5, 14: 3, 18: 1, 20: 1});
      expect(finding.categoryIds, ['a', 'b']);
      expect(finding.evidence.independentUnits, 6);
    });

    test('MostCommonDayRule uses a deterministic weekday tie break', () {
      final monday = DateTime(2025, 1, 6);
      final entries = [
        InsightEntry(entryId: 'm1', categoryId: 'a', occurredAt: monday),
        InsightEntry(
          entryId: 'm2',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 13),
        ),
        InsightEntry(
          entryId: 't1',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 7),
        ),
        InsightEntry(
          entryId: 't2',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 14),
        ),
        InsightEntry(
          entryId: 'w1',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 8),
        ),
        InsightEntry(
          entryId: 'th1',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 9),
        ),
        InsightEntry(
          entryId: 'f1',
          categoryId: 'a',
          occurredAt: DateTime(2025, 1, 10),
        ),
      ];
      final evaluation =
          const MostCommonDayRule()
                  .evaluate(InsightBlockContext(dataset: _dataset(entries)))
                  .single
              as AcceptedFindingEvaluation;
      final finding = evaluation.finding as MostCommonDayFinding;

      expect(finding.weekday, DateTime.monday);
      expect(finding.commonDayEntryCount, 2);
      expect(finding.hasTiedPeak, isTrue);
      expect(finding.weekdayCounts, {1: 2, 2: 2, 3: 1, 4: 1, 5: 1});
    });

    test('rhythm summaries enforce their minimum entry thresholds', () {
      final dataset = _dataset([
        for (var day = 1; day <= 4; day++) _emptyEntry('$day', 'a', day),
      ]);

      for (final rule in const <FindingRule>[
        PeakHourRule(),
        MostCommonDayRule(),
      ]) {
        final evaluation =
            rule.evaluate(InsightBlockContext(dataset: dataset)).single
                as RejectedFindingEvaluation;
        expect(evaluation.code, FindingRejectionCode.insufficientObservations);
      }
    });

    test('MostCommonDayRule requires a full week window and data span', () {
      final dataset = _dataset([
        for (var index = 0; index < 7; index++)
          _emptyEntry('$index', 'a', 1 + (index % 6)),
      ], endExclusive: DateTime(2025, 1, 7));

      final evaluation =
          const MostCommonDayRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as RejectedFindingEvaluation;

      expect(evaluation.code, FindingRejectionCode.insufficientSpan);
      expect(evaluation.detail, contains('7-day window'));
    });

    test('PeakHourRule rejects a diffuse distribution below its cutoff', () {
      final dataset = _dataset([
        for (var hour = 0; hour < 24; hour++)
          _emptyEntry('hour-$hour', 'a', 1 + (hour % 6), hour: hour),
      ]);

      final evaluation =
          const PeakHourRule()
                  .evaluate(InsightBlockContext(dataset: dataset))
                  .single
              as RejectedFindingEvaluation;

      expect(evaluation.code, FindingRejectionCode.effectTooSmall);
      expect(evaluation.detail, contains('15%'));
    });
  });
}

InsightDataset _dataset(
  Iterable<InsightEntry> entries, {
  DateTime? endExclusive,
}) => InsightDataset.fromEntries(
  entries,
  focusWindow: InsightTimeWindow(
    start: DateTime(2025, 1, 1),
    endExclusive: endExclusive ?? DateTime(2025, 2, 1),
  ),
);

InsightEntry _emptyEntry(
  String entryId,
  String categoryId,
  int day, {
  int hour = 9,
}) => InsightEntry(
  entryId: entryId,
  categoryId: categoryId,
  occurredAt: DateTime(2025, 1, day, hour),
  timePrecision: InsightTimePrecision.exact,
);

DateTime _day(int day) => DateTime(2025, 1, day);

InsightDataset _choiceDataset(
  List<List<String>> answers, {
  bool allowsMultiple = false,
}) => _dataset([
  for (var index = 0; index < answers.length; index++)
    _choiceEntry(
      entryId: 'choice-${index + 1}',
      questionId: 'blue-color',
      day: index + 1,
      choices: answers[index],
      allowsMultiple: allowsMultiple,
      promptKey: index == answers.length - 1
          ? 'questions.blue.latest'
          : 'questions.blue.old',
    ),
]);

InsightEntry _choiceEntry({
  required String entryId,
  required String questionId,
  required int day,
  required List<String> choices,
  bool allowsMultiple = false,
  String promptKey = 'questions.choice',
}) {
  final occurredAt = DateTime(2025, 1, day, 9);
  return InsightEntry(
    entryId: entryId,
    categoryId: 'bowel-movement',
    occurredAt: occurredAt,
    observations: [
      InsightObservation(
        entryId: entryId,
        questionId: questionId,
        promptKey: promptKey,
        categoryId: 'bowel-movement',
        occurredAt: occurredAt,
        value: ChoiceInsightValue(
          choices: choices,
          allowsMultiple: allowsMultiple,
        ),
      ),
    ],
  );
}
