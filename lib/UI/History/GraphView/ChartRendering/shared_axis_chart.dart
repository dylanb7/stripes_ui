import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/render_chart.dart';

/// A chart lane representing one or more datasets with its own label and y-axis bounds.
class ChartLane<T, D> {
  final List<ChartSeriesData<T, D>> datasets;
  final String label;
  final Color? labelColor;
  final double? height;
  final ChartAxis<num>? yAxis;
  final bool hideYAxis;
  final bool stackBars;

  const ChartLane({
    required this.datasets,
    required this.label,
    this.labelColor,
    this.height,
    this.yAxis,
    this.hideYAxis = false,
    this.stackBars = false,
  });

  /// Convenience constructor for a lane with a single dataset.
  ChartLane.single({
    required ChartSeriesData<T, D> data,
    required this.label,
    this.labelColor,
    this.height,
    this.yAxis,
    this.hideYAxis = false,
  })  : datasets = [data],
        stackBars = false;
}

/// A chart that renders multiple datasets in stacked horizontal lanes
/// with a shared x-axis at the bottom.
///
/// Each lane has its own y-axis scaling for independent comparison.
class SharedAxisChart<T, D> extends StatelessWidget {
  final List<ChartLane<T, D>> lanes;
  final double? width;
  final double laneHeight;
  final double lanePadding;
  final bool showLaneLabels;

  final void Function(int laneIndex, ChartHitTestResult<T, D>? hit)? onTap;
  final void Function(int laneIndex, ChartHitTestResult<T, D>? hit)? onHover;

  final ChartAxis<D> xAxis;
  final ChartAxis<dynamic>? yAxis;
  final ChartStyle? style;

  final ChartSelectionController<T, D>? selectionController;
  final bool compact;

  SharedAxisChart({
    super.key,
    required this.lanes,
    this.width,
    this.laneHeight = 100,
    this.lanePadding = 20,
    this.showLaneLabels = true,
    required this.xAxis,
    ChartAxis<dynamic>? yAxis,
    this.style,
    this.onTap,
    this.onHover,
    this.selectionController,
    this.compact = false,
  }) : yAxis = yAxis ??
            NumberAxis(
                formatter: NumberFormat.decimalPattern()
                  ..maximumFractionDigits = 0);

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveStyle = style ?? ChartStyle.fromTheme(context);
    final maxYLabelWidth =
        _calculateMaxYLabelWidth(context, effectiveStyle).clamp(40.0, 500.0);

    // Calculate global X bounds across all lanes
    double globalMinX = double.infinity;
    double globalMaxX = double.negativeInfinity;
    double minDataStep = double.infinity;
    bool hasBarData = false;

    for (final lane in lanes) {
      if (lane.datasets.isEmpty) continue;
      final DataBounds laneBounds = DataBounds.combined(
          lane.datasets.map((d) => d.calculateRanges(xAxis)));

      globalMinX = min(globalMinX, xAxis.minValue() ?? laneBounds.minX);
      globalMaxX = max(globalMaxX, xAxis.maxValue() ?? laneBounds.maxX);
      if (laneBounds.minDataStep > 0) {
        minDataStep = min(minDataStep, laneBounds.minDataStep);
      }
      if (lane.datasets.any((d) => d is BarChartData)) {
        hasBarData = true;
      }
    }

    if (globalMinX == double.infinity) {
      globalMinX = 0;
      globalMaxX = 1;
      minDataStep = 0;
    }

    final double range = globalMaxX - globalMinX;
    double globalTickSize = xAxis.interval ?? 1.0;

    if (xAxis.interval == null) {
      // We need a width to estimate the tick size reliably.
      // Default to a reasonable width if not provided.
      final double availableWidth =
          width ?? MediaQuery.of(context).size.width - 60;
      globalTickSize =
          getEfficientInterval(availableWidth, range, pixelPerInterval: 40);

      if (minDataStep != double.infinity && minDataStep > 0) {
        double multiple = (globalTickSize / minDataStep).roundToDouble();
        if (multiple < 1.0) multiple = 1.0;
        globalTickSize = multiple * minDataStep;
      }

      // Ensure tick size isn't too small for multi-day ranges to avoid duplicated day labels
      if (xAxis is DateTimeAxis) {
        const double dayMs = 24 * 3600 * 1000;
        const double sixHoursMs = 6 * 3600 * 1000;
        // Multi-day (strictly more than 1 day): use daily ticks
        // Single day or less: use 6h intervals to match HourAxis format
        if (range > dayMs && globalTickSize < dayMs) {
          globalTickSize = dayMs;
        } else if (range <= dayMs) {
          globalTickSize = sixHoursMs;
        }
      }
    }

    // Only apply half-step padding if style option is enabled
    final double globalHalfStep = effectiveStyle.hasHalfStepPadding &&
            hasBarData &&
            minDataStep != double.infinity &&
            minDataStep > 0
        ? minDataStep * 0.5
        : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Render each lane as a separate RenderChart
        for (int i = 0; i < lanes.length; i++) ...[
          if (showLaneLabels && !compact) // Hide lane labels in compact mode
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Colored dot indicator
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: lanes[i].labelColor ??
                          effectiveStyle.axisLabelStyle.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Label text in readable theme color
                  Text(
                    lanes[i].label,
                    style: effectiveStyle.axisLabelStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Lane container - borders now controlled via ChartStyle axis lines
          SizedBox(
            height: lanes[i].height ?? laneHeight,
            child: RenderChart<T, D>.multi(
              datasets: lanes[i].datasets,
              height: lanes[i].height ?? laneHeight,
              xAxis: compact
                  ? xAxis.copyWithShowing(false)
                  : xAxis.copyWithShowing(i ==
                      lanes.length - 1), // Only show x-axis labels on last lane
              yAxis: (lanes[i].hideYAxis || compact)
                  ? const NumberAxis(showing: false)
                  : (lanes[i].yAxis ?? yAxis ?? const NumberAxis()),
              forcedLeftMargin: compact ? 0 : maxYLabelWidth,
              stackBars: lanes[i].stackBars,
              minX: globalMinX,
              maxX: globalMaxX,
              xAxisTickSize: globalTickSize,
              forcedHalfStep: globalHalfStep,
              // Axis lines for lane borders (top line on all lanes, bottom on last)
              style: compact
                  ? effectiveStyle.copyWith(
                      showGridLines: false,
                      drawXAxisLine: false,
                      drawYAxisLine: false,
                      drawTopAxisLine: false,
                      chartPadding: EdgeInsets.zero,
                    )
                  : effectiveStyle.copyWith(
                      showGridLines: false,
                      // Top line for visual separation between lanes
                      drawTopAxisLine: true,
                      // Bottom (X) axis line only on last lane
                      drawXAxisLine: i == lanes.length - 1,
                      axisLineColor:
                          effectiveStyle.axisLineColor.withValues(alpha: 0.5),
                      chartPadding:
                          effectiveStyle.chartPadding.copyWith(right: 20.0),
                    ),
              animate: i == lanes.length - 1,

              onHover: onHover != null || selectionController != null
                  ? (hit) {
                      if (hit == null) {
                        selectionController?.clear();
                        onHover?.call(i, null);
                        return;
                      }
                      // Find all hits at this X across all lanes
                      final allHits =
                          _findAllHitsAtX(hit.xValue, hit.screenPosition);
                      if (selectionController != null) {
                        selectionController!
                            .select(allHits, position: hit.screenPosition);
                      }
                      // Create corrected hit with lane index as datasetIndex
                      final correctedHit = ChartHitTestResult<T, D>(
                        item: hit.item,
                        datasetIndex: i,
                        itemIndex: hit.itemIndex,
                        xValue: hit.xValue,
                        yValue: hit.yValue,
                        screenPosition: hit.screenPosition,
                      );
                      onHover?.call(i, correctedHit);
                    }
                  : null,
              onTap: onTap != null || selectionController != null
                  ? (hit) {
                      if (hit == null) {
                        // Tapped empty area - clear selection and notify
                        selectionController?.clear();
                        onTap?.call(i, null);
                        return;
                      }
                      final allHits =
                          _findAllHitsAtX(hit.xValue, hit.screenPosition);
                      if (selectionController != null) {
                        selectionController!
                            .select(allHits, position: hit.screenPosition);
                      }
                      // Create corrected hit with lane index as datasetIndex
                      final correctedHit = ChartHitTestResult<T, D>(
                        item: hit.item,
                        datasetIndex: i,
                        itemIndex: hit.itemIndex,
                        xValue: hit.xValue,
                        yValue: hit.yValue,
                        screenPosition: hit.screenPosition,
                      );
                      onTap?.call(i, correctedHit);
                    }
                  : null,
              // We don't pass selectionController directly to lanes anymore
              // because we want to handle the aggregation ourselves
            ),
          ),
          if (i < lanes.length - 1) SizedBox(height: compact ? 2 : lanePadding),
        ],
      ],
    );
  }

  List<ChartHitTestResult<T, D>> _findAllHitsAtX(
      D targetX, Offset screenPosition) {
    final hits = <ChartHitTestResult<T, D>>[];
    for (int i = 0; i < lanes.length; i++) {
      for (final dataset in lanes[i].datasets) {
        for (int k = 0; k < dataset.data.length; k++) {
          final item = dataset.data[k];
          final pointX = dataset.getPointX(item, k);
          // Use epsilon for double/DateTime comparison if needed, or rely on == for exact matches.
          // Since hit.xValue comes from getPointX, exact match should work, but
          // let's be robust against strictly-typed D differences or potential double issues.
          bool match = false;
          if (pointX == targetX) {
            match = true;
          } else if (pointX is num && targetX is num) {
            match = (pointX - targetX).abs() < 0.0001;
          } else if (pointX is DateTime && targetX is DateTime) {
            match = pointX.isAtSameMomentAs(targetX);
          }

          if (match) {
            hits.add(ChartHitTestResult<T, D>(
              item: item,
              datasetIndex: i, // We use lane index for display coloring
              itemIndex: k,
              xValue: targetX,
              yValue: dataset.getPointY(item, k),
              screenPosition: screenPosition,
            ));
            break;
          }
        }
      }
    }
    return hits;
  }

  double _calculateMaxYLabelWidth(BuildContext context, ChartStyle style) {
    double maxWidth = 0.0;

    for (final lane in lanes) {
      final yAxisConfig = lane.yAxis ?? yAxis ?? const NumberAxis();
      if (!yAxisConfig.showing) continue;

      // We need to estimate bounds and labels.
      // For simplicity, we can look at the data range directly.
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final dataset in lane.datasets) {
        final points = dataset.data;
        if (points.isEmpty) continue;

        for (int i = 0; i < points.length; i++) {
          final y = dataset.getPointY(points[i], i);
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }

      if (minY == double.infinity) continue;

      // Adjust min/max based on axis config
      minY = yAxisConfig.minValue() ?? (minY == maxY ? 0 : minY);
      maxY = yAxisConfig.maxValue() ?? maxY;

      final range = maxY - minY;
      final step = yAxisConfig.interval ?? (range / 3.0);
      if (step <= 0) continue;

      double val = minY;
      while (val <= maxY + 0.0001) {
        final text = yAxisConfig.formatFromDouble(val);
        final tp = TextPainter(
          text: TextSpan(text: text, style: style.axisLabelStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        if (tp.width > maxWidth) maxWidth = tp.width;
        val += step;
      }
    }

    return maxWidth > 0 ? maxWidth + style.axisLabelPadding : 0;
  }
}

// Extension to help with axis visibility
extension ChartAxisCopyWith<D> on ChartAxis<D> {
  ChartAxis<D> copyWithShowing(bool showing) {
    if (this is DateTimeAxis) {
      final axis = this as DateTimeAxis;
      return DateTimeAxis(
        min: axis.min,
        max: axis.max,
        interval: axis.interval,
        showing: showing,
        formatter: axis.formatter,
      ) as ChartAxis<D>;
    } else if (this is NumberAxis) {
      final axis = this as NumberAxis;
      return NumberAxis(
        min: axis.min,
        max: axis.max,
        interval: axis.interval,
        showing: showing,
        formatter: axis.formatter,
      ) as ChartAxis<D>;
    }
    return this;
  }
}
