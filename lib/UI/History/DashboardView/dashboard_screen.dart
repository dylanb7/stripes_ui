import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_data_provider.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_stats.dart';
import 'package:stripes_ui/Providers/Dashboard/insight_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_range_selector.dart';
import 'package:stripes_ui/UI/History/Insights/insight_widgets.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DashboardStat> stats = ref.watch(dashboardStatsProvider);

    final List<Insight> insights = ref.watch(dashboardInsightsProvider);

    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.small, horizontal: AppPadding.medium),
      children: [
        const _TimeRangeHeader(),
        const SizedBox(height: AppPadding.medium),
        _StatsRow(stats: stats, colors: colors),
        const SizedBox(height: AppPadding.medium),
        const _SectionTitle(title: 'Activity'),
        const SizedBox(height: AppPadding.small),
        const _ActivityHeatmap(),
        const SizedBox(height: AppPadding.large),
        if (insights.isNotEmpty) ...[
          InsightsList(
            insights: insights,
          ),
          const SizedBox(
            height: AppPadding.xl,
          )
        ]
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _TimeRangeHeader extends ConsumerWidget {
  const _TimeRangeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardState state = ref.watch(dashboardStateProvider);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              TimeCycle.week,
              TimeCycle.month,
              TimeCycle.quarter,
              TimeCycle.year,
              TimeCycle.all
            ].map((cycle) {
              final isSelected = state.cycle == cycle;
              return Padding(
                padding: const EdgeInsets.only(right: AppPadding.small),
                child: ChoiceChip(
                  label: Text(cycle.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(dashboardStateProvider.notifier).setCycle(cycle);
                    }
                  },
                  showCheckmark: false,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppPadding.tiny),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRounding.small),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: DateRangeSelector(
            rangeText: state.getRangeString(),
            canGoPrev: state.canGoPrev,
            canGoNext: state.canGoNext,
            onPrev: () =>
                ref.read(dashboardStateProvider.notifier).shift(forward: false),
            onNext: () =>
                ref.read(dashboardStateProvider.notifier).shift(forward: true),
            onTap: () async {
              ref.read(sheetControllerProvider).show(
                  scrollControlled: true,
                  context: context,
                  sheetBuilder: (context, controller) {
                    return BottomSheetCalendar(
                      initialRange: state.range,
                      ignoreFilters: true,
                      onRangeSelected: (range) {
                        ref
                            .read(dashboardStateProvider.notifier)
                            .setRange(range);
                      },
                    );
                  });
            },
            getPreviewText: (forward) {
              return ref
                  .read(dashboardStateProvider.notifier)
                  .getPreviewString(forward: forward);
            },
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<DashboardStat> stats;
  final ColorScheme colors;

  const _StatsRow({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.map((stat) {
        final index = stats.indexOf(stat);
        final color = stat.color ?? _getDefaultColor(index, colors);
        return Expanded(
          child: _StatTile(stat: stat, color: color),
        );
      }).toList(),
    );
  }

  Color _getDefaultColor(int index, ColorScheme colors) {
    if (index == 3) {
      return Colors.amber.shade900; // Best/Max stat - darker for visibility
    }
    return colors.primary;
  }
}

class _StatTile extends StatelessWidget {
  final DashboardStat stat;
  final Color color;

  const _StatTile({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Parse numeric value for animation
    final numericValue =
        double.tryParse(stat.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppPadding.small),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(stat.icon, color: color, size: 28),
        ),
        const SizedBox(height: AppPadding.tiny),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: numericValue),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            // Format based on original value format
            String displayValue;
            if (stat.value.contains('.')) {
              displayValue = value.toStringAsFixed(1);
            } else {
              displayValue = value.round().toString();
            }
            return Text(
              displayValue,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            );
          },
        ),
        Text(
          stat.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ActivityHeatmap extends ConsumerStatefulWidget {
  const _ActivityHeatmap();

  @override
  ConsumerState<_ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<_ActivityHeatmap> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Map<DateTime, int> dailyCounts =
        ref.watch(dashboardDailyCountsProvider);
    final DashboardState state = ref.read(dashboardStateProvider);

    final int daysDiff =
        state.range.end.difference(state.range.start).inDays + 1;
    final int weeksToShow = (daysDiff / 7).ceil().clamp(1, 53);
    final bool isCompact = weeksToShow <= 2;

    final int maxCount = dailyCounts.values.fold(0, (a, b) => a > b ? a : b);

    final DateFormat dateFormat = DateFormat.E();
    final List<String> dayLabels = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i);
      return dateFormat.format(date)[0];
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRounding.small),
          ),
          padding: const EdgeInsets.all(AppPadding.small),
          child: isCompact
              ? CompactActivityLayout(dayLabels: dayLabels)
              : StandardActivityLayout(
                  dayLabels: dayLabels,
                  weeksToShow: weeksToShow,
                  maxCount: maxCount,
                ),
        ),
        const SizedBox(height: AppPadding.small),
        if (state.cycle != TimeCycle.week)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('0', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final intensity = i / 4;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: intensity == 0
                        ? colors.surfaceContainerHighest
                        : colors.primary
                            .withValues(alpha: 0.2 + intensity * 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(maxCount.toString(),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class StandardActivityLayout extends ConsumerWidget {
  final List<String> dayLabels;
  final int weeksToShow, maxCount;
  const StandardActivityLayout(
      {super.key,
      required this.dayLabels,
      required this.weeksToShow,
      required this.maxCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardState state = ref.read(dashboardStateProvider);
    final Map<DateTime, int> dailyCounts =
        ref.watch(dashboardDailyCountsProvider);
    final DateTime today = DateTime(
        state.range.end.year, state.range.end.month, state.range.end.day);
    final DateFormat monthFormat = DateFormat.MMM();
    final ColorScheme colors = Theme.of(context).colorScheme;

    const double cellSize = 16.0;
    const double cellSpacing = 2.0;
    final double gridWidth = weeksToShow * (cellSize + cellSpacing);

    final List<(int weekIndex, String monthName)> monthMarkers = [];
    String? lastMonth;

    for (int weekIndex = 0; weekIndex < weeksToShow; weekIndex++) {
      final daysBack = (weeksToShow - 1 - weekIndex) * 7;
      final weekStart = today.subtract(Duration(days: daysBack));
      final checkDate = weekStart.add(const Duration(days: 0));

      final monthName = monthFormat.format(checkDate);
      if (monthName != lastMonth) {
        monthMarkers.add((weekIndex, monthName));
        lastMonth = monthName;
      }
    }

    if (monthMarkers.length >= 2) {
      if (monthMarkers[1].$1 - monthMarkers[0].$1 < 3) {
        monthMarkers.removeAt(0);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            ...List.generate(7, (i) {
              final bool show = i % 2 == 0;
              return SizedBox(
                height: cellSize + cellSpacing,
                child: Center(
                  child: Text(
                    show ? dayLabels[i] : '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 16,
                    child: Stack(
                      children: monthMarkers.map((marker) {
                        return Positioned(
                          left: marker.$1 * (cellSize + cellSpacing),
                          child: Text(
                            marker.$2,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  ...List.generate(7, (dayIndex) {
                    return Row(
                      children: List.generate(weeksToShow, (weekIndex) {
                        final daysBack =
                            (weeksToShow - 1 - weekIndex) * 7 + (6 - dayIndex);
                        final cellDate =
                            today.subtract(Duration(days: daysBack));

                        if (cellDate.isBefore(state.range.start)) {
                          return const SizedBox(
                            width: cellSize + cellSpacing,
                            height: cellSize + cellSpacing,
                          );
                        }

                        final count = dailyCounts[cellDate] ?? 0;
                        final intensity = maxCount > 0 ? count / maxCount : 0.0;

                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(cellSpacing / 2),
                          decoration: BoxDecoration(
                            color: count == 0
                                ? colors.surfaceContainerHighest
                                : colors.primary
                                    .withValues(alpha: 0.2 + intensity * 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CompactActivityLayout extends ConsumerWidget {
  final List<String> dayLabels;
  const CompactActivityLayout({super.key, required this.dayLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardState state = ref.read(dashboardStateProvider);
    final Map<DateTime, int> dailyCounts =
        ref.watch(dashboardDailyCountsProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int maxCount = dailyCounts.values.fold(0, (a, b) => a > b ? a : b);
    final int startWeekday = state.range.start.weekday;
    final DateTime viewStart =
        state.range.start.subtract(Duration(days: startWeekday - 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (d) {
        final cellDate = viewStart.add(Duration(days: d));
        final count = dailyCounts[cellDate] ?? 0;
        final widthFactor = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Text(
                  dayLabels[d],
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor > 0 ? widthFactor : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: count > 0 ? colors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 20,
                child: Text(
                  count > 0 ? count.toString() : '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
