import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

@immutable
class HistoryChartScene {
  final Size size;
  final Rect plotBounds;
  final List<HistoryChartLaneScene> lanes;
  final List<HistoryChartTimeTick> timeTicks;
  final List<HistoryChartMarkerGeometry> markers;
  final List<HistoryChartHitRegion> hitRegions;

  HistoryChartScene({
    required this.size,
    required this.plotBounds,
    required List<HistoryChartLaneScene> lanes,
    required List<HistoryChartTimeTick> timeTicks,
    required List<HistoryChartMarkerGeometry> markers,
    required List<HistoryChartHitRegion> hitRegions,
  }) : lanes = List<HistoryChartLaneScene>.unmodifiable(lanes),
       timeTicks = List<HistoryChartTimeTick>.unmodifiable(timeTicks),
       markers = List<HistoryChartMarkerGeometry>.unmodifiable(markers),
       hitRegions = List<HistoryChartHitRegion>.unmodifiable(hitRegions);

  List<GraphSelectionItem> hitTest(Offset position) {
    HistoryChartHitRegion? closest;
    double closestDistance = double.infinity;

    for (final HistoryChartHitRegion region in hitRegions) {
      if (!region.hitBounds.contains(position)) continue;
      final double distance = region.distanceToVisibleShape(position);
      if (distance < closestDistance) {
        closest = region;
        closestDistance = distance;
      }
    }

    return closest == null
        ? const <GraphSelectionItem>[]
        : _itemsFor(closest, position.dx);
  }

  /// Finds the nearest drawable value using only the horizontal coordinate.
  /// Used while scrubbing so short bars and sparse points do not drop the
  /// selection merely because the pointer is vertically distant from a mark.
  List<GraphSelectionItem> scrubTest(double x) {
    if (x < plotBounds.left || x > plotBounds.right) {
      return const <GraphSelectionItem>[];
    }
    HistoryChartHitRegion? closest;
    double closestDistance = double.infinity;
    for (final HistoryChartHitRegion region in hitRegions) {
      if (region.visibleBounds.isEmpty) continue;
      final double distance = x < region.visibleBounds.left
          ? region.visibleBounds.left - x
          : x > region.visibleBounds.right
          ? x - region.visibleBounds.right
          : 0;
      if (distance < closestDistance) {
        closest = region;
        closestDistance = distance;
      }
    }
    return closest == null
        ? const <GraphSelectionItem>[]
        : _itemsFor(closest, x);
  }

  List<GraphSelectionItem> _itemsFor(HistoryChartHitRegion closest, double x) {
    final GraphTimeBin? bin = closest.item.datum.bin;
    final List<GraphSelectionItem> items = <GraphSelectionItem>[];
    final Set<GraphSelectionItem> seen = <GraphSelectionItem>{};
    for (final HistoryChartHitRegion region in hitRegions) {
      final bool isRange = region.item.series.mark == GraphMark.range;
      final bool selectedRange = closest.item.series.mark == GraphMark.range;
      final bool isPoint = region.item.series.mark == GraphMark.point;
      final bool selectedPoint = closest.item.series.mark == GraphMark.point;
      bool sharesPosition;
      if (isPoint && selectedPoint) {
        // Dots retain their actual day even when aggregation bins span months.
        sharesPosition =
            region.item.datum.xCenter == closest.item.datum.xCenter;
      } else if (isPoint &&
          selectedRange &&
          closest.item.datum.timing == GraphTiming.unknown) {
        final date = region.item.datum.xCenter;
        sharesPosition =
            !date.isBefore(closest.item.datum.xStart) &&
            date.isBefore(closest.item.datum.xEnd);
      } else if (isRange && selectedPoint) {
        final date = closest.item.datum.xCenter;
        sharesPosition =
            !date.isBefore(region.item.datum.xStart) &&
            date.isBefore(region.item.datum.xEnd);
      } else if (isRange || selectedRange) {
        sharesPosition =
            x >= region.visibleBounds.left && x <= region.visibleBounds.right;
      } else {
        sharesPosition =
            bin != null && region.item.datum.bin?.index == bin.index;
      }
      final bool sharesSelection =
          region.item == closest.item || sharesPosition;
      if (!sharesSelection || !seen.add(region.item)) {
        continue;
      }
      items.add(region.item);
    }
    return List<GraphSelectionItem>.unmodifiable(items);
  }

  HistoryChartHitRegion? regionFor(GraphSelectionItem item) {
    for (final HistoryChartHitRegion region in hitRegions) {
      if (region.item == item) return region;
    }
    return null;
  }
}

@immutable
class HistoryChartLaneScene {
  final PreparedLane lane;
  final Rect frame;
  final Rect plot;
  final HistoryChartValueDomain domain;
  final List<HistoryChartValueTick> valueTicks;
  final List<HistoryChartBarGeometry> bars;
  final List<HistoryChartPointGeometry> points;
  final List<HistoryChartLineGeometry> lines;
  final List<HistoryChartRangeGeometry> ranges;
  final List<HistoryChartDayPartBand> dayPartBands;

  HistoryChartLaneScene({
    required this.lane,
    required this.frame,
    required this.plot,
    required this.domain,
    required List<HistoryChartValueTick> valueTicks,
    required List<HistoryChartBarGeometry> bars,
    required List<HistoryChartPointGeometry> points,
    required List<HistoryChartLineGeometry> lines,
    required List<HistoryChartRangeGeometry> ranges,
    List<HistoryChartDayPartBand> dayPartBands = const [],
  }) : valueTicks = List<HistoryChartValueTick>.unmodifiable(valueTicks),
       bars = List<HistoryChartBarGeometry>.unmodifiable(bars),
       points = List<HistoryChartPointGeometry>.unmodifiable(points),
       lines = List<HistoryChartLineGeometry>.unmodifiable(lines),
       ranges = List<HistoryChartRangeGeometry>.unmodifiable(ranges),
       dayPartBands = List<HistoryChartDayPartBand>.unmodifiable(dayPartBands);
}

@immutable
class HistoryChartValueDomain {
  final double min;
  final double max;

  const HistoryChartValueDomain({required this.min, required this.max});

  double get span => max - min;
}

@immutable
class HistoryChartTimeTick {
  final DateTime time;
  final double x;
  final String label;
  final Rect labelBounds;

  const HistoryChartTimeTick({
    required this.time,
    required this.x,
    required this.label,
    required this.labelBounds,
  });
}

@immutable
class HistoryChartDayPartBand {
  final Rect rect;
  final String label;

  const HistoryChartDayPartBand({required this.rect, required this.label});
}

@immutable
class HistoryChartValueTick {
  final double value;
  final double y;
  final String label;

  const HistoryChartValueTick({
    required this.value,
    required this.y,
    required this.label,
  });
}

@immutable
class HistoryChartBarGeometry {
  final GraphSelectionItem item;
  final Rect rect;
  final Color color;

  const HistoryChartBarGeometry({
    required this.item,
    required this.rect,
    required this.color,
  });
}

@immutable
class HistoryChartPointGeometry {
  final GraphSelectionItem item;
  final Offset center;
  final double radius;
  final Color color;

  const HistoryChartPointGeometry({
    required this.item,
    required this.center,
    required this.radius,
    required this.color,
  });
}

@immutable
class HistoryChartLineGeometry {
  final PreparedSeries series;
  final List<HistoryChartLineVertex> vertices;
  final Color color;

  HistoryChartLineGeometry({
    required this.series,
    required List<HistoryChartLineVertex> vertices,
    required this.color,
  }) : vertices = List<HistoryChartLineVertex>.unmodifiable(vertices);
}

@immutable
class HistoryChartLineVertex {
  final GraphSelectionItem item;
  final Offset position;

  const HistoryChartLineVertex({required this.item, required this.position});
}

@immutable
class HistoryChartRangeGeometry {
  final GraphSelectionItem item;
  final Rect rect;
  final Color color;

  const HistoryChartRangeGeometry({
    required this.item,
    required this.rect,
    required this.color,
  });
}

@immutable
class HistoryChartMarkerGeometry {
  final GraphMarker marker;
  final double startX;
  final double? endX;
  final Rect? band;

  const HistoryChartMarkerGeometry({
    required this.marker,
    required this.startX,
    required this.endX,
    required this.band,
  });
}

@immutable
class HistoryChartHitRegion {
  final GraphSelectionItem item;
  final Rect visibleBounds;
  final Rect hitBounds;
  final Offset anchor;

  const HistoryChartHitRegion({
    required this.item,
    required this.visibleBounds,
    required this.hitBounds,
    required this.anchor,
  });

  double distanceToVisibleShape(Offset position) {
    final double dx = position.dx < visibleBounds.left
        ? visibleBounds.left - position.dx
        : position.dx > visibleBounds.right
        ? position.dx - visibleBounds.right
        : 0;
    final double dy = position.dy < visibleBounds.top
        ? visibleBounds.top - position.dy
        : position.dy > visibleBounds.bottom
        ? position.dy - visibleBounds.bottom
        : 0;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
