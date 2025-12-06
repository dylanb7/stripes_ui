import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_axis.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_data.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/render_chart.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/Util/paddings.dart';

import 'package:stripes_ui/Util/palette.dart';

import 'package:stripes_ui/UI/History/GraphView/graph_tooltip.dart';

class GraphSymptom extends ConsumerStatefulWidget {
  final Map<GraphKey, List<Response>> responses;
  final bool isDetailed, forExport;

  final Map<GraphKey, Color>? colorKeys;
  final Map<GraphKey, String>? customLabels;
  const GraphSymptom({
    super.key,
    required this.responses,
    required this.isDetailed,
    this.forExport = false,
    this.colorKeys,
    this.customLabels,
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
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _closeTimer?.cancel();
    _closeTimer = null;
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    if (mounted && _selectedHit != null) {
      setState(() {
        _selectedHit = null;
      });
    }
  }

  void _showTooltip(ChartHitTestResult<GraphPoint, DateTime>? hit) {
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

        final currentHit = _selectedHit!;
        final currentKey =
            widget.responses.keys.elementAt(currentHit.datasetIndex);
        String? currentLabel;
        if (widget.responses.keys.length > 1) {
          currentLabel = widget.customLabels?[currentKey] ??
              currentKey.toLocalizedString(context);
        }

        final RenderBox? currentBox =
            _chartKey.currentContext?.findRenderObject() as RenderBox?;

        final settings = ref.read(displayDataProvider);
        final bool scatter = settings.axis == GraphYAxis.entrytime;

        double currentShiftX = 0;
        bool currentShowAbove = !scatter;

        if (currentBox != null) {
          final Offset local = currentHit.screenPosition;
          final Offset global = currentBox.localToGlobal(local);
          final mq = MediaQuery.of(context);
          final double sw = mq.size.width;
          const double tw = 200.0;
          final double le = global.dx - (tw / 2);
          final double re = global.dx + (tw / 2);

          if (le < 16) {
            currentShiftX = 16 - le;
          } else if (re > sw - 16) {
            currentShiftX = (sw - 16) - re;
          }
          if (!scatter && global.dy < mq.padding.top + 180) {
            currentShowAbove = false;
          }
        }

        return Stack(
          children: [
            Positioned(
              width: 200,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: currentHit.screenPosition,
                showWhenUnlinked: false,
                child: Transform.translate(
                  offset: Offset(currentShiftX, 0),
                  child: FractionalTranslation(
                    translation: Offset(-0.5, currentShowAbove ? -1.05 : 0.05),
                    child: GraphTooltip(
                      hit: currentHit,
                      label: currentLabel,
                      isAbove: currentShowAbove,
                      arrowOffset: -currentShiftX,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      final List<ChartSeriesData<GraphPoint, DateTime>> datasets = [];
      final int buckets = settings.getBuckets();
      final double stepSizeMs =
          settings.range.duration.inMilliseconds / buckets;
      final int startTime = settings.range.start.millisecondsSinceEpoch;

      for (final GraphKey key in widget.responses.keys) {
        final List<List<Stamp>>? bucketsData =
            bucketEvents(widget.responses[key]!, settings.range, buckets);

        if (bucketsData == null) continue;

        final Color color = widget.colorKeys?[key] ?? forGraphKey(key);
        final int currentDatasetIndex = datasets.length;

        if (settings.axis == GraphYAxis.entrytime) {
          final List<GraphPoint> points = [];
          for (int i = 0; i < bucketsData.length; i++) {
            // Group stamps by their Y value (time) to merge overlapping points
            final Map<double, List<Stamp>> grouped = {};
            for (final stamp in bucketsData[i]) {
              final date = dateFromStamp(stamp.stamp);
              final double y = date.hour + (date.minute / 60.0);
              grouped.putIfAbsent(y, () => []).add(stamp);
            }

            final x = startTime + (i * stepSizeMs) + (stepSizeMs / 2);
            for (final entry in grouped.entries) {
              final double y = entry.key;
              final List<Stamp> stamps = entry.value;
              points.add(GraphPoint(x, y, color, stamps));
            }
          }

          double spotRadius =
              min((constraints.maxWidth / buckets.toDouble() / 2) * 0.6, 6.0);

          datasets.add(ScatterChartData<GraphPoint, DateTime>(
            data: points,
            getPointX: (p, i) =>
                DateTime.fromMillisecondsSinceEpoch(p.x.toInt()),
            getPointY: (p, i) => p.y,
            getPointColor: (p, i) {
              if (_selectedHit != null &&
                  _selectedHit!.datasetIndex == currentDatasetIndex &&
                  _selectedHit!.itemIndex == i) {
                return Color.lerp(p.color, Colors.white, 0.5) ?? p.color;
              }
              return p.color;
            },
            getRadius: (_) => spotRadius,
          ));
        } else {
          final List<GraphPoint> points = [];
          for (int i = 0; i < bucketsData.length; i++) {
            final List<Stamp> bucket = bucketsData[i];
            double y = 0;
            if (settings.axis == GraphYAxis.number) {
              y = bucket.length.toDouble();
            } else {
              final numerics = bucket.whereType<NumericResponse>();
              if (numerics.isNotEmpty) {
                y = numerics.map((e) => e.response).average;
              }
            }

            final x = startTime + (i * stepSizeMs) + (stepSizeMs / 2);
            points.add(GraphPoint(x, y, color, bucket));
          }
          datasets.add(BarChartData<GraphPoint, DateTime>(
            data: points,
            getPointX: (p, i) {
              return DateTime.fromMillisecondsSinceEpoch(p.x.toInt());
            },
            getPointY: (p, i) => p.y,
            getPointColor: (p, i) {
              if (_selectedHit != null &&
                  _selectedHit!.datasetIndex == currentDatasetIndex &&
                  _selectedHit!.itemIndex == i) {
                return Color.lerp(p.color, Colors.white, 0.5) ?? p.color;
              }
              return p.color;
            },
          ));
        }
      }

      final chart = RenderChart<GraphPoint, DateTime>.multi(
        datasets: datasets,
        height: 200,
        animate: widget.isDetailed,
        onHover: widget.isDetailed ? _showTooltip : null,
        xAxis: DateTimeAxis(
          formatter: settings.getFormat(),
          min: settings.range.start,
          max: settings.range.end,
          showing: widget.isDetailed,
          interval: settings.cycle == DisplayTimeCycle.custom
              ? null
              : settings.range.duration.inMilliseconds / settings.getTitles(),
        ),
        style: ChartStyle.fromTheme(context).copyWith(
          showGridLines: widget.isDetailed,
          gridLineColor: Theme.of(context).colorScheme.outline,
          gridLineWidth: 0.5,
        ),
        yAxis: settings.axis == GraphYAxis.entrytime
            ? HourAxis(showing: widget.isDetailed, interval: 6.0)
            : NumberAxis(
                formatter: NumberFormat.compact(), showing: widget.isDetailed),
        stackBars: true,
        onTap: widget.isDetailed ? _showTooltip : null,
      );

      Widget chartWidget = AspectRatio(
          aspectRatio: 2.0,
          child: CompositedTransformTarget(
              key: _chartKey, link: _layerLink, child: chart));

      if (widget.forExport) {
        return GraphWithKeys(
          chartWidget: chartWidget,
          colorKeys: widget.colorKeys,
          responses: widget.responses,
          customLabels: widget.customLabels,
        );
      }

      return chartWidget;
    });
  }

  List<List<Stamp>>? bucketEvents(
      List<Stamp> events, DateTimeRange range, int buckets) {
    if (events.isEmpty) return null;
    List<List<Stamp>> eventLists = [];
    final double startValue = range.start.millisecondsSinceEpoch.toDouble();
    final double endValue = range.end.millisecondsSinceEpoch.toDouble();
    final double totalRange = endValue - startValue;
    final double stepSize = totalRange / buckets.toDouble();

    events.sort((first, second) => first.stamp.compareTo(second.stamp));
    int furthestReach = 0;
    for (double start = startValue; start < endValue; start += stepSize) {
      final double end = start + stepSize;
      List<Stamp> valuesInRange = [];
      while (furthestReach < events.length) {
        final Stamp current = events[furthestReach];
        if (current.stamp < start.floor() || current.stamp > end.ceil()) {
          break;
        }
        valuesInRange.add(current);
        furthestReach++;
      }
      eventLists.add(valuesInRange);
    }
    return eventLists;
  }
}

class GraphWithKeys extends ConsumerWidget {
  final Widget chartWidget;
  final Map<GraphKey, Color>? colorKeys;
  final Map<GraphKey, List<Response<Question>>> responses;
  final Map<GraphKey, String>? customLabels;

  const GraphWithKeys({
    super.key,
    required this.chartWidget,
    required this.colorKeys,
    required this.responses,
    this.customLabels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(displayDataProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Symptom Report",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: AppPadding.tiny),
      Text(
        settings.getRangeString(context),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
      const SizedBox(height: AppPadding.tiny),
      chartWidget,
      Wrap(
        spacing: AppRounding.small,
        runSpacing: AppPadding.tiny,
        children: responses.keys.map((key) {
          final Color color = colorKeys?[key] ?? forGraphKey(key);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppPadding.tiny),
              Flexible(
                child: Text(
                  customLabels?[key] ?? key.toLocalizedString(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ]);
  }
}
