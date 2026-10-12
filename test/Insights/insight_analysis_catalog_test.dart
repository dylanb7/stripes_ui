import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Insights/Engine/insight_analysis_catalog.dart';

void main() {
  group('InsightAnalysisCatalog', () {
    test('parses only the selected analysis section', () {
      final catalog = InsightAnalysisCatalog.fromDocument({
        // Deliberately malformed. The analysis parser must never inspect this.
        'questions': 'owned by the question parser',
        'analysis': {
          'schemaVersion': '1.2.0',
          'categories': {
            'category.PAIN': {
              'role': 'outcome',
              'timeSemantics': 'occurred_at',
              'cadence': 'event-driven',
            },
          },
          'questions': {
            'pain.severity': {
              'measurement': 'ordinal',
              'aggregation': 'max',
              'polarity': 'higher_worse',
              'validRange': [0, 10],
              'missingValues': [-1],
              'meaningfulChange': 2,
            },
          },
        },
      });

      final spec = catalog.question('pain.severity');
      expect(spec, isNotNull);
      expect(spec!.measurement, InsightMeasurement.ordinal);
      expect(spec.aggregation, InsightAggregation.maximum);
      expect(spec.polarity, InsightPolarity.higherWorse);
      expect(spec.isMissing(-1), isTrue);
      expect(spec.isInValidRange(10), isTrue);
      expect(spec.isInValidRange(11), isFalse);

      final resolved = catalog.resolve(
        questionId: 'pain.severity',
        categoryId: 'category.PAIN',
      );
      expect(resolved, isNotNull);
      expect(resolved!.role, InsightRole.outcome);
      expect(resolved.timeSemantics, InsightTimeSemantics.occurredAt);
      expect(resolved.cadence, InsightCadence.eventDriven);
    });

    test('returns an empty catalog when the section is absent', () {
      final catalog = InsightAnalysisCatalog.fromDocument({
        'questions': [
          {'id': 'pain.severity'},
        ],
      });

      expect(catalog.questions, isEmpty);
      expect(catalog.categories, isEmpty);
    });

    test('supports a standalone sparse catalog', () {
      final catalog = InsightAnalysisCatalog.fromMap({
        'schemaVersion': 1,
        'questions': {
          'stool.count': {'measurement': 'count', 'aggregation': 'sum'},
        },
      });

      expect(catalog.questions.keys, ['stool.count']);
      expect(catalog.question('not-listed'), isNull);
    });

    test('parses absence semantics and defaults to unobserved', () {
      final catalog = InsightAnalysisCatalog.fromMap({
        'questions': {
          'explicit-check': {
            'measurement': 'binary',
            'aggregation': 'any',
            'absenceSemantics': 'unselected_means_false',
          },
          'unspecified-check': {'measurement': 'binary', 'aggregation': 'any'},
        },
      });

      expect(
        catalog.question('explicit-check')!.absenceSemantics,
        InsightAbsenceSemantics.unselectedMeansFalse,
      );
      expect(
        catalog.question('unspecified-check')!.absenceSemantics,
        InsightAbsenceSemantics.unobserved,
      );
    });

    test('parses landmark category mode and excludes generic patterns', () {
      final catalog = InsightAnalysisCatalog.fromMap({
        'categories': {
          'landmark.medication-change': {
            'mode': 'landmark',
            'role': 'exposure',
          },
        },
        'questions': {
          'medication-name': {
            'measurement': 'nominal',
            'aggregation': 'perEvent',
          },
        },
      });

      final category = catalog.category('landmark.medication-change');
      expect(category, isNotNull);
      expect(category!.mode, InsightAnalysisMode.landmark);
      expect(category.role, InsightRole.exposure);

      final resolved = catalog.resolve(
        questionId: 'medication-name',
        categoryId: 'landmark.medication-change',
      );
      expect(resolved, isNotNull);
      expect(resolved!.eligibleForGenericPatterns, isFalse);
    });

    test('defensively copies mutable metadata collections', () {
      final missingValues = <num>{-1};
      final spec = QuestionAnalysisSpec(
        questionId: 'pain',
        measurement: InsightMeasurement.ordinal,
        aggregation: InsightAggregation.mean,
        missingValues: missingValues,
      );

      missingValues.add(-2);

      expect(spec.missingValues, {-1});
      expect(() => spec.missingValues.add(-3), throwsUnsupportedError);
    });

    test('uses an explicit name for counting recorded observations', () {
      final catalog = InsightAnalysisCatalog.fromMap({
        'questions': {
          'events': {
            'measurement': 'continuous',
            'aggregation': 'observationCount',
          },
        },
      });

      expect(
        catalog.question('events')!.aggregation,
        InsightAggregation.observationCount,
      );
      expect(
        () => InsightAnalysisCatalog.fromMap({
          'questions': {
            'events': {'measurement': 'count', 'aggregation': 'count'},
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown fields with their catalog path', () {
      expect(
        () => InsightAnalysisCatalog.fromMap({
          'questions': {
            'pain.severity': {
              'measurement': 'ordinal',
              'aggregation': 'mean',
              'questionPrompt': 'must not be coupled to Question',
            },
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.questions.pain.severity.questionPrompt'),
          ),
        ),
      );
    });

    test('rejects invalid ranges and unsupported schema versions', () {
      expect(
        () => InsightAnalysisCatalog.fromMap({
          'questions': {
            'pain.severity': {
              'measurement': 'ordinal',
              'aggregation': 'mean',
              'validRange': [10, 0],
            },
          },
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => InsightAnalysisCatalog.fromMap({'schemaVersion': 2}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
