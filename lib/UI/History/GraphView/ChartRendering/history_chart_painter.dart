import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_layout.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_scene.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

class HistoryChartPainter extends CustomPainter {
  final HistoryChartScene scene;
  final HistoryChartVisualStyle style;
  final HistoryChartAppearance appearance;
  final TextDirection textDirection;
  final TextScaler textScaler;

  const HistoryChartPainter({
    required this.scene,
    required this.style,
    required this.appearance,
    required this.textDirection,
    required this.textScaler,
  });

  bool get _compact => appearance == HistoryChartAppearance.compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (scene.lanes.isEmpty || scene.plotBounds.isEmpty) return;

    _paintMarkerBands(canvas);
    for (final HistoryChartLaneScene lane in scene.lanes) {
      _paintLaneFrame(canvas, lane);
      canvas.save();
      canvas.clipRect(lane.plot);
      _paintRanges(canvas, lane);
      _paintBars(canvas, lane);
      _paintLines(canvas, lane);
      _paintPoints(canvas, lane);
      canvas.restore();
    }
    _paintMarkers(canvas);
    _paintTimeAxis(canvas);
  }

  void _paintLaneFrame(Canvas canvas, HistoryChartLaneScene lane) {
    final Paint gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;
    final Paint axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1;

    for (int index = 0; index < lane.dayPartBands.length; index++) {
      final HistoryChartDayPartBand band = lane.dayPartBands[index];
      if (index.isEven) {
        canvas.drawRect(
          band.rect,
          Paint()..color = style.gridColor.withValues(alpha: 0.07),
        );
      }
      canvas.drawLine(band.rect.topLeft, band.rect.topRight, gridPaint);
    }
    if (!_compact) {
      for (final tick in scene.timeTicks) {
        canvas.drawLine(
          Offset(tick.x, lane.plot.top),
          Offset(tick.x, lane.plot.bottom),
          Paint()
            ..color = style.gridColor.withValues(alpha: 0.12)
            ..strokeWidth = 1,
        );
      }
    }

    for (final HistoryChartValueTick tick in lane.valueTicks) {
      if (lane.dayPartBands.isEmpty) {
        canvas.drawLine(
          Offset(lane.plot.left, tick.y),
          Offset(lane.plot.right, tick.y),
          gridPaint,
        );
      }
      if (!_compact) {
        _paintText(
          canvas,
          tick.label,
          style.axisLabelStyle,
          Offset(lane.plot.left - 8, tick.y),
          horizontal: _HorizontalTextAlignment.end,
          vertical: _VerticalTextAlignment.center,
          maxWidth: math.max(1, lane.plot.left - 18),
          maxLines: lane.dayPartBands.isEmpty ? 1 : null,
        );
      }
    }

    if (lane.lane.scaleKind != GraphScaleKind.range) {
      canvas.drawLine(lane.plot.bottomLeft, lane.plot.bottomRight, axisPaint);
    }
    if (!_compact) {
      _paintText(
        canvas,
        historyChartLaneHeading(lane.lane),
        style.laneLabelStyle,
        lane.frame.topLeft,
        horizontal: _HorizontalTextAlignment.start,
        vertical: _VerticalTextAlignment.start,
        maxWidth: lane.frame.width,
        maxLines: null,
      );
    }
  }

  void _paintBars(Canvas canvas, HistoryChartLaneScene lane) {
    for (final HistoryChartBarGeometry bar in lane.bars) {
      final Paint paint = Paint()
        ..color = bar.color
        ..style = PaintingStyle.fill;
      if (bar.rect.height <= 0.5) {
        canvas.drawLine(bar.rect.bottomLeft, bar.rect.bottomRight, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  void _paintPoints(Canvas canvas, HistoryChartLaneScene lane) {
    for (final HistoryChartPointGeometry point in lane.points) {
      canvas.drawCircle(
        point.center,
        point.radius,
        Paint()
          ..color = point.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintLines(Canvas canvas, HistoryChartLaneScene lane) {
    for (final HistoryChartLineGeometry line in lane.lines) {
      if (line.vertices.isEmpty) continue;
      final Paint paint = Paint()
        ..color = line.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Path path = Path()
        ..moveTo(
          line.vertices.first.position.dx,
          line.vertices.first.position.dy,
        );
      for (final HistoryChartLineVertex vertex in line.vertices.skip(1)) {
        path.lineTo(vertex.position.dx, vertex.position.dy);
      }
      canvas.drawPath(path, paint);

      final Paint pointPaint = Paint()
        ..color = line.color
        ..style = PaintingStyle.fill;
      for (final HistoryChartLineVertex vertex in line.vertices) {
        canvas.drawCircle(vertex.position, _compact ? 1.75 : 2.5, pointPaint);
      }
    }
  }

  void _paintRanges(Canvas canvas, HistoryChartLaneScene lane) {
    for (final HistoryChartRangeGeometry range in lane.ranges) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(range.rect, const Radius.circular(3)),
        Paint()
          ..color = range.color.withValues(
            alpha: switch (range.item.datum.timing) {
              GraphTiming.unknown => 0.06,
              GraphTiming.dayPart => 0.15,
              GraphTiming.reviewPeriod => 0.24,
              GraphTiming.exact => 0.24,
            },
          )
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(range.rect, const Radius.circular(3)),
        Paint()
          ..color = range.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintMarkerBands(Canvas canvas) {
    for (final HistoryChartMarkerGeometry marker in scene.markers) {
      final Rect? band = marker.band;
      if (band == null || band.isEmpty) continue;
      canvas.drawRect(
        band,
        Paint()
          ..color = marker.marker.color.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintMarkers(Canvas canvas) {
    final Paint linePaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double lastLabelRight = double.negativeInfinity;
    for (final HistoryChartMarkerGeometry marker in scene.markers) {
      linePaint.color = marker.marker.color.withValues(alpha: 0.85);
      canvas.drawLine(
        Offset(marker.startX, scene.plotBounds.top),
        Offset(marker.startX, scene.plotBounds.bottom),
        linePaint,
      );
      final double? endX = marker.endX;
      if (endX != null) {
        canvas.drawLine(
          Offset(endX, scene.plotBounds.top),
          Offset(endX, scene.plotBounds.bottom),
          linePaint,
        );
      }

      if (!_compact) {
        final TextPainter label = _textPainter(
          marker.marker.label,
          style.markerLabelStyle.copyWith(color: marker.marker.color),
          maxWidth: math.max(40, scene.plotBounds.width * 0.35),
        );
        double x = marker.startX + 4;
        x = x.clamp(
          scene.plotBounds.left,
          math.max(scene.plotBounds.left, scene.plotBounds.right - label.width),
        );
        // Dense annotations remain readable by suppressing labels that collide;
        // every marker line is still rendered.
        if (x >= lastLabelRight + 6) {
          label.paint(canvas, Offset(x, 2));
          lastLabelRight = x + label.width;
        }
      }
    }
  }

  void _paintTimeAxis(Canvas canvas) {
    for (final HistoryChartTimeTick tick in scene.timeTicks) {
      _paintText(
        canvas,
        tick.label,
        style.axisLabelStyle,
        tick.labelBounds.topLeft,
        horizontal: _HorizontalTextAlignment.start,
        vertical: _VerticalTextAlignment.start,
        maxWidth: tick.labelBounds.width,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle textStyle,
    Offset anchor, {
    required _HorizontalTextAlignment horizontal,
    required _VerticalTextAlignment vertical,
    double maxWidth = double.infinity,
    Rect? horizontalBounds,
    int? maxLines = 1,
  }) {
    if (text.isEmpty) return;
    final TextPainter painter = _textPainter(
      text,
      textStyle,
      maxWidth: maxWidth,
      maxLines: maxLines,
      textAlign: horizontal == _HorizontalTextAlignment.end
          ? TextAlign.end
          : TextAlign.start,
    );
    double dx = switch (horizontal) {
      _HorizontalTextAlignment.start => anchor.dx,
      _HorizontalTextAlignment.center => anchor.dx - painter.width / 2,
      _HorizontalTextAlignment.end => anchor.dx - painter.width,
    };
    final double dy = switch (vertical) {
      _VerticalTextAlignment.start => anchor.dy,
      _VerticalTextAlignment.center => anchor.dy - painter.height / 2,
    };
    if (horizontalBounds != null) {
      dx = dx.clamp(
        horizontalBounds.left,
        math.max(horizontalBounds.left, horizontalBounds.right - painter.width),
      );
    }
    painter.paint(canvas, Offset(dx, dy));
  }

  TextPainter _textPainter(
    String text,
    TextStyle textStyle, {
    double maxWidth = double.infinity,
    int? maxLines = 1,
    TextAlign textAlign = TextAlign.start,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      textAlign: textAlign,
      ellipsis: maxLines == null ? null : '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
    return <CustomPainterSemantics>[
      for (final HistoryChartHitRegion region in scene.hitRegions)
        CustomPainterSemantics(
          rect: region.hitBounds,
          properties: SemanticsProperties(
            label: _semanticLabel(region.item),
            textDirection: textDirection,
          ),
        ),
    ];
  };

  String _semanticLabel(GraphSelectionItem item) {
    if (style.semanticLabelFormatter != null) {
      return style.semanticLabelFormatter!(item);
    }
    final List<String> pieces = <String>[item.series.label];
    final GraphTimeBin? bin = item.datum.bin;
    if (bin != null && bin.label.isNotEmpty) pieces.add(bin.label);
    final double? value = item.datum.value;
    if (item.datum.timing == GraphTiming.unknown) {
      pieces.add('Time unknown');
    } else if (item.series.unit == 'time' && value != null) {
      pieces.add(
        item.datum.valueEnd == null
            ? style.formatHour(value)
            : '${style.formatHour(value)} – ${style.formatHour(item.datum.valueEnd!)}',
      );
    } else if (value != null) {
      final String formatted = value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
      final String? unit = item.series.unit;
      pieces.add(unit == null || unit.isEmpty ? formatted : '$formatted $unit');
    }
    final int count = item.datum.summary.reportCount;
    if (count > 0 && item.series.unit != 'reports') {
      pieces.add('$count ${count == 1 ? 'report' : 'reports'}');
    }
    return pieces.join(', ');
  }

  @override
  bool shouldRepaint(covariant HistoryChartPainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.style != style ||
      oldDelegate.appearance != appearance ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.textScaler != textScaler;

  @override
  bool shouldRebuildSemantics(covariant HistoryChartPainter oldDelegate) =>
      oldDelegate.scene != scene;
}

class HistoryChartSelectionPainter extends CustomPainter {
  final HistoryChartScene scene;
  final GraphSelectionState selection;
  final HistoryChartVisualStyle style;

  const HistoryChartSelectionPainter({
    required this.scene,
    required this.selection,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selection.isEmpty || scene.plotBounds.isEmpty) return;
    final List<HistoryChartHitRegion> selected = <HistoryChartHitRegion>[];
    for (final GraphSelectionItem item in selection.items) {
      final HistoryChartHitRegion? region = scene.regionFor(item);
      if (region != null) selected.add(region);
    }
    if (selected.isEmpty) return;

    final Paint crosshair = Paint()
      ..color = style.selectionColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(selected.first.anchor.dx, scene.plotBounds.top),
      Offset(selected.first.anchor.dx, scene.plotBounds.bottom),
      crosshair,
    );

    final Paint fill = Paint()
      ..color = style.selectionFillColor
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = style.selectionColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final HistoryChartHitRegion region in selected) {
      final Rect visible = region.visibleBounds;
      if (visible.width <= 8 && visible.height <= 8) {
        canvas.drawCircle(region.anchor, 7, fill);
        canvas.drawCircle(region.anchor, 7, stroke);
      } else {
        final RRect highlight = RRect.fromRectAndRadius(
          visible.inflate(2),
          const Radius.circular(4),
        );
        canvas.drawRRect(highlight, fill);
        canvas.drawRRect(highlight, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HistoryChartSelectionPainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.selection != selection ||
      oldDelegate.style != style;
}

enum _HorizontalTextAlignment { start, center, end }

enum _VerticalTextAlignment { start, center }
