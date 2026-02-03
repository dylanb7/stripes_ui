import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/palette.dart';

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
    // If responses are empty, just show the chart (or empty state handling elsewhere)
    if (responses.isEmpty) return chartWidget;

    final settings = ref.watch(displayDataProvider);
    final String mainTitle = responses.keys.length <= 1
        ? responses.keys.first.toLocalizedString(context)
        : (responses.keys.length == 2
            ? "Symptom Comparison"
            : "Combined Trends");

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        mainTitle,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      Text(
        settings.getRangeString(context),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
      const SizedBox(height: AppPadding.small),
      chartWidget,
      const SizedBox(height: AppPadding.medium),
      Wrap(
        spacing: AppRounding.small,
        runSpacing: AppPadding.tiny,
        children: responses.keys.map((key) {
          // Use custom color if set, otherwise use the default color from palette
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ]);
  }
}
