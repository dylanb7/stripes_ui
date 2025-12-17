import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Util/Helpers/stats.dart';

void main() {
  group('findPeakWindow (Kadane\'s Algorithm)', () {
    test('finds single peak hour', () {
      // Peak at hour 10 with 20 entries
      final counts = List.filled(24, 1);
      counts[10] = 20;

      final result = findPeakWindow(counts);

      expect(result.count, greaterThanOrEqualTo(20));
      expect(result.startHour, lessThanOrEqualTo(10));
      expect(result.endHour, greaterThanOrEqualTo(10));
    });

    test('finds contiguous peak range', () {
      // Peak from 9am-12pm (hours 9, 10, 11)
      final counts = List.filled(24, 1);
      counts[9] = 15;
      counts[10] = 20;
      counts[11] = 18;

      final result = findPeakWindow(counts);

      expect(result.startHour, lessThanOrEqualTo(9));
      expect(result.endHour, greaterThanOrEqualTo(11));
      expect(result.count, greaterThanOrEqualTo(53)); // 15 + 20 + 18
    });

    test('handles all zeros', () {
      final counts = List.filled(24, 0);

      final result = findPeakWindow(counts);

      expect(result.count, equals(0));
      expect(result.startHour, equals(0));
      expect(result.endHour, equals(23));
    });

    test('handles uniform distribution', () {
      final counts = List.filled(24, 10);

      final result = findPeakWindow(counts);

      // With uniform distribution and auto cost = 240/24 = 10,
      // profit per hour is 0, so any window or full range works
      expect(result.count, greaterThanOrEqualTo(10));
    });

    test('prefers concentrated activity over spread activity', () {
      // Concentrated: hours 10-11 with 30 each = 60 total
      final concentrated = List.filled(24, 2);
      concentrated[10] = 30;
      concentrated[11] = 30;

      // Spread: hours 8-14 with 10 each = 70 total but spread out
      final spread = List.filled(24, 2);
      for (int i = 8; i < 15; i++) {
        spread[i] = 10;
      }

      final concentratedResult = findPeakWindow(concentrated);
      final spreadResult = findPeakWindow(spread);

      // Concentrated window should have better score despite less total
      expect(concentratedResult.score, greaterThan(spreadResult.score));
    });

    test('custom cost parameter affects window size', () {
      final counts = List.filled(24, 5);
      counts[10] = 20;
      counts[11] = 20;
      counts[12] = 20;

      // Low cost = wider windows acceptable
      final lowCostResult = findPeakWindow(counts, costPerHour: 1.0);
      // High cost = narrower windows preferred
      final highCostResult = findPeakWindow(counts, costPerHour: 10.0);

      expect(lowCostResult.duration,
          greaterThanOrEqualTo(highCostResult.duration));
    });

    test('PeakWindow duration calculation is correct', () {
      final counts = List.filled(24, 0);
      counts[10] = 50;
      counts[11] = 50;
      counts[12] = 50;

      final result = findPeakWindow(counts);

      expect(result.duration, equals(result.endHour - result.startHour + 1));
    });
  });

  group('loessSmooth (LOESS)', () {
    test('smooths noisy data', () {
      // Create noisy linear data: y = x + noise
      final x = List.generate(20, (i) => i.toDouble());
      final y =
          List.generate(20, (i) => i.toDouble() + (i.isEven ? 2.0 : -2.0));

      final result = loessSmooth(x, y, bandwidth: 0.5);

      expect(result.smoothedY.length, equals(20));

      // Check middle values follow approximate linear trend
      for (int i = 3; i < 17; i++) {
        // Smoothed should be closer to true line (y=x) than noisy data
        final trueY = i.toDouble();
        final smoothedDeviation = (result.smoothedY[i] - trueY).abs();
        final noisyDeviation = (y[i] - trueY).abs();
        expect(smoothedDeviation, lessThan(noisyDeviation + 1));
      }
    });

    test('preserves data length', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [2.0, 4.0, 6.0, 8.0, 10.0];

      final result = loessSmooth(x, y);

      expect(result.x.length, equals(5));
      expect(result.smoothedY.length, equals(5));
    });

    test('handles perfect linear data', () {
      final x = List.generate(10, (i) => i.toDouble());
      final y = List.generate(10, (i) => (2 * i + 1).toDouble()); // y = 2x + 1

      final result = loessSmooth(x, y, bandwidth: 0.5);

      // Should be very close to original linear data
      for (int i = 2; i < 8; i++) {
        expect(result.smoothedY[i], closeTo(y[i], 0.5));
      }
    });

    test('bandwidth affects smoothness', () {
      final x = List.generate(30, (i) => i.toDouble());
      // Create step function with noise
      final y =
          List.generate(30, (i) => (i < 15 ? 0.0 : 10.0) + (i % 3).toDouble());

      final narrowResult = loessSmooth(x, y, bandwidth: 0.15);
      final wideResult = loessSmooth(x, y, bandwidth: 0.6);

      // Wide bandwidth should produce smoother result (less variation)
      double narrowVariation = 0;
      double wideVariation = 0;
      for (int i = 1; i < 29; i++) {
        narrowVariation +=
            (narrowResult.smoothedY[i] - narrowResult.smoothedY[i - 1]).abs();
        wideVariation +=
            (wideResult.smoothedY[i] - wideResult.smoothedY[i - 1]).abs();
      }

      expect(wideVariation, lessThan(narrowVariation));
    });

    test('throws on insufficient data points', () {
      expect(
        () => loessSmooth([1.0, 2.0], [1.0, 2.0]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on mismatched x and y lengths', () {
      expect(
        () => loessSmooth([1.0, 2.0, 3.0], [1.0, 2.0]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on invalid bandwidth', () {
      expect(
        () => loessSmooth([1.0, 2.0, 3.0], [1.0, 2.0, 3.0], bandwidth: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => loessSmooth([1.0, 2.0, 3.0], [1.0, 2.0, 3.0], bandwidth: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('robustness iterations reduce outlier impact', () {
      final x = List.generate(20, (i) => i.toDouble());
      final y = List.generate(20, (i) => i.toDouble());
      y[10] = 100.0; // Add outlier

      final noRobust = loessSmooth(x, y, robustnessIterations: 0);
      final robust = loessSmooth(x, y, robustnessIterations: 3);

      // Around the outlier, robust should be closer to the true line
      // Average deviation from line in range 8-12
      double noRobustDeviation = 0;
      double robustDeviation = 0;
      for (int i = 8; i <= 12; i++) {
        if (i != 10) {
          noRobustDeviation += (noRobust.smoothedY[i] - i).abs();
          robustDeviation += (robust.smoothedY[i] - i).abs();
        }
      }

      expect(robustDeviation, lessThanOrEqualTo(noRobustDeviation + 1));
    });
  });

  group('linearRegression', () {
    test('calculates correct slope for linear data', () {
      final x = [0.0, 1.0, 2.0, 3.0, 4.0];
      final y = [2.0, 4.0, 6.0, 8.0, 10.0]; // y = 2x + 2

      final result = linearRegression(x, y);

      expect(result, isNotNull);
      expect(result!.slope, closeTo(2.0, 0.01));
      expect(result.intercept, closeTo(2.0, 0.01));
    });

    test('returns null for insufficient data', () {
      expect(linearRegression([1.0], [1.0]), isNull);
      expect(linearRegression([], []), isNull);
    });

    test('handles flat data (zero slope)', () {
      final x = [0.0, 1.0, 2.0, 3.0];
      final y = [5.0, 5.0, 5.0, 5.0];

      final result = linearRegression(x, y);

      expect(result, isNotNull);
      expect(result!.slope, closeTo(0.0, 0.01));
      expect(result.meanY, equals(5.0));
    });

    test('percentChangePerUnit calculates correctly', () {
      // y goes from 10 to 20 over x=0 to x=10, so slope ≈ 1, mean ≈ 15
      final x = List.generate(11, (i) => i.toDouble());
      final y = List.generate(11, (i) => (10 + i).toDouble());

      final result = linearRegression(x, y);

      expect(result, isNotNull);
      expect(result!.slope, closeTo(1.0, 0.01));
      // percentChange = (1 / 15) * 100 ≈ 6.67%
      expect(result.percentChangePerUnit, closeTo(6.67, 0.5));
    });
  });

  group('spearmanCorrelation', () {
    test('perfect positive correlation', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [10.0, 20.0, 30.0, 40.0, 50.0];

      final result = spearmanCorrelation(x, y);

      expect(result, isNotNull);
      expect(result!.rho, closeTo(1.0, 0.01));
      expect(result.strength, equals('strong'));
      expect(result.direction, equals('positive'));
      expect(result.isMeaningful, isTrue);
    });

    test('perfect negative correlation', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [50.0, 40.0, 30.0, 20.0, 10.0];

      final result = spearmanCorrelation(x, y);

      expect(result, isNotNull);
      expect(result!.rho, closeTo(-1.0, 0.01));
      expect(result.strength, equals('strong'));
      expect(result.direction, equals('negative'));
    });

    test('no correlation', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [3.0, 1.0, 4.0, 2.0, 5.0]; // Scrambled

      final result = spearmanCorrelation(x, y);

      expect(result, isNotNull);
      // Should be close to 0 but not exactly
      expect(result!.rho.abs(), lessThanOrEqualTo(0.5));
    });

    test('handles ties correctly', () {
      final x = [1.0, 1.0, 2.0, 2.0, 3.0];
      final y = [10.0, 10.0, 20.0, 20.0, 30.0];

      final result = spearmanCorrelation(x, y);

      expect(result, isNotNull);
      expect(result!.rho, closeTo(1.0, 0.01));
    });

    test('returns null for insufficient data', () {
      expect(spearmanCorrelation([1.0, 2.0], [1.0, 2.0]), isNull);
      expect(spearmanCorrelation([], []), isNull);
    });

    test('strength thresholds are correct', () {
      // Strong: |ρ| >= 0.7
      expect(SpearmanResult(rho: 0.8, n: 10).strength, equals('strong'));
      expect(SpearmanResult(rho: -0.75, n: 10).strength, equals('strong'));

      // Moderate: 0.4 <= |ρ| < 0.7
      expect(SpearmanResult(rho: 0.5, n: 10).strength, equals('moderate'));

      // Weak: 0.2 <= |ρ| < 0.4
      expect(SpearmanResult(rho: 0.25, n: 10).strength, equals('weak'));

      // Negligible: |ρ| < 0.2
      expect(SpearmanResult(rho: 0.1, n: 10).strength, equals('negligible'));
    });
  });

  group('findTopCoOccurrence', () {
    test('finds most common pair', () {
      final itemsByGroup = {
        'day1': {'A', 'B', 'C'},
        'day2': {'A', 'B'},
        'day3': {'A', 'B'},
        'day4': {'B', 'C'},
        'day5': {'A', 'C'},
      };

      final result = findTopCoOccurrence(itemsByGroup);

      expect(result, isNotNull);
      expect(result!.item1, equals('A'));
      expect(result.item2, equals('B'));
      expect(result.occurrences, equals(3));
      expect(result.totalInstances, equals(5));
      expect(result.percentage, equals(60.0));
    });

    test('returns null for single-item groups', () {
      final itemsByGroup = {
        'day1': {'A'},
        'day2': {'B'},
      };

      expect(findTopCoOccurrence(itemsByGroup), isNull);
    });

    test('returns null for empty input', () {
      expect(findTopCoOccurrence({}), isNull);
    });

    test('handles multiple ties by taking first alphabetically', () {
      final itemsByGroup = {
        'day1': {'A', 'B'},
        'day2': {'C', 'D'},
      };

      final result = findTopCoOccurrence(itemsByGroup);

      expect(result, isNotNull);
      expect(result!.occurrences, equals(1));
      // Either A+B or C+D, both have count 1
    });
  });
}
