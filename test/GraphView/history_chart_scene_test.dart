import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_layout.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

void main() {
  test('the scene uses one geometry source for painting and selection', () {
    final DateTime start = DateTime(2025, 1, 1);
    final GraphTimeBin bin = GraphTimeBin(
      index: 0,
      start: start,
      end: start.add(const Duration(days: 1)),
      label: 'Jan 1',
    );
    PreparedSeries series(String title, Color color, double value) {
      final GraphSeriesId id = GraphSeriesId(
        title: title,
        questionId: title,
        type: 'GI',
        isCategory: false,
        isReview: false,
      );
      return PreparedSeries(
        id: id,
        label: title,
        color: color,
        mark: GraphMark.bar,
        data: <PreparedDatum>[
          PreparedDatum(
            id: GraphDatumId(seriesId: id, binIndex: 0),
            bin: bin,
            xStart: bin.start,
            xEnd: bin.end,
            value: value,
          ),
        ],
        domainMin: 0,
        domainMax: 10,
      );
    }

    final PreparedGraph graph = PreparedGraph(
      query: GraphQuery(
        start: bin.start,
        end: bin.end,
        metric: GraphMetric.reports,
        comparison: GraphComparison.overlaid,
        bins: <GraphTimeBin>[bin],
      ),
      lanes: <PreparedLane>[
        PreparedLane(
          index: 0,
          label: 'Comparison',
          series: <PreparedSeries>[
            series('Pain', Colors.blue, 3),
            series('Nausea', Colors.orange, 6),
          ],
          scaleKind: GraphScaleKind.numeric,
          minY: 0,
          maxY: 10,
        ),
      ],
    );
    const HistoryChartVisualStyle style = HistoryChartVisualStyle(
      axisLabelStyle: TextStyle(fontSize: 10),
      laneLabelStyle: TextStyle(fontSize: 11),
      markerLabelStyle: TextStyle(fontSize: 10),
      axisColor: Colors.grey,
      gridColor: Colors.black12,
      selectionColor: Colors.blue,
      selectionFillColor: Colors.blueGrey,
    );

    final scene = const HistoryChartLayoutEngine().layout(
      graph: graph,
      size: const Size(320, 180),
      appearance: HistoryChartAppearance.detailed,
      style: style,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(scene.lanes.single.bars, hasLength(2));
    expect(scene.hitRegions, hasLength(2));
    expect(
      scene.hitRegions.first.visibleBounds,
      scene.lanes.single.bars.first.rect,
    );
    expect(scene.hitTest(scene.hitRegions.first.anchor), hasLength(2));
    expect(scene.scrubTest(scene.plotBounds.center.dx), hasLength(2));
    expect(
      scene.lanes.single.bars.map((bar) => bar.rect.left).toSet(),
      hasLength(1),
    );
  });
}
