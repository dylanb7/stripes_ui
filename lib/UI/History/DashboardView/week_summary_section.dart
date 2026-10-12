import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/DashboardView/dashboard_widgets.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/Insights/finding_widgets.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';
import 'package:go_router/go_router.dart';

class WeekSummarySection extends ConsumerWidget {
  const WeekSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsEnabled = ref.watch(configProvider).display.insightsEnabled;
    final stats = ref.watch(weekStatsProvider);
    final AsyncValue<FindingFeed>? findingFeedAsync = insightsEnabled
        ? ref.watch(dashboardFindingsProvider)
        : null;
    final FindingFeed? findingFeed = findingFeedAsync?.value;
    final bool showFindingSurface = findingFeed != null
        ? findingFeed.state != FindingFeedState.noData
        : findingFeedAsync?.hasError ?? false;
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final int daysLimit = ref.watch(
      dashboardStateProvider.select((state) => state.periodDays),
    );

    // Fetch completed check-ins scoped to the selected period range
    final AsyncValue<List<ReviewItem>> checkinsAsync = ref.watch(
      dashboardCheckinsProvider,
    );
    final List<ReviewItem> completedCheckins = checkinsAsync.when(
      data: (value) =>
          value.map((r) => localizations?.translateReview(r) ?? r).toList(),
      loading: () => const [],
      error: (_, _) => const [],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.medium),

        // Inline Stats — anchored in a card container
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.large,
            horizontal: AppPadding.medium,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRounding.medium),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _MiniStat(
                value: stats.entries.toString(),
                label: 'Entries',
                icon: Icons.edit_note,
                color: colors.primary,
              ),
              _divider(context),
              _MiniStat(
                value: '${stats.days}/$daysLimit',
                label: 'Days Active',
                icon: Icons.calendar_today,
                color: colors.primary,
                trailing: daysLimit == 7
                    ? _ActivityDots(
                        activeDates: stats.activeDates,
                        totalDays: 7,
                      )
                    : null,
              ),
            ],
          ),
        ),

        // Completed Check-ins
        if (completedCheckins.isNotEmpty) ...[
          const SizedBox(height: AppPadding.medium),
          Text(
            'Completed Check-ins',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          ...completedCheckins.map((item) => _InlineCheckin(item: item)),
        ],

        // Engine findings: evidence-backed patterns first, summaries second.
        if (showFindingSurface) ...[
          const SizedBox(height: AppPadding.medium),
          if (findingFeed != null && findingFeed.findings.isNotEmpty)
            EngineFindingsList(
              findings: findingFeed.findings,
              dataset: findingFeed.run.dataset,
              compact: true,
            )
          else
            EngineFindingsNotice(
              state: findingFeed?.state ?? FindingFeedState.unavailable,
              compact: true,
            ),
        ],
      ],
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 48,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
  );
}

class _InlineCheckin extends ConsumerWidget {
  final ReviewItem item;
  const _InlineCheckin({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final response = item.response!;
    final DateTime stampDate = dateFromStamp(response.stamp);
    final DateTimeRange range = item.path.period!.getRange(stampDate);
    final localizations = QuestionsLocalizations.of(context);
    final StripesConfig config = ref.watch(configProvider);
    final bool colored = config.betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(item.type);
    final Color accentColor = colored ? appearance.color : colors.primary;
    final String displayName =
        localizations?.value(item.path.name) ?? item.path.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: InkWell(
        onTap: () async {
          await context.pushNamed(
            'recordType',
            pathParameters: {'type': item.type},
            extra: SessionData(
              responses: {for (final r in response.responses) r.question.id: r},
              editId: response.id,
              submitTime: dateFromStamp(response.stamp),
              description: response.description,
            ),
          );
          if (context.mounted) {
            ref.invalidate(stampsStreamProvider);
          }
        },
        borderRadius: BorderRadius.circular(AppRounding.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: accentColor, size: 18),
                const SizedBox(width: AppPadding.small),
                Text(
                  displayName,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${DateFormat.MMMd().format(range.start)} - ${DateFormat.MMMd().format(range.end)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            if (response.responses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 4),
                child: Opacity(
                  opacity: 0.8,
                  child: DetailDisplay(
                    detail: response,
                    accentColor: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
        ],
      ),
    );
  }
}

class _ActivityDots extends StatelessWidget {
  final Set<DateTime> activeDates;
  final int totalDays;

  const _ActivityDots({required this.activeDates, required this.totalDays});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDays, (index) {
        // index = 0 is 6 days ago, index = 6 is today
        final date = todayMidnight.subtract(
          Duration(days: totalDays - 1 - index),
        );
        final isActive = activeDates.contains(date);

        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary
                : colors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
