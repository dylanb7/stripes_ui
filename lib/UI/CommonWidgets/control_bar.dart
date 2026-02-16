import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class ControlBar extends ConsumerWidget {
  final List<Widget> children;

  const ControlBar({required this.children, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<LabeledFilter> activeFilters =
        ref.watch(displayDataProvider.select((value) => value.filters));
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRounding.medium),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: AppPadding.tiny,
            ),
            child: Row(children: children),
          ),
          AnimatedSize(
            duration: Durations.medium2,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: activeFilters.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.small,
                          vertical: AppPadding.tiny,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _InlineFilterChips(filters: activeFilters),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Horizontally-scrollable filter chip row used inside [ControlBar].
class _InlineFilterChips extends ConsumerWidget {
  final List<LabeledFilter> filters;
  const _InlineFilterChips({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    String getLocalizedName(LabeledFilter filter) {
      if (filter.filterType == FilterType.category) {
        return localizations?.value(filter.name) ?? filter.name;
      }
      return filter.name;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map<Widget>((filter) => FilterChip(
                  label: Text(
                    getLocalizedName(filter),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  selected: true,
                  showCheckmark: false,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.standard,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (value) {
                    ref.read(displayDataProvider.notifier).updateFilters(
                        filters.where((f) => f != filter).toList());
                  },
                  onDeleted: () {
                    ref.read(displayDataProvider.notifier).updateFilters(
                        filters.where((f) => f != filter).toList());
                  },
                ))
            .separated(by: const SizedBox(width: AppPadding.tiny))
            .toList(),
      ),
    );
  }
}
