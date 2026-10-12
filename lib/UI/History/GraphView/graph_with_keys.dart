import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_context_caption.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';

class GraphWithKeys extends ConsumerWidget {
  final Widget chartWidget;
  final PreparedGraph? graph;
  final Map<GraphKey, Color>? colorKeys;
  final Map<GraphKey, List<Response<Question>>> responses;
  final Map<GraphKey, String>? customLabels;

  const GraphWithKeys({
    super.key,
    required this.chartWidget,
    this.graph,
    required this.colorKeys,
    required this.responses,
    this.customLabels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If responses are empty, just show the chart (or empty state handling elsewhere)
    if (responses.isEmpty) return chartWidget;

    final settings = ref.watch(displayDataProvider);
    final dateRange = graphExportRangeLabel(context, settings.range);
    final String mainTitle = responses.keys.length <= 1
        ? (customLabels?[responses.keys.first] ??
              responses.keys.first.toLocalizedString(context))
        : (responses.keys.length == 2
              ? "Symptom Comparison"
              : "Combined Trends");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mainTitle,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          dateRange,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        Text(
          graph == null ? settings.axis.label : graphAggregationLabel(graph!),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (settings.filters.isNotEmpty)
          Text(
            'Filters: ${settings.filters.map((filter) => filter.name).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: AppPadding.small),
        chartWidget,
        const SizedBox(height: AppPadding.medium),
        Wrap(
          spacing: AppRounding.small,
          runSpacing: AppPadding.tiny,
          children: responses.keys.map((key) {
            final Color color = colorKeys?[key] ?? forGraphKey(key);
            final String label =
                customLabels?[key] ?? key.toLocalizedString(context);
            return Semantics(
              label: 'Legend: $label',
              child: Row(
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
                      label,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

String graphExportRangeLabel(BuildContext context, DateTimeRange range) {
  final dates = DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  );
  final start = range.start.toLocal();
  final end = range.end.toLocal();
  final wholeDays =
      start == DateUtils.dateOnly(start) && end == DateUtils.dateOnly(end);
  String time(DateTime value) => TimeOfDay.fromDateTime(value).format(context);
  if (!wholeDays) {
    return DateUtils.isSameDay(start, end)
        ? '${dates.format(start)} · ${time(start)} – ${time(end)}'
        : '${dates.format(start)} ${time(start)} – ${dates.format(end)} ${time(end)}';
  }
  final visibleEnd = end.isAfter(start)
      ? end.subtract(const Duration(microseconds: 1))
      : end;
  return DateUtils.isSameDay(start, visibleEnd)
      ? dates.format(start)
      : '${dates.format(start)} – ${dates.format(visibleEnd)}';
}
