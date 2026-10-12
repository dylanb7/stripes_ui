import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_layout.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_painter.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_scene.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../accessibility/audit_harness.dart' show loadAuditFonts;

const _style = HistoryChartVisualStyle(
  axisLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
  laneLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14),
  markerLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
  axisColor: Colors.grey,
  gridColor: Colors.black12,
  selectionColor: Colors.blue,
  selectionFillColor: Colors.blueGrey,
);

const _id = GraphSeriesId(
  title: 'Pain',
  questionId: 'pain',
  type: 'GI',
  isCategory: false,
  isReview: false,
);

PreparedGraph _graph({
  DateTime? start,
  DateTime? end,
  GraphScaleKind scale = GraphScaleKind.count,
  double max = 2,
  GraphMark mark = GraphMark.bar,
  List<PreparedDatum>? data,
  String? unit,
}) {
  start ??= DateTime(2026, 10, 1);
  end ??= DateTime(2026, 11, 1);
  final List<GraphTimeBin> bins = [];
  DateTime cursor = start;
  while (cursor.isBefore(end)) {
    final DateTime next = DateTime(cursor.year, cursor.month, cursor.day + 1);
    bins.add(
      GraphTimeBin(
        index: bins.length,
        start: cursor,
        end: next.isAfter(end) ? end : next,
        // A deliberately ambiguous aggregation label must not reach the axis.
        label: 'bin',
      ),
    );
    cursor = next;
  }
  final PreparedSeries series = PreparedSeries(
    id: _id,
    label: 'Pain',
    color: Colors.blue,
    mark: mark,
    unit: unit ?? (scale == GraphScaleKind.hour ? 'time' : 'reports'),
    data:
        data ??
        [
          PreparedDatum(
            id: const GraphDatumId(seriesId: _id, binIndex: 0),
            bin: bins.first,
            xStart: bins.first.start,
            xEnd: bins.first.end,
            value: max,
          ),
        ],
  );
  return PreparedGraph(
    query: GraphQuery(
      start: start,
      end: end,
      metric: scale == GraphScaleKind.hour
          ? GraphMetric.timeOfDay
          : GraphMetric.reports,
      comparison: GraphComparison.separate,
      bins: bins,
    ),
    lanes: [
      PreparedLane(
        index: 0,
        label: 'Pain',
        series: [series],
        scaleKind: scale,
        minY: 0,
        maxY: max,
      ),
    ],
  );
}

HistoryChartScene _layout(
  PreparedGraph graph, {
  Size size = const Size(620, 300),
  TextScaler scaler = TextScaler.noScaling,
}) => const HistoryChartLayoutEngine().layout(
  graph: graph,
  size: size,
  appearance: HistoryChartAppearance.detailed,
  style: _style,
  textDirection: TextDirection.ltr,
  textScaler: scaler,
);

PreparedGraph _coarseTimingGraph() {
  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 11, 1);
  final month = GraphTimeBin(index: 0, start: start, end: end, label: 'Oct');
  final base = _graph(
    start: start,
    end: end,
    scale: GraphScaleKind.hour,
    mark: GraphMark.point,
    max: 24,
    data: [
      for (final day in [6, 7])
        PreparedDatum(
          id: GraphDatumId(seriesId: _id, binIndex: 0, ordinal: day),
          bin: month,
          xStart: DateTime(2026, 10, day, 12),
          value: 9.25,
        ),
    ],
  );
  const unknownId = GraphSeriesId(
    title: 'Pain',
    questionId: 'pain',
    type: 'GI',
    isCategory: false,
    isReview: false,
    timing: GraphTiming.unknown,
  );
  final unknown = PreparedSeries(
    id: unknownId,
    label: 'Pain · Time unknown',
    color: Colors.blue,
    mark: GraphMark.range,
    unit: 'reports',
    data: [
      PreparedDatum(
        id: const GraphDatumId(seriesId: unknownId, binIndex: 0),
        bin: month,
        xStart: DateTime(2026, 10, 6),
        xEnd: DateTime(2026, 10, 7),
        value: null,
        timing: GraphTiming.unknown,
      ),
    ],
  );
  return PreparedGraph(
    query: base.query,
    lanes: [
      ...base.lanes,
      PreparedLane(
        index: 1,
        label: unknown.label,
        series: [unknown],
        scaleKind: GraphScaleKind.range,
        minY: 0,
        maxY: 1,
      ),
    ],
  );
}

void main() {
  test(
    'large-text compact previews devote height to data without axis labels',
    () {
      final graph = _graph();
      const engine = HistoryChartLayoutEngine();
      const scaler = TextScaler.linear(3);
      final height = engine.preferredHeight(
        graph: graph,
        width: 320,
        appearance: HistoryChartAppearance.compact,
        style: _style,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      );
      final scene = engine.layout(
        graph: graph,
        size: Size(320, height),
        appearance: HistoryChartAppearance.compact,
        style: _style,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      );
      expect(scene.timeTicks, isEmpty);
      expect(scene.plotBounds.height, greaterThan(60));
      expect(height, lessThan(100));
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAuditFonts);

  test('small report counts have only whole-number ticks', () {
    for (final max in [0.0, 1.0, 2.0, 3.0, 5.0, 100.0]) {
      final lane = _layout(_graph(max: max)).lanes.single;
      expect(lane.domain.min, 0);
      expect(lane.domain.max, greaterThanOrEqualTo(max));
      expect(lane.valueTicks.length, greaterThanOrEqualTo(2));
      for (final tick in lane.valueTicks) {
        expect(tick.value, tick.value.roundToDouble());
        expect(tick.label, isNot(contains('.')));
      }
    }
  });

  test('fractional averages retain fractional ticks', () {
    final lane = _layout(
      _graph(scale: GraphScaleKind.numeric, max: 0.5, unit: 'average'),
    ).lanes.single;
    expect(
      lane.valueTicks.any((tick) => tick.value != tick.value.roundToDouble()),
      isTrue,
    );
    expect(lane.valueTicks.any((tick) => tick.label.contains('.')), isTrue);
  });

  test('month ticks use a regular calendar step, independently of bins', () {
    final scene = _layout(_graph());
    expect(scene.timeTicks.length, greaterThanOrEqualTo(3));
    final times = scene.timeTicks.map((tick) => tick.time).toList();
    final interval = times[1].difference(times[0]);
    for (int index = 1; index < times.length; index++) {
      expect(times[index].difference(times[index - 1]), interval);
      expect(times[index].hour, 0);
    }
    expect(scene.timeTicks.any((tick) => tick.label == 'bin'), isFalse);
    expect(times.last.isBefore(DateTime(2026, 11, 1)), isTrue);
  });

  test('weekday labels fit all seven days at normal phone text size', () {
    final scene = _layout(
      _graph(
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 12),
        scale: GraphScaleKind.hour,
        max: 24,
      ),
      size: const Size(343, 250),
    );
    expect(
      scene.timeTicks.map((tick) => tick.label),
      orderedEquals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']),
    );
  });

  test('coarse bins do not merge distinct days during point selection', () {
    final scene = _layout(_coarseTimingGraph());
    final first = scene.lanes.first.points.first;
    final selected = scene.hitTest(first.center);
    expect(
      selected.where((item) => item.series.mark == GraphMark.point),
      hasLength(1),
    );
    expect(
      selected.where((item) => item.datum.timing == GraphTiming.unknown),
      hasLength(1),
    );
    final unknown = scene.lanes.last.ranges.single;
    final fromUnknown = scene.hitTest(
      Offset(
        unknown.rect.left + unknown.rect.width * 0.1,
        unknown.rect.center.dy,
      ),
    );
    expect(
      fromUnknown
          .where((item) => item.series.mark == GraphMark.point)
          .single
          .datum,
      first.item.datum,
    );
  });

  test(
    'large weekday labels fall back to at least two regular day numbers',
    () {
      final scene = _layout(
        _graph(
          start: DateTime(2026, 10, 5),
          end: DateTime(2026, 10, 12),
          scale: GraphScaleKind.hour,
          max: 24,
        ),
        size: const Size(343, 600),
        scaler: const TextScaler.linear(3),
      );
      expect(scene.timeTicks.length, greaterThanOrEqualTo(2));
      expect(
        scene.timeTicks.every((tick) => int.tryParse(tick.label) != null),
        isTrue,
      );
      final step = scene.timeTicks[1].time.difference(scene.timeTicks[0].time);
      for (int index = 1; index < scene.timeTicks.length; index++) {
        expect(
          scene.timeTicks[index].time.difference(
            scene.timeTicks[index - 1].time,
          ),
          step,
        );
        expect(
          scene.timeTicks[index].labelBounds.left,
          greaterThan(scene.timeTicks[index - 1].labelBounds.right),
        );
      }
    },
  );

  test(
    'range lanes stay compact while scaled headings and day labels wrap',
    () {
      final graph = _coarseTimingGraph();
      const scaler = TextScaler.linear(3);
      final height = const HistoryChartLayoutEngine().preferredHeight(
        graph: graph,
        width: 375,
        appearance: HistoryChartAppearance.detailed,
        style: _style,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      );
      final scene = _layout(graph, size: Size(375, height), scaler: scaler);
      expect(scene.lanes.last.plot.height, lessThanOrEqualTo(32));
      expect(
        scene.lanes.first.plot.height,
        greaterThan(scene.lanes.last.plot.height * 4),
      );
      for (final lane in scene.lanes) {
        final heading = TextPainter(
          text: TextSpan(
            text: historyChartLaneHeading(lane.lane),
            style: _style.laneLabelStyle,
          ),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout(maxWidth: lane.frame.width);
        expect(
          heading.height,
          lessThanOrEqualTo(lane.plot.top - lane.frame.top),
        );
        expect(lane.frame.left, lessThan(lane.plot.left));
        for (final band in lane.dayPartBands) {
          final label = TextPainter(
            text: TextSpan(text: band.label, style: _style.axisLabelStyle),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: lane.plot.left - 18);
          expect(label.height, lessThan(band.rect.height));
        }
      }
    },
  );

  test('arbitrary long ranges use distinct labels at calendar boundaries', () {
    final scene = _layout(
      _graph(
        start: DateTime(2024, 1, 31, 17, 35),
        end: DateTime(2027, 2, 17, 8),
      ),
    );
    expect(scene.timeTicks.length, greaterThanOrEqualTo(2));
    expect(
      scene.timeTicks.map((tick) => tick.label).toSet().length,
      scene.timeTicks.length,
    );
    for (final tick in scene.timeTicks) {
      expect(tick.time.day, 1);
      expect(tick.time.hour, 0);
    }
  });

  test('scaled time labels stay inside the scene and do not collide', () {
    for (final scale in [1.0, 2.0, 3.0]) {
      final scene = _layout(
        _graph(),
        size: const Size(375, 360),
        scaler: TextScaler.linear(scale),
      );
      for (int index = 0; index < scene.timeTicks.length; index++) {
        final bounds = scene.timeTicks[index].labelBounds;
        expect(bounds.left, greaterThanOrEqualTo(scene.plotBounds.left));
        expect(bounds.right, lessThanOrEqualTo(scene.plotBounds.right + 0.01));
        expect(bounds.bottom, lessThanOrEqualTo(scene.size.height + 0.01));
        if (index > 0) {
          expect(
            bounds.left,
            greaterThan(scene.timeTicks[index - 1].labelBounds.right),
          );
        }
      }
    }
  });

  test('day-part uncertainty covers its actual duration and is selectable', () {
    final date = DateTime(2026, 10, 6);
    final bin = GraphTimeBin(
      index: 0,
      start: date,
      end: DateTime(2026, 10, 7),
      label: 'Tue',
    );
    final datum = PreparedDatum(
      id: const GraphDatumId(seriesId: _id, binIndex: 0),
      bin: bin,
      xStart: bin.center,
      value: 6,
      valueEnd: 12,
      timing: GraphTiming.dayPart,
    );
    final scene = _layout(
      _graph(
        start: date,
        end: bin.end,
        scale: GraphScaleKind.hour,
        max: 24,
        mark: GraphMark.point,
        data: [datum],
      ),
    );
    final lane = scene.lanes.single;
    expect(lane.points, isEmpty);
    expect(lane.ranges, hasLength(1));
    expect(lane.ranges.single.rect.height, closeTo(lane.plot.height / 4, 0.01));
    expect(lane.dayPartBands, hasLength(5));
    expect(
      lane.dayPartBands[0].rect.height,
      closeTo(lane.dayPartBands[4].rect.height * 2, 0.01),
    );
    expect(scene.hitTest(lane.ranges.single.rect.center).single.datum, datum);
    expect(
      scene.scrubTest(lane.ranges.single.rect.center.dx).single.datum,
      datum,
    );
  });

  test('unknown-time intervals remain selectable across their full date', () {
    final start = DateTime(2026, 10, 6);
    final end = DateTime(2026, 10, 7);
    final datum = PreparedDatum(
      id: const GraphDatumId(seriesId: _id, binIndex: 0),
      bin: null,
      xStart: start,
      xEnd: end,
      value: null,
      timing: GraphTiming.unknown,
    );
    final scene = _layout(
      _graph(
        start: start,
        end: end,
        scale: GraphScaleKind.range,
        mark: GraphMark.range,
        data: [datum],
      ),
    );
    final range = scene.lanes.single.ranges.single;
    for (final fraction in [0.1, 0.5, 0.9]) {
      final x = range.rect.left + range.rect.width * fraction;
      expect(scene.scrubTest(x).single.datum, datum);
      expect(
        scene.hitTest(Offset(x, range.rect.center.dy)).single.datum,
        datum,
      );
    }
  });

  testWidgets(
    'check-in semantics announce the inclusive reporting dates once',
    (tester) async {
      final start = DateTime(2026, 10, 5);
      final end = DateTime(2026, 10, 12);
      final graph = _graph(
        start: start,
        end: end,
        scale: GraphScaleKind.range,
        mark: GraphMark.range,
        data: [
          PreparedDatum(
            id: const GraphDatumId(seriesId: _id, binIndex: 0),
            bin: null,
            xStart: start,
            xEnd: end,
            value: null,
            timing: GraphTiming.reviewPeriod,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SingleChildScrollView(child: HistoryChart(graph: graph)),
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<HistoryChartPainter>()
          .single;
      final label = painter
          .semanticsBuilder(painter.scene.size)
          .single
          .properties
          .label!;
      expect(label, contains('Oct 5, 2026 – Oct 11, 2026'));
      expect(label, isNot(contains('Oct 12')));
      expect('Oct 5'.allMatches(label), hasLength(1));
    },
  );

  testWidgets('large-text charts grow their axes and announce clock times', (
    tester,
  ) async {
    final date = DateTime(2026, 10, 6);
    final datum = PreparedDatum(
      id: const GraphDatumId(seriesId: _id, binIndex: 0),
      bin: null,
      xStart: date,
      value: 9.25,
    );
    final graph = _graph(
      start: date,
      end: DateTime(2026, 10, 7),
      scale: GraphScaleKind.hour,
      mark: GraphMark.point,
      data: [datum],
    );
    Future<void> pump(double scale) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: SizedBox(width: 375, child: HistoryChart(graph: graph)),
          ),
        ),
      ),
    );
    await pump(1);
    final double normalHeight = tester
        .getSize(find.byType(HistoryChart))
        .height;
    await pump(3);
    expect(
      tester.getSize(find.byType(HistoryChart)).height,
      greaterThan(normalHeight),
    );
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<HistoryChartPainter>()
        .single;
    final semantics = painter.semanticsBuilder(painter.scene.size).single;
    expect(semantics.properties.label, contains('9:15'));
    expect(semantics.properties.label, isNot(contains('9.3 time')));
    expect(tester.takeException(), isNull);
  });
}
