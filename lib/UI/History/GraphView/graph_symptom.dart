import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/graph_packets.dart';

class GraphSymptom extends StatefulWidget {
  final List<List<Response>> responses;
  final GraphSettings settings;
  final bool isDetailed;
  const GraphSymptom(
      {super.key,
      required this.responses,
      required this.settings,
      required this.isDetailed});

  @override
  State<StatefulWidget> createState() {
    return _GraphSymptomState();
  }
}

class _GraphSymptomState extends State<GraphSymptom> {
  int touchedIndex = -1;

  late GraphDataSet dataSet;

  @override
  void initState() {
    List<List<List<Stamp>>> sets = [];
    for (List<Response> dataset in widget.responses) {
      final List<List<Stamp>>? setValue = bucketEvents(
        dataset,
        widget.settings.range,
        widget.settings.span.getBuckets(widget.settings.range.start),
      );
      if (setValue != null) {
        sets.add(setValue);
      }
      print(widget.responses
          .map((val) => val.map((s) => dateFromStamp(s.stamp)).join(", "))
          .join("_"));
      print(sets);
    }

    dataSet = widget.settings.axis == GraphYAxis.entrytime
        ? getSpotSet(sets)
        : getBarChartDataSet(sets);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final FlGridData gridData = FlGridData(
      show: widget.isDetailed,
      getDrawingVerticalLine: (value) => const FlLine(dashArray: [4, 8]),
      getDrawingHorizontalLine: (value) => const FlLine(dashArray: [4, 8]),
    );

    final FlBorderData borderData = FlBorderData(
        show: widget.isDetailed,
        border: const Border(
            bottom: BorderSide(width: 1.0), right: BorderSide(width: 1.0)));

    final AxisTitles bottomTitles = AxisTitles(sideTitles: SideTitles());

    final FlTitlesData titlesData = widget.isDetailed
        ? FlTitlesData(
            bottomTitles: bottomTitles,
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          )
        : const FlTitlesData(show: false);
    if (widget.settings.axis == GraphYAxis.entrytime) {
      return ScatterChart(
        ScatterChartData(
          scatterSpots: dataSet.data as List<ScatterSpot>,
          minX: dataSet.minX,
          maxX: dataSet.maxX,
          minY: dataSet.minY,
          maxY: dataSet.maxY,
          gridData: gridData,
          borderData: borderData,
          titlesData: titlesData,
        ),
      );
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        groupsSpace: 0.0,
        barGroups: dataSet.data as List<BarChartGroupData>,
        maxY: dataSet.maxY,
        minY: dataSet.minY,
        gridData: gridData,
        borderData: borderData,
        barTouchData: widget.isDetailed
            ? BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: _getTooltipItem,
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = response.spot!.touchedBarGroupIndex;
                  });
                },
              )
            : null,
        titlesData: titlesData,
      ),
    );
  }

  GraphDataSet<BarChartGroupData> getBarChartDataSet(
      List<List<List<Stamp>>> sets) {
    if (sets.isEmpty) return const GraphDataSet.empty();

    final int yAxisTicks = widget.isDetailed ? 5 : 3;

    List<BarChartGroupData> barChartGroups = [];

    double maxY = double.negativeInfinity, minY = double.infinity;

    void adjustBounds(double value) {
      if (value > maxY) {
        maxY = value;
      }
      if (value < minY) {
        minY = value;
      }
    }

    for (int i = 0; i < sets.length; i++) {
      final List<List<Stamp>> graphSet = sets[i];
      List<BarChartRodData> rods = [];
      for (final List<Stamp> point in graphSet) {
        if (widget.settings.axis == GraphYAxis.frequency) {
          final double rodY = point.length.toDouble();
          adjustBounds(rodY);
          rods.add(BarChartRodData(toY: rodY));
        } else if (widget.settings.axis == GraphYAxis.severity) {
          final Iterable<NumericResponse> numerics =
              point.whereType<NumericResponse>();
          if (numerics.isEmpty) {
            adjustBounds(0);
            rods.add(BarChartRodData(toY: 0));
            continue;
          }
          double total = 0.0;
          for (final NumericResponse numeric in numerics) {
            total += numeric.response;
          }
          final double average = total / numerics.length;
          adjustBounds(average);
          rods.add(BarChartRodData(toY: average));
        }
      }
      barChartGroups.add(BarChartGroupData(x: i, barRods: rods));
    }

    final YAxisRange range =
        YAxisRange.rangeFromMax(ticks: yAxisTicks, max: maxY, min: minY);

    return GraphDataSet<BarChartGroupData>(
        data: barChartGroups,
        minX: range.lowerBound,
        maxX: barChartGroups.length.toDouble(),
        minY: 0,
        maxY: range.upperBound);
  }

  GraphDataSet<ScatterSpot> getSpotSet(List<List<List<Stamp>>> sets) {
    List<ScatterSpot> spots = [];

    for (final List<List<Stamp>> graphSet in sets) {
      for (int i = 0; i < graphSet.length; i++) {
        final List<Stamp> atPoint = graphSet[i];
        for (final Stamp value in atPoint) {
          final DateTime spotDate = dateFromStamp(value.stamp);
          spots.add(ScatterSpot(
              i.toDouble(), (spotDate.hour + (spotDate.minute / 60))));
        }
      }
    }
    return GraphDataSet(
        data: spots,
        minY: 0,
        maxY: 24,
        minX: 0,
        maxX: (widget.settings.span.getBuckets(widget.settings.range.start) - 1)
            .toDouble());
  }

  BarTooltipItem? _getTooltipItem(BarChartGroupData group, int groupIndex,
      BarChartRodData rod, int rodIndex) {
    return BarTooltipItem(
      'hi',
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
      children: [TextSpan(text: "hi")],
    );
  }
}

class GraphDataSet<T> {
  final List<T> data;
  final double minX, maxX, minY, maxY;

  const GraphDataSet(
      {required this.data,
      required this.minX,
      required this.maxX,
      required this.minY,
      required this.maxY});

  const GraphDataSet.empty()
      : data = const [],
        maxX = 0,
        minX = 0,
        maxY = 0,
        minY = 0;
}

@immutable
class YAxisRange {
  final double upperBound, lowerBound, tickSize;
  const YAxisRange(
      {required this.lowerBound,
      required this.upperBound,
      required this.tickSize});

  factory YAxisRange.rangeFrom(
      {required int ticks, required List<num> values}) {
    if (values.isEmpty) {
      return const YAxisRange(lowerBound: 0, upperBound: 10, tickSize: 0);
    }
    num min = values[0], max = values[0];
    for (final num value in values) {
      if (value < min) {
        min = value;
      } else if (value > max) {
        max = value;
      }
    }
    return YAxisRange.rangeFromMax(ticks: ticks, min: min, max: max);
  }

  factory YAxisRange.rangeFromMax(
      {required int ticks, required num max, num min = 0}) {
    if (min == max) {
      return YAxisRange(
          lowerBound: 0,
          upperBound: (min + (min.toDouble() / 2)),
          tickSize: min.toDouble());
    }
    final num range = max - min;
    final double unroundedTickSize = range.toDouble() / ticks;
    final double x = ((log(unroundedTickSize) / ln10) - 1).ceilToDouble();
    final double pow10x = pow(10, x).toDouble();
    final double roundedTick = (unroundedTickSize / pow10x).ceil() * pow10x;
    return YAxisRange(
        lowerBound: (min.toDouble() / roundedTick).round() * roundedTick,
        upperBound: (max.toDouble() / roundedTick).round() * roundedTick,
        tickSize: roundedTick);
  }
}

List<List<Stamp>>? bucketEvents(
    List<Stamp> events, DateTimeRange range, int buckets) {
  if (events.isEmpty) return null;
  List<List<Stamp>> eventLists = [];
  final double startValue = range.start.millisecondsSinceEpoch.toDouble();
  final double endValue = range.end.millisecondsSinceEpoch.toDouble();
  final double totalRange = endValue - startValue;
  final double stepSize = totalRange / buckets.toDouble();

  events.sort((first, second) => first.stamp.compareTo(second.stamp));
  int furthestReach = 0;
  for (double start = startValue; start <= endValue; start += stepSize) {
    final double end = start + stepSize;
    List<Stamp> valuesInRange = [];
    while (furthestReach < events.length) {
      final Stamp current = events[furthestReach];
      if (current.stamp < start.floor() || current.stamp > end.ceil()) {
        break;
      }
      valuesInRange.add(current);
      furthestReach++;
    }
    eventLists.add(valuesInRange);
  }
  return eventLists;
}
