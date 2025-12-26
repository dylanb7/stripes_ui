import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/Util/Helpers/stats.dart';

@immutable
sealed class TrendLine {
  final Color? color;
  final double strokeWidth;
  final bool dashed;
  final List<double>? dashPattern;

  const TrendLine({
    this.color,
    this.strokeWidth = 2.0,
    this.dashed = false,
    this.dashPattern,
  });
}

@immutable
class LoessTrendLine extends TrendLine {
  final double bandwidth;
  final int robustnessIterations;

  const LoessTrendLine({
    this.bandwidth = 0.3,
    this.robustnessIterations = 2,
    super.color,
    super.strokeWidth,
    super.dashed,
    super.dashPattern,
  });

  LoessTrendLine copyWith({
    double? bandwidth,
    int? robustnessIterations,
    Color? color,
    double? strokeWidth,
    bool? dashed,
    List<double>? dashPattern,
  }) {
    return LoessTrendLine(
      bandwidth: bandwidth ?? this.bandwidth,
      robustnessIterations: robustnessIterations ?? this.robustnessIterations,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dashed: dashed ?? this.dashed,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }
}

@immutable
class LinearTrendLine extends TrendLine {
  const LinearTrendLine({
    super.color,
    super.strokeWidth,
    super.dashed,
    super.dashPattern,
  });

  LinearTrendLine copyWith({
    Color? color,
    double? strokeWidth,
    bool? dashed,
    List<double>? dashPattern,
  }) {
    return LinearTrendLine(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dashed: dashed ?? this.dashed,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }
}

class TrendLinePainter {
  static void paint<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    ChartSeriesData<T, D> data,
    ChartAxis<D> xAxis,
    TrendLine config,
  ) {
    switch (config) {
      case LoessTrendLine():
        _paintLoess(canvas, geometry, data, xAxis, config);
      case LinearTrendLine():
        _paintLinear(canvas, geometry, data, xAxis, config);
    }
  }

  static void _paintLoess<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    ChartSeriesData<T, D> data,
    ChartAxis<D> xAxis,
    LoessTrendLine config,
  ) {
    if (data.data.length < 3) return;

    final List<double> xValues = [];
    final List<double> yValues = [];

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      xValues.add(xAxis.toDouble(data.getPointX(item, i)));
      yValues.add(data.getPointY(item, i));
    }

    final LoessResult result = loessSmooth(
      xValues,
      yValues,
      bandwidth: config.bandwidth,
      robustnessIterations: config.robustnessIterations,
    );

    _drawTrendPath(
      canvas,
      geometry,
      xValues,
      result.smoothedY,
      data.getPointColor(data.data.first, 0),
      config,
    );
  }

  static void _paintLinear<T, D>(
    Canvas canvas,
    ChartGeometry geometry,
    ChartSeriesData<T, D> data,
    ChartAxis<D> xAxis,
    LinearTrendLine config,
  ) {
    if (data.data.length < 2) return;

    final List<double> xValues = [];
    final List<double> yValues = [];

    for (int i = 0; i < data.data.length; i++) {
      final item = data.data[i];
      xValues.add(xAxis.toDouble(data.getPointX(item, i)));
      yValues.add(data.getPointY(item, i));
    }

    final LinearRegressionResult? regression =
        linearRegression(xValues, yValues);
    if (regression == null) return;

    final double minX = xValues.reduce((a, b) => a < b ? a : b);
    final double maxX = xValues.reduce((a, b) => a > b ? a : b);

    final double y1 = regression.slope * minX + regression.intercept;
    final double y2 = regression.slope * maxX + regression.intercept;

    _drawTrendPath(
      canvas,
      geometry,
      [minX, maxX],
      [y1, y2],
      data.getPointColor(data.data.first, 0),
      config,
    );
  }

  static void _drawTrendPath(
    Canvas canvas,
    ChartGeometry geometry,
    List<double> xValues,
    List<double> yValues,
    Color datasetColor,
    TrendLine config,
  ) {
    final Color lineColor = config.color ?? datasetColor.withValues(alpha: 0.7);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sortedIndices = List.generate(xValues.length, (i) => i);
    sortedIndices.sort((a, b) => xValues[a].compareTo(xValues[b]));

    // Build sorted screen points
    final List<Offset> points = [];
    for (int i = 0; i < sortedIndices.length; i++) {
      final idx = sortedIndices[i];
      points.add(geometry.dataToScreen(xValues[idx], yValues[idx]));
    }

    if (config is LoessTrendLine && points.length >= 3) {
      _drawSmoothPath(canvas, points, paint, config);
    } else {
      _drawLinearPath(canvas, points, paint, config);
    }
  }

  static void _drawLinearPath(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    TrendLine config,
  ) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (config.dashed) {
      _drawDashedPath(canvas, path, paint, config.dashPattern ?? [5, 3]);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  static void _drawSmoothPath(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    TrendLine config,
  ) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    if (config.dashed) {
      _drawDashedPath(canvas, path, paint, config.dashPattern ?? [5, 3]);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// Draws a dashed path.
  static void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dashPattern,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      int dashIndex = 0;
      bool draw = true;

      while (distance < metric.length) {
        final dashLength = dashPattern[dashIndex % dashPattern.length];
        final end = (distance + dashLength).clamp(0.0, metric.length);

        if (draw) {
          final extractPath = metric.extractPath(distance, end);
          canvas.drawPath(extractPath, paint);
        }

        distance = end;
        dashIndex++;
        draw = !draw;
      }
    }
  }
}
