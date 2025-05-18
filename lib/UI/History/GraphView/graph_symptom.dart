import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/graph_packets.dart';

class GraphSymptom extends StatefulWidget {
  final Map<GraphKey, List<Response>> responses;
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

  @override
  Widget build(BuildContext context) {
    Map<GraphKey, List<List<Stamp>>> sets = {};
    for (final GraphKey datasetKey in widget.responses.keys) {
      final List<List<Stamp>>? setValue = bucketEvents(
        widget.responses[datasetKey]!,
        widget.settings.range,
        widget.settings.span.getBuckets(widget.settings.range.start),
      );
      if (setValue != null) {
        sets[datasetKey] = setValue;
      }
    }

    GraphDataSet dataSet = widget.settings.axis == GraphYAxis.entrytime
        ? getSpotSet(sets)
        : getBarChartDataSet(sets);

    final FlGridData gridData = FlGridData(
      show: widget.isDetailed,
    );

    final FlBorderData borderData = FlBorderData(show: false);

    final Duration span = widget.settings.range.duration;
    final int stepSize = (span.inMilliseconds /
            widget.settings.span.getBuckets(widget.settings.range.start))
        .round();

    final AxisTitles bottomTitles = AxisTitles(
      sideTitles: SideTitles(
        interval:
            (widget.settings.span.getBuckets(widget.settings.range.start) /
                    widget.settings.span.getTitles())
                .floorToDouble(),
        showTitles: widget.isDetailed,
        getTitlesWidget: (value, meta) {
          if (value == value.ceilToDouble()) {
            final DateTime forPoint = widget.settings.range.start.add(
              Duration(
                milliseconds: (stepSize * value).ceil(),
              ),
            );
            return Text(
              widget.settings.span.getFormat().format(forPoint),
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          return const SizedBox();
        },
      ),
    );

    final int yAxisTicks = widget.isDetailed ? 5 : 3;

    final YAxisRange range = YAxisRange.rangeFromMax(
        ticks: yAxisTicks, max: dataSet.maxY, min: dataSet.minY);

    final AxisTitles leftTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        minIncluded: false,
        interval: range.tickSize == 0 ? null : range.tickSize,
        getTitlesWidget: (value, meta) {
          return Text(
            NumberFormat.compact().format(value.toInt()),
            style: Theme.of(context).textTheme.bodySmall,
          );
        },
      ),
    );

    final FlTitlesData titlesData = FlTitlesData(
      bottomTitles: bottomTitles,
      leftTitles: leftTitles,
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );

    Widget chart;

    if (widget.settings.axis == GraphYAxis.entrytime) {
      chart = LayoutBuilder(builder: (context, constraints) {
        final List<ScatterSpot> spots = dataSet.data as List<ScatterSpot>;
        double spotRadius = min(
            (constraints.maxWidth /
                    widget.settings.span
                        .getBuckets(widget.settings.range.start) /
                    2) *
                0.85,
            24.0);

        final List<ScatterSpot> scaledSpots = spots
            .map(
              (spot) => spot.copyWith(
                dotPainter: FlDotCirclePainter(
                  color: spot.dotPainter.mainColor,
                  radius: spotRadius,
                ),
              ),
            )
            .toList();
        return ScatterChart(
          ScatterChartData(
            scatterSpots: scaledSpots,
            minX: dataSet.minX,
            maxX: dataSet.maxX,
            minY: dataSet.minY,
            maxY: dataSet.maxY,
            gridData: gridData,
            borderData: borderData,
            titlesData: titlesData,
          ),
        );
      });
    } else {
      chart = LayoutBuilder(builder: (context, constraints) {
        final List<BarChartGroupData> barData =
            dataSet.data as List<BarChartGroupData>;

        final List<BarChartGroupData> styled = barData.map((data) {
          return data.copyWith(
              barRods: data.barRods
                  .map(
                    (rod) => rod.copyWith(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(0.0))),
                  )
                  .toList(),
              groupVertically: true,
              barsSpace: 0.0);
        }).toList();
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.center,
            groupsSpace: 1.0,
            barGroups: styled,
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
      });
    }
    return chart;
  }

  GraphDataSet<BarChartGroupData> getBarChartDataSet(
      Map<GraphKey, List<List<Stamp>>> sets) {
    if (sets.isEmpty) return const GraphDataSet.empty();

    final int yAxisTicks = widget.isDetailed ? 5 : 3;

    List<BarChartGroupData> barChartGroups = List.generate(
      sets.values.first.length,
      (index) => BarChartGroupData(x: index),
    );

    double maxY = double.negativeInfinity, minY = double.infinity;

    void adjustBounds(double value) {
      if (value > maxY) {
        maxY = value;
      }
      if (value < minY) {
        minY = value;
      }
    }

    for (final GraphKey graphKey in sets.keys) {
      final List<List<Stamp>> graphSet = sets[graphKey]!;
      for (int i = 0; i < graphSet.length; i++) {
        final List<Stamp> point = graphSet[i];

        BarChartRodData? rod;
        Color? barColor =
            point.isEmpty ? null : estimateColorFor(graphKey, context);
        if (widget.settings.axis == GraphYAxis.frequency) {
          final double rodY = point.length.toDouble();
          adjustBounds(rodY);
          rod = BarChartRodData(toY: rodY, color: barColor);
        } else if (widget.settings.axis == GraphYAxis.average) {
          final Iterable<NumericResponse> numerics =
              point.whereType<NumericResponse>();
          if (numerics.isEmpty) {
            adjustBounds(0);
            rod = BarChartRodData(toY: 0, color: barColor);
            continue;
          }
          double total = 0.0;
          for (final NumericResponse numeric in numerics) {
            total += numeric.response;
          }
          final double average = total / numerics.length;
          adjustBounds(average);
          rod = BarChartRodData(toY: average, color: barColor);
        }
        if (rod == null) continue;
        final BarChartGroupData toEdit = barChartGroups[i];
        barChartGroups[i] = toEdit.copyWith(barRods: [...toEdit.barRods, rod]);
      }
    }

    final YAxisRange range =
        YAxisRange.rangeFromMax(ticks: yAxisTicks, max: maxY, min: minY);

    return GraphDataSet<BarChartGroupData>(
        data: barChartGroups,
        minX: 0,
        maxX: (barChartGroups.length - 1).toDouble(),
        minY: range.lowerBound,
        maxY: range.upperBound);
  }

  GraphDataSet<ScatterSpot> getSpotSet(Map<GraphKey, List<List<Stamp>>> sets) {
    List<ScatterSpot> spots = [];

    for (final GraphKey graphKey in sets.keys) {
      final List<List<Stamp>> graphSet = sets[graphKey]!;
      for (int i = 0; i < graphSet.length; i++) {
        final List<Stamp> atPoint = graphSet[i];
        for (final Stamp value in atPoint) {
          final Color color = estimateColorFor(graphKey, context);
          final DateTime spotDate = dateFromStamp(value.stamp);
          spots.add(
            ScatterSpot(i.toDouble(), (spotDate.hour + (spotDate.minute / 60)),
                dotPainter: FlDotCirclePainter(color: color)),
          );
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
      "${widget.settings.axis == GraphYAxis.average ? rod.toY : rod.toY.toInt()}",
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
  }
}

Color estimateColorFor(GraphKey key, BuildContext context) {
  final List<Color> allColors = [...Colors.primaries, ...Colors.primaries];
  return allColors[key.hashCode % (allColors.length - 1)];
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
