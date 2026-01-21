import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';

class GraphDataProcessor {
  static List<ChartSeriesData<GraphPoint, DateTime>> processData({
    required Map<GraphKey, List<Response>> responses,
    required DisplayDataSettings settings,
    required GraphOverviewMode mode,
    required Color Function(GraphKey) colorResolver,
    required BoxConstraints constraints,
    Map<GraphKey, Color>? colorKeys,
    Map<String, RecordPath>? reviewPaths,
  }) {
    final List<ChartSeriesData<GraphPoint, DateTime>> datasets = [];
    final int buckets = settings.getBuckets();
    final double stepSizeMs = settings.range.duration.inMilliseconds / buckets;
    final int startTime = settings.range.start.millisecondsSinceEpoch;

    for (final GraphKey key in responses.keys) {
      if (key.isReview) {
        final RecordPath? reviewPath = (key.type != null && reviewPaths != null)
            ? reviewPaths[key.type!]
            : null;

        if (reviewPath?.period != null) {
          final Color color = colorKeys?[key] ?? colorResolver(key);
          final List<Response> keyResponses = responses[key]!;

          // Create range data for each response using RangeGraphPoint
          final List<RangeGraphPoint> rangePoints = [];
          for (int i = 0; i < keyResponses.length; i++) {
            final Response response = keyResponses[i];
            final DateTime stampDate =
                DateUtils.dateOnly(dateFromStamp(response.stamp));
            final DateTimeRange range = reviewPath!.period!.getRange(stampDate);
            rangePoints.add(RangeGraphPoint(
              range.start.millisecondsSinceEpoch.toDouble(),
              range.end.millisecondsSinceEpoch.toDouble(),
              0,
              color,
              [response],
            ));
          }

          datasets.add(RangeChartData<GraphPoint, DateTime>(
            data: rangePoints,
            getPointX: (p, i) =>
                DateTime.fromMillisecondsSinceEpoch(p.x.toInt()),
            getPointXEnd: (p, i) => DateTime.fromMillisecondsSinceEpoch(
                (p as RangeGraphPoint).xEnd.toInt()),
            getPointY: (p, i) => p.y,
            getPointColor: (p, i) {
              return p.color;
            },
          ));
          continue;
        }
      }

      final List<List<Stamp>>? bucketsData =
          bucketEvents(responses[key]!, settings.range, buckets);

      if (bucketsData == null) continue;

      final Color color = colorKeys?[key] ?? colorResolver(key);

      if (settings.axis == GraphYAxis.entrytime) {
        final List<GraphPoint> points = [];
        for (int i = 0; i < bucketsData.length; i++) {
          final Map<double, List<Stamp>> grouped = {};
          for (final stamp in bucketsData[i]) {
            final date = dateFromStamp(stamp.stamp);
            final double y = date.hour + (date.minute / 60.0);
            grouped.putIfAbsent(y, () => []).add(stamp);
          }

          final x = startTime + (i * stepSizeMs) + (stepSizeMs / 2);
          for (final entry in grouped.entries) {
            final double y = entry.key;
            final List<Stamp> stamps = entry.value;
            points.add(GraphPoint(x, y, color, stamps));
          }
        }

        double spotRadius =
            min((constraints.maxWidth / buckets.toDouble() / 2) * 0.6, 6.0);

        datasets.add(ScatterChartData<GraphPoint, DateTime>(
          data: points,
          getPointX: (p, i) => DateTime.fromMillisecondsSinceEpoch(p.x.toInt()),
          getPointY: (p, i) => p.y,
          getPointColor: (p, i) {
            return mode == GraphOverviewMode.overlayed
                ? p.color.withValues(alpha: 0.5)
                : p.color;
          },
          getRadius: (_) => spotRadius,
        ));
      } else {
        final List<GraphPoint> points = [];
        for (int i = 0; i < bucketsData.length; i++) {
          final List<Stamp> bucket = bucketsData[i];
          double y = 0;
          if (settings.axis == GraphYAxis.number) {
            y = bucket.length.toDouble();
          } else {
            final numerics = bucket.whereType<NumericResponse>();
            if (numerics.isNotEmpty) {
              y = numerics.map((e) => e.response).average;
            }
          }

          final x = startTime + (i * stepSizeMs) + (stepSizeMs / 2);
          points.add(GraphPoint(x, y, color, bucket));
        }
        datasets.add(BarChartData<GraphPoint, DateTime>(
          data: points,
          getPointX: (p, i) => DateTime.fromMillisecondsSinceEpoch(p.x.toInt()),
          getPointY: (p, i) => p.y,
          getPointColor: (p, i) {
            return p.color;
          },
        ));
      }
    }
    return datasets;
  }

  // Helper method copied from GraphSymptom
  static List<List<Stamp>>? bucketEvents(
      List<Stamp> events, DateTimeRange range, int buckets) {
    if (events.isEmpty) return null;
    List<List<Stamp>> eventLists = [];
    final double startValue = range.start.millisecondsSinceEpoch.toDouble();
    final double endValue = range.end.millisecondsSinceEpoch.toDouble();
    final double totalRange = endValue - startValue;
    final double stepSize = totalRange / buckets.toDouble();

    events.sort((first, second) => first.stamp.compareTo(second.stamp));
    int furthestReach = 0;
    for (double start = startValue; start < endValue; start += stepSize) {
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
}
