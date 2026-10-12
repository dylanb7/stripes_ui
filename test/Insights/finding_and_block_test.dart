import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/finding_engine.dart';
import 'package:stripes_ui/Insights/Engine/insight_block.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Insights/Engine/prepared_feature.dart';

void main() {
  group('Finding', () {
    test('concrete finding types expose their fixed claim kind', () {
      final findings = <Finding>[
        _TestAggregateFinding(),
        _TestObservationFinding(),
        _TestAnomalyFinding(),
        _TestInferentialFinding(),
      ];

      expect(findings.map((finding) => finding.kind), [
        FindingKind.aggregate,
        FindingKind.observation,
        FindingKind.anomaly,
        FindingKind.inferential,
      ]);
    });

    test('defensively copies source IDs and exclusions', () {
      final sourceIds = <String>['entry-1'];
      final contributingIds = <String>['entry-1'];
      final exclusions = <FeatureExclusion>[
        const FeatureExclusion(
          code: FeatureExclusionCode.missingValue,
          count: 1,
        ),
      ];
      final finding = _TestAggregateFinding(
        sourceEntryIds: sourceIds,
        contributingEntryIds: contributingIds,
        exclusions: exclusions,
      );

      sourceIds.add('entry-2');
      contributingIds.clear();
      exclusions.add(
        const FeatureExclusion(code: FeatureExclusionCode.outOfRange, count: 1),
      );

      expect(finding.sourceEntryIds, {'entry-1'});
      expect(finding.contributingEntryIds, {'entry-1'});
      expect(finding.exclusions, hasLength(1));
      expect(
        () => finding.sourceEntryIds.add('entry-3'),
        throwsUnsupportedError,
      );
      expect(
        () => finding.exclusions.add(
          const FeatureExclusion(
            code: FeatureExclusionCode.unsupported,
            count: 1,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('PreparedFeature', () {
    test('defensively preserves evidence lineage through map', () {
      final sourceIds = <String>['entry-1'];
      final contributingIds = <String>['entry-1'];
      final dependencyKeys = <InsightBlockKeyBase>[
        InsightBlockKey<int>(_CountingBlock, 'source', ['question-a']),
      ];
      final exclusions = <FeatureExclusion>[
        const FeatureExclusion(
          code: FeatureExclusionCode.missingValue,
          count: 2,
        ),
      ];
      final prepared = PreparedFeature<int>(
        value: 4,
        evidence: _evidence,
        sourceEntryIds: sourceIds,
        contributingEntryIds: contributingIds,
        dependencyKeys: dependencyKeys,
        exclusions: exclusions,
      );

      sourceIds.add('entry-2');
      contributingIds.clear();
      dependencyKeys.add(InsightBlockKey<int>(_CountingBlock, 'other'));
      exclusions.clear();

      final mapped = prepared.map((value) => 'value:$value');

      expect(prepared.sourceEntryIds, {'entry-1'});
      expect(prepared.contributingEntryIds, {'entry-1'});
      expect(prepared.dependencyKeys, hasLength(1));
      expect(prepared.exclusions, hasLength(1));
      expect(prepared.excludedCount, 2);
      expect(mapped.value, 'value:4');
      expect(mapped.evidence, same(prepared.evidence));
      expect(mapped.sourceEntryIds, prepared.sourceEntryIds);
      expect(mapped.contributingEntryIds, prepared.contributingEntryIds);
      expect(mapped.dependencyKeys, prepared.dependencyKeys);
      expect(mapped.exclusions, orderedEquals(prepared.exclusions));
      expect(
        () => prepared.dependencyKeys.add(
          InsightBlockKey<int>(_CountingBlock, 'blocked'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('InsightBlockContext', () {
    test('equal-value keys compute once across distinct block instances', () {
      final calls = _Counter();
      final context = InsightBlockContext(dataset: _emptyDataset());

      final first = context.use(_CountingBlock('same', calls));
      final second = context.use(_CountingBlock('same', calls));

      expect(first, same(second));
      expect(first.value, 1);
      expect(calls.value, 1);
      expect(
        context.computationsFor(
          InsightBlockKey<int>(_CountingBlock, 'counting', ['same']),
        ),
        1,
      );
      expect(context.cachedBlockCount, 1);
    });

    test('different value keys compute independently', () {
      final calls = _Counter();
      final context = InsightBlockContext(dataset: _emptyDataset());

      final first = context.use(_CountingBlock('first', calls));
      final second = context.use(_CountingBlock('second', calls));

      expect(first.value, 1);
      expect(second.value, 2);
      expect(calls.value, 2);
      expect(context.cachedBlockCount, 2);
      expect(
        InsightBlockKey<int>(_CountingBlock, 'counting', ['first']),
        isNot(InsightBlockKey<int>(_CountingBlock, 'counting', ['second'])),
      );
      expect(
        InsightBlockKey<int>(_CountingBlock, 'counting', ['first']),
        isNot(InsightBlockKey<String>(_CountingBlock, 'counting', ['first'])),
      );
    });

    test('different block implementations cannot collide by namespace', () {
      final calls = _Counter();
      final context = InsightBlockContext(dataset: _emptyDataset());

      final first = context.use(_CountingBlock('same', calls));
      final second = context.use(_OtherCountingBlock('same', calls));

      expect(first.value, 1);
      expect(second.value, 2);
      expect(context.cachedBlockCount, 2);
    });

    test('rejects mutable collection parameters', () {
      expect(
        () => InsightBlockKey<int>(_CountingBlock, 'unsafe', [
          <int>[1, 2],
        ]),
        throwsArgumentError,
      );
    });

    test('detects cycles using equal-value keys', () {
      final context = InsightBlockContext(dataset: _emptyDataset());
      final key = InsightBlockKey<int>(_SelfCyclingBlock, 'self-cycle', ['a']);

      expect(
        () => context.use(const _SelfCyclingBlock('a')),
        throwsA(
          isA<InsightBlockCycleException>()
              .having((error) => error.cycle, 'cycle', [key, key])
              .having(
                (error) => error.toString(),
                'description',
                contains('self-cycle.v1<int>(a)'),
              ),
        ),
      );
      expect(context.cachedBlockCount, 0);
      expect(context.computationsFor(key), 1);
    });

    test('does not cache failures or leave a false active cycle', () {
      final attempts = _Counter();
      final context = InsightBlockContext(dataset: _emptyDataset());
      final key = InsightBlockKey<int>(_FlakyBlock, 'flaky', ['a']);

      expect(() => context.use(_FlakyBlock('a', attempts)), throwsStateError);
      expect(context.cachedBlockCount, 0);
      expect(context.computationsFor(key), 1);

      final recovered = context.use(_FlakyBlock('a', attempts));
      final cached = context.use(_FlakyBlock('a', attempts));

      expect(recovered.value, 2);
      expect(cached, same(recovered));
      expect(attempts.value, 2);
      expect(context.computationsFor(key), 2);
      expect(context.cachedBlockCount, 1);
    });

    test('memoization is local to one context', () {
      final calls = _Counter();
      final dataset = _emptyDataset();
      final firstContext = InsightBlockContext(dataset: dataset);
      final secondContext = InsightBlockContext(dataset: dataset);

      firstContext.use(_CountingBlock('shared', calls));
      firstContext.use(_CountingBlock('shared', calls));
      secondContext.use(_CountingBlock('shared', calls));

      expect(calls.value, 2);
      expect(firstContext.cachedBlockCount, 1);
      expect(secondContext.cachedBlockCount, 1);
    });
  });

  test('FindingEngine commits a rule atomically when iteration throws', () {
    final result = FindingEngine(
      rules: [_PartiallyThrowingRule()],
    ).evaluate(_emptyDataset());

    expect(result.accepted, isEmpty);
    expect(result.rejected, hasLength(1));
    expect(result.rejected.single.code, FindingRejectionCode.analysisFailed);
  });
}

const _evidence = FindingEvidence(
  observations: 1,
  independentUnits: 1,
  unit: EvidenceUnit.entry,
  spanDays: 1,
);

final class _TestAggregateFinding extends AggregateFinding {
  _TestAggregateFinding({
    super.sourceEntryIds,
    super.contributingEntryIds,
    super.exclusions,
  }) : super(findingId: 'aggregate', ruleId: 'test', evidence: _evidence);
}

final class _TestObservationFinding extends ObservationFinding {
  _TestObservationFinding()
    : super(findingId: 'observation', ruleId: 'test', evidence: _evidence);
}

final class _TestAnomalyFinding extends AnomalyFinding {
  _TestAnomalyFinding()
    : super(findingId: 'anomaly', ruleId: 'test', evidence: _evidence);
}

final class _TestInferentialFinding extends InferentialFinding {
  _TestInferentialFinding()
    : super(findingId: 'inferential', ruleId: 'test', evidence: _evidence);
}

final class _EngineTestFinding extends AggregateFinding {
  _EngineTestFinding()
    : super(findingId: 'partial', ruleId: 'partial-rule', evidence: _evidence);
}

class _PartiallyThrowingRule implements FindingRule {
  @override
  String get id => 'partial-rule';

  @override
  Iterable<FindingEvaluation> evaluate(InsightBlockContext context) sync* {
    yield AcceptedFindingEvaluation(finding: _EngineTestFinding());
    throw StateError('after a partial result');
  }
}

class _Counter {
  int value = 0;
}

class _CountingBlock implements InsightBlock<int> {
  final String parameter;
  final _Counter calls;

  const _CountingBlock(this.parameter, this.calls);

  @override
  InsightBlockKey<int> get key =>
      InsightBlockKey(_CountingBlock, 'counting', [parameter]);

  @override
  PreparedFeature<int> compute(InsightBlockContext context) {
    calls.value++;
    return PreparedFeature(value: calls.value, evidence: _evidence);
  }
}

class _SelfCyclingBlock implements InsightBlock<int> {
  final String parameter;

  const _SelfCyclingBlock(this.parameter);

  @override
  InsightBlockKey<int> get key =>
      InsightBlockKey(_SelfCyclingBlock, 'self-cycle', [parameter]);

  @override
  PreparedFeature<int> compute(InsightBlockContext context) =>
      context.use(_SelfCyclingBlock(parameter));
}

class _OtherCountingBlock implements InsightBlock<int> {
  final String parameter;
  final _Counter calls;

  const _OtherCountingBlock(this.parameter, this.calls);

  @override
  InsightBlockKey<int> get key =>
      InsightBlockKey(_OtherCountingBlock, 'counting', [parameter]);

  @override
  PreparedFeature<int> compute(InsightBlockContext context) {
    calls.value++;
    return PreparedFeature(value: calls.value, evidence: _evidence);
  }
}

class _FlakyBlock implements InsightBlock<int> {
  final String parameter;
  final _Counter attempts;

  const _FlakyBlock(this.parameter, this.attempts);

  @override
  InsightBlockKey<int> get key =>
      InsightBlockKey(_FlakyBlock, 'flaky', [parameter]);

  @override
  PreparedFeature<int> compute(InsightBlockContext context) {
    attempts.value++;
    if (attempts.value == 1) throw StateError('first attempt fails');
    return PreparedFeature(value: attempts.value, evidence: _evidence);
  }
}

InsightDataset _emptyDataset() => InsightDataset.fromEntries(
  const [],
  focusWindow: InsightTimeWindow(
    start: DateTime(2025, 1, 1),
    endExclusive: DateTime(2025, 1, 2),
  ),
);
