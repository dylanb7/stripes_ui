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
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge!
        .copyWith(fontWeight: FontWeight.w600);
    final labels = [
      context.translate.historyListView,
      context.translate.historyGraphView,
    ];
    double textWidth(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    // Reserve the full translated label, icon, and padding before choosing a
    // layout. Enlarged text gets more room instead of shrinking or truncating.
    final widestLabel = labels
        .map((label) => textWidth(label, textStyle))
        .reduce((a, b) => a > b ? a : b);
    final switchWidth = 2 * (widestLabel + 20 + 8 + 24) + 8;
    final exportWidth =
        textWidth(
          context.translate.exportName,
          Theme.of(context).textTheme.labelLarge!,
        ) +
        20 +
        8 +
        32;

    return Padding(
      key: const ValueKey('history-presentation-controls'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.xl,
        vertical: AppPadding.small,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!hasGraphing) {
            return const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Export(showLabel: true),
            );
          }
          final vertical = switchWidth > constraints.maxWidth;
          final switcher = _HistoryPresentationSwitch(
            mode: mode,
            onChanged: onModeChanged,
            labels: labels,
            textStyle: textStyle,
            vertical: vertical,
          );
          if (switchWidth + AppPadding.small + exportWidth <=
              constraints.maxWidth) {
            return Row(
              children: [
                SizedBox(width: switchWidth, child: switcher),
                const Spacer(),
                const Export(showLabel: true),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switcher,
              const SizedBox(height: AppPadding.tiny),
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Export(showLabel: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryPresentationSwitch extends StatelessWidget {
  const _HistoryPresentationSwitch({
    required this.mode,
    required this.onChanged,
    required this.labels,
    required this.textStyle,
    required this.vertical,
  });

  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;
  final List<String> labels;
  final TextStyle textStyle;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final selectedAlignment = vertical
        ? (mode == ViewMode.events
              ? Alignment.topCenter
              : Alignment.bottomCenter)
        : (mode == ViewMode.events
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd);
    final buttons = [
      for (var index = 0; index < ViewMode.values.length; index++)
        _segment(context, ViewMode.values[index], labels[index], duration),
    ];

    return DecoratedBox(
      key: const ValueKey('history-presentation-switch'),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.07),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRounding.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.tiny),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                key: const ValueKey('history-presentation-indicator'),
                alignment: selectedAlignment,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: vertical ? 1 : 0.5,
                  heightFactor: vertical ? 0.5 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRounding.medium),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.10),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (vertical)
              IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final button in buttons) Expanded(child: button),
                  ],
                ),
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final button in buttons) Expanded(child: button),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    ViewMode view,
    String label,
    Duration duration,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = mode == view;
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;
    return Semantics(
      key: ValueKey('history-presentation-${view.name}'),
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: TextButton(
        onPressed: () => onChanged(view),
        style:
            TextButton.styleFrom(
              foregroundColor: foreground,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRounding.medium),
              ),
              textStyle: textStyle,
              animationDuration: duration,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? BorderSide(color: foreground, width: 2)
                    : BorderSide.none,
              ),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              view == ViewMode.events
                  ? Icons.view_list_rounded
                  : Icons.bar_chart_rounded,
              size: 20,
            ),
            const SizedBox(width: AppPadding.small),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
