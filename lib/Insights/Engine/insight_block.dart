import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Insights/Engine/insight_block_key.dart';
import 'package:stripes_ui/Insights/Engine/prepared_feature.dart';

export 'insight_block_key.dart';

abstract interface class InsightBlock<T> {
  InsightBlockKey<T> get key;

  PreparedFeature<T> compute(InsightBlockContext context);
}

class InsightBlockCycleException implements Exception {
  final List<InsightBlockKeyBase> cycle;

  InsightBlockCycleException(Iterable<InsightBlockKeyBase> cycle)
    : cycle = List.unmodifiable(cycle);

  @override
  String toString() => 'InsightBlockCycleException: ${cycle.join(' -> ')}';
}

/// Shared, memoized feature context used by every rule in one engine run.
class InsightBlockContext {
  final InsightDataset dataset;
  final Map<InsightBlockKeyBase, Object> _cache = {};
  final List<InsightBlockKeyBase> _active = [];
  final Map<InsightBlockKeyBase, int> _computationCounts = {};

  InsightBlockContext({required this.dataset});

  PreparedFeature<T> use<T>(InsightBlock<T> block) {
    final key = block.key;
    final cached = _cache[key];
    if (cached != null) return cached as PreparedFeature<T>;

    final cycleStart = _active.indexOf(key);
    if (cycleStart >= 0) {
      throw InsightBlockCycleException([..._active.skip(cycleStart), key]);
    }

    _active.add(key);
    try {
      _computationCounts[key] = (_computationCounts[key] ?? 0) + 1;
      final prepared = block.compute(this);
      _cache[key] = prepared;
      return prepared;
    } finally {
      _active.removeLast();
    }
  }

  int computationsFor<T>(InsightBlockKey<T> key) =>
      _computationCounts[key] ?? 0;

  int get cachedBlockCount => _cache.length;
}
