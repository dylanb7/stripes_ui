import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/History/DashboardView/action_items_section.dart';
import 'package:stripes_ui/UI/History/DashboardView/dashboard_widgets.dart';
import 'package:stripes_ui/UI/History/DashboardView/recent_section.dart';
import 'package:stripes_ui/UI/History/DashboardView/today_section.dart';
import 'package:stripes_ui/UI/History/DashboardView/week_summary_section.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';

export 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart'
    show dashboardFindingsProvider;

// Re-export providers so existing consumers (tab_view.dart, etc.) aren't broken.
export 'package:stripes_ui/UI/History/DashboardView/dashboard_widgets.dart'
    show
        streakProvider,
        weekStatsProvider,
        weekResponsesProvider,
        WeekStats,
        weekRangeProvider,
        weekInsightsProvider,
        dashboardCheckinsProvider;

class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    return AddIndicator(
      builder: (context, hasIndicator) => Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshWidget(
          depth: RefreshDepth.authuser,
          scrollable: SizedBox.expand(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ─── Header: Patient + Streak ───
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppPadding.medium,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: AppPadding.xl),
                            FadeInSlide(
                              duration: Duration(milliseconds: 600),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: PatientChanger()),
                                  //GlobalStreakBadge()
                                  SizedBox(width: AppPadding.medium),
                                ],
                              ),
                            ),
                            SizedBox(height: AppPadding.medium),
                          ],
                        ),
                      ),
                    ),

                    if (ref.watch(configProvider).betaUi.multiSessionFlow)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppPadding.medium,
                            0,
                            AppPadding.medium,
                            AppPadding.medium,
                          ),
                          child: FilledButton.icon(
                            key: const ValueKey('dashboard-multi-record'),
                            onPressed: () =>
                                context.pushNamed(RouteName.MULTI_RECORD),
                            icon: const Icon(Icons.add),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(context.translate.recordStart),
                            ),
                          ),
                        ),
                      ),

                    // ─── Action Items (tests, check-ins) ───
                    const SliverToBoxAdapter(
                      child: FadeInSlide(
                        delay: Duration(milliseconds: 100),
                        child: OngoingTasksSection(),
                      ),
                    ),

                    // ─── TODAY sticky header group ───
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: DashboardSectionHeaderDelegate(
                            child: _SectionHeaderBar(
                              title: 'Today',
                              subtitle: DateFormat.MMMEd().format(now),
                            ),
                            height: 64.0,
                          ),
                        ),

                        // Today activity chips + expand
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                            ),
                            child: FadeInSlide(
                              delay: Duration(milliseconds: 200),
                              child: TodayActivitySection(),
                            ),
                          ),
                        ),

                        // Recent entries
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                            ),
                            child: FadeInSlide(
                              delay: Duration(milliseconds: 300),
                              child: Padding(
                                padding: EdgeInsets.only(top: AppPadding.large),
                                child: RecentEntriesSection(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ─── Visual divider between sections ───
                    const SliverToBoxAdapter(
                      child: Divider(
                        height: AppPadding.xl,
                        thickness: 2.0,
                        indent: AppPadding.xl,
                        endIndent: AppPadding.xl,
                      ),
                    ),

                    // ─── WEEK sticky header group ───
                    const SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: DashboardSectionHeaderDelegate(
                            child: _PeriodDropdownHeader(),
                            height: 64.0,
                          ),
                        ),

                        // Week stats + insights + completed check-ins
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                            ),
                            child: FadeInSlide(
                              delay: Duration(milliseconds: 400),
                              child: WeekSummarySection(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ─── Bottom padding ───
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height:
                            FloatingNavBarScope.bottomPaddingOf(context) +
                            (hasIndicator ? AppPadding.xxxl : AppPadding.large),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sticky section header bar — rendered by DashboardSectionHeaderDelegate
// =============================================================================

class _SectionHeaderBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeaderBar({
    this.title,
    this.titleWidget,
    required this.subtitle,
    this.trailing,
  }) : assert(title != null || titleWidget != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child:
                        titleWidget ??
                        Text(
                          title ?? '',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppPadding.small),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Dropdown period header — selecting dashboard timeframe with navigation chevrons
// =============================================================================

class _PeriodDropdownHeader extends ConsumerWidget {
  const _PeriodDropdownHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final days = dashboardState.periodDays;
    final range = ref.watch(weekRangeProvider);
    final colors = Theme.of(context).colorScheme;
    final offset = dashboardState.offset;
    final label = offset == 0
        ? (days == 7 ? 'Last 7 Days' : 'Last $days Days')
        : offset == -1
        ? 'Previous $days Days'
        : '${days * offset.abs()}–${days * (offset.abs() + 1)} Days Ago';
    final subtitle =
        '${DateFormat.MMMd().format(range.start)} – ${DateFormat.MMMd().format(range.end)}';

    final bool canPrev = offset > -10;
    final bool canNext = offset < 0;
    final bool isCurrent = offset == 0;

    return _SectionHeaderBar(
      titleWidget: PopupMenuButton<int>(
        tooltip: 'Select timeframe',
        onSelected: (val) {
          ref.read(dashboardStateProvider.notifier).setPeriodDays(val);
        },
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 40),
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            value: 7,
            child: Text(
              '7 Days',
              style: TextStyle(
                fontWeight: days == 7 ? FontWeight.bold : FontWeight.normal,
                color: days == 7 ? colors.primary : colors.onSurface,
              ),
            ),
          ),
          PopupMenuItem<int>(
            value: 30,
            child: Text(
              '30 Days',
              style: TextStyle(
                fontWeight: days == 30 ? FontWeight.bold : FontWeight.normal,
                color: days == 30 ? colors.primary : colors.onSurface,
              ),
            ),
          ),
          PopupMenuItem<int>(
            value: 60,
            child: Text(
              '60 Days',
              style: TextStyle(
                fontWeight: days == 60 ? FontWeight.bold : FontWeight.normal,
                color: days == 60 ? colors.primary : colors.onSurface,
              ),
            ),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.primary,
              size: 24,
            ),
          ],
        ),
      ),
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavChevron(
            icon: Icons.chevron_left,
            enabled: canPrev,
            onTap: () => ref
                .read(dashboardStateProvider.notifier)
                .shiftPeriod(forward: false),
          ),
          const SizedBox(width: 4),
          _NavChevron(
            icon: Icons.chevron_right,
            enabled: canNext,
            visible: !isCurrent,
            onTap: () => ref
                .read(dashboardStateProvider.notifier)
                .shiftPeriod(forward: true),
          ),
        ],
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool visible;
  final VoidCallback onTap;

  const _NavChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible && enabled ? 1.0 : 0.3,
      child: IgnorePointer(
        ignoring: !enabled || !visible,
        child: IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
