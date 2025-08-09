import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/filter.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class EventsView extends ConsumerWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);
    return AddIndicator(builder: (context, hasIndicator) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
          child: RefreshWidget(
            depth: RefreshDepth.authuser,
            scrollable: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: AppPadding.xl,
                      right: AppPadding.xl,
                      top: AppPadding.xl,
                      bottom: AppPadding.medium),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: PatientChanger(
                            tab: TabOption.history,
                          ),
                        ),
                        if (config.hasGraphing) ...[
                          IconButton(
                            onPressed: () {
                              context.pushNamed(RouteName.TRENDS);
                            },
                            icon: const Icon(Icons.trending_up),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                /*const SliverFloatingHeader(
                    child: SizedBox.expand(
                  child: FiltersRow(),
                )),*/
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                  sliver: SliverConstrainedCrossAxis(
                    maxExtent: Breakpoint.small.value,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        const [
                          FilterView(),
                          SizedBox(
                            height: AppPadding.small,
                          ),
                          EventsCalendar(),
                          SizedBox(
                            height: AppPadding.large,
                          ),
                          ActionRow()
                        ],
                      ),
                    ),
                  ),
                ),
                const EventGrid(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class FiltersRow extends ConsumerStatefulWidget {
  const FiltersRow({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return FiltersRowState();
  }
}

class FiltersRowState extends ConsumerState<FiltersRow> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        IconButton.filled(
            onPressed: () {
              showBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container();
                  });
            },
            icon: const Icon(Icons.filter_list))
      ],
    );
  }
}

class ActionsRow extends ConsumerStatefulWidget {
  const ActionsRow({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return ActionsRowState();
  }
}

class ActionsRowState extends ConsumerState<ActionsRow> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
