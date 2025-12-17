import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Providers/contribution_data_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/contribution_graph.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Dashboard screen showing entry activity visualizations.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<DateTime, int>> contributionData =
        ref.watch(contributionDataProvider);
    final AsyncValue<DashboardStats> statsData =
        ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: contributionData.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards Row
              statsData.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _StatsRow(stats: stats),
              ),
              const SizedBox(height: AppPadding.xl),

              // Contribution Graph Section
              const _SectionHeader(
                title: 'Activity',
                subtitle: 'Your entry history',
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: ContributionGraph(
                    data: data,
                    onDateTapped: (date, count) {
                      _showDateDetails(context, date, count);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.xl),

              // Weekly Activity Chart
              const _SectionHeader(
                title: 'Weekly Pattern',
                subtitle: 'Entries by day of week',
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: _WeeklyActivityChart(data: data),
                ),
              ),
              const SizedBox(height: AppPadding.xl),

              // Time of Day Distribution
              const _SectionHeader(
                title: 'Time Distribution',
                subtitle: 'When you log entries',
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: _TimeDistributionChart(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateDetails(BuildContext context, DateTime date, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${DateFormat.yMMMd().format(date)}: $count entries'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(
            icon: Icons.note_alt_outlined,
            label: 'This Month',
            value: stats.totalEntriesThisMonth.toString(),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppPadding.medium),
          _StatCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Current Streak',
            value: '${stats.currentStreak} days',
            color: Colors.orange,
          ),
          const SizedBox(width: AppPadding.medium),
          _StatCard(
            icon: Icons.emoji_events_outlined,
            label: 'Best Streak',
            value: '${stats.bestStreakThisMonth} days',
            color: Colors.amber,
          ),
          const SizedBox(width: AppPadding.medium),
          _StatCard(
            icon: Icons.calendar_today_outlined,
            label: 'This Week',
            value: stats.entriesThisWeek.toString(),
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: AppPadding.medium),
          _StatCard(
            icon: Icons.trending_up,
            label: 'Avg/Day',
            value: stats.averagePerDay.toStringAsFixed(1),
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.large,
          vertical: AppPadding.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppPadding.small),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final Map<DateTime, int> data;

  const _WeeklyActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Aggregate by day of week
    final Map<int, int> byDayOfWeek = {
      for (var i = 1; i <= 7; i++) i: 0,
    };

    for (final entry in data.entries) {
      final int weekday = entry.key.weekday;
      byDayOfWeek[weekday] = byDayOfWeek[weekday]! + entry.value;
    }

    final int maxValue = byDayOfWeek.values.reduce((a, b) => a > b ? a : b);
    final double effectiveMax = maxValue > 0 ? maxValue.toDouble() : 1.0;

    final List<String> dayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final int weekday = index + 1;
          final int count = byDayOfWeek[weekday]!;
          final double heightPercent = count / effectiveMax;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.tiny),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightPercent.clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3 + (heightPercent * 0.7)),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    dayNames[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TimeDistributionChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a placeholder - would need actual timestamp data
    // For now, show a simple message
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          'Coming soon: Time of day distribution',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
