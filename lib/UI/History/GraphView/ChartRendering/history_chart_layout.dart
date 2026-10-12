import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_scene.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

enum HistoryChartAppearance { compact, detailed }

@immutable
class HistoryChartVisualStyle {
  final TextStyle axisLabelStyle;
  final TextStyle laneLabelStyle;
  final TextStyle markerLabelStyle;
  final Color axisColor;
  final Color gridColor;
  final Color selectionColor;
  final Color selectionFillColor;
  final double lineWidth;
  final double pointRadius;
  final String? locale;
  final String Function(double hour)? hourLabelFormatter;
  final String Function(RecordDayPart part)? dayPartLabelFormatter;
  final String Function(GraphSelectionItem item)? semanticLabelFormatter;

  const HistoryChartVisualStyle({
    required this.axisLabelStyle,
    required this.laneLabelStyle,
    required this.markerLabelStyle,
    required this.axisColor,
    required this.gridColor,
    required this.selectionColor,
    required this.selectionFillColor,
    this.lineWidth = 2,
    this.pointRadius = 3.5,
    this.locale,
    this.hourLabelFormatter,
    this.dayPartLabelFormatter,
    this.semanticLabelFormatter,
  });

  factory HistoryChartVisualStyle.fromTheme(
    ThemeData theme, {
    String? locale,
    String Function(double hour)? hourLabelFormatter,
    String Function(RecordDayPart part)? dayPartLabelFormatter,
    String Function(GraphSelectionItem item)? semanticLabelFormatter,
  }) {
    final ColorScheme colors = theme.colorScheme;
    return HistoryChartVisualStyle(
      axisLabelStyle: (theme.textTheme.labelSmall ?? const TextStyle())
          .copyWith(color: colors.onSurfaceVariant),
      laneLabelStyle: (theme.textTheme.labelMedium ?? const TextStyle())
          .copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      markerLabelStyle: (theme.textTheme.labelSmall ?? const TextStyle())
          .copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      axisColor: colors.outlineVariant,
      gridColor: colors.outlineVariant.withValues(alpha: 0.3),
      selectionColor: colors.primary,
      selectionFillColor: colors.primary.withValues(alpha: 0.12),
      locale: locale,
      hourLabelFormatter: hourLabelFormatter,
      dayPartLabelFormatter: dayPartLabelFormatter,
      semanticLabelFormatter: semanticLabelFormatter,
    );
  }

  String formatHour(double hour) =>
      hourLabelFormatter?.call(hour) ?? _formatHour(hour);

  String dayPartLabel(RecordDayPart part) =>
      dayPartLabelFormatter?.call(part) ??
      switch (part) {
        RecordDayPart.earlyMorning => 'Early morning',
        RecordDayPart.morning => 'Morning',
        RecordDayPart.afternoon => 'Afternoon',
        RecordDayPart.evening => 'Evening',
        RecordDayPart.night => 'Night',
      };
}

/// Resolves a [PreparedGraph] and a viewport into all drawable geometry.
///
/// The result is immutable and is shared by painting, hit testing and
/// semantics. No response parsing, bucketing or widget state belongs here.
class HistoryChartLayoutEngine {
  const HistoryChartLayoutEngine();

  double preferredHeight({
    required PreparedGraph graph,
    required double width,
    required HistoryChartAppearance appearance,
    required HistoryChartVisualStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final axisHeight = _measure(
      'Mg',
      style.axisLabelStyle,
      textDirection,
      textScaler,
    ).height;
    final timeAxisHeight =
        appearance == HistoryChartAppearance.compact &&
            textScaler.scale(12) > 18
        ? 0.0
        : axisHeight * 1.5 + 12;
    if (appearance == HistoryChartAppearance.compact) {
      return math.max(88, 60 + timeAxisHeight);
    }
    final scales = [
      for (final lane in graph.lanes)
        _resolveLaneScale(lane, desiredTicks: 5, style: style),
    ];
    final axisWidth = _valueAxisWidth(
      scales,
      width,
      style,
      textDirection,
      textScaler,
    );
    final sizes = _laneSizes(
      graph,
      width,
      axisWidth,
      style,
      textDirection,
      textScaler,
    );
    final markerHeight = graph.markers.isEmpty
        ? 4
        : _measure(
                'Mg',
                style.markerLabelStyle,
                textDirection,
                textScaler,
              ).height +
              8;
    final result =
        markerHeight +
        timeAxisHeight +
        math.max(0, sizes.length - 1) * 10 +
        sizes.fold<double>(0, (sum, size) => sum + size.header + size.plot);
    return math.max(
      graph.lanes.any((lane) => lane.scaleKind != GraphScaleKind.range)
          ? 190
          : 80,
      result,
    );
  }

  HistoryChartScene layout({
    required PreparedGraph graph,
    required Size size,
    required HistoryChartAppearance appearance,
    required HistoryChartVisualStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final double width = size.width.isFinite ? math.max(0, size.width) : 0;
    final double height = size.height.isFinite ? math.max(0, size.height) : 0;
    final Size safeSize = Size(width, height);
    final bool compact = appearance == HistoryChartAppearance.compact;

    if (graph.lanes.isEmpty || width <= 1 || height <= 1) {
      return HistoryChartScene(
        size: safeSize,
        plotBounds: Rect.zero,
        lanes: const <HistoryChartLaneScene>[],
        timeTicks: const <HistoryChartTimeTick>[],
        markers: const <HistoryChartMarkerGeometry>[],
        hitRegions: const <HistoryChartHitRegion>[],
      );
    }

    final double axisTextHeight = _measure(
      'Mg',
      style.axisLabelStyle,
      textDirection,
      textScaler,
    ).height;
    final double markerHeader = !compact && graph.markers.isNotEmpty
        ? _measure(
                'Mg',
                style.markerLabelStyle,
                textDirection,
                textScaler,
              ).height +
              8
        : 4;
    final hidePreviewLabels = compact && textScaler.scale(12) > 18;
    final double timeAxisHeight = hidePreviewLabels
        ? 0
        : axisTextHeight * 1.5 + 12;
    final List<_ResolvedLaneScale> scales = graph.lanes
        .map(
          (PreparedLane lane) => _resolveLaneScale(
            lane,
            desiredTicks: compact ? 3 : 5,
            style: style,
          ),
        )
        .toList(growable: false);

    final double valueAxisWidth = compact
        ? 0
        : _valueAxisWidth(scales, width, style, textDirection, textScaler);

    final double outerPadding = compact ? 4 : 10;
    final double desiredLeft = compact
        ? outerPadding
        : outerPadding + valueAxisWidth + 8;
    final double right = math.max(1, width - outerPadding);
    final double left = math.min(desiredLeft, math.max(0, right - 1));
    final double desiredLaneGap = compact ? 3 : 10;
    final double contentTop = markerHeader;
    final double contentBottom = math.max(contentTop, height - timeAxisHeight);
    final int laneCount = graph.lanes.length;
    final double contentHeight = math.max(1, contentBottom - contentTop);
    final double laneGap = laneCount <= 1
        ? 0
        : math.min(desiredLaneGap, contentHeight / (laneCount * 4));
    final double availableLaneHeight = math.max(
      1,
      contentHeight - (laneGap * (laneCount - 1)),
    );
    final List<_LaneSize> sizes = compact
        ? [
            for (final lane in graph.lanes)
              _LaneSize(0, lane.scaleKind == GraphScaleKind.range ? 16 : 60),
          ]
        : _laneSizes(
            graph,
            width,
            valueAxisWidth,
            style,
            textDirection,
            textScaler,
          );
    final double headerTotal = sizes.fold(0, (sum, size) => sum + size.header);
    final double plotTotal = sizes.fold(0, (sum, size) => sum + size.plot);
    final double headerScale = headerTotal > availableLaneHeight
        ? availableLaneHeight / headerTotal
        : 1;
    final double plotScale = plotTotal <= 0
        ? 1
        : ((availableLaneHeight - headerTotal) / plotTotal).clamp(0, 1);
    final int valueLaneCount = graph.lanes
        .where((lane) => lane.scaleKind != GraphScaleKind.range)
        .length;
    final double extraPerValueLane = valueLaneCount == 0
        ? 0
        : math.max(0, availableLaneHeight - headerTotal - plotTotal) /
              valueLaneCount;

    final List<HistoryChartLaneScene> laneScenes = <HistoryChartLaneScene>[];
    final List<HistoryChartHitRegion> hitRegions = <HistoryChartHitRegion>[];

    double frameTop = contentTop;
    for (int laneIndex = 0; laneIndex < laneCount; laneIndex++) {
      final PreparedLane lane = graph.lanes[laneIndex];
      final double labelHeight = sizes[laneIndex].header * headerScale;
      final double plotHeight =
          sizes[laneIndex].plot * plotScale +
          (lane.scaleKind == GraphScaleKind.range ? 0 : extraPerValueLane);
      final _ResolvedLaneScale scale = _resolveLaneScale(
        lane,
        desiredTicks: (plotHeight / (axisTextHeight + 12)).floor().clamp(
          2,
          compact ? 3 : 5,
        ),
        style: style,
      );
      final Rect frame = Rect.fromLTRB(
        outerPadding,
        frameTop,
        right,
        frameTop + labelHeight + plotHeight,
      );
      final Rect plot = Rect.fromLTRB(
        left,
        math.min(frame.bottom, frame.top + labelHeight),
        frame.right,
        frame.bottom,
      );

      final _LaneGeometry geometry = _layoutLane(
        graph: graph,
        lane: lane,
        plot: plot,
        domain: scale.domain,
        style: style,
        compact: compact,
      );
      hitRegions.addAll(geometry.hitRegions);

      laneScenes.add(
        HistoryChartLaneScene(
          lane: lane,
          frame: frame,
          plot: plot,
          domain: scale.domain,
          valueTicks: scale.ticks
              .map(
                (_ValueTick tick) => HistoryChartValueTick(
                  value: tick.value,
                  y: _yFor(tick.value, scale.domain, plot),
                  label: tick.label,
                ),
              )
              .toList(growable: false),
          bars: geometry.bars,
          points: geometry.points,
          lines: geometry.lines,
          ranges: geometry.ranges,
          dayPartBands: lane.scaleKind == GraphScaleKind.hour
              ? [
                  for (final part in RecordDayPart.values)
                    HistoryChartDayPartBand(
                      rect: Rect.fromLTRB(
                        plot.left,
                        _yFor(part.endHour.toDouble(), scale.domain, plot),
                        plot.right,
                        _yFor(part.startHour.toDouble(), scale.domain, plot),
                      ),
                      label: style.dayPartLabel(part),
                    ),
                ]
              : const [],
        ),
      );
      frameTop = frame.bottom + laneGap;
    }

    final Rect plotBounds = Rect.fromLTRB(
      left,
      laneScenes.first.plot.top,
      right,
      laneScenes.last.plot.bottom,
    );
    final List<HistoryChartTimeTick> timeTicks = hidePreviewLabels
        ? []
        : _layoutTimeTicks(
            graph.query.start,
            graph.query.end,
            plotBounds,
            style,
            textDirection,
            textScaler,
            compact: compact,
          );
    final List<HistoryChartMarkerGeometry> markers = _layoutMarkers(
      graph,
      plotBounds,
    );

    return HistoryChartScene(
      size: safeSize,
      plotBounds: plotBounds,
      lanes: laneScenes,
      timeTicks: timeTicks,
      markers: markers,
      hitRegions: hitRegions,
    );
  }

  _LaneGeometry _layoutLane({
    required PreparedGraph graph,
    required PreparedLane lane,
    required Rect plot,
    required HistoryChartValueDomain domain,
    required HistoryChartVisualStyle style,
    required bool compact,
  }) {
    final List<HistoryChartBarGeometry> bars = <HistoryChartBarGeometry>[];
    final List<HistoryChartPointGeometry> points =
        <HistoryChartPointGeometry>[];
    final List<HistoryChartLineGeometry> lines = <HistoryChartLineGeometry>[];
    final List<HistoryChartRangeGeometry> ranges =
        <HistoryChartRangeGeometry>[];
    final List<HistoryChartHitRegion> hitRegions = <HistoryChartHitRegion>[];

    final List<PreparedSeries> barSeries = lane.series
        .where((PreparedSeries series) => series.mark == GraphMark.bar)
        .toList(growable: false);
    final bool stacked = graph.query.comparison == GraphComparison.stacked;
    final bool overlaid = graph.query.comparison == GraphComparison.overlaid;
    final Map<Object, double> positiveBottoms = <Object, double>{};
    final Map<Object, double> negativeBottoms = <Object, double>{};

    for (int seriesIndex = 0; seriesIndex < lane.series.length; seriesIndex++) {
      final PreparedSeries series = lane.series[seriesIndex];
      switch (series.mark) {
        case GraphMark.bar:
          for (final PreparedDatum datum in series.data) {
            final double? value = datum.value;
            if (value == null || !value.isFinite) continue;

            final _HorizontalInterval interval = _datumInterval(
              datum,
              graph.query,
              plot,
            );
            double left = interval.left;
            double right = interval.right;
            final double inset = math.min(
              (right - left) * 0.11,
              compact ? 2 : 4,
            );
            left += inset;
            right -= inset;

            final Object stackKey = datum.bin?.index ?? datum.xStart;
            final Map<Object, double> bottoms = value >= 0
                ? positiveBottoms
                : negativeBottoms;
            final double bottom = stacked ? (bottoms[stackKey] ?? 0) : 0;
            final double top = bottom + value;
            if (stacked) bottoms[stackKey] = top;

            final double y1 = _yFor(bottom, domain, plot);
            final double y2 = _yFor(top, domain, plot);
            final Rect visible = Rect.fromLTRB(
              math.min(left, right),
              math.min(y1, y2),
              math.max(left, right),
              math.max(y1, y2),
            );
            final Rect hit = _minimumHitRect(
              visible,
              plot,
              minWidth: compact ? 18 : 24,
              minHeight: compact ? 18 : 32,
            );
            final Offset anchor = Offset(visible.center.dx, y2);
            final GraphSelectionItem item = GraphSelectionItem(
              series: series,
              datum: datum,
            );
            bars.add(
              HistoryChartBarGeometry(
                item: item,
                rect: visible,
                color: overlaid && barSeries.length > 1
                    ? series.color.withValues(alpha: 0.62)
                    : series.color,
              ),
            );
            hitRegions.add(
              HistoryChartHitRegion(
                item: item,
                visibleBounds: visible,
                hitBounds: hit,
                anchor: anchor,
              ),
            );
          }

        case GraphMark.point:
          for (final PreparedDatum datum in series.data) {
            final double? value = datum.value;
            if (value == null || !value.isFinite) continue;
            final GraphSelectionItem item = GraphSelectionItem(
              series: series,
              datum: datum,
            );
            final double? valueEnd = datum.valueEnd;
            if (valueEnd != null && valueEnd.isFinite) {
              final double x = _xFor(datum.xCenter, graph.query, plot);
              final double y1 = _yFor(value, domain, plot);
              final double y2 = _yFor(valueEnd, domain, plot);
              final double halfWidth = compact ? 3 : 6;
              final Rect visible = Rect.fromLTRB(
                x - halfWidth,
                math.min(y1, y2),
                x + halfWidth,
                math.max(y1, y2),
              ).intersect(plot);
              ranges.add(
                HistoryChartRangeGeometry(
                  item: item,
                  rect: visible,
                  color: series.color,
                ),
              );
              hitRegions.add(
                HistoryChartHitRegion(
                  item: item,
                  visibleBounds: visible,
                  hitBounds: _minimumHitRect(
                    visible,
                    plot,
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  anchor: visible.center,
                ),
              );
              continue;
            }
            final Offset center = Offset(
              _xFor(datum.xCenter, graph.query, plot),
              _yFor(value, domain, plot),
            );
            final double radius = compact ? 2.75 : style.pointRadius;
            final Rect visible = Rect.fromCircle(
              center: center,
              radius: radius,
            );
            final Rect hit = Rect.fromCircle(
              center: center,
              radius: 24,
            ).intersect(plot.inflate(1));
            points.add(
              HistoryChartPointGeometry(
                item: item,
                center: center,
                radius: radius,
                color: series.color,
              ),
            );
            hitRegions.add(
              HistoryChartHitRegion(
                item: item,
                visibleBounds: visible,
                hitBounds: hit,
                anchor: center,
              ),
            );
          }

        case GraphMark.line:
          _layoutLine(
            graph: graph,
            series: series,
            plot: plot,
            domain: domain,
            style: style,
            lines: lines,
            hitRegions: hitRegions,
          );

        case GraphMark.range:
          break;
      }
    }

    _layoutRanges(
      graph: graph,
      lane: lane,
      plot: plot,
      ranges: ranges,
      hitRegions: hitRegions,
      compact: compact,
    );

    return _LaneGeometry(
      bars: bars,
      points: points,
      lines: lines,
      ranges: ranges,
      hitRegions: hitRegions,
    );
  }

  void _layoutLine({
    required PreparedGraph graph,
    required PreparedSeries series,
    required Rect plot,
    required HistoryChartValueDomain domain,
    required HistoryChartVisualStyle style,
    required List<HistoryChartLineGeometry> lines,
    required List<HistoryChartHitRegion> hitRegions,
  }) {
    final List<PreparedDatum> data =
        series.data
            .where((PreparedDatum datum) => datum.hasValue)
            .toList(growable: false)
          ..sort(
            (PreparedDatum first, PreparedDatum second) =>
                first.xCenter.compareTo(second.xCenter),
          );
    List<HistoryChartLineVertex> segment = <HistoryChartLineVertex>[];
    PreparedDatum? previous;

    void flush() {
      if (segment.isNotEmpty) {
        lines.add(
          HistoryChartLineGeometry(
            series: series,
            vertices: segment,
            color: series.color,
          ),
        );
      }
      segment = <HistoryChartLineVertex>[];
    }

    for (final PreparedDatum datum in data) {
      final GraphTimeBin? previousBin = previous?.bin;
      final GraphTimeBin? currentBin = datum.bin;
      if (previousBin != null &&
          currentBin != null &&
          currentBin.index - previousBin.index > 1) {
        flush();
      }

      final Offset position = Offset(
        _xFor(datum.xCenter, graph.query, plot),
        _yFor(datum.value!, domain, plot),
      );
      final Rect visible = Rect.fromCircle(
        center: position,
        radius: math.max(2, style.lineWidth),
      );
      final Rect hit = Rect.fromCircle(
        center: position,
        radius: 24,
      ).intersect(plot.inflate(1));
      final GraphSelectionItem item = GraphSelectionItem(
        series: series,
        datum: datum,
      );
      segment.add(HistoryChartLineVertex(item: item, position: position));
      hitRegions.add(
        HistoryChartHitRegion(
          item: item,
          visibleBounds: visible,
          hitBounds: hit,
          anchor: position,
        ),
      );
      previous = datum;
    }
    flush();
  }

  void _layoutRanges({
    required PreparedGraph graph,
    required PreparedLane lane,
    required Rect plot,
    required List<HistoryChartRangeGeometry> ranges,
    required List<HistoryChartHitRegion> hitRegions,
    required bool compact,
  }) {
    final List<_RangeDatum> data =
        <_RangeDatum>[
          for (final PreparedSeries series in lane.series)
            if (series.mark == GraphMark.range)
              for (final PreparedDatum datum in series.data)
                _RangeDatum(series: series, datum: datum),
        ]..sort(
          (_RangeDatum first, _RangeDatum second) =>
              first.datum.xStart.compareTo(second.datum.xStart),
        );
    if (data.isEmpty) return;

    final List<DateTime> trackEnds = <DateTime>[];
    final List<int> tracks = <int>[];
    for (final _RangeDatum entry in data) {
      int track = trackEnds.indexWhere(
        (DateTime end) => !end.isAfter(entry.datum.xStart),
      );
      if (track < 0) {
        track = trackEnds.length;
        trackEnds.add(entry.datum.xEnd);
      } else {
        trackEnds[track] = entry.datum.xEnd;
      }
      tracks.add(track);
    }

    final int trackCount = math.max(1, trackEnds.length);
    final double trackStep = plot.height / trackCount;
    final double rangeHeight = math.max(
      2,
      math.min(compact ? 10 : 20, trackStep - 3),
    );

    for (int index = 0; index < data.length; index++) {
      final _RangeDatum entry = data[index];
      double x1 = _xFor(entry.datum.xStart, graph.query, plot);
      double x2 = _xFor(entry.datum.xEnd, graph.query, plot);
      if (x2 < x1) {
        final double temporary = x1;
        x1 = x2;
        x2 = temporary;
      }
      if ((x2 - x1).abs() < 2) x2 = x1 + 2;
      final double centerY = plot.top + (tracks[index] + 0.5) * trackStep;
      final Rect visible = Rect.fromLTRB(
        x1,
        centerY - rangeHeight / 2,
        x2,
        centerY + rangeHeight / 2,
      ).intersect(plot);
      final Rect hit = _minimumHitRect(
        visible,
        plot,
        minWidth: 24,
        minHeight: compact ? 20 : 44,
      );
      final Offset anchor = visible.center;
      final GraphSelectionItem item = GraphSelectionItem(
        series: entry.series,
        datum: entry.datum,
      );
      ranges.add(
        HistoryChartRangeGeometry(
          item: item,
          rect: visible,
          color: entry.series.color,
        ),
      );
      hitRegions.add(
        HistoryChartHitRegion(
          item: item,
          visibleBounds: visible,
          hitBounds: hit,
          anchor: anchor,
        ),
      );
    }
  }

  List<HistoryChartTimeTick> _layoutTimeTicks(
    DateTime start,
    DateTime end,
    Rect plot,
    HistoryChartVisualStyle style,
    TextDirection textDirection,
    TextScaler textScaler, {
    required bool compact,
  }) {
    start = start.toLocal();
    end = end.toLocal();
    if (!end.isAfter(start) || plot.width <= 1) {
      return const <HistoryChartTimeTick>[];
    }
    final int maxTicks = compact ? 3 : math.max(2, (plot.width / 24).floor());
    final Duration duration = end.difference(start);
    final double labelY =
        plot.bottom +
        _measure('Mg', style.axisLabelStyle, textDirection, textScaler).height /
            2 +
        8;

    HistoryChartTimeTick tick(
      DateTime time,
      _CalendarStep step, {
      bool numericDay = false,
    }) {
      final String label = numericDay
          ? DateFormat.d(style.locale).format(time)
          : _calendarLabel(time, step, start, end, style);
      final Size measured = _measure(
        label,
        style.axisLabelStyle,
        textDirection,
        textScaler,
      );
      final bool dailyWeekLabel =
          step.unit == _CalendarUnit.day && duration.inDays <= 7;
      final DateTime nextDay = DateTime(time.year, time.month, time.day + 1);
      final DateTime labelTime = dailyWeekLabel
          ? time.add(nextDay.difference(time) ~/ 2)
          : time;
      final double x = _xForRange(labelTime, start, end, plot);
      final double labelWidth = math.min(measured.width, plot.width);
      final double left = (x - labelWidth / 2).clamp(
        plot.left,
        math.max(plot.left, plot.right - labelWidth),
      );
      return HistoryChartTimeTick(
        time: time,
        x: x,
        label: label,
        labelBounds: Rect.fromLTWH(left, labelY, labelWidth, measured.height),
      );
    }

    // Calendar ticks are independent of aggregation bins. In particular, do
    // not round sampled bin indices: that alternates short and long gaps.
    List<HistoryChartTimeTick>? singleTickFallback;
    for (final numericDay in [
      false,
      if (duration.inDays >= 2 && duration.inDays <= 7) true,
    ]) {
      for (final _CalendarStep step in _calendarSteps) {
        if (numericDay && step.unit != _CalendarUnit.day) continue;
        if (duration.inSeconds / step.approximateSeconds > maxTicks * 2) {
          continue;
        }
        final List<DateTime> times = step.ticks(start, end);
        if (times.isEmpty || times.length > maxTicks) continue;
        final List<HistoryChartTimeTick> ticks = [
          for (final time in times) tick(time, step, numericDay: numericDay),
        ];
        bool fits = true;
        for (int index = 1; index < ticks.length; index++) {
          if (ticks[index].labelBounds.left <
              ticks[index - 1].labelBounds.right + 8) {
            fits = false;
            break;
          }
        }
        if (fits) {
          if (ticks.length > 1) return ticks;
          singleTickFallback ??= ticks;
          // When large weekday text leaves just one label, day numbers can
          // restore useful reference points without changing calendar steps.
          break;
        }
      }
    }
    return singleTickFallback ??
        [tick(start, const _CalendarStep(_CalendarUnit.day, 1))];
  }

  List<HistoryChartMarkerGeometry> _layoutMarkers(
    PreparedGraph graph,
    Rect plot,
  ) {
    final List<HistoryChartMarkerGeometry> result =
        <HistoryChartMarkerGeometry>[];
    for (final GraphMarker marker in graph.markers) {
      final DateTime markerEnd = marker.end ?? marker.start;
      if (markerEnd.isBefore(graph.query.start) ||
          marker.start.isAfter(graph.query.end)) {
        continue;
      }
      final double startX = _xFor(marker.start, graph.query, plot);
      final double? endX = marker.end == null
          ? null
          : _xFor(marker.end!, graph.query, plot);
      final Rect? band = endX == null
          ? null
          : Rect.fromLTRB(
              math.min(startX, endX),
              plot.top,
              math.max(startX, endX),
              plot.bottom,
            );
      result.add(
        HistoryChartMarkerGeometry(
          marker: marker,
          startX: startX,
          endX: endX,
          band: band,
        ),
      );
    }
    return result;
  }
}

String historyChartLaneHeading(PreparedLane lane) {
  if (lane.scaleKind == GraphScaleKind.hour ||
      lane.scaleKind == GraphScaleKind.range) {
    return lane.label;
  }
  final unit = lane.series
      .map((series) => series.unit)
      .whereType<String>()
      .where((unit) => unit.isNotEmpty)
      .firstOrNull;
  return unit == null ? lane.label : '${lane.label} ($unit)';
}

double _valueAxisWidth(
  List<_ResolvedLaneScale> scales,
  double width,
  HistoryChartVisualStyle style,
  TextDirection direction,
  TextScaler scaler,
) {
  double widest = 0;
  double widestWord = 0;
  for (final scale in scales) {
    for (final tick in scale.ticks) {
      widest = math.max(
        widest,
        _measure(tick.label, style.axisLabelStyle, direction, scaler).width,
      );
      for (final word in tick.label.split(' ')) {
        widestWord = math.max(
          widestWord,
          _measure(word, style.axisLabelStyle, direction, scaler).width,
        );
      }
    }
  }
  return math.min(
    widest,
    math.max(width * 0.4, math.min(widestWord, width * 0.55)),
  );
}

List<_LaneSize> _laneSizes(
  PreparedGraph graph,
  double width,
  double axisWidth,
  HistoryChartVisualStyle style,
  TextDirection direction,
  TextScaler scaler,
) {
  final axisHeight = _measure(
    'Mg',
    style.axisLabelStyle,
    direction,
    scaler,
  ).height;
  return [
    for (final lane in graph.lanes)
      () {
        final headerHeight =
            _measure(
              historyChartLaneHeading(lane),
              style.laneLabelStyle,
              direction,
              scaler,
              maxWidth: math.max(1, width - 20),
              maxLines: null,
            ).height +
            (lane.scaleKind == GraphScaleKind.range ? 8 : axisHeight / 2 + 8);
        double plotHeight;
        if (lane.scaleKind == GraphScaleKind.range) {
          plotHeight = _rangeTrackCount(lane) * 28.0;
        } else if (lane.scaleKind == GraphScaleKind.hour) {
          plotHeight = 0;
          for (final part in RecordDayPart.values) {
            final labelHeight = _measure(
              style.dayPartLabel(part),
              style.axisLabelStyle,
              direction,
              scaler,
              maxWidth: math.max(1, axisWidth),
              maxLines: null,
            ).height;
            plotHeight = math.max(
              plotHeight,
              (labelHeight + 8) * 24 / (part.endHour - part.startHour),
            );
          }
        } else {
          plotHeight = math.max(80, 4 * (axisHeight + 12));
        }
        return _LaneSize(headerHeight, plotHeight);
      }(),
  ];
}

int _rangeTrackCount(PreparedLane lane) {
  final data = lane.series.expand((series) => series.data).toList()
    ..sort((first, second) => first.xStart.compareTo(second.xStart));
  final ends = <DateTime>[];
  for (final datum in data) {
    final track = ends.indexWhere((end) => !end.isAfter(datum.xStart));
    if (track < 0) {
      ends.add(datum.xEnd);
    } else {
      ends[track] = datum.xEnd;
    }
  }
  return math.max(1, ends.length);
}

class _LaneSize {
  final double header;
  final double plot;
  const _LaneSize(this.header, this.plot);
}

_ResolvedLaneScale _resolveLaneScale(
  PreparedLane lane, {
  required int desiredTicks,
  required HistoryChartVisualStyle style,
}) {
  if (lane.scaleKind == GraphScaleKind.range) {
    return const _ResolvedLaneScale(
      domain: HistoryChartValueDomain(min: 0, max: 1),
      ticks: <_ValueTick>[],
    );
  }
  if (lane.scaleKind == GraphScaleKind.hour) {
    const HistoryChartValueDomain domain = HistoryChartValueDomain(
      min: 0,
      max: 24,
    );
    return _ResolvedLaneScale(
      domain: domain,
      ticks: <_ValueTick>[
        for (final part in RecordDayPart.values)
          _ValueTick(
            (part.startHour + part.endHour) / 2,
            style.dayPartLabel(part),
          ),
      ],
    );
  }

  double min = lane.minY.isFinite ? lane.minY : 0;
  double max = lane.maxY.isFinite ? lane.maxY : 1;
  if (max < min) {
    final double temporary = min;
    min = max;
    max = temporary;
  }
  final bool hasBar = lane.series.any(
    (PreparedSeries series) => series.mark == GraphMark.bar,
  );
  if (hasBar && min >= 0) min = 0;
  if (hasBar && max <= 0) max = min < 0 ? 0 : 1;
  if (max == min) {
    final double padding = max == 0 ? 1 : math.max(1, max.abs() * 0.1);
    min -= padding;
    max += padding;
  }

  final double niceStep = _niceNumber((max - min) / (desiredTicks - 1));
  final double step = lane.scaleKind == GraphScaleKind.count
      ? math.max(1, niceStep.ceilToDouble())
      : niceStep;
  final double niceMin = (min / step).floorToDouble() * step;
  final double niceMax = (max / step).ceilToDouble() * step;
  final HistoryChartValueDomain domain = HistoryChartValueDomain(
    min: niceMin,
    max: niceMax == niceMin ? niceMin + step : niceMax,
  );
  final List<_ValueTick> ticks = <_ValueTick>[];
  for (
    double value = domain.min;
    value <= domain.max + step * 0.001 && ticks.length < 12;
    value += step
  ) {
    ticks.add(_ValueTick(value, _formatNumber(value, step)));
  }
  return _ResolvedLaneScale(domain: domain, ticks: ticks);
}

double _niceNumber(double value) {
  if (!value.isFinite || value <= 0) return 1;
  final double exponent = math
      .pow(10, (math.log(value) / math.ln10).floor())
      .toDouble();
  final double fraction = value / exponent;
  final double niceFraction;
  if (fraction <= 1) {
    niceFraction = 1;
  } else if (fraction <= 2) {
    niceFraction = 2;
  } else if (fraction <= 5) {
    niceFraction = 5;
  } else {
    niceFraction = 10;
  }
  return niceFraction * exponent;
}

String _formatNumber(double value, double step) {
  if (value.abs() < step * 0.0001) value = 0;
  final double magnitude = value.abs();
  if (magnitude >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (magnitude >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  if (step >= 1) return value.toStringAsFixed(0);
  final int decimals = math.min(4, math.max(1, -_base10Floor(step)));
  return value.toStringAsFixed(decimals);
}

int _base10Floor(double value) {
  if (value <= 0 || !value.isFinite) return 0;
  return (math.log(value) / math.ln10).floor();
}

String _formatHour(double value) {
  final int totalMinutes = (value * 60).round();
  final int hour = (totalMinutes ~/ 60) % 24;
  final int minute = totalMinutes % 60;
  final String minutes = minute == 0
      ? ''
      : ':${minute.toString().padLeft(2, '0')}';
  return '${hour % 12 == 0 ? 12 : hour % 12}$minutes ${hour < 12 ? 'AM' : 'PM'}';
}

double _xFor(DateTime value, GraphQuery query, Rect plot) =>
    _xForRange(value, query.start, query.end, plot);

double _xForRange(DateTime value, DateTime start, DateTime end, Rect plot) {
  final int range = end.difference(start).inMicroseconds;
  if (range <= 0 || plot.width <= 0) return plot.left;
  final double fraction = value.difference(start).inMicroseconds / range;
  return plot.left + fraction.clamp(0.0, 1.0) * plot.width;
}

double _yFor(double value, HistoryChartValueDomain domain, Rect plot) {
  if (domain.span <= 0 || plot.height <= 0) return plot.bottom;
  final double fraction = (value - domain.min) / domain.span;
  return plot.bottom - fraction.clamp(0.0, 1.0) * plot.height;
}

_HorizontalInterval _datumInterval(
  PreparedDatum datum,
  GraphQuery query,
  Rect plot,
) {
  DateTime start = datum.xStart;
  DateTime end = datum.xEnd;
  if (!end.isAfter(start) && datum.bin != null) {
    start = datum.bin!.start;
    end = datum.bin!.end;
  }
  double left = _xFor(start, query, plot);
  double right = _xFor(end, query, plot);
  if (right < left) {
    final double temporary = left;
    left = right;
    right = temporary;
  }
  if (right - left < 4) {
    final double center = (left + right) / 2;
    left = center - 2;
    right = center + 2;
  }
  return _HorizontalInterval(left, right);
}

Rect _minimumHitRect(
  Rect visible,
  Rect clip, {
  required double minWidth,
  required double minHeight,
}) {
  final double width = math.max(minWidth, visible.width);
  final double height = math.max(minHeight, visible.height);
  return Rect.fromCenter(
    center: visible.center,
    width: width,
    height: height,
  ).intersect(clip.inflate(1));
}

enum _CalendarUnit { second, minute, hour, day, month, year }

class _CalendarStep {
  final _CalendarUnit unit;
  final int amount;

  const _CalendarStep(this.unit, this.amount);

  int get approximateSeconds =>
      amount *
      switch (unit) {
        _CalendarUnit.second => 1,
        _CalendarUnit.minute => 60,
        _CalendarUnit.hour => 3600,
        _CalendarUnit.day => 86400,
        _CalendarUnit.month => 2629800,
        _CalendarUnit.year => 31557600,
      };

  DateTime _floor(DateTime date) {
    switch (unit) {
      case _CalendarUnit.second:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second ~/ amount * amount,
        );
      case _CalendarUnit.minute:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute ~/ amount * amount,
        );
      case _CalendarUnit.hour:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour ~/ amount * amount,
        );
      case _CalendarUnit.day:
        // A UTC ordinal measures calendar days without DST shifting midnight.
        // Weekly steps start on Monday; other steps have a stable day anchor.
        final DateTime anchor = DateTime.utc(1970, 1, amount % 7 == 0 ? 5 : 1);
        final int ordinal = DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(anchor).inDays;
        final DateTime aligned = anchor.add(
          Duration(days: (ordinal / amount).floor() * amount),
        );
        return DateTime(aligned.year, aligned.month, aligned.day);
      case _CalendarUnit.month:
        final int index = date.year * 12 + date.month - 1;
        final int aligned = index ~/ amount * amount;
        return DateTime(aligned ~/ 12, aligned % 12 + 1);
      case _CalendarUnit.year:
        return DateTime(date.year ~/ amount * amount);
    }
  }

  DateTime _advance(DateTime date) => switch (unit) {
    _CalendarUnit.second => date.add(Duration(seconds: amount)),
    _CalendarUnit.minute => date.add(Duration(minutes: amount)),
    _CalendarUnit.hour => date.add(Duration(hours: amount)),
    _CalendarUnit.day => DateTime(date.year, date.month, date.day + amount),
    _CalendarUnit.month => DateTime(date.year, date.month + amount),
    _CalendarUnit.year => DateTime(date.year + amount),
  };

  List<DateTime> ticks(DateTime start, DateTime end) {
    DateTime time = _floor(start);
    if (time.isBefore(start)) time = _advance(time);
    final List<DateTime> result = [];
    while (time.isBefore(end) && result.length < 256) {
      result.add(time);
      final DateTime next = _advance(time);
      if (!next.isAfter(time)) break;
      time = next;
    }
    return result;
  }
}

final List<_CalendarStep> _calendarSteps = [
  for (final amount in [1, 2, 5, 10, 15, 30])
    _CalendarStep(_CalendarUnit.second, amount),
  for (final amount in [1, 2, 5, 10, 15, 30])
    _CalendarStep(_CalendarUnit.minute, amount),
  for (final amount in [1, 2, 3, 6, 12])
    _CalendarStep(_CalendarUnit.hour, amount),
  for (final amount in [1, 2, 3, 7, 14])
    _CalendarStep(_CalendarUnit.day, amount),
  for (final amount in [1, 2, 3, 6]) _CalendarStep(_CalendarUnit.month, amount),
  for (final amount in [1, 2, 5, 10, 20, 50, 100])
    _CalendarStep(_CalendarUnit.year, amount),
];

String _calendarLabel(
  DateTime time,
  _CalendarStep step,
  DateTime start,
  DateTime end,
  HistoryChartVisualStyle style,
) {
  final Duration duration = end.difference(start);
  final bool multipleYears =
      start.year != end.subtract(const Duration(microseconds: 1)).year;
  final String? locale = style.locale;
  return switch (step.unit) {
    _CalendarUnit.second => DateFormat.Hms(locale).format(time),
    _CalendarUnit.minute || _CalendarUnit.hour =>
      duration.inHours <= 24
          ? style.formatHour(time.hour + time.minute / 60)
          : '${DateFormat.MMMd(locale).format(time)} ${style.formatHour(time.hour + time.minute / 60)}',
    _CalendarUnit.day =>
      duration.inDays <= 7
          ? DateFormat.E(locale).format(time)
          : multipleYears
          ? DateFormat.yMMMd(locale).format(time)
          : DateFormat.MMMd(locale).format(time),
    _CalendarUnit.month =>
      multipleYears
          ? DateFormat.yMMM(locale).format(time)
          : DateFormat.MMM(locale).format(time),
    _CalendarUnit.year => DateFormat.y(locale).format(time),
  };
}

Size _measure(
  String text,
  TextStyle style,
  TextDirection textDirection,
  TextScaler textScaler, {
  double maxWidth = double.infinity,
  int? maxLines = 1,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  return painter.size;
}

class _ValueTick {
  final double value;
  final String label;

  const _ValueTick(this.value, this.label);
}

class _ResolvedLaneScale {
  final HistoryChartValueDomain domain;
  final List<_ValueTick> ticks;

  const _ResolvedLaneScale({required this.domain, required this.ticks});
}

class _HorizontalInterval {
  final double left;
  final double right;

  const _HorizontalInterval(this.left, this.right);
}

class _RangeDatum {
  final PreparedSeries series;
  final PreparedDatum datum;

  const _RangeDatum({required this.series, required this.datum});
}

class _LaneGeometry {
  final List<HistoryChartBarGeometry> bars;
  final List<HistoryChartPointGeometry> points;
  final List<HistoryChartLineGeometry> lines;
  final List<HistoryChartRangeGeometry> ranges;
  final List<HistoryChartHitRegion> hitRegions;

  const _LaneGeometry({
    required this.bars,
    required this.points,
    required this.lines,
    required this.ranges,
    required this.hitRegions,
  });
}
