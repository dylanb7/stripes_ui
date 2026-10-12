import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Insights/Engine/Blocks/numeric_blocks.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';

void main() {
  group('numeric preparation blocks', () {
    test(
      'validates normalized values and preserves excluded-source lineage',
      () {
        final dataset = _dataset([
          _numericEntry('valid', DateTime(2025, 1, 1), 'a', 5),
          _numericEntry('missing', DateTime(2025, 1, 2), 'a', -1),
          _numericEntry('out-of-range', DateTime(2025, 1, 3), 'a', 11),
        ]);
        final context = InsightBlockContext(dataset: dataset);

        final prepared = context.use(
          const NumericObservationsBlock(
            questionId: 'a',
            eligibleForGenericAnalysis: true,
          ),
        );

        expect(prepared.value.map((item) => item.value), [5]);
        expect(prepared.sourceEntryIds, {'valid', 'missing', 'out-of-range'});
        expect(prepared.evidence.observations, 1);
        expect(prepared.evidence.independentUnits, 1);
        expect(prepared.evidence.coverage, closeTo(1 / 3, 0.000001));
        expect(
          _exclusionCount(
            prepared.exclusions,
            FeatureExclusionCode.missingValue,
          ),
          1,
        );
        expect(
          _exclusionCount(prepared.exclusions, FeatureExclusionCode.outOfRange),
          1,
        );
      },
    );

    test(
      'pairs shared days while retaining transitive lineage and exclusions',
      () {
        final dataset = _dataset([
          _numericEntry('a-day-1', DateTime(2025, 1, 1, 8), 'a', 1),
          _numericEntry('b-day-1', DateTime(2025, 1, 1, 9), 'b', 2),
          _numericEntry('a-day-2', DateTime(2025, 1, 2), 'a', 3),
          _numericEntry('b-day-3', DateTime(2025, 1, 3), 'b', 4),
          _numericEntry('b-missing', DateTime(2025, 1, 4), 'b', -1),
        ]);
        final context = InsightBlockContext(dataset: dataset);
        const block = PairedDailyNumericBlock(
          leftQuestionId: 'a',
          rightQuestionId: 'b',
          leftAggregation: InsightAggregation.mean,
          rightAggregation: InsightAggregation.mean,
          eligibleForGenericAnalysis: true,
        );

        final prepared = context.use(block);

        expect(prepared.value, hasLength(1));
        expect(prepared.value.single.day, DateTime(2025, 1, 1));
        expect(prepared.evidence.observations, 2);
        expect(prepared.evidence.independentUnits, 1);
        expect(prepared.evidence.unit, EvidenceUnit.day);
        expect(prepared.evidence.overlap, 1);
        expect(prepared.evidence.coverage, closeTo(1 / 3, 0.000001));
        expect(prepared.sourceEntryIds, {
          'a-day-1',
          'b-day-1',
          'a-day-2',
          'b-day-3',
          'b-missing',
        });
        expect(prepared.contributingEntryIds, {'a-day-1', 'b-day-1'});
        expect(
          _exclusionCount(
            prepared.exclusions,
            FeatureExclusionCode.unpairedUnit,
          ),
          2,
        );
        expect(
          _exclusionCount(
            prepared.exclusions,
            FeatureExclusionCode.missingValue,
          ),
          1,
        );
        expect(prepared.dependencyKeys, contains(block.leftBlock.key));
        expect(prepared.dependencyKeys, contains(block.rightBlock.key));
        expect(context.computationsFor(block.leftBlock.key), 1);
        expect(context.computationsFor(block.rightBlock.key), 1);
      },
    );
  });
}

InsightDataset _dataset(Iterable<InsightEntry> entries) =>
    InsightDataset.fromEntries(
      entries,
      focusWindow: InsightTimeWindow(
        start: DateTime(2025, 1, 1),
        endExclusive: DateTime(2025, 2, 1),
      ),
      catalog: InsightAnalysisCatalog.fromMap({
        'questions': {
          for (final questionId in ['a', 'b'])
            questionId: {
              'measurement': 'ordinal',
              'aggregation': 'mean',
              'validRange': [0, 10],
              'missingValues': [-1],
            },
        },
      }),
    );

InsightEntry _numericEntry(
  String entryId,
  DateTime occurredAt,
  String questionId,
  double value,
) => InsightEntry(
  entryId: entryId,
  categoryId: 'category.SYMPTOM',
  occurredAt: occurredAt,
  observations: [
    InsightObservation(
      entryId: entryId,
      questionId: questionId,
      promptKey: 'questions.$questionId',
      categoryId: 'category.SYMPTOM',
      occurredAt: occurredAt,
      value: NumericInsightValue(value),
    ),
  ],
);

int _exclusionCount(
  Iterable<FeatureExclusion> exclusions,
  FeatureExclusionCode code,
) => exclusions
    .where((exclusion) => exclusion.code == code)
    .fold(0, (total, exclusion) => total + exclusion.count);
