import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

/// Context that travels with a chart, including when it is shared as an image.
class GraphContextCaption extends StatelessWidget {
  final PreparedGraph graph;

  const GraphContextCaption({super.key, required this.graph});

  @override
  Widget build(BuildContext context) {
    final timing = <Object, GraphTiming>{};
    for (final series in graph.series) {
      for (final datum in series.data) {
        for (final response in datum.evidence.whereType<Response>()) {
          timing[recordIdentityForResponse(
            response,
          )] = datum.timing == GraphTiming.reviewPeriod
              ? GraphTiming.reviewPeriod
              : switch (recordTimeForResponse(response)?.precision) {
                  RecordTimePrecision.dayPart => GraphTiming.dayPart,
                  RecordTimePrecision.unknown => GraphTiming.unknown,
                  _ => GraphTiming.exact,
                };
        }
      }
    }
    final exact = timing.values.where((v) => v == GraphTiming.exact).length;
    final approximate = timing.values
        .where((v) => v == GraphTiming.dayPart)
        .length;
    final unknown = timing.values.where((v) => v == GraphTiming.unknown).length;
    final reviews = timing.values
        .where((v) => v == GraphTiming.reviewPeriod)
        .length;
    final hasUncertainTiming = approximate + unknown > 0;
    final hasTimingLanes = graph.series.any(
      (series) =>
          series.mark == GraphMark.range &&
          series.data.any((datum) => datum.timing != GraphTiming.reviewPeriod),
    );
    final showTiming =
        graph.query.metric == GraphMetric.timeOfDay || hasTimingLanes;
    final lines = <String>[
      if (graph.query.metric == GraphMetric.average)
        for (final series in graph.series.where(
          (series) => series.mark == GraphMark.bar,
        ))
          '${series.label}: ${series.data.fold<int>(0, (sum, datum) => sum + datum.summary.reportCount)} numeric answers',
      if (showTiming && timing.isNotEmpty)
        [
          '$exact exact',
          if (approximate > 0) '$approximate approximate',
          if (unknown > 0) '$unknown time unknown',
          if (reviews > 0) '$reviews check-ins',
        ].join(' · '),
      if (showTiming && approximate > 0)
        'Outlined spans show possible event times, not symptom duration.',
      if (hasTimingLanes &&
          hasUncertainTiming &&
          graph.query.metric != GraphMetric.timeOfDay)
        'Values by time use exact entries. Other entries are shown separately for that day.',
      if (reviews > 0)
        'Check-in spans describe reporting periods, not symptom duration.',
      switch (graph.query.metric) {
        GraphMetric.reports => 'Counts show recorded activity. No entries does not mean no symptoms.',
        GraphMetric.average => 'Averages use recorded numeric answers. Gaps mean no numeric answers.',
        GraphMetric.timeOfDay =>
          'Times describe when events happened, not when they were recorded.',
      },
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Text(
        lines.join('\n'),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

String graphAggregationLabel(PreparedGraph graph) {
  if (graph.query.metric == GraphMetric.timeOfDay) return 'Event times';
  if (graph.query.bins.isEmpty) return 'Selected period';
  final longest = graph.query.bins
      .map((bin) => bin.end.difference(bin.start))
      .reduce((a, b) => a > b ? a : b);
  final String interval;
  if (longest.inDays >= 365 && longest.inDays <= 366) {
    interval = 'year';
  } else if (longest.inDays >= 28 && longest.inDays <= 31) {
    interval = 'month';
  } else if (longest.inHours >= 167 && longest.inHours <= 169) {
    interval = 'week';
  } else if (longest.inHours >= 23 && longest.inHours <= 25) {
    interval = 'day';
  } else if (longest.inMinutes == 60) {
    interval = 'hour';
  } else if (longest.inSeconds == 60) {
    interval = 'minute';
  } else {
    interval = 'interval';
  }
  return '${graph.query.metric == GraphMetric.reports ? 'Count' : 'Average'} per $interval';
}
