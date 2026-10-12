import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Models/record_time.dart';

class GraphPreparer {
  const GraphPreparer._();

  static PreparedGraph prepare({
    required Map<GraphKey, List<Response>> responses,
    required DisplayDataSettings settings,
    required GraphComparison comparison,
    required Color Function(GraphKey key) colorResolver,
    Map<GraphKey, Color>? colorOverrides,
    Map<GraphKey, String>? labelOverrides,
    String Function(GraphKey key)? labelResolver,
    Map<String, RecordPath>? reviewPaths,
    List<GraphMarker> markers = const [],
  }) {
    final GraphMetric metric = switch (settings.axis) {
      GraphYAxis.number => GraphMetric.reports,
      GraphYAxis.average => GraphMetric.average,
      GraphYAxis.entrytime => GraphMetric.timeOfDay,
    };
    final List<GraphTimeBin> bins = _buildBins(settings);
    final bool intraday = _stepFor(settings).isIntraday;
    final List<PreparedSeries> preparedSeries = <PreparedSeries>[];

    for (final MapEntry<GraphKey, List<Response>> entry in responses.entries) {
      final GraphKey key = entry.key;
      final List<Response> source = List<Response>.of(entry.value)
        ..sort(
          (Response first, Response second) =>
              first.stamp.compareTo(second.stamp),
        );
      final GraphSeriesId seriesId = _seriesId(key);
      final Color color = colorOverrides?[key] ?? colorResolver(key);
      final String label =
          labelOverrides?[key] ?? labelResolver?.call(key) ?? key.title;
      final RecordPath? reviewPath = key.type == null
          ? null
          : reviewPaths?[key.type!];

      if (key.isReview &&
          metric != GraphMetric.average &&
          reviewPath?.period != null) {
        preparedSeries.add(
          _prepareRanges(
            id: seriesId,
            label: label,
            color: color,
            responses: source,
            bins: bins,
            path: reviewPath!,
          ),
        );
        continue;
      }

      preparedSeries.add(switch (metric) {
        GraphMetric.reports => _prepareReports(
          id: seriesId,
          label: label,
          color: color,
          responses: source,
          bins: bins,
          exactOnly: intraday,
        ),
        GraphMetric.average => _prepareAverages(
          id: seriesId,
          label: label,
          color: color,
          responses: source,
          bins: bins,
          exactOnly: intraday,
        ),
        GraphMetric.timeOfDay => _prepareTimes(
          id: seriesId,
          label: label,
          color: color,
          responses: source,
          bins: bins,
          intraday: intraday,
        ),
      });
      if (intraday || metric == GraphMetric.timeOfDay) {
        preparedSeries.addAll(
          _prepareTimingRanges(
            id: seriesId,
            label: label,
            color: color,
            responses: source,
            bins: bins,
            includeDayParts: intraday,
          ),
        );
      }
    }

    final GraphComparison effectiveComparison = _effectiveComparison(
      requested: comparison,
      metric: metric,
      series: preparedSeries,
    );
    final GraphQuery query = GraphQuery(
      start: settings.range.start,
      end: settings.range.end,
      metric: metric,
      comparison: effectiveComparison,
      bins: bins,
    );

    return PreparedGraph(
      query: query,
      lanes: _buildLanes(
        preparedSeries,
        metric: metric,
        comparison: effectiveComparison,
      ),
      markers: markers,
    );
  }

  static PreparedSeries _prepareReports({
    required GraphSeriesId id,
    required String label,
    required Color color,
    required List<Response> responses,
    required List<GraphTimeBin> bins,
    required bool exactOnly,
  }) {
    final List<PreparedDatum> data = <PreparedDatum>[];
    for (final GraphTimeBin bin in bins) {
      final List<Response> evidence = _responsesInBin(
        responses,
        bin,
        exactOnly: exactOnly,
      );
      data.add(
        PreparedDatum(
          id: GraphDatumId(seriesId: id, binIndex: bin.index),
          bin: bin,
          xStart: bin.start,
          xEnd: bin.end,
          value:
              (id.isCategory
                      ? evidence.map(recordIdentityForResponse).toSet().length
                      : evidence.length)
                  .toDouble(),
          evidence: evidence,
          summary: _summarize(evidence),
        ),
      );
    }
    return PreparedSeries(
      id: id,
      label: label,
      color: color,
      mark: GraphMark.bar,
      data: data,
      domainMin: 0,
      unit: 'reports',
      scaleId: 'reportCount',
    );
  }

  static PreparedSeries _prepareAverages({
    required GraphSeriesId id,
    required String label,
    required Color color,
    required List<Response> responses,
    required List<GraphTimeBin> bins,
    required bool exactOnly,
  }) {
    final Numeric? question = responses
        .whereType<NumericResponse>()
        .map((NumericResponse response) => response.question)
        .firstOrNull;
    final List<PreparedDatum> data = <PreparedDatum>[];

    for (final GraphTimeBin bin in bins) {
      final List<NumericResponse> evidence = _responsesInBin(
        responses,
        bin,
        exactOnly: exactOnly,
      ).whereType<NumericResponse>().toList(growable: false);
      final double? value = evidence.isEmpty
          ? null
          : evidence.fold<double>(
                  0,
                  (double sum, NumericResponse item) => sum + item.response,
                ) /
                evidence.length;
      data.add(
        PreparedDatum(
          id: GraphDatumId(seriesId: id, binIndex: bin.index),
          bin: bin,
          xStart: bin.start,
          xEnd: bin.end,
          value: value,
          evidence: evidence,
          summary: _summarize(evidence),
        ),
      );
    }

    return PreparedSeries(
      id: id,
      label: label,
      color: color,
      mark: GraphMark.bar,
      data: data,
      domainMin: question?.min?.toDouble(),
      domainMax: question?.max?.toDouble(),
      unit: 'average',
      scaleId: question?.min == null || question?.max == null
          ? null
          : 'numeric:${question!.min!.toDouble()}:${question.max!.toDouble()}',
    );
  }

  static PreparedSeries _prepareTimes({
    required GraphSeriesId id,
    required String label,
    required Color color,
    required List<Response> responses,
    required List<GraphTimeBin> bins,
    required bool intraday,
  }) {
    final groups = <(DateTime, int, int?), List<Response>>{};
    for (final response in responses) {
      final timing = recordTimeForResponse(response);
      if (timing?.precision == RecordTimePrecision.unknown) continue;
      final approximate = hasApproximateRecordTime(response);
      if (approximate && intraday) continue;
      final date = occurrenceTimeForResponse(response);
      final interval = occurrenceRangeForResponse(response);
      if (_binFor(date, bins) == null &&
          (interval == null || _binForInterval(interval, bins) == null)) {
        continue;
      }
      final part = timing?.dayPart;
      final key = (
        DateUtils.dateOnly(date),
        approximate
            ? (part?.startHour ?? 0) * 60
            : date.hour * 60 + date.minute,
        approximate ? (part?.endHour ?? 24) * 60 : null,
      );
      groups.putIfAbsent(key, () => []).add(response);
    }
    final data = <PreparedDatum>[];
    for (final group in groups.entries) {
      final date = occurrenceTimeForResponse(group.value.first);
      final bin =
          _binFor(date, bins) ??
          _binForInterval(occurrenceRangeForResponse(group.value.first)!, bins);
      if (bin == null) continue;
      final day = group.key.$1;
      data.add(
        PreparedDatum(
          id: GraphDatumId(
            seriesId: id,
            binIndex: bin.index,
            ordinal: data.length,
          ),
          bin: bin,
          xStart: intraday ? date : _visibleDayCenter(day, bins),
          value: group.key.$2 / 60,
          valueEnd: group.key.$3 == null ? null : group.key.$3! / 60,
          timing: group.key.$3 == null
              ? GraphTiming.exact
              : GraphTiming.dayPart,
          evidence: group.value,
          summary: _summarize(group.value),
        ),
      );
    }
    return PreparedSeries(
      id: id,
      label: label,
      color: color,
      mark: GraphMark.point,
      data: data,
      domainMin: 0,
      domainMax: 24,
      unit: 'time',
      scaleId: 'timeOfDay',
    );
  }

  static DateTime _visibleDayCenter(DateTime day, List<GraphTimeBin> bins) {
    final end = DateTime(day.year, day.month, day.day + 1);
    final start = day.isBefore(bins.first.start) ? bins.first.start : day;
    final visibleEnd = end.isAfter(bins.last.end) ? bins.last.end : end;
    return start.add(visibleEnd.difference(start) ~/ 2);
  }

  static Iterable<PreparedSeries> _prepareTimingRanges({
    required GraphSeriesId id,
    required String label,
    required Color color,
    required List<Response> responses,
    required List<GraphTimeBin> bins,
    required bool includeDayParts,
  }) sync* {
    for (final timing in [GraphTiming.dayPart, GraphTiming.unknown]) {
      if (timing == GraphTiming.dayPart && !includeDayParts) continue;
      final groups = <(DateTime, DateTime), List<Response>>{};
      for (final response in responses) {
        final precision = recordTimeForResponse(response)?.precision;
        if (timing == GraphTiming.unknown
            ? precision != RecordTimePrecision.unknown
            : precision != RecordTimePrecision.dayPart) {
          continue;
        }
        final interval = occurrenceRangeForResponse(response)!;
        if (_binForInterval(interval, bins) == null) continue;
        groups
            .putIfAbsent((interval.start, interval.end), () => [])
            .add(response);
      }
      if (groups.isEmpty) continue;
      final rangeId = GraphSeriesId(
        title: id.title,
        questionId: id.questionId,
        type: id.type,
        isCategory: id.isCategory,
        isReview: id.isReview,
        timing: timing,
      );
      final data = <PreparedDatum>[];
      for (final group in groups.entries) {
        final interval = DateTimeRange(start: group.key.$1, end: group.key.$2);
        final bin = _binForInterval(interval, bins)!;
        data.add(
          PreparedDatum(
            id: GraphDatumId(
              seriesId: rangeId,
              binIndex: bin.index,
              ordinal: data.length,
            ),
            bin: bin,
            xStart: interval.start,
            xEnd: interval.end,
            value: null,
            timing: timing,
            evidence: group.value,
            summary: _summarize(group.value),
          ),
        );
      }
      yield PreparedSeries(
        id: rangeId,
        label:
            '$label · ${timing == GraphTiming.unknown ? 'Time unknown' : 'Approximate time'}',
        color: color,
        mark: GraphMark.range,
        data: data,
        domainMin: 0,
        domainMax: 1,
        unit: 'reports',
        scaleId: 'timing:${timing.name}',
      );
    }
  }

  static GraphTimeBin? _binForInterval(
    DateTimeRange interval,
    List<GraphTimeBin> bins,
  ) {
    for (final bin in bins) {
      if (interval.start.isBefore(bin.end) && interval.end.isAfter(bin.start)) {
        return bin;
      }
    }
    return null;
  }

  static PreparedSeries _prepareRanges({
    required GraphSeriesId id,
    required String label,
    required Color color,
    required List<Response> responses,
    required List<GraphTimeBin> bins,
    required RecordPath path,
  }) {
    final List<PreparedDatum> data = <PreparedDatum>[];
    final Map<(DateTime, DateTime), List<Response>> byPeriod =
        <(DateTime, DateTime), List<Response>>{};
    for (final Response response in responses) {
      final DateTime date = occurrenceTimeForResponse(response);
      final DateTimeRange period = path.period!.getRange(
        DateUtils.dateOnly(date),
      );
      if (_binForInterval(period, bins) == null) continue;
      byPeriod
          .putIfAbsent((period.start, period.end), () => <Response>[])
          .add(response);
    }
    final List<MapEntry<(DateTime, DateTime), List<Response>>> periods =
        byPeriod.entries.toList()
          ..sort((first, second) => first.key.$1.compareTo(second.key.$1));
    for (final periodEntry in periods) {
      final DateTime start = periodEntry.key.$1;
      final DateTime end = periodEntry.key.$2;
      final List<Response> evidence = periodEntry.value;
      final GraphTimeBin? bin = _binForInterval(
        DateTimeRange(start: start, end: end),
        bins,
      );
      data.add(
        PreparedDatum(
          id: GraphDatumId(
            seriesId: id,
            binIndex: bin?.index ?? -1,
            ordinal: start.microsecondsSinceEpoch,
          ),
          bin: bin,
          xStart: start,
          xEnd: end,
          value: null,
          timing: GraphTiming.reviewPeriod,
          evidence: evidence,
          summary: _summarize(evidence),
        ),
      );
    }

    return PreparedSeries(
      id: id,
      label: label,
      color: color,
      mark: GraphMark.range,
      data: data,
      domainMin: 0,
      domainMax: 1,
      unit: 'period',
      scaleId: 'reviewPeriod',
    );
  }

  static GraphDatumSummary _summarize(Iterable<Stamp> stamps) {
    final List<Response> responses = stamps.whereType<Response>().toList();
    Iterable<Response> answers(Response response) sync* {
      if (response is ResponseWrap) {
        for (final child in response.responses) {
          yield* answers(child);
        }
      } else {
        yield response;
      }
    }

    final flattened = responses.expand(answers).toList();
    final List<NumericResponse> numerics = flattened
        .whereType<NumericResponse>()
        .toList();
    final Map<String, int> choices = <String, int>{};
    for (final Response response in flattened) {
      switch (response) {
        case MultiResponse():
          choices.update(
            response.choice,
            (int value) => value + 1,
            ifAbsent: () => 1,
          );
        case AllResponse():
          for (final String choice in response.choices) {
            choices.update(choice, (int value) => value + 1, ifAbsent: () => 1);
          }
        default:
          break;
      }
    }
    final uniqueEntries = responses.map(recordIdentityForResponse).toSet();
    return GraphDatumSummary(
      reportCount: responses.length,
      uniqueEntryCount: uniqueEntries.length,
      numericAverage: numerics.isEmpty
          ? null
          : numerics.fold<double>(
                  0,
                  (double sum, NumericResponse item) => sum + item.response,
                ) /
                numerics.length,
      choiceCounts: choices,
    );
  }

  static List<Response> _responsesInBin(
    List<Response> responses,
    GraphTimeBin bin, {
    bool exactOnly = false,
  }) {
    return responses
        .where((Response response) {
          if (exactOnly && hasApproximateRecordTime(response)) return false;
          final date = occurrenceTimeForResponse(response);
          if (bin.contains(date)) return true;
          final interval = occurrenceRangeForResponse(response);
          return interval != null &&
              date.isBefore(bin.start) &&
              interval.end.isAfter(bin.start);
        })
        .toList(growable: false);
  }

  static GraphTimeBin? _binFor(DateTime value, List<GraphTimeBin> bins) {
    for (final GraphTimeBin bin in bins) {
      if (bin.contains(value)) return bin;
    }
    return null;
  }

  static GraphSeriesId _seriesId(GraphKey key) => GraphSeriesId(
    title: key.title,
    questionId: key.qid,
    type: key.type,
    isCategory: key.isCategory,
    isReview: key.isReview,
  );

  static GraphComparison _effectiveComparison({
    required GraphComparison requested,
    required GraphMetric metric,
    required List<PreparedSeries> series,
  }) {
    if (requested == GraphComparison.stacked && metric != GraphMetric.reports) {
      return GraphComparison.separate;
    }
    if (requested == GraphComparison.stacked &&
        series
                .where((item) => item.mark != GraphMark.range)
                .map((item) => item.id.isCategory)
                .toSet()
                .length >
            1) {
      return GraphComparison.separate;
    }
    if (requested == GraphComparison.overlaid &&
        metric == GraphMetric.average &&
        !_compatibleNumericDomains(series)) {
      return GraphComparison.separate;
    }
    return requested;
  }

  static bool _compatibleNumericDomains(List<PreparedSeries> series) {
    final List<PreparedSeries> numeric = series
        .where((PreparedSeries item) => item.mark != GraphMark.range)
        .toList();
    if (numeric.length < 2) return true;
    final PreparedSeries first = numeric.first;
    if (first.domainMin == null ||
        first.domainMax == null ||
        first.scaleId == null) {
      return false;
    }
    return numeric
        .skip(1)
        .every(
          (PreparedSeries item) =>
              item.scaleId == first.scaleId &&
              item.domainMin == first.domainMin &&
              item.domainMax == first.domainMax,
        );
  }

  static List<PreparedLane> _buildLanes(
    List<PreparedSeries> series, {
    required GraphMetric metric,
    required GraphComparison comparison,
  }) {
    final List<PreparedLane> lanes = <PreparedLane>[];
    final List<PreparedSeries> ranges = series
        .where((PreparedSeries item) => item.mark == GraphMark.range)
        .toList();
    final List<PreparedSeries> values = series
        .where((PreparedSeries item) => item.mark != GraphMark.range)
        .toList();

    if (comparison == GraphComparison.separate) {
      final double sharedReportMax = metric == GraphMetric.reports
          ? math.max(
              1,
              values
                  .expand((PreparedSeries item) => item.data)
                  .map((PreparedDatum datum) => datum.value)
                  .whereType<double>()
                  .fold<double>(0, math.max),
            )
          : 1;
      for (final PreparedSeries item in values) {
        final PreparedLane lane = _lane(
          lanes.length,
          item.label,
          <PreparedSeries>[item],
          metric: metric,
          comparison: comparison,
        );
        lanes.add(
          metric == GraphMetric.reports
              ? PreparedLane(
                  index: lane.index,
                  label: lane.label,
                  series: lane.series,
                  scaleKind: lane.scaleKind,
                  minY: 0,
                  maxY: sharedReportMax,
                )
              : lane,
        );
      }
    } else if (values.isNotEmpty) {
      final String label = comparison == GraphComparison.stacked
          ? 'Stacked reports'
          : 'Overlaid comparison';
      lanes.add(
        _lane(
          lanes.length,
          label,
          values,
          metric: metric,
          comparison: comparison,
        ),
      );
    }

    for (final PreparedSeries item in ranges) {
      lanes.add(
        PreparedLane(
          index: lanes.length,
          label: item.label,
          series: <PreparedSeries>[item],
          scaleKind: GraphScaleKind.range,
          minY: 0,
          maxY: 1,
        ),
      );
    }
    return lanes;
  }

  static PreparedLane _lane(
    int index,
    String label,
    List<PreparedSeries> series, {
    required GraphMetric metric,
    required GraphComparison comparison,
  }) {
    if (metric == GraphMetric.timeOfDay) {
      return PreparedLane(
        index: index,
        label: label,
        series: series,
        scaleKind: GraphScaleKind.hour,
        minY: 0,
        maxY: 24,
      );
    }

    final Iterable<double> values = series
        .expand((PreparedSeries item) => item.data)
        .map((PreparedDatum datum) => datum.value)
        .whereType<double>()
        .where((double value) => value.isFinite);
    double minY = series
        .map((PreparedSeries item) => item.domainMin)
        .whereType<double>()
        .fold<double>(double.infinity, math.min);
    double maxY = series
        .map((PreparedSeries item) => item.domainMax)
        .whereType<double>()
        .fold<double>(double.negativeInfinity, math.max);

    if (values.isNotEmpty) {
      minY = math.min(minY, values.reduce(math.min));
      maxY = math.max(maxY, values.reduce(math.max));
    }
    if (comparison == GraphComparison.stacked) {
      final Map<int, double> totals = <int, double>{};
      for (final PreparedSeries item in series) {
        for (final PreparedDatum datum in item.data) {
          if (datum.value == null || datum.bin == null) continue;
          totals.update(
            datum.bin!.index,
            (double total) => total + datum.value!,
            ifAbsent: () => datum.value!,
          );
        }
      }
      if (totals.isNotEmpty) maxY = totals.values.reduce(math.max);
    }

    if (!minY.isFinite) minY = 0;
    if (!maxY.isFinite) maxY = 1;
    if (metric == GraphMetric.reports) minY = 0;
    if (maxY <= minY) {
      maxY = minY == 0 ? 1 : minY + math.max(minY.abs() * 0.1, 1);
    }

    return PreparedLane(
      index: index,
      label: label,
      series: series,
      scaleKind: metric == GraphMetric.reports
          ? GraphScaleKind.count
          : GraphScaleKind.numeric,
      minY: minY,
      maxY: maxY,
    );
  }

  static List<GraphTimeBin> _buildBins(DisplayDataSettings settings) {
    final DateTime start = settings.range.start.toLocal();
    final DateTime end = settings.range.end.toLocal();
    if (!start.isBefore(end)) return const <GraphTimeBin>[];

    final _BinStep step = _stepFor(settings);
    final DateFormat formatter = switch (step.unit) {
      _BinUnit.second => DateFormat('MMM d, HH:mm:ss'),
      _BinUnit.minute || _BinUnit.hour => DateFormat('MMM d, HH:mm'),
      _BinUnit.day || _BinUnit.week => DateFormat(
        start.year == end.year ? 'MMM d' : 'MMM d, yyyy',
      ),
      _BinUnit.month => DateFormat('MMM yyyy'),
      _BinUnit.year => DateFormat('yyyy'),
    };
    final List<GraphTimeBin> bins = <GraphTimeBin>[];
    DateTime cursor = _floorStep(start, step);
    int safety = 0;
    while (cursor.isBefore(end) && safety++ < 10000) {
      final next = _advance(cursor, step);
      if (!next.isAfter(cursor)) break;
      final visibleStart = cursor.isBefore(start) ? start : cursor;
      final visibleEnd = next.isAfter(end) ? end : next;
      bins.add(
        GraphTimeBin(
          index: bins.length,
          start: visibleStart,
          end: visibleEnd,
          label: formatter.format(visibleStart),
        ),
      );
      cursor = next;
    }
    return bins;
  }

  static _BinStep _stepFor(DisplayDataSettings settings) =>
      switch (settings.cycle) {
        TimeCycle.day => const _BinStep(_BinUnit.hour),
        TimeCycle.week || TimeCycle.month => const _BinStep(_BinUnit.day),
        TimeCycle.quarter => const _BinStep(_BinUnit.week),
        TimeCycle.year => const _BinStep(_BinUnit.month),
        TimeCycle.custom ||
        TimeCycle.all => _autoStep(settings.range.start, settings.range.end),
      };

  static DateTime _floorStep(DateTime date, _BinStep step) {
    final amount = step.amount;
    switch (step.unit) {
      case _BinUnit.second:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second ~/ amount * amount,
        );
      case _BinUnit.minute:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute ~/ amount * amount,
        );
      case _BinUnit.hour:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour ~/ amount * amount,
        );
      case _BinUnit.day:
      case _BinUnit.week:
        // UTC date arithmetic here measures calendar days across DST changes.
        final epoch = DateTime.utc(1970, 1, step.unit == _BinUnit.week ? 5 : 1);
        final days = DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(epoch).inDays;
        final span = amount * (step.unit == _BinUnit.week ? 7 : 1);
        final aligned = epoch.add(Duration(days: (days / span).floor() * span));
        return DateTime(aligned.year, aligned.month, aligned.day);
      case _BinUnit.month:
        final month = date.year * 12 + date.month - 1;
        final aligned = month ~/ amount * amount;
        return DateTime(aligned ~/ 12, aligned % 12 + 1);
      case _BinUnit.year:
        return DateTime(date.year ~/ amount * amount);
    }
  }

  static _BinStep _autoStep(DateTime start, DateTime end) {
    final Duration duration = end.difference(start);
    if (duration.inSeconds <= 120) {
      return _BinStep(
        _BinUnit.second,
        math.max(1, (duration.inSeconds / 50).ceil()),
      );
    }
    if (duration.inMinutes <= 120) {
      return _BinStep(
        _BinUnit.minute,
        math.max(1, (duration.inMinutes / 50).ceil()),
      );
    }
    if (duration.inHours <= 48) {
      return _BinStep(
        _BinUnit.hour,
        math.max(1, (duration.inHours / 48).ceil()),
      );
    }
    if (duration.inDays <= 60) {
      return _BinStep(_BinUnit.day, math.max(1, (duration.inDays / 50).ceil()));
    }
    if (duration.inDays <= 730) {
      return _BinStep(
        _BinUnit.week,
        math.max(1, (duration.inDays / 350).ceil()),
      );
    }
    if (duration.inDays <= 3650) {
      final int months = math.max(1, (duration.inDays / 30).ceil());
      return _BinStep(_BinUnit.month, math.max(1, (months / 50).ceil()));
    }
    final int years = math.max(1, (duration.inDays / 365).ceil());
    return _BinStep(_BinUnit.year, math.max(1, (years / 50).ceil()));
  }

  static DateTime _advance(DateTime date, _BinStep step) => switch (step.unit) {
    _BinUnit.second => date.add(Duration(seconds: step.amount)),
    _BinUnit.minute => date.add(Duration(minutes: step.amount)),
    _BinUnit.hour => date.add(Duration(hours: step.amount)),
    _BinUnit.day => DateTime(
      date.year,
      date.month,
      date.day + step.amount,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    ),
    _BinUnit.week => DateTime(
      date.year,
      date.month,
      date.day + (7 * step.amount),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    ),
    _BinUnit.month => _addMonths(date, step.amount),
    _BinUnit.year => _addMonths(date, 12 * step.amount),
  };

  static DateTime _addMonths(DateTime date, int count) {
    final int monthIndex = (date.month - 1) + count;
    final int year = date.year + (monthIndex ~/ 12);
    final int month = (monthIndex % 12) + 1;
    final int lastDay = DateUtils.getDaysInMonth(year, month);
    return DateTime(
      year,
      month,
      math.min(date.day, lastDay),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}

enum _BinUnit { second, minute, hour, day, week, month, year }

class _BinStep {
  final _BinUnit unit;
  final int amount;

  const _BinStep(this.unit, [this.amount = 1]);

  bool get isIntraday =>
      unit == _BinUnit.second ||
      unit == _BinUnit.minute ||
      unit == _BinUnit.hour;
}
