import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// Keeps the selected scope visible without turning the header into a chip wall.
/// Whole labels earn their place; the editor represents anything that won't fit.
class HistoryActiveFilters extends ConsumerWidget {
  const HistoryActiveFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(
      configProvider.select((config) => config.betaUi.historyOverview),
    )) {
      return const SizedBox.shrink();
    }
    final filters = ref.watch(
      displayDataProvider.select((settings) => settings.filters),
    );
    if (filters.isEmpty) return const SizedBox.shrink();

    final localizations = QuestionsLocalizations.of(context);
    final labels = [
      for (final filter in filters)
        filter.filterType == FilterType.category
            ? localizations?.value(filter.name) ?? filter.name
            : '${filter.filterType.name}: ${filter.filterType == FilterType.numericRange ? filter.name.split('|').first : filter.name}',
    ];
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge!;
    final textScaler = MediaQuery.textScalerOf(context);

    double textWidth(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    String countLabel(int visibleCount) => visibleCount == 0
        ? context.translate.historyActiveFilterCount(filters.length)
        : context.translate.historyMoreFilterCount(
            filters.length - visibleCount,
          );

    void editFilters() {
      ref
          .read(sheetControllerProvider)
          .show(
            context: context,
            scrollControlled: true,
            sheetBuilder: (context, controller) =>
                FilterSheet(scrollController: controller),
          );
    }

    return Padding(
      key: const ValueKey('history-active-filters'),
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Match the explicit padding, close icon, and gap used below. A
          // minimum 48px target makes the whole chip easy to dismiss by thumb.
          final widths = [for (final label in labels) textWidth(label) + 56];
          var visibleCount = 0;
          for (
            var candidate = math.min(2, filters.length);
            candidate > 0;
            candidate--
          ) {
            final hasMore = candidate < filters.length;
            final chipsWidth = widths
                .take(candidate)
                .fold(0.0, (a, b) => a + b);
            final moreWidth = hasMore
                ? textWidth(countLabel(candidate)) + 24
                : 0;
            final gaps = AppPadding.small * (candidate - 1 + (hasMore ? 1 : 0));
            if (chipsWidth + moreWidth + gaps <= constraints.maxWidth) {
              visibleCount = candidate;
              break;
            }
          }

          final children = <Widget>[
            for (var index = 0; index < visibleCount; index++)
              SizedBox(
                width: widths[index],
                child: Tooltip(
                  message: context.translate.historyRemoveFilter(labels[index]),
                  excludeFromSemantics: true,
                  child: TextButton(
                    key: ValueKey('history-remove-filter-$index'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: style,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      final current = ref.read(displayDataProvider).filters;
                      ref
                          .read(displayDataProvider.notifier)
                          .updateFilters(
                            current
                                .where((filter) => filter != filters[index])
                                .toList(),
                          );
                    },
                    child: Semantics(
                      label: context.translate.historyRemoveFilter(
                        labels[index],
                      ),
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(labels[index]),
                          const SizedBox(width: 8),
                          const Icon(Icons.close, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (visibleCount < filters.length)
              TextButton(
                key: const ValueKey('history-more-filters'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: style,
                ),
                onPressed: editFilters,
                child: Semantics(
                  label:
                      '${countLabel(visibleCount)}: ${labels.skip(visibleCount).join(', ')}',
                  excludeSemantics: true,
                  child: Text(countLabel(visibleCount)),
                ),
              ),
          ];

          // The count can wrap at extreme text scales without clipping or a
          // horizontal scrolling trap. At normal sizes this stays a single row.
          return Wrap(spacing: AppPadding.small, children: children);
        },
      ),
    );
  }
}
