import 'dart:math';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';

@immutable
class CategoryBehaviorMaps {
  final Map<String, int> categoryMap;
  final Map<String, List<Response>> behaviorMap;
  final Map<String, Map<String, int>> categoryBehaviorMap;
  const CategoryBehaviorMaps(
      this.categoryMap, this.behaviorMap, this.categoryBehaviorMap);

  factory CategoryBehaviorMaps.empty() =>
      const CategoryBehaviorMaps({}, {}, {});
}

List<Response> _flattenedPrompts(Iterable<Response> input) {
  List<Response> flat = [];
  for (Response res in input) {
    if (res is DetailResponse) {
      flat.addAll(_flattenedPrompts(res.responses));
    } else {
      flat.add(res);
    }
  }
  return flat;
}

List<Response> _flattenedPrompt(Response input) {
  return _flattenedPrompts([input]);
}

Map<String, int> _orderedResponses(List<Response> responses, Set<String> keys,
    String Function(Response) getKey) {
  Map<String, int> map = {for (String val in keys) val: 0};
  for (Response res in responses) {
    final String key = getKey(res);
    if (map.containsKey(key)) {
      final int val = map[key]!;
      map[key] = val + 1;
    }
  }
  return _sortedMap<int>(map, (val) => val);
}

Map<String, T> _sortedMap<T>(Map<String, T> input, num Function(T) getVal) {
  List<String> sortedKeys = input.keys.toList()
    ..sort(
      (a, b) => getVal(input[b] as T).compareTo(
        getVal(input[a] as T),
      ),
    );
  return {for (String key in sortedKeys) key: input[key] as T};
}

CategoryBehaviorMaps _generateValueMaps(
    Available availible, List<Response> all, List<Response> filt) {
  if (all.isEmpty || filt.isEmpty) return CategoryBehaviorMaps.empty();
  Set<String> types = {};
  Map<String, Set<String>> promptKeys = {};
  for (Response res in all) {
    final String type = res.type;
    types.add(type);
    if (res.question.prompt.isEmpty || res.question.id == '4') continue;
    if (promptKeys.containsKey(type)) {
      promptKeys[type]!.add(res.question.prompt);
    } else {
      promptKeys[type] = {res.question.prompt};
    }
  }

  Map<String, List<Response>> prompts = {};
  Map<String, List<Response>> behaviorMap = {};
  for (Response parent in filt) {
    for (Response res in _flattenedPrompt(parent)) {
      final String type = res.type;
      final String prompt = res.question.prompt;
      if (behaviorMap.containsKey(prompt)) {
        behaviorMap[prompt]!.add(res);
      } else {
        behaviorMap[prompt] = [res];
      }
      if (prompts.containsKey(res.type)) {
        prompts[type]!.add(res);
      } else {
        prompts[type] = [res];
      }
    }
  }
  behaviorMap = _sortedMap<List<Response>>(behaviorMap, (list) => list.length);
  final Map<String, int> categoryMap =
      _orderedResponses(filt, types, (res) => res.type);
  final Map<String, Map<String, int>> promptsMap = {
    for (String key in types)
      key: _orderedResponses(
          prompts[key]!, promptKeys[key]!, (res) => res.question.prompt)
  };
  return CategoryBehaviorMaps(categoryMap, behaviorMap, promptsMap);
}

@immutable
class GraphData extends Equatable {
  final DateTime? start, end;
  final Map<int, GraphLabel> labels;
  final Map<String, GraphBarData> behaviorBarData;
  final String axisLabel;
  const GraphData(
      {required this.start,
      required this.end,
      required this.behaviorBarData,
      required this.labels,
      required this.axisLabel});

  factory GraphData.empty() => const GraphData(
      start: null, end: null, behaviorBarData: {}, labels: {}, axisLabel: '');

  bool get isEmpty => this == GraphData.empty();

  @override
  List<Object?> get props => [start, end, labels, behaviorBarData, axisLabel];
}

@immutable
class GraphLabel {
  final String value, abr;
  const GraphLabel(this.value, this.abr);
}

@immutable
class GraphBarData extends Equatable {
  final List<BarData> barData;
  final int maxHeight;
  final bool isSeverity;
  final num? minSeverity, maxSeverity;
  const GraphBarData(
      {required this.barData,
      required this.maxHeight,
      required this.isSeverity,
      this.minSeverity,
      this.maxSeverity});

  factory GraphBarData.empty() =>
      const GraphBarData(barData: [], maxHeight: 0, isSeverity: false);

  bool get isEmpty => this == GraphBarData.empty();

  @override
  List<Object?> get props =>
      [barData, maxHeight, isSeverity, minSeverity, maxSeverity];
}

@immutable
class BarData extends Equatable {
  final int height;
  final double? severity;
  const BarData(this.height, this.severity);

  factory BarData.empty() => const BarData(0, null);

  @override
  List<Object?> get props => [height, severity];
}

GraphBarData _bucketEvents(
    List<Response> events, double start, double inc, int detail) {
  final Response sample = events.first;
  final bool isSeverity = sample is NumericResponse;

  List<BarData> data = [];
  int furthestReach = 0;
  int maxHeight = 0;
  for (int i = 0; i < detail; i++) {
    final double lower = start + (i * inc);
    final double upper = start + ((i + 1) * inc);

    List<Response> valsInRange = [];

    while (furthestReach < events.length) {
      final Response current = events[furthestReach];
      if (current.stamp < lower || current.stamp > upper) {
        break;
      }
      valsInRange.add(current);
      furthestReach++;
    }
    BarData point;
    if (valsInRange.isEmpty) {
      point = BarData.empty();
    } else {
      final int rangeLength = valsInRange.length;
      if (isSeverity) {
        double value = 0;
        for (NumericResponse res in valsInRange.whereType<NumericResponse>()) {
          value += res.response;
        }
        point = BarData(rangeLength,
            double.parse((((value / rangeLength))).toStringAsFixed(1)));
      } else {
        point = BarData(rangeLength, null);
      }
    }
    maxHeight = max(point.height, maxHeight);
    data.add(point);
  }
  if (!isSeverity) {
    return GraphBarData(
        barData: data, maxHeight: maxHeight, isSeverity: isSeverity);
  }
  Numeric numeric = sample.question;
  return GraphBarData(
      barData: data,
      maxHeight: maxHeight,
      isSeverity: isSeverity,
      maxSeverity: numeric.max,
      minSeverity: numeric.min);
}

Map<int, GraphLabel> _iterLabels(
    int bucketDivisor,
    int detail,
    Duration shiftAmount,
    DateTime startDate,
    GraphLabel Function(DateTime) convert) {
  Map<int, GraphLabel> labels = {};
  final double inc = shiftAmount.inMilliseconds / bucketDivisor.toDouble();
  final double start = dateToStamp(startDate).toDouble();
  for (int i = 0; i < bucketDivisor; i++) {
    if (bucketDivisor % detail == 0) {
      DateTime dateTime = dateFromStamp((start + (inc * i)).toInt());
      labels[i] = convert(dateTime);
    }
  }
  return labels;
}

// ignore: unused_element
double _genVariance(GraphBarData packet) {
  List<BarData> points = packet.barData;
  double sum = 0;
  for (int i = 0; i < points.length; i++) {
    sum += points[i].height;
  }
  final double aver = sum / points.length;
  return points.map((point) {
        final diff = point.height - aver;
        return diff * diff;
      }).reduce((value, element) => value + element) /
      points.length;
}

Map<GraphChoice, int> buckets = {
  GraphChoice.day: 8,
  GraphChoice.week: 7,
  GraphChoice.month: 30,
  GraphChoice.year: 12,
};

GraphData _generateData(Available availible, GraphChoice graph, DateTime end,
    Map<String, List<Response>> behaviors) {
  final int bucketDivisor = buckets[graph]!;
  final Duration shiftAmount = graphToDuration[graph]!;
  final DateTime startDate = end.subtract(shiftAmount);
  Map<int, GraphLabel> labels = {};
  String axisLabel = '';
  switch (graph) {
    case GraphChoice.day:
      labels = _iterLabels(bucketDivisor, 4, shiftAmount, startDate, (date) {
        final TimeOfDay time = TimeOfDay.fromDateTime(date);
        final String timeVal = timeString(time, hasPeriod: false);
        final String timePeriod = timeString(time);
        return GraphLabel(timePeriod, timeVal);
      });
      axisLabel = 'Time';
      break;
    case GraphChoice.week:
      labels = _iterLabels(bucketDivisor, 1, shiftAmount, startDate, (date) {
        final String dayVal = date.getDayString();
        return GraphLabel(dayVal, dayVal.substring(0, 1));
      });
      axisLabel = 'Day';
      break;
    case GraphChoice.month:
      labels = _iterLabels(bucketDivisor, 3, shiftAmount, startDate, (date) {
        final String dayVal = date.getDayString();
        return GraphLabel(dayVal, dayVal.substring(0, 1));
      });
      axisLabel = 'Day';
      break;
    case GraphChoice.year:
      labels = _iterLabels(bucketDivisor, 1, shiftAmount, startDate, (date) {
        final String monthVal = date.getMonthString();
        return GraphLabel(monthVal, monthVal.substring(0, 1));
      });
      axisLabel = 'Month';
      break;
  }

  Map<String, GraphBarData> res = {};

  for (String key in behaviors.keys) {
    List<Response> values = behaviors[key]!.reversed.toList();

    final DateTime start = shiftAmount == Duration.zero
        ? dateFromStamp(availible.all.last.stamp)
        : startDate;

    if (values.isEmpty) {
      res[key] = GraphBarData.empty();
      continue;
    }

    final double inc = end.difference(start).inMilliseconds.toDouble() /
        bucketDivisor.toDouble();

    res[key] = _bucketEvents(
        values, dateToStamp(start).toDouble(), inc, bucketDivisor);
  }

  Map<String, GraphBarData> sorted = _sortedMap(res,
      (val) => (val.barData.where((element) => element.height > 0).length));
  return GraphData(
      start: startDate,
      end: end,
      behaviorBarData: sorted,
      labels: labels,
      axisLabel: axisLabel);
}

final resMapProvider =
    FutureProvider.autoDispose<CategoryBehaviorMaps>((ref) async {
  final Available availible = ref.watch(availibleStampsProvider);
  final List<Response> all = availible.all;
  final List<Response> filt = availible.filtered;
  CancelableOperation<CategoryBehaviorMaps> freqs =
      CancelableOperation.fromFuture(
          Future.microtask(() => _generateValueMaps(availible, all, filt)));
  ref.onDispose(() {
    freqs.cancel();
  });
  return freqs.value;
});

final orderedBehaviorProvider =
    FutureProvider.autoDispose<GraphData>((ref) async {
  Map<String, List<Response>> behaviors = ref.watch(
    resMapProvider.select(
      (value) => value.when(
          data: (data) => data.behaviorMap,
          error: (_, __) => {},
          loading: () => {}),
    ),
  );
  if (behaviors.isEmpty) return GraphData.empty();

  Available availible = ref.watch(availibleStampsProvider);

  GraphChoice graph =
      ref.watch(historyLocationProvider.select((value) => value.graph));
  DateTime end =
      ref.watch(filtersProvider.select((value) => value.end)) ?? DateTime.now();

  CancelableOperation<GraphData> packets = CancelableOperation.fromFuture(
      Future.microtask(() => _generateData(availible, graph, end, behaviors)));
  ref.onDispose(() {
    packets.cancel();
  });
  return packets.value;
});
