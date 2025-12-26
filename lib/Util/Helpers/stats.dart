import 'dart:math';

class PeakWindow {
  final int startHour;
  final int endHour;
  final double score;
  final int count;

  const PeakWindow({
    required this.startHour,
    required this.endHour,
    required this.score,
    required this.count,
  });

  /// Duration in hours, handles wraparound (e.g., 10pm-2am = 5 hours)
  int get duration {
    if (startHour <= endHour) {
      return endHour - startHour + 1;
    } else {
      // Wraparound case: hours from start to midnight + midnight to end
      return (24 - startHour) + (endHour + 1);
    }
  }

  @override
  String toString() =>
      'PeakWindow($startHour:00-$endHour:00, count: $count, score: $score)';
}

PeakWindow findPeakWindow(
  List<int> hourlyCounts, {
  double? costPerHour,
}) {
  assert(
      hourlyCounts.length == 24, 'hourlyCounts must have exactly 24 entries');

  final totalEntries = hourlyCounts.fold(0, (sum, c) => sum + c);
  if (totalEntries == 0) {
    return const PeakWindow(startHour: 0, endHour: 23, score: 0, count: 0);
  }

  // Cost = average entries per hour * 1.5 (to favor more constrained peaks).
  final effectiveCost = costPerHour ?? (totalEntries / 24.0) * 1.5;

  // Double the array to handle wraparound (e.g., 10pm-2am peaks)
  final doubled = [...hourlyCounts, ...hourlyCounts];
  final profits = doubled.map((c) => c - effectiveCost).toList();

  double maxScore = double.negativeInfinity;
  int bestStart = 0;
  int bestEnd = 0;

  double currentScore = 0;
  int currentStart = 0;

  // Scan through 48 hours but limit window size to 24 hours
  for (int i = 0; i < 48; i++) {
    currentScore += profits[i];

    // Shrink window if it exceeds 24 hours
    while (i - currentStart >= 24) {
      currentScore -= profits[currentStart];
      currentStart++;
    }

    if (currentScore > maxScore) {
      maxScore = currentScore;
      bestStart = currentStart;
      bestEnd = i;
    }

    if (currentScore < 0) {
      currentScore = 0;
      currentStart = i + 1;
    }
  }

  // Map back to 0-23 range
  final startHour = bestStart % 24;
  final endHour = bestEnd % 24;

  int windowCount = 0;
  if (startHour <= endHour) {
    for (int i = startHour; i <= endHour; i++) {
      windowCount += hourlyCounts[i];
    }
  } else {
    // Wraparound case
    for (int i = startHour; i < 24; i++) {
      windowCount += hourlyCounts[i];
    }
    for (int i = 0; i <= endHour; i++) {
      windowCount += hourlyCounts[i];
    }
  }

  return PeakWindow(
    startHour: startHour,
    endHour: endHour,
    score: maxScore,
    count: windowCount,
  );
}

class LoessResult {
  final List<double> x;
  final List<double> smoothedY;

  const LoessResult({required this.x, required this.smoothedY});
}

/// [x] and [y] must have the same length and at least 3 points.
///
/// [bandwidth] controls smoothness (0.0-1.0):
/// - Higher values = smoother curve (more points influence each fit)
/// - Lower values = more local detail preserved
/// - Default 0.3 works well for most data
///
/// [robustnessIterations] adds outlier robustness (0 = none, typically 2-3).
///
/// Returns [LoessResult] with original x and smoothed y values.
LoessResult loessSmooth(
  List<double> x,
  List<double> y, {
  double bandwidth = 0.3,
  int robustnessIterations = 2,
}) {
  assert(x.length == y.length, 'x and y must have same length');
  assert(x.length >= 3, 'Need at least 3 data points');
  assert(bandwidth > 0 && bandwidth <= 1, 'bandwidth must be in (0, 1]');

  final int n = x.length;
  final int k = max(3, (bandwidth * n).ceil());

  final indices = List.generate(n, (i) => i);
  indices.sort((a, b) => x[a].compareTo(x[b]));
  final sortedX = indices.map((i) => x[i]).toList();
  final sortedY = indices.map((i) => y[i]).toList();
  var robustnessWeights = List.filled(n, 1.0);
  var smoothed = List.filled(n, 0.0);

  for (int iter = 0; iter <= robustnessIterations; iter++) {
    for (int i = 0; i < n; i++) {
      final distances = <_IndexDistance>[];
      for (int j = 0; j < n; j++) {
        distances.add(_IndexDistance(j, (sortedX[j] - sortedX[i]).abs()));
      }
      distances.sort((a, b) => a.distance.compareTo(b.distance));

      final maxDist = distances[k - 1].distance;
      if (maxDist == 0) {
        double sumY = 0, sumW = 0;
        for (int j = 0; j < k; j++) {
          final idx = distances[j].index;
          sumY += sortedY[idx] * robustnessWeights[idx];
          sumW += robustnessWeights[idx];
        }
        smoothed[i] = sumW > 0 ? sumY / sumW : sortedY[i];
        continue;
      }

      double sumW = 0, sumWX = 0, sumWY = 0, sumWX2 = 0, sumWXY = 0;

      for (int j = 0; j < k; j++) {
        final idx = distances[j].index;
        final dist = distances[j].distance;

        final u = dist / maxDist;
        final tricube = pow(1 - pow(u, 3), 3).toDouble();
        final w = tricube * robustnessWeights[idx];

        final xj = sortedX[idx];
        final yj = sortedY[idx];

        sumW += w;
        sumWX += w * xj;
        sumWY += w * yj;
        sumWX2 += w * xj * xj;
        sumWXY += w * xj * yj;
      }

      final denom = sumW * sumWX2 - sumWX * sumWX;
      if (denom.abs() < 1e-10) {
        smoothed[i] = sumW > 0 ? sumWY / sumW : sortedY[i];
      } else {
        final a = (sumWY * sumWX2 - sumWX * sumWXY) / denom;
        final b = (sumW * sumWXY - sumWX * sumWY) / denom;
        smoothed[i] = a + b * sortedX[i];
      }
    }

    // Update robustness weights based on residuals (if not last iteration)
    if (iter < robustnessIterations) {
      final residuals =
          List.generate(n, (i) => (sortedY[i] - smoothed[i]).abs());
      final medianResidual = _median(residuals);
      final scale = 6.0 * medianResidual;

      if (scale > 0) {
        for (int i = 0; i < n; i++) {
          final u = residuals[i] / scale;
          robustnessWeights[i] = u < 1 ? pow(1 - u * u, 2).toDouble() : 0.0;
        }
      }
    }
  }

  final result = List.filled(n, 0.0);
  for (int i = 0; i < n; i++) {
    result[indices[i]] = smoothed[i];
  }

  return LoessResult(x: x, smoothedY: result);
}

class _IndexDistance {
  final int index;
  final double distance;
  const _IndexDistance(this.index, this.distance);
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

class LinearRegressionResult {
  final double slope;
  final double intercept;
  final double meanY;

  double get percentChangePerUnit => meanY > 0 ? (slope / meanY) * 100 : 0;

  const LinearRegressionResult({
    required this.slope,
    required this.intercept,
    required this.meanY,
  });
}

LinearRegressionResult? linearRegression(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 2) return null;

  final int n = x.length;
  double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

  for (int i = 0; i < n; i++) {
    sumX += x[i];
    sumY += y[i];
    sumXY += x[i] * y[i];
    sumX2 += x[i] * x[i];
  }

  final double denom = n * sumX2 - sumX * sumX;
  if (denom.abs() < 0.001) return null;

  final double slope = (n * sumXY - sumX * sumY) / denom;
  final double intercept = (sumY - slope * sumX) / n;
  final double meanY = sumY / n;

  return LinearRegressionResult(
    slope: slope,
    intercept: intercept,
    meanY: meanY,
  );
}

class SpearmanResult {
  final double rho;
  final int n;

  const SpearmanResult({required this.rho, required this.n});

  String get strength {
    final absRho = rho.abs();
    if (absRho >= 0.7) return 'strong';
    if (absRho >= 0.4) return 'moderate';
    if (absRho >= 0.2) return 'weak';
    return 'negligible';
  }

  String get direction => rho >= 0 ? 'positive' : 'negative';

  bool get isMeaningful => rho.abs() >= 0.3;
}

SpearmanResult? spearmanCorrelation(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 3) return null;

  final int n = x.length;

  final List<double> rankX = _toRanks(x);
  final List<double> rankY = _toRanks(y);

  double sumD2 = 0;
  for (int i = 0; i < n; i++) {
    final double d = rankX[i] - rankY[i];
    sumD2 += d * d;
  }

  // Spearman formula: ρ = 1 - (6 * Σd²) / (n * (n² - 1))
  final double rho = 1 - (6 * sumD2) / (n * (n * n - 1));

  return SpearmanResult(rho: rho.clamp(-1.0, 1.0), n: n);
}

List<double> _toRanks(List<double> values) {
  final int n = values.length;
  final List<int> indices = List.generate(n, (i) => i);
  indices.sort((a, b) => values[a].compareTo(values[b]));

  final List<double> ranks = List.filled(n, 0.0);

  int i = 0;
  while (i < n) {
    int j = i;
    while (j < n - 1 && values[indices[j]] == values[indices[j + 1]]) {
      j++;
    }
    final double avgRank = (i + j) / 2.0 + 1;
    for (int k = i; k <= j; k++) {
      ranks[indices[k]] = avgRank;
    }
    i = j + 1;
  }

  return ranks;
}

class CoOccurrenceResult {
  final String item1;
  final String item2;
  final int occurrences;
  final int totalInstances;

  double get percentage =>
      totalInstances > 0 ? occurrences / totalInstances * 100 : 0;

  const CoOccurrenceResult({
    required this.item1,
    required this.item2,
    required this.occurrences,
    required this.totalInstances,
  });
}

CoOccurrenceResult? findTopCoOccurrence(
    Map<dynamic, Iterable<String>> itemsByGroup) {
  final Map<String, int> pairCounts = {};

  for (final items in itemsByGroup.values) {
    if (items.length >= 2) {
      final List<String> itemList = items.toList()..sort();
      for (int i = 0; i < itemList.length - 1; i++) {
        for (int j = i + 1; j < itemList.length; j++) {
          final String pair = '${itemList[i]}|${itemList[j]}';
          pairCounts[pair] = (pairCounts[pair] ?? 0) + 1;
        }
      }
    }
  }

  if (pairCounts.isEmpty) return null;

  final sortedPairs = pairCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topPair = sortedPairs.first;
  final parts = topPair.key.split('|');

  return CoOccurrenceResult(
    item1: parts[0],
    item2: parts[1],
    occurrences: topPair.value,
    totalInstances: itemsByGroup.length,
  );
}

double calculateMean(Iterable<num> values) {
  if (values.isEmpty) return 0;
  return values.fold(0.0, (sum, v) => sum + v) / values.length;
}

double calculateStandardDeviation(Iterable<num> values) {
  if (values.length < 2) return 0;
  final mean = calculateMean(values);
  final squaredDiffs = values.map((v) => pow(v - mean, 2));
  final variance = squaredDiffs.fold(0.0, (sum, v) => sum + v) / values.length;
  return sqrt(variance);
}
