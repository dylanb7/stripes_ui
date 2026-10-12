import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_layout.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_painter.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart_scene.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

export 'history_chart_layout.dart' show HistoryChartAppearance;

class HistoryChart extends StatefulWidget {
  final PreparedGraph graph;
  final GraphSelectionController? selectionController;
  final HistoryChartAppearance appearance;
  final double? height;

  const HistoryChart({
    super.key,
    required this.graph,
    this.selectionController,
    this.appearance = HistoryChartAppearance.detailed,
    this.height,
  });

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  GraphSelectionController? _ownedSelectionController;

  GraphSelectionController get _selectionController =>
      widget.selectionController ??
      (_ownedSelectionController ??= GraphSelectionController());

  @override
  void didUpdateWidget(covariant HistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      final GraphSelectionController controller = _selectionController;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(controller, _selectionController)) {
          controller.clear();
        }
      });
    }
  }

  @override
  void dispose() {
    _ownedSelectionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final AppLocalizations? strings = AppLocalizations.of(context);
    String formatHour(double hour) {
      final int minutes = (hour * 60).round();
      return MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
    }

    final HistoryChartVisualStyle style = HistoryChartVisualStyle.fromTheme(
      theme,
      locale: locale,
      hourLabelFormatter: formatHour,
      dayPartLabelFormatter: strings == null
          ? null
          : (part) => part.label(strings),
      semanticLabelFormatter: (item) =>
          _semanticLabel(item, context, locale, strings, formatHour),
    );
    return LayoutBuilder(
      builder: (context, viewport) {
        final width = viewport.hasBoundedWidth
            ? viewport.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double effectiveHeight =
            widget.height ??
            const HistoryChartLayoutEngine().preferredHeight(
              graph: widget.graph,
              width: width,
              appearance: widget.appearance,
              style: style,
              textDirection: textDirection,
              textScaler: textScaler,
            );
        if (widget.graph.isEmpty) {
          return SizedBox(
            height: effectiveHeight,
            child: Center(
              child: Text(
                'No data in this period',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: effectiveHeight,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final double height = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : effectiveHeight;
              final Size size = Size(math.max(1, width), math.max(1, height));
              final HistoryChartScene scene = const HistoryChartLayoutEngine()
                  .layout(
                    graph: widget.graph,
                    size: size,
                    appearance: widget.appearance,
                    style: style,
                    textDirection: textDirection,
                    textScaler: textScaler,
                  );

              final Widget baseChart = CustomPaint(
                painter: HistoryChartPainter(
                  scene: scene,
                  style: style,
                  appearance: widget.appearance,
                  textDirection: textDirection,
                  textScaler: textScaler,
                ),
                isComplex: true,
              );

              if (widget.appearance == HistoryChartAppearance.compact) {
                // Overview charts live inside tappable rows/cards. They are visual
                // summaries, so they must not compete with the parent gesture or
                // announce dozens of individual values before the row itself.
                return ExcludeSemantics(
                  child: RepaintBoundary(child: baseChart),
                );
              }

              return RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    baseChart,
                    MouseRegion(
                      cursor: SystemMouseCursors.precise,
                      onHover: (PointerHoverEvent event) {
                        if (_selectionController.value.pinned) return;
                        _updateSelection(
                          scene,
                          event.localPosition,
                          pinned: false,
                        );
                      },
                      onExit: (_) =>
                          _selectionController.clear(preservePinned: true),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (TapDownDetails details) => _updateSelection(
                          scene,
                          details.localPosition,
                          pinned: true,
                        ),
                        onHorizontalDragStart: (DragStartDetails details) =>
                            _updateSelection(
                              scene,
                              details.localPosition,
                              pinned: true,
                              horizontalOnly: true,
                            ),
                        onHorizontalDragUpdate: (DragUpdateDetails details) =>
                            _updateSelection(
                              scene,
                              details.localPosition,
                              pinned: true,
                              horizontalOnly: true,
                            ),
                        child: ValueListenableBuilder<GraphSelectionState>(
                          valueListenable: _selectionController,
                          builder:
                              (
                                BuildContext context,
                                GraphSelectionState selection,
                                Widget? child,
                              ) {
                                return CustomPaint(
                                  painter: HistoryChartSelectionPainter(
                                    scene: scene,
                                    selection: selection,
                                    style: style,
                                  ),
                                  willChange: true,
                                );
                              },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _updateSelection(
    HistoryChartScene scene,
    Offset position, {
    required bool pinned,
    bool horizontalOnly = false,
  }) {
    final List<GraphSelectionItem> items = horizontalOnly
        ? scene.scrubTest(position.dx)
        : scene.hitTest(position);
    if (items.isEmpty) {
      if (pinned) {
        _selectionController.clear();
      } else {
        _selectionController.clear(preservePinned: true);
      }
      return;
    }
    _selectionController.select(
      bin: items.first.datum.bin,
      items: items,
      pinned: pinned,
    );
  }
}

String _semanticLabel(
  GraphSelectionItem item,
  BuildContext context,
  String locale,
  AppLocalizations? strings,
  String Function(double) formatHour,
) {
  final PreparedDatum datum = item.datum;
  final bool aggregated =
      item.series.mark == GraphMark.bar || item.series.mark == GraphMark.line;
  final DateTime start =
      (aggregated ? datum.bin?.start ?? datum.xStart : datum.xStart).toLocal();
  final DateTime end = (aggregated ? datum.bin?.end ?? datum.xEnd : datum.xEnd)
      .toLocal();
  final DateFormat dateFormat = DateFormat.yMMMd(locale);
  final DateTime lastDate = end.isAfter(start)
      ? end.subtract(const Duration(microseconds: 1))
      : start;
  final List<String> pieces = [
    item.series.label,
    DateUtils.isSameDay(start, lastDate)
        ? dateFormat.format(start)
        : '${dateFormat.format(start)} – ${dateFormat.format(lastDate)}',
  ];
  final double? value = datum.value;
  switch (datum.timing) {
    case GraphTiming.unknown:
      pieces.add(strings?.recordTimeUnknown ?? 'Time unknown');
    case GraphTiming.dayPart:
      final RecordTime? recordTime = datum.evidence
          .whereType<Response>()
          .map(recordTimeForResponse)
          .whereType<RecordTime>()
          .firstOrNull;
      if (recordTime != null && strings != null) {
        pieces.add(recordTime.label(context, includeRange: true));
      } else if (value != null && datum.valueEnd != null) {
        pieces.add('${formatHour(value)} – ${formatHour(datum.valueEnd!)}');
      } else {
        pieces.add(
          '${formatHour(datum.xStart.hour + datum.xStart.minute / 60)} – '
          '${formatHour(datum.xEnd.hour + datum.xEnd.minute / 60)}',
        );
      }
    case GraphTiming.reviewPeriod:
      pieces.add(strings?.checkInLabel ?? 'Check-in');
    case GraphTiming.exact:
      if (value != null) {
        pieces.add(
          item.series.unit == 'time'
              ? formatHour(value)
              : item.series.unit == 'reports'
              ? strings?.entriesCount(value.round()) ??
                    '${value.round()} reports'
              : '${NumberFormat.decimalPattern(locale).format(value)} ${item.series.unit ?? ''}'
                    .trim(),
        );
      }
  }
  if (datum.summary.reportCount > 0 &&
      (item.series.unit != 'reports' || datum.timing != GraphTiming.exact)) {
    pieces.add(
      strings?.entriesCount(datum.summary.reportCount) ??
          '${datum.summary.reportCount} reports',
    );
  }
  return pieces.join(', ');
}
