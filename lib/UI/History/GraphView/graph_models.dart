import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

enum GraphMetric { reports, average, timeOfDay }

enum GraphComparison { separate, stacked, overlaid }

enum GraphMark { bar, point, line, range }

enum GraphScaleKind { numeric, count, hour, range }

enum GraphTiming { exact, dayPart, unknown, reviewPeriod }

@immutable
class GraphSeriesId extends Equatable {
  final String title;
  final String? questionId;
  final String? type;
  final bool isCategory;
  final bool isReview;
  final GraphTiming? timing;

  const GraphSeriesId({
    required this.title,
    required this.questionId,
    required this.type,
    required this.isCategory,
    required this.isReview,
    this.timing,
  });

  @override
  List<Object?> get props => [
    title,
    questionId,
    type,
    isCategory,
    isReview,
    timing,
  ];
}

@immutable
class GraphDatumId extends Equatable {
  final GraphSeriesId seriesId;
  final int binIndex;
  final int ordinal;

  const GraphDatumId({
    required this.seriesId,
    required this.binIndex,
    this.ordinal = 0,
  });

  @override
  List<Object?> get props => [seriesId, binIndex, ordinal];
}

@immutable
class GraphTimeBin extends Equatable {
  final int index;
  final DateTime start;
  final DateTime end;
  final String label;

  const GraphTimeBin({
    required this.index,
    required this.start,
    required this.end,
    required this.label,
  });

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);

  DateTime get center => start.add(end.difference(start) ~/ 2);

  @override
  List<Object?> get props => [index, start, end, label];
}

@immutable
class GraphQuery extends Equatable {
  final DateTime start;
  final DateTime end;
  final GraphMetric metric;
  final GraphComparison comparison;
  final List<GraphTimeBin> bins;

  GraphQuery({
    required this.start,
    required this.end,
    required this.metric,
    required this.comparison,
    required List<GraphTimeBin> bins,
  }) : bins = List.unmodifiable(bins);

  @override
  List<Object?> get props => [start, end, metric, comparison, bins];
}

@immutable
class GraphDatumSummary extends Equatable {
  final int reportCount;
  final int uniqueEntryCount;
  final double? numericAverage;
  final Map<String, int> choiceCounts;

  GraphDatumSummary({
    required this.reportCount,
    required this.uniqueEntryCount,
    required this.numericAverage,
    Map<String, int> choiceCounts = const {},
  }) : choiceCounts = Map.unmodifiable(choiceCounts);

  const GraphDatumSummary.empty()
    : reportCount = 0,
      uniqueEntryCount = 0,
      numericAverage = null,
      choiceCounts = const {};

  bool get hasEvidence => reportCount > 0;

  @override
  List<Object?> get props => [
    reportCount,
    uniqueEntryCount,
    numericAverage,
    choiceCounts,
  ];
}

@immutable
class PreparedDatum extends Equatable {
  final GraphDatumId id;
  final GraphTimeBin? bin;
  final DateTime xStart;
  final DateTime xEnd;
  final double? value;
  final double? valueEnd;
  final GraphTiming timing;
  final List<Stamp> evidence;
  final GraphDatumSummary summary;

  PreparedDatum({
    required this.id,
    required this.bin,
    required this.xStart,
    DateTime? xEnd,
    required this.value,
    this.valueEnd,
    this.timing = GraphTiming.exact,
    List<Stamp> evidence = const [],
    this.summary = const GraphDatumSummary.empty(),
  }) : xEnd = xEnd ?? xStart,
       evidence = List.unmodifiable(evidence);

  bool get hasValue => value != null && value!.isFinite;

  DateTime get xCenter => xStart.add(xEnd.difference(xStart) ~/ 2);

  @override
  List<Object?> get props => [
    id,
    bin,
    xStart,
    xEnd,
    value,
    valueEnd,
    timing,
    evidence,
    summary,
  ];
}

@immutable
class PreparedSeries extends Equatable {
  final GraphSeriesId id;
  final String label;
  final Color color;
  final GraphMark mark;
  final List<PreparedDatum> data;
  final double? domainMin;
  final double? domainMax;
  final String? unit;
  final String? scaleId;

  PreparedSeries({
    required this.id,
    required this.label,
    required this.color,
    required this.mark,
    required List<PreparedDatum> data,
    this.domainMin,
    this.domainMax,
    this.unit,
    this.scaleId,
  }) : data = List.unmodifiable(data);

  @override
  List<Object?> get props => [
    id,
    label,
    color,
    mark,
    data,
    domainMin,
    domainMax,
    unit,
    scaleId,
  ];
}

@immutable
class PreparedLane extends Equatable {
  final int index;
  final String label;
  final List<PreparedSeries> series;
  final GraphScaleKind scaleKind;
  final double minY;
  final double maxY;

  PreparedLane({
    required this.index,
    required this.label,
    required List<PreparedSeries> series,
    required this.scaleKind,
    required this.minY,
    required this.maxY,
  }) : series = List.unmodifiable(series);

  @override
  List<Object?> get props => [index, label, series, scaleKind, minY, maxY];
}

@immutable
class GraphMarker extends Equatable {
  final String id;
  final DateTime start;
  final DateTime? end;
  final String label;
  final Color color;
  final Object? payload;

  const GraphMarker({
    required this.id,
    required this.start,
    this.end,
    required this.label,
    required this.color,
    this.payload,
  });

  @override
  List<Object?> get props => [id, start, end, label, color];
}

@immutable
class PreparedGraph extends Equatable {
  final GraphQuery query;
  final List<PreparedLane> lanes;
  final List<GraphMarker> markers;

  PreparedGraph({
    required this.query,
    required List<PreparedLane> lanes,
    List<GraphMarker> markers = const [],
  }) : lanes = List.unmodifiable(lanes),
       markers = List.unmodifiable(markers);

  bool get isEmpty => !series.any(
    (series) => series.data.any(
      (datum) =>
          datum.evidence.isNotEmpty ||
          datum.summary.hasEvidence ||
          (datum.hasValue && datum.value != 0) ||
          (series.mark == GraphMark.range && datum.xEnd.isAfter(datum.xStart)),
    ),
  );

  List<PreparedSeries> get series =>
      List.unmodifiable(lanes.expand((lane) => lane.series));

  @override
  List<Object?> get props => [query, lanes, markers];
}

@immutable
class GraphSelectionItem extends Equatable {
  final PreparedSeries series;
  final PreparedDatum datum;

  const GraphSelectionItem({required this.series, required this.datum});

  @override
  List<Object?> get props => [series.id, datum.id];
}

@immutable
class GraphSelectionState extends Equatable {
  final GraphTimeBin? bin;
  final List<GraphSelectionItem> items;
  final bool pinned;

  GraphSelectionState({
    required this.bin,
    List<GraphSelectionItem> items = const [],
    this.pinned = false,
  }) : items = List.unmodifiable(items);

  const GraphSelectionState.empty()
    : bin = null,
      items = const [],
      pinned = false;

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [bin, items, pinned];
}

class GraphSelectionController extends ValueNotifier<GraphSelectionState> {
  GraphSelectionController([GraphSelectionState? value])
    : super(value ?? const GraphSelectionState.empty());

  void select({
    required GraphTimeBin? bin,
    required List<GraphSelectionItem> items,
    bool pinned = false,
  }) {
    value = GraphSelectionState(bin: bin, items: items, pinned: pinned);
  }

  void clear({bool preservePinned = false}) {
    if (preservePinned && value.pinned) return;
    value = const GraphSelectionState.empty();
  }
}
