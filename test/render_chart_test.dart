import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/render_chart.dart';

void main() {
  testWidgets('RenderChart builds correctly with LineChartData',
      (WidgetTester tester) async {
    final data = LineChartData<int>(
      data: [1, 2, 3, 4, 5],
      getPointX: (i) => i.toDouble(),
      getPointY: (i) => i * 2.0,
      getPointColor: (i) => Colors.blue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RenderChart.single(
            data: data,
          ),
        ),
      ),
    );

    expect(find.byType(RenderChart), findsOneWidget);
    // Find CustomPaint that is a descendant of RenderChart
    expect(
      find.descendant(
        of: find.byType(RenderChart),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('RenderChart handles empty data', (WidgetTester tester) async {
    final data = BarChartData<int>(
      data: [],
      getPointX: (i) => i.toDouble(),
      getPointY: (i) => i * 2.0,
      getPointColor: (i) => Colors.blue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RenderChart.single(
            data: data,
          ),
        ),
      ),
    );

    expect(find.byType(RenderChart), findsOneWidget);
    // Should still build CustomPaint, just paints nothing
    expect(
      find.descendant(
        of: find.byType(RenderChart),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('RenderChart supports different chart types',
      (WidgetTester tester) async {
    final chartDataList = <ChartData>[
      LineChartData<int>(
        data: [1, 2],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.red,
      ),
      BarChartData<int>(
        data: [1, 2],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.red,
      ),
      ScatterChartData<int>(
        data: [1, 2],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.red,
        getRadius: (i) => 4.0,
      ),
    ];

    for (var data in chartDataList) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RenderChart.single(
              data: data,
            ),
          ),
        ),
      );
      expect(find.byType(RenderChart), findsOneWidget);
    }
  });

  testWidgets('RenderChart supports multiple datasets',
      (WidgetTester tester) async {
    final datasets = <ChartData>[
      LineChartData<int>(
        data: [1, 2, 3],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.blue,
      ),
      LineChartData<int>(
        data: [4, 5, 6],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => (i * 1.5),
        getPointColor: (i) => Colors.red,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RenderChart(
            datasets: datasets,
          ),
        ),
      ),
    );

    expect(find.byType(RenderChart), findsOneWidget);
  });

  testWidgets('ScatterChartData uses custom radius',
      (WidgetTester tester) async {
    final data = ScatterChartData<int>(
      data: [1, 2, 3],
      getPointX: (i) => i.toDouble(),
      getPointY: (i) => i.toDouble(),
      getPointColor: (i) => Colors.green,
      getRadius: (i) => i * 2.0, // Dynamic radius based on value
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RenderChart.single(
            data: data,
          ),
        ),
      ),
    );

    expect(find.byType(RenderChart), findsOneWidget);
  });

  group('YAxisRange', () {
    test('rangeFromMax creates nice tick values', () {
      final range = YAxisRange.rangeFromMax(ticks: 5, max: 47, min: 0);

      // Should create nice round bounds
      expect(range.lowerBound, 0);
      expect(range.upperBound >= 47, true);
      expect(range.tickSize > 0, true);
    });

    test('rangeFrom calculates from values list', () {
      final values = [3, 15, 8, 22, 5];
      final range = YAxisRange.rangeFrom(ticks: 5, values: values);

      // Should produce nice round bounds and a positive tick size
      // The upperBound should be at least the max value (22)
      expect(range.upperBound, greaterThanOrEqualTo(22));
      expect(range.tickSize, greaterThan(0));
      // Lower bound should be a reasonable value (non-negative or close to min)
      expect(range.lowerBound, lessThanOrEqualTo(range.upperBound));
    });

    test('rangeFrom handles empty values', () {
      final range = YAxisRange.rangeFrom(ticks: 5, values: []);

      expect(range.lowerBound, 0);
      expect(range.upperBound, 10);
      expect(range.tickSize, 0);
    });

    test('rangeFromMax handles equal min and max', () {
      final range = YAxisRange.rangeFromMax(ticks: 5, max: 10, min: 10);

      expect(range.lowerBound, 0);
      expect(range.upperBound, 20); // min * 2
      expect(range.tickSize, 10);
    });
  });

  group('ChartData ranges', () {
    test('calculates data bounds correctly', () {
      final data = LineChartData<int>(
        data: [1, 5, 10, 15, 20],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.blue,
      );

      expect(data.dataMinX, 1.0);
      expect(data.dataMaxX, 20.0);
      expect(data.dataMinY, 1.0);
      expect(data.dataMaxY, 20.0);
    });

    test('uses YAxisRange when provided', () {
      final yRange = YAxisRange.rangeFromMax(ticks: 5, max: 100, min: 0);
      final data = BarChartData<int>(
        data: [10, 20, 30],
        getPointX: (i) => i.toDouble(),
        getPointY: (i) => i.toDouble(),
        getPointColor: (i) => Colors.blue,
        yAxisRange: yRange,
      );

      // Should use yAxisRange bounds instead of data bounds
      expect(data.minY, yRange.lowerBound);
      expect(data.maxY, yRange.upperBound);
    });
  });
}
