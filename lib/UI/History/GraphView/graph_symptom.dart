import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_with_keys.dart';
import 'package:stripes_ui/Util/Design/palette.dart';

/// Adapts history responses to the prepared chart boundary.
///
/// Response bucketing lives in [GraphPreparer] and rendering lives in
/// [HistoryChart], keeping this widget deliberately free of chart policy.
class GraphSymptom extends ConsumerWidget {
  final Map<GraphKey, List<Response>> responses;
  final bool isDetailed;
  final bool forExport;
  final GraphComparison mode;
  final Map<GraphKey, Color>? colorKeys;
  final Map<GraphKey, String>? customLabels;
  final GraphSelectionController? selectionController;
  final Map<String, RecordPath>? reviewPaths;
  final double? height;

  const GraphSymptom({
    super.key,
    required this.responses,
    required this.isDetailed,
    this.forExport = false,
    this.mode = GraphComparison.separate,
    this.colorKeys,
    this.customLabels,
    this.selectionController,
    this.reviewPaths,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final PreparedGraph graph = GraphPreparer.prepare(
      responses: responses,
      settings: settings,
      comparison: mode,
      colorResolver: forGraphKey,
      colorOverrides: colorKeys,
      labelOverrides: customLabels,
      labelResolver: (GraphKey key) => key.toLocalizedString(context),
      reviewPaths: reviewPaths,
    );
    final Widget chart = HistoryChart(
      graph: graph,
      selectionController: selectionController,
      appearance: isDetailed || forExport
          ? HistoryChartAppearance.detailed
          : HistoryChartAppearance.compact,
      height: height,
    );

    if (!forExport) return chart;
    return GraphWithKeys(
      chartWidget: chart,
      graph: graph,
      colorKeys: colorKeys,
      responses: responses,
      customLabels: customLabels,
    );
  }
}
