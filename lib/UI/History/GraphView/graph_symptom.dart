import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';

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
  final bool showTooltip;

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
    this.showTooltip = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _GraphSymptomState();
  }
}

class _GraphSymptomState extends ConsumerState<GraphSymptom> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _chartKey = GlobalKey();
  List<ChartHitTestResult<GraphPoint, DateTime>>? _selectedHits;
  OverlayEntry? _tooltipEntry;
  Timer? _closeTimer;

  @override
  void dispose() {
    _removeTooltip(disposing: true);
    super.dispose();
  }

  double _getRefHeight() {
    switch (widget.mode) {
      case GraphOverviewMode.shared:
        return 70.0;
      case GraphOverviewMode.stacked:
      case GraphOverviewMode.overlayed:
        return 120.0;
    }
  }

  ChartAxis<num> _getYAxis({
    required DisplayDataSettings settings,
    required double laneMaxY,
    required bool showing,
    double? min,
  }) {
    if (settings.axis == GraphYAxis.entrytime) {
      return HourAxis(min: 0, max: 24, showing: showing);
    }
    return NumberAxis(
      min: min,
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
    if (!disposing && mounted && _selectedHits != null) {
      setState(() {
        _selectedHits = null;
      });
      widget.selectionController?.clear();
    }
  }

  void _showTooltip(ChartHitTestResult<GraphPoint, DateTime>? hit) {
    if (widget.forExport) return;
    if (hit == null) {
      _removeTooltip();
      return;
    }

    List<ChartHitTestResult<GraphPoint, DateTime>> hits = [hit];
    if (widget.selectionController != null &&
        widget.selectionController!.value.results.isNotEmpty) {
      if (widget.selectionController!.value.results == hits) {
      } else {
        hits = widget.selectionController!.value.results;
      }
    }

    if (!const ListEquality().equals(_selectedHits, hits)) {
      setState(() {
        _selectedHits = hits;
      });
    }

    if (!widget.showTooltip) return;

    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(seconds: 2), _removeTooltip);

    if (_tooltipEntry != null) {
      _tooltipEntry!.markNeedsBuild();
      return;
    }

    final entry = OverlayEntry(
      builder: (context) {
        if (_selectedHits == null || _selectedHits!.isEmpty) {
          return const SizedBox.shrink();
        }

        final RenderBox? currentBox =
            _chartKey.currentContext?.findRenderObject() as RenderBox?;

        // Resolve labels for all hits
        final Map<int, String> labels = {};
        for (final h in _selectedHits!) {
          if (h.datasetIndex < widget.responses.keys.length) {
            final key = widget.responses.keys.elementAt(h.datasetIndex);
            labels[h.datasetIndex] =
                widget.customLabels?[key] ?? key.toLocalizedString(context);
          }
        }

        return TooltipOverlay(
          selectedHits: _selectedHits!,
          layerLink: _layerLink,
          chartRenderBox: currentBox,
          labels: labels,
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
      final bool effectiveIsDetailed = widget.isDetailed &&
          (constraints.maxHeight > 220 || !constraints.maxHeight.isFinite);

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
          final selection = widget.selectionController?.value.results;
          if (selection != null &&
              selection.any((hit) =>
                  hit.datasetIndex == currentDatasetIndex &&
                  hit.itemIndex == index)) {
            return Color.lerp(p.color, Colors.white, 0.5) ?? p.color;
          }
          if (_selectedHits != null &&
              _selectedHits!.any((hit) =>
                  hit.datasetIndex == currentDatasetIndex &&
                  hit.itemIndex == index)) {
            return Color.lerp(p.color, Colors.white, 0.5) ?? p.color;
          }
          return originalColorGetter(p, index);
        }

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

      final List<double> laneMaxes = highlightedDatasets.map((d) {
        double maxVal = 0.0;
        if (d.data.isNotEmpty) {
          maxVal = d.data.map((p) => p.y).reduce(max).ceilToDouble();
        }
        if (settings.axis == GraphYAxis.average) {
          // Attempt to find the question max
          for (final point in d.data) {
            if (point.data.isNotEmpty) {
              final first = point.data.first;
              if (first is Response && first.question is Numeric) {
                final q = first.question as Numeric;
                if (q.max != null) {
                  maxVal = max(maxVal, q.max!.toDouble());
                }
                break;
              }
            }
          }
        }
        return maxVal;
      }).toList();

      final nonZeroMaxes = laneMaxes.where((m) => m > 0);
      final double avgMax = nonZeroMaxes.isEmpty
          ? 1.0
          : nonZeroMaxes.reduce((a, b) => a + b) / nonZeroMaxes.length;

      const double topOverhead = 8.0;
      const double xAxisOverhead = 24.0;
      final double refHeight = widget.height ?? _getRefHeight();
      final double refDrawHeight = refHeight - topOverhead;

      final double globalPPU = refDrawHeight / max(avgMax, 1.0);

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
          final laneMax = laneMaxes[datasetIdx];
          final laneMaxY = laneMax.clamp(1.0, double.infinity);

          final double proportionalHeight = laneMaxY * globalPPU;

          const double minDrawHeight = 50.0;
          final double targetDrawHeight =
              max(minDrawHeight, proportionalHeight);

          final double visibleAxisMax = targetDrawHeight / globalPPU;

          lanes.add(ChartLane.single(
            data: dataset,
            label: label,
            labelColor: color,
            height: effectiveIsDetailed
                ? (isReview ? 40.0 : targetDrawHeight + topOverhead + 10.0)
                : null,
            hideYAxis: isReview,
            yAxisLabel: effectiveIsDetailed ? settings.axis.label : null,
            yAxis: _getYAxis(
              settings: settings,
              laneMaxY: visibleAxisMax,
              showing: !isReview && effectiveIsDetailed,
              min: (() {
                if (settings.axis == GraphYAxis.average) {
                  for (final point in dataset.data) {
                    if (point.data.isNotEmpty) {
                      final first = point.data.first;
                      if (first is Response && first.question is Numeric) {
                        return (first.question as Numeric).min?.toDouble();
                      }
                    }
                  }
                }
                return null;
              })(),
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

        final double proportionalHeight = laneMaxY * globalPPU;
        final double targetDrawHeight = max(50.0, proportionalHeight);
        final double visibleAxisMax = targetDrawHeight / globalPPU;

        lanes.add(ChartLane(
          datasets: overlaySymptoms,
          label: overlayKeys.length > 2
              ? "Combined Trends"
              : (overlayKeys.length == 2
                  ? "Symptom Comparison"
                  : overlayKeys.first.toLocalizedString(context)),
          yAxisLabel: effectiveIsDetailed ? settings.axis.label : null,
          height: effectiveIsDetailed
              ? targetDrawHeight + topOverhead + 10.0
              : null,
          stackBars: widget.mode == GraphOverviewMode.stacked,
          yAxis: _getYAxis(
            settings: settings,
            laneMaxY: visibleAxisMax,
            showing: effectiveIsDetailed,
            min: (() {
              // For overlay/stacked, we might have multiple questions.
              // Taking min of the first valid one or maybe min of all?
              // Assuming consistent scale for overlay of same type, or just using first.
              if (settings.axis == GraphYAxis.average &&
                  overlaySymptoms.isNotEmpty) {
                for (final point in overlaySymptoms.first.data) {
                  if (point.data.isNotEmpty) {
                    final first = point.data.first;
                    if (first is Response && first.question is Numeric) {
                      return (first.question as Numeric).min?.toDouble();
                    }
                  }
                }
              }
              return null;
            })(),
          ),
        ));
      }

      if (lanes.isNotEmpty && effectiveIsDetailed) {
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
      // For non-detailed views, calculate effective height early so the chart
      // can use the actual available height from the parent container
      final double effectiveCompactHeight =
          !effectiveIsDetailed && constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : compactHeight;

      final chartWidget = SharedAxisChart<GraphPoint, DateTime>(
        lanes: lanes,
        showLaneLabels: false,
        xAxis: DateTimeAxis(
          formatter: settings.getFormat(),
          min: settings.range.start,
          max: settings.range.end,
          interval: settings.getLabelInterval(),
        ),
        onHover:
            effectiveIsDetailed ? (laneIndex, hit) => _showTooltip(hit) : null,
        onTap:
            effectiveIsDetailed ? (laneIndex, hit) => _showTooltip(hit) : null,
        selectionController: widget.selectionController,
        compact: !effectiveIsDetailed,
        laneHeight: effectiveIsDetailed ? 100 : effectiveCompactHeight,
        showSelectionLabels: false,
        yAxisLabel: effectiveIsDetailed ? settings.axis.label : null,
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
      if (!effectiveIsDetailed) {
        return SizedBox(
          height: effectiveCompactHeight,
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
  final List<ChartHitTestResult<GraphPoint, DateTime>> selectedHits;

  final LayerLink layerLink;

  final RenderBox? chartRenderBox;

  final Map<int, String> labels;

  const TooltipOverlay(
      {super.key,
      required this.selectedHits,
      required this.layerLink,
      required this.chartRenderBox,
      required this.labels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedHits.isEmpty) return const SizedBox.shrink();

    final primaryHit = selectedHits.first;

    final settings = ref.read(displayDataProvider);
    final bool scatter = settings.axis == GraphYAxis.entrytime;

    double currentShiftX = 0;
    bool currentShowAbove = !scatter;

    if (chartRenderBox != null) {
      final Offset local = primaryHit.screenPosition;
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
            offset: primaryHit.screenPosition,
            showWhenUnlinked: false,
            child: Transform.translate(
              offset: Offset(currentShiftX, 0),
              child: FractionalTranslation(
                translation: Offset(-0.5, currentShowAbove ? -1.05 : 0.05),
                child: GraphTooltip(
                  hits: selectedHits,
                  labels: labels,
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
