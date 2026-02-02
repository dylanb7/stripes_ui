import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/shared_axis_chart.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_data_processor.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_with_keys.dart';

import 'package:stripes_ui/Util/Design/palette.dart';

import 'package:stripes_ui/UI/History/GraphView/graph_tooltip.dart';

enum GraphOverviewMode { stacked, shared, overlayed }

class GraphSymptom extends ConsumerStatefulWidget {
  final Map<GraphKey, List<Response>> responses;
  final bool isDetailed, forExport;
  final GraphOverviewMode mode;

  final Map<GraphKey, Color>? colorKeys;
  final Map<GraphKey, String>? customLabels;
  final ChartSelectionController<GraphPoint, DateTime>? selectionController;

  /// Map of category/type names to RecordPaths for resolving review periods
  final Map<String, RecordPath>? reviewPaths;
  final double? height;

  const GraphSymptom({
    super.key,
    required this.responses,
    required this.isDetailed,
    this.forExport = false,
    this.mode = GraphOverviewMode.stacked,
    this.colorKeys,
    this.customLabels,
    this.selectionController,
    this.reviewPaths,
    this.height,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _GraphSymptomState();
  }
}

class _GraphSymptomState extends ConsumerState<GraphSymptom> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _chartKey = GlobalKey();
  ChartHitTestResult<GraphPoint, DateTime>? _selectedHit;
  OverlayEntry? _tooltipEntry;
  Timer? _closeTimer;

  @override
  void dispose() {
    _removeTooltip(disposing: true);
    super.dispose();
  }

  /// Returns the base reference height based on the current display mode.
  /// Lanes mode uses less height per lane; stacked/overlay uses more for single chart.
  double _getRefHeight() {
    switch (widget.mode) {
      case GraphOverviewMode.shared:
        return 70.0; // Per-lane height (more compact)
      case GraphOverviewMode.stacked:
      case GraphOverviewMode.overlayed:
        return 120.0; // Single combined chart (more space)
    }
  }

  /// Returns the appropriate Y-axis based on display settings.
  /// Uses HourAxis for entry time view, NumberAxis otherwise.
  ChartAxis<num> _getYAxis({
    required DisplayDataSettings settings,
    required double laneMaxY,
    required bool showing,
  }) {
    if (settings.axis == GraphYAxis.entrytime) {
      return HourAxis(min: 0, max: 24, showing: showing);
    }
    return NumberAxis(
      max: laneMaxY,
      showing: showing,
      formatter: NumberFormat.compact(),
    );
  }

  void _removeTooltip({bool disposing = false}) {
    _closeTimer?.cancel();
    _closeTimer = null;
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    if (!disposing && mounted && _selectedHit != null) {
      setState(() {
        _selectedHit = null;
      });
    }
  }

  void _showTooltip(ChartHitTestResult<GraphPoint, DateTime>? hit) {
    if (widget.forExport) return;
    if (hit == null) {
      _removeTooltip();
      return;
    }

    if (_selectedHit != hit) {
      setState(() {
        _selectedHit = hit;
      });
    }

    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(seconds: 3), _removeTooltip);

    if (_tooltipEntry != null) {
      _tooltipEntry!.markNeedsBuild();
      return;
    }

    final entry = OverlayEntry(
      builder: (context) {
        if (_selectedHit == null) return const SizedBox.shrink();
        final RenderBox? currentBox =
            _chartKey.currentContext?.findRenderObject() as RenderBox?;
        final currentKey =
            widget.responses.keys.elementAt(_selectedHit!.datasetIndex);
        String? currentLabel;
        if (widget.responses.keys.length > 1) {
          currentLabel = widget.customLabels?[currentKey] ??
              currentKey.toLocalizedString(context);
        }

        return TooltipOverlay(
          selectedHit: _selectedHit!,
          layerLink: _layerLink,
          chartRenderBox: currentBox,
          label: currentLabel,
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(entry);
    _tooltipEntry = entry;
  }

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final datasets = GraphDataProcessor.processData(
        responses: widget.responses,
        settings: settings,
        mode: widget.mode,
        colorResolver: forGraphKey,
        constraints: constraints,
        colorKeys: widget.colorKeys,
        reviewPaths: widget.reviewPaths,
      );

      final highlightedDatasets = <ChartSeriesData<GraphPoint, DateTime>>[];

      for (int i = 0; i < datasets.length; i++) {
        final dataset = datasets[i];
        final currentDatasetIndex = i;

        final originalColorGetter = dataset.getPointColor;
        Color selectionColorGetter(GraphPoint p, int index) {
          if (_selectedHit != null &&
              _selectedHit!.datasetIndex == currentDatasetIndex &&
              _selectedHit!.itemIndex == index) {
            return Color.lerp(p.color, Colors.white, 0.5) ?? p.color;
          }
          return originalColorGetter(p, index);
        }

        // We need to clone the dataset with the new color getter.
        // Since ChartSeriesData subclasses don't have a copyWith, we check type.
        switch (dataset) {
          case BarChartData<GraphPoint, DateTime>(
              data: final data,
              getPointX: final getPointX,
              getPointY: final getPointY
            ):
            highlightedDatasets.add(BarChartData(
              data: data,
              getPointX: getPointX,
              getPointY: getPointY,
              getPointColor: selectionColorGetter,
            ));
            break;
          case LineChartData<GraphPoint, DateTime>(
              data: final data,
              getPointX: final getPointX,
              getPointY: final getPointY
            ):
            highlightedDatasets.add(LineChartData(
              data: data,
              getPointX: getPointX,
              getPointY: getPointY,
              getPointColor: selectionColorGetter,
            ));
            break;
          case ScatterChartData<GraphPoint, DateTime>(
              data: final data,
              getPointX: final getPointX,
              getPointY: final getPointY,
              getRadius: final getRadius
            ):
            highlightedDatasets.add(ScatterChartData(
              data: data,
              getPointX: getPointX,
              getPointY: getPointY,
              getPointColor: selectionColorGetter,
              getRadius: getRadius,
            ));
            break;
          case RangeChartData<GraphPoint, DateTime>(
              data: final data,
              getPointX: final getPointX,
              getPointXEnd: final getPointXEnd,
              getPointY: final getPointY
            ):
            highlightedDatasets.add(RangeChartData(
              data: data,
              getPointX: getPointX,
              getPointXEnd: getPointXEnd,
              getPointY: getPointY,
              getPointColor: selectionColorGetter,
            ));
            break;
        }
      }

      final double globalMax = highlightedDatasets
          .map((d) => d.data.isEmpty ? 0.0 : d.data.map((p) => p.y).reduce(max))
          .fold(0.0, max)
          .ceilToDouble()
          .clamp(1.0, double.infinity);

      const double topOverhead = 8.0;
      const double xAxisOverhead = 24.0;
      // Mode-specific base heights for better readability
      final double refHeight = widget.height ?? _getRefHeight();
      final double refDrawHeight = refHeight - topOverhead;

      final double ppuSqrt = refDrawHeight / sqrt(globalMax);

      final lanes = <ChartLane<GraphPoint, DateTime>>[];
      final List<ChartSeriesData<GraphPoint, DateTime>> overlaySymptoms = [];
      final List<GraphKey> overlayKeys = [];

      int datasetIdx = 0;
      for (final key in widget.responses.keys) {
        if (datasetIdx >= highlightedDatasets.length) break;
        final dataset = highlightedDatasets[datasetIdx];
        final bool isReview = dataset is RangeChartData;

        if (widget.mode == GraphOverviewMode.shared || isReview) {
          final label =
              widget.customLabels?[key] ?? key.toLocalizedString(context);
          final color = widget.colorKeys?[key] ?? forGraphKey(key);
          final laneMax = dataset.data.isEmpty
              ? 0.0
              : dataset.data.map((p) => p.y).reduce(max);
          final laneMaxY = laneMax.ceilToDouble().clamp(1.0, double.infinity);
          final drawHeight = sqrt(laneMaxY) * ppuSqrt;

          lanes.add(ChartLane.single(
            data: dataset,
            label: label,
            labelColor: color,
            // Only set explicit height for detailed view; compact uses laneHeight
            height: widget.isDetailed
                ? (isReview ? 40.0 : max(50.0, drawHeight + topOverhead + 10.0))
                : null,
            hideYAxis: isReview,
            yAxis: _getYAxis(
              settings: settings,
              laneMaxY: laneMaxY,
              showing: !isReview && widget.isDetailed,
            ),
          ));
        } else {
          overlaySymptoms.add(dataset);
          overlayKeys.add(key);
        }
        datasetIdx++;
      }

      if (overlaySymptoms.isNotEmpty) {
        final double laneMax = overlaySymptoms
            .map((d) =>
                d.data.isEmpty ? 0.0 : d.data.map((p) => p.y).reduce(max))
            .fold(0.0, max);
        final double laneMaxY =
            laneMax.ceilToDouble().clamp(1.0, double.infinity);
        final double drawHeight = sqrt(laneMaxY) * ppuSqrt;

        lanes.add(ChartLane(
          datasets: overlaySymptoms,
          label: overlayKeys.length > 2
              ? "Combined Trends"
              : (overlayKeys.length == 2
                  ? "Symptom Comparison"
                  : overlayKeys.first.toLocalizedString(context)),
          // Only set explicit height for detailed view; compact uses laneHeight
          height: widget.isDetailed
              ? max(50.0, drawHeight + topOverhead + 10.0)
              : null,
          stackBars: widget.mode == GraphOverviewMode.stacked,
          yAxis: _getYAxis(
            settings: settings,
            laneMaxY: laneMaxY,
            showing: widget.isDetailed,
          ),
        ));
      }

      // Adjust lane heights for the last lane to include xAxisOverhead
      if (lanes.isNotEmpty && widget.isDetailed) {
        final lastLane = lanes.last;
        lanes[lanes.length - 1] = ChartLane(
          datasets: lastLane.datasets,
          label: lastLane.label,
          labelColor: lastLane.labelColor,
          height: (lastLane.height ?? 0) + xAxisOverhead,
          yAxis: lastLane.yAxis,
          hideYAxis: lastLane.hideYAxis,
          stackBars: lastLane.stackBars,
        );
      }

      const double compactHeight = 80.0;
      final chartWidget = SharedAxisChart<GraphPoint, DateTime>(
        lanes: lanes,
        showLaneLabels: false,
        xAxis: DateTimeAxis(
          formatter: settings.getFormat(),
          min: settings.range.start,
          max: settings.range.end,
        ),
        // Unified behavior: both tap and hover update selection
        // null hit clears selection (tap outside or pan away)
        onHover:
            widget.isDetailed ? (laneIndex, hit) => _showTooltip(hit) : null,
        onTap: widget.isDetailed ? (laneIndex, hit) => _showTooltip(hit) : null,
        selectionController: widget.selectionController,
        compact: !widget.isDetailed,
        laneHeight: widget.isDetailed ? 100 : compactHeight,
      );
      if (widget.forExport) {
        return GraphWithKeys(
          chartWidget: chartWidget,
          colorKeys: widget.colorKeys,
          responses: widget.responses,
          customLabels: widget.customLabels,
        );
      }
      // For non-detailed views, lanes use laneHeight directly
      // ClipRect prevents overflow during Hero animation transition
      if (!widget.isDetailed) {
        return SizedBox(
          height: compactHeight,
          width: constraints.maxWidth,
          child: ClipRect(child: chartWidget),
        );
      }
      // Detailed view
      return chartWidget;
    });
  }
}

class TooltipOverlay extends ConsumerWidget {
  final ChartHitTestResult<GraphPoint, DateTime> selectedHit;

  final LayerLink layerLink;

  final RenderBox? chartRenderBox;

  final String? label;

  const TooltipOverlay(
      {super.key,
      required this.selectedHit,
      required this.layerLink,
      required this.chartRenderBox,
      required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(displayDataProvider);
    final bool scatter = settings.axis == GraphYAxis.entrytime;

    double currentShiftX = 0;
    bool currentShowAbove = !scatter;

    if (chartRenderBox != null) {
      final Offset local = selectedHit.screenPosition;
      final Offset global = chartRenderBox!.localToGlobal(local);

      final Size size = MediaQuery.sizeOf(context);
      final EdgeInsets insets = MediaQuery.paddingOf(context);
      final double sw = size.width;
      const double tw = 200.0;
      final double le = global.dx - (tw / 2);
      final double re = global.dx + (tw / 2);

      if (le < 16) {
        currentShiftX = 16 - le;
      } else if (re > sw - 16) {
        currentShiftX = (sw - 16) - re;
      }
      if (!scatter && global.dy < insets.top + 180) {
        currentShowAbove = false;
      }
    }

    return Stack(
      children: [
        Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: layerLink,
            offset: selectedHit.screenPosition,
            showWhenUnlinked: false,
            child: Transform.translate(
              offset: Offset(currentShiftX, 0),
              child: FractionalTranslation(
                translation: Offset(-0.5, currentShowAbove ? -1.05 : 0.05),
                child: GraphTooltip(
                  hit: selectedHit,
                  label: label,
                  isAbove: currentShowAbove,
                  arrowOffset: -currentShiftX,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
