import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/History/Export/export.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// Describes the selected recordings, independently of their presentation.
class HistoryPeriodSummary extends ConsumerWidget {
  const HistoryPeriodSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(availableStampsProvider).asData?.value;
    final reviews = ref.watch(reviewPaths(const ReviewPathsProps()));
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();

    final localizations = QuestionsLocalizations.of(context);
    final categories = <String, int>{};
    final days = <DateTime>{};
    for (final entry in entries) {
      categories.update(entry.type, (count) => count + 1, ifAbsent: () => 1);
      days.add(DateUtils.dateOnly(occurrenceTimeForResponse(entry)));
    }
    // A check-in describes a period, not an observation on its submission day.
    // Only describe day coverage when all records have event-day semantics.
    final reviewTypes = {
      for (final review in reviews.asData?.value ?? [])
        if (review.path.period != null) review.type,
    };
    final showDays =
        reviews.hasValue &&
        !entries.any((entry) => reviewTypes.contains(entry.type));
    final entryCount = context.translate.historyEntryCount(entries.length);
    final heading = showDays
        ? context.translate.historySummaryDays(entryCount, days.length)
        : entryCount;
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) {
        final countOrder = b.value.compareTo(a.value);
        return countOrder != 0 ? countOrder : a.key.compareTo(b.key);
      });
    final categorySummary = [
      for (final category in sortedCategories.take(3))
        '${localizations?.value(category.key) ?? category.key} ${category.value}',
      if (sortedCategories.length > 3)
        context.translate.historyMoreCategories(sortedCategories.length - 3),
    ].join(' · ');
    final theme = Theme.of(context);

    return Padding(
      key: const ValueKey('history-period-summary'),
      padding: const EdgeInsets.fromLTRB(
        AppPadding.xl,
        AppPadding.medium,
        AppPadding.xl,
        AppPadding.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppPadding.tiny),
          Text(
            categorySummary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation and export act on the collection established above them.
class HistoryPresentationControls extends StatelessWidget {
  final bool hasGraphing;
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  const HistoryPresentationControls({
    required this.hasGraphing,
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('history-presentation-controls'),
    padding: const EdgeInsets.symmetric(
      horizontal: AppPadding.xl,
      vertical: AppPadding.small,
    ),
    child: Wrap(
      spacing: AppPadding.small,
      runSpacing: AppPadding.tiny,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasGraphing)
          for (final view in ViewMode.values)
            ChoiceChip(
              avatar: Icon(
                view == ViewMode.events ? Icons.list : Icons.bar_chart,
                size: 20,
              ),
              label: Text(
                view == ViewMode.events
                    ? context.translate.historyListView
                    : context.translate.historyGraphView,
              ),
              selected: mode == view,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onModeChanged(view),
            ),
        const Export(showLabel: true),
      ],
    ),
  );
}
