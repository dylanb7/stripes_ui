import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/Dashboard/insight_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Insights/insight_widgets.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';

class EventsView extends ConsumerWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);

    return AddIndicator(builder: (context, hasIndicator) {
      return RefreshWidget(
        depth: RefreshDepth.authuser,
        scrollable: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                  left: AppPadding.xl,
                  right: AppPadding.xl,
                  top: AppPadding.xl,
                  bottom: AppPadding.medium),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: Breakpoint.medium.value,
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: PatientChanger(
                          tab: TabOption.history,
                        ),
                      ),
                      _ControlsRow(hasGraphing: config.hasGraphing),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsetsGeometry.symmetric(horizontal: AppPadding.xl),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: Breakpoint.medium.value,
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const CurrentFilters(),
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      const EventsCalendar(),
                      const SizedBox(
                        height: AppPadding.large,
                      ),
                      const _HistoryInsights(),
                      const ActionRow()
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsetsGeometry.symmetric(horizontal: AppPadding.xl),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: Breakpoint.large.value,
                sliver: const EventGrid(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Compact controls row with graph toggle and filter button
class _ControlsRow extends ConsumerWidget {
  final bool hasGraphing;

  const _ControlsRow({required this.hasGraphing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int filterCount = ref.watch(
        displayDataProvider.select((settings) => settings.filters.length));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasGraphing) ...[
          IconButton.filled(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              context.pushNamed(RouteName.TRENDS);
            },
            icon: const Icon(Icons.trending_up),
          ),
          const SizedBox(width: AppPadding.small),
        ],
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text(filterCount.toString()),
          child: IconButton.filled(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              ref.read(sheetControllerProvider).show(
                    context: context,
                    scrollControlled: true,
                    sheetBuilder: (context, controller) =>
                        FilterSheet(scrollController: controller),
                  );
            },
            icon: const Icon(Icons.filter_list),
          ),
        ),
      ],
    );
  }
}

/// Compact insights section for the history tab - constrained width
class _HistoryInsights extends ConsumerWidget {
  const _HistoryInsights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Insight> insights = ref.watch(historyInsightsProvider);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.medium),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: InsightsList(insights: insights),
      ),
    );
  }
}
