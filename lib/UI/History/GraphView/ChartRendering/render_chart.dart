import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/annotation_painter.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/axis_painter.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_annotation.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_animation_state.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/dataset_painter.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/trend_line_painter.dart';

class RenderChart<T, D> extends StatefulWidget {
  final List<ChartSeriesData<T, D>> datasets;
  final double? width;
  final double? height;

  final Duration animationDuration;
  final Curve animationCurve;
  final bool animate;

  final void Function(ChartHitTestResult<T, D> hit)? onTap;

  final void Function(ChartHitTestResult<T, D>? hit)? onHover;

  final ChartAxis<D> xAxis;
  final ChartAxis<dynamic> yAxis;
  final ChartStyle? style;
  final bool stackBars;
  final List<ChartAnnotation<D>>? verticalAnnotations;
  final List<ChartAnnotation<dynamic>>? horizontalAnnotations;

  final TrendLine? trendLine;
  final String? xAxisLabel;
  final String? yAxisLabel;

  final ChartSelectionController<T, D>? selectionController;

  const RenderChart.multi({
    super.key,
    required this.datasets,
    this.width,
    this.height = 300,
    this.animate = true,
    this.onTap,
    this.onHover,
    this.animationDuration = Durations.medium1,
    this.animationCurve = Curves.easeInOut,
    required this.xAxis,
    this.yAxis = const NumberAxis(),
    this.style,
    this.stackBars = false,
    this.verticalAnnotations,
    this.horizontalAnnotations,
    this.trendLine,
    this.xAxisLabel,
    this.yAxisLabel,
    this.selectionController,
  });

  RenderChart({
    super.key,
    required ChartSeriesData<T, D> data,
    this.width,
    this.height = 300,
    this.animate = true,
    this.onTap,
    this.onHover,
    this.animationDuration = Durations.medium1,
    this.animationCurve = Curves.easeInOut,
    required this.xAxis,
    this.yAxis = const NumberAxis(),
    this.style,
    this.verticalAnnotations,
    this.horizontalAnnotations,
    this.trendLine,
    this.xAxisLabel,
    this.yAxisLabel,
    this.selectionController,
  })  : datasets = [data],
        stackBars = false;

  @override
  State<RenderChart<T, D>> createState() => _RenderChartState<T, D>();
}

class _RenderChartState<T, D> extends State<RenderChart<T, D>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ChartAnimationState<T, D> _animState;

  List<ChartHitTestResult<T, D>>? _lastHoverResults;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animState = ChartAnimationState<T, D>();
    _animState.initializeFromDatasets(widget.datasets);

    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant RenderChart<T, D> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.animationDuration;

    final dataChanged = !listEquals(widget.datasets, oldWidget.datasets);
    final axisChanged =
        widget.xAxis != oldWidget.xAxis || widget.yAxis != oldWidget.yAxis;

    if (dataChanged) {
      _animState.updateFromDatasets(widget.datasets);
    }

    if (dataChanged || axisChanged) {
      if (widget.animate) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DataBounds _computeCombinedBounds(double availableWidth, ChartStyle style) {
    if (widget.datasets.isEmpty) {
      return const DataBounds(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        xAxisTickSize: 0,
        yAxisTickSize: 0,
      );
    }

    final DataBounds calculated = DataBounds.combined(
        widget.datasets.map((d) => d.calculateRanges(widget.xAxis)));
    double minX = widget.xAxis.minValue() ?? calculated.minX;
    double maxX = widget.xAxis.maxValue() ?? calculated.maxX;
    double minY = widget.yAxis.minValue() ?? calculated.minY;
    double maxY = widget.yAxis.maxValue() ?? calculated.maxY;

    if (style.barChartStyle.stackBars &&
        widget.datasets.any((d) => d is BarChartData)) {
      final Map<double, double> stackedSums = {};
      for (final ds in widget.datasets) {
        if (ds is BarChartData<T, D>) {
          for (int i = 0; i < ds.data.length; i++) {
            final T item = ds.data[i];
            final double x = widget.xAxis.toDouble(ds.getPointX(item, i));
            final double y = ds.getPointY(item, i);
            stackedSums[x] = (stackedSums[x] ?? 0) + y;
          }
        }
      }
      if (stackedSums.isNotEmpty) {
        double stackMax = 0;
        for (final val in stackedSums.values) {
          if (val > stackMax) stackMax = val;
        }
        if (stackMax > maxY) maxY = stackMax;
      }
    }

    final double labelMinX = minX;
    final double labelMaxX = maxX;

    final bool hasBarChart = widget.datasets.any((d) => d is BarChartData);
    double xAxisTickSize = widget.xAxis.interval ?? calculated.xAxisTickSize;

    if (widget.xAxis.interval == null) {
      if (widget.xAxis is DateTimeAxis) {
        final double rangeMs =
            labelMaxX - (widget.xAxis.minValue() ?? calculated.minX);
        double desiredInterval = getEfficientInterval(availableWidth, rangeMs);

        if (calculated.minDataStep > 0) {
          final double step = calculated.minDataStep;

          double multiple = (desiredInterval / step).roundToDouble();
          if (multiple < 1.0) multiple = 1.0;
          desiredInterval = multiple * step;
        }
        xAxisTickSize = desiredInterval;
      } else {
        xAxisTickSize = getEfficientInterval(availableWidth, maxX - minX);
      }
    }

    if (hasBarChart) {
      final double interval =
          calculated.minDataStep > 0 ? calculated.minDataStep : xAxisTickSize;

      if (interval > 0) {
        final halfInterval = interval * 0.5;
        minX -= halfInterval;
        maxX += halfInterval;
      }
    }

    double yAxisTickSize = widget.yAxis.interval ?? 1.0;
    if (widget.yAxis.interval == null) {
      final yAxisRange = calculateYAxisRange(ticks: 3, max: maxY, min: minY);
      yAxisTickSize = yAxisRange.tickSize < 1.0 ? 1.0 : yAxisRange.tickSize;
    }

    return DataBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      labelMinX: labelMinX,
      labelMaxX: labelMaxX,
      xAxisTickSize: xAxisTickSize,
      yAxisTickSize: yAxisTickSize,
      minDataStep:
          calculated.minDataStep > 0 ? calculated.minDataStep : xAxisTickSize,
    );
  }

  List<ChartHitTestResult<T, D>> _hitTest(
      Offset position, ChartGeometry geometry, ChartStyle style) {
    return ChartHitTester.hitTest(
      position: position,
      geometry: geometry,
      datasets: widget.datasets,
      xAxis: widget.xAxis,
      style: style,
    );
  }

  void _handleTap(Offset position, ChartGeometry geometry, ChartStyle style) {
    // Check for annotation taps first
    final annotationHit = AnnotationPainter.hitTest(
      position: position,
      geometry: geometry,
      xAxis: widget.xAxis,
      yAxis: widget.yAxis,
      verticalAnnotations: widget.verticalAnnotations ?? [],
      horizontalAnnotations: widget.horizontalAnnotations ?? [],
    );

    if (annotationHit != null) {
      annotationHit.onTap?.call();
      if (annotationHit.onTap != null) return;
    }

    if (widget.onTap == null) return;

    final hits = _hitTest(position, geometry, style);
    if (hits.isNotEmpty) {
      widget.onTap!(hits.first);
    }
  }

  void _handleHover(Offset position, ChartGeometry geometry, ChartStyle style) {
    if (_hoverPosition != position) {
      setState(() {
        _hoverPosition = position;
      });
    }

    if (widget.onHover == null) return;

    final List<ChartHitTestResult<T, D>> hits =
        _hitTest(position, geometry, style);

    // Simple equality check for multi-hits (check if count and first hit match)
    final bool changed = hits.length != (_lastHoverResults?.length ?? 0) ||
        (hits.isNotEmpty &&
            _lastHoverResults?.isNotEmpty == true &&
            hits.first != _lastHoverResults!.first);

    if (changed || _hoverPosition != position) {
      _lastHoverResults = hits;
      widget.selectionController?.select(hits, position: position);
      widget.onHover?.call(hits.isNotEmpty ? hits.first : null);
    }
  }

  void _handleHoverExit() {
    if (_hoverPosition != null) {
      setState(() {
        _hoverPosition = null;
      });
    }

    widget.selectionController?.clear();
    if (widget.onHover == null) return;

    if (_lastHoverResults?.isNotEmpty == true) {
      _lastHoverResults = null;
      widget.onHover!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    var style = widget.style ?? ChartStyle.fromTheme(context);
    if (widget.stackBars != style.barChartStyle.stackBars) {
      style = style.copyWith(
        barChartStyle: BarChartStyle(
          stackBars: widget.stackBars,
          barWidthRatio: style.barChartStyle.barWidthRatio,
          barMaxWidth: style.barChartStyle.barMaxWidth,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        final DataBounds bounds =
            _computeCombinedBounds(constraints.maxWidth, style);

        double anchor = 0.0;
        if (widget.datasets.any((d) => d is BarChartData) &&
            bounds.minDataStep > 0) {
          anchor = bounds.labelMinX + bounds.minDataStep * 0.5;
        }

        _animState.updateAxisLabels(bounds, widget.xAxis, widget.yAxis,
            anchor: anchor);

        final ChartGeometry geometry = ChartGeometry.compute(
          size: constraints.biggest,
          bounds: bounds,
          yAxisState: _animState.yAxis,
          showYAxis: widget.yAxis.showing,
          showXAxis: widget.xAxis.showing,
          style: style,
          xAxisLabel: widget.xAxisLabel,
          yAxisLabel: widget.yAxisLabel,
        );

        return MouseRegion(
          onHover: widget.onHover != null
              ? (event) => _handleHover(event.localPosition, geometry, style)
              : null,
          onExit: widget.onHover != null ? (_) => _handleHoverExit() : null,
          child: GestureDetector(
            onTapUp: (details) =>
                _handleTap(details.localPosition, geometry, style),
            onHorizontalDragStart: widget.onHover != null
                ? (details) =>
                    _handleHover(details.localPosition, geometry, style)
                : null,
            onHorizontalDragUpdate: widget.onHover != null
                ? (details) =>
                    _handleHover(details.localPosition, geometry, style)
                : null,
            onHorizontalDragEnd:
                widget.onHover != null ? (_) => _handleHoverExit() : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ValueListenableBuilder<ChartSelectionState<T, D>>(
                  valueListenable: widget.selectionController ??
                      ChartSelectionController<T, D>(),
                  builder: (context, selectionState, _) {
                    final selection = selectionState.results;
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _ChartPainter(
                        datasets: widget.datasets,
                        bounds: bounds,
                        animState: _animState,
                        animationValue: _controller.value,
                        xAxis: widget.xAxis,
                        yAxis: widget.yAxis,
                        geometry: geometry,
                        style: style,
                        stackBars: widget.stackBars,
                        verticalAnnotations: widget.verticalAnnotations ?? [],
                        horizontalAnnotations:
                            widget.horizontalAnnotations ?? [],
                        hoverPosition: _hoverPosition,
                        trendLine: widget.trendLine,
                        xAxisLabel: widget.xAxisLabel,
                        yAxisLabel: widget.yAxisLabel,
                        selection: selection,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _ChartPainter<T, D> extends CustomPainter {
  final List<ChartSeriesData<T, D>> datasets;
  final DataBounds bounds;
  final ChartAnimationState<T, D> animState;
  final double animationValue;
  final ChartAxis<D> xAxis;
  final ChartAxis<dynamic> yAxis;
  final ChartStyle style;
  final ChartGeometry geometry;
  final bool stackBars;
  final List<ChartAnnotation<D>> verticalAnnotations;
  final List<ChartAnnotation<dynamic>> horizontalAnnotations;
  final Offset? hoverPosition;
  final TrendLine? trendLine;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final List<ChartHitTestResult<T, D>> selection;

  _ChartPainter({
    required this.datasets,
    required this.bounds,
    required this.animState,
    required this.animationValue,
    required this.xAxis,
    required this.yAxis,
    required this.geometry,
    required this.style,
    required this.stackBars,
    required this.verticalAnnotations,
    required this.horizontalAnnotations,
    this.selection = const [],
    this.hoverPosition,
    this.trendLine,
    this.xAxisLabel,
    this.yAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (datasets.isEmpty) return;

    AxisPainter.paintGridLines(canvas, geometry, animState.xAxis,
        animState.yAxis, animationValue, style);

    AnnotationPainter.paint(
      canvas,
      geometry,
      xAxis,
      yAxis,
      verticalAnnotations,
      horizontalAnnotations,
      style,
    );

    AxisPainter.paintAxisLines(canvas, geometry, style);
    if (yAxis.showing) {
      AxisPainter.paintYAxis(
          canvas, geometry, animState.yAxis, animationValue, style);
    }
    if (xAxis.showing) {
      AxisPainter.paintXAxis(
          canvas, geometry, animState.xAxis, animationValue, style);
    }

    AxisPainter.paintAxisTitles(
        canvas, geometry, style, xAxisLabel, yAxisLabel);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
      geometry.leftMargin,
      geometry.topMargin,
      geometry.drawWidth,
      geometry.drawHeight,
    ));

    final maxBarsInDataset = datasets
        .whereType<BarChartData>()
        .map((ds) => ds.data.length)
        .fold(0, (a, b) => a > b ? a : b);

    final Map<double, double>? stackBottoms = stackBars ? {} : null;

    for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
      final data = datasets[dsIndex];
      if (data.data.isEmpty) continue;

      final Set<int> selectedIndices = selection
          .where((hit) => hit.datasetIndex == dsIndex)
          .map((hit) => hit.itemIndex)
          .toSet();

      DatasetPainter.paint(
        canvas,
        geometry,
        data,
        xAxis,
        dsIndex,
        (di, pi, targetY) =>
            animState.getAnimatedY(di, pi, targetY, animationValue),
        maxBarsInDataset,
        style,
        stackBottoms: stackBottoms,
        selectedIndices: selectedIndices,
      );
    }

    if (trendLine != null) {
      for (int dsIndex = 0; dsIndex < datasets.length; dsIndex++) {
        final data = datasets[dsIndex];
        if (data.data.length < 3) continue;

        TrendLinePainter.paint(
          canvas,
          geometry,
          data,
          xAxis,
          trendLine!,
        );
      }
    }

    canvas.restore();

    final crosshairStyle = style.crosshairStyle;
    if (crosshairStyle != null && hoverPosition != null) {
      final Paint crosshairPaint = Paint()
        ..color = crosshairStyle.color
        ..strokeWidth = crosshairStyle.strokeWidth
        ..style = PaintingStyle.stroke;

      if (crosshairStyle.showX) {
        canvas.drawLine(
          Offset(hoverPosition!.dx, geometry.topMargin),
          Offset(hoverPosition!.dx, geometry.topMargin + geometry.drawHeight),
          crosshairPaint,
        );
      }

      if (crosshairStyle.showY) {
        canvas.drawLine(
          Offset(geometry.leftMargin, hoverPosition!.dy),
          Offset(geometry.leftMargin + geometry.drawWidth, hoverPosition!.dy),
          crosshairPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter<T, D> oldDelegate) {
    return oldDelegate.datasets != datasets ||
        oldDelegate.bounds != bounds ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.style != style ||
        oldDelegate.stackBars != stackBars ||
        oldDelegate.verticalAnnotations != verticalAnnotations ||
        oldDelegate.horizontalAnnotations != horizontalAnnotations ||
        oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.trendLine != trendLine ||
        oldDelegate.xAxisLabel != xAxisLabel ||
        oldDelegate.yAxisLabel != yAxisLabel;
  }
}
