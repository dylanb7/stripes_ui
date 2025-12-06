import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/sheet_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
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
            ),

            /*const SliverFloatingHeader(
                    child: SizedBox.expand(
                  child: FiltersRow(),
                )),*/
            SliverPadding(
              padding:
                  const EdgeInsetsGeometry.symmetric(horizontal: AppPadding.xl),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: Breakpoint.medium.value,
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      IconButton.filled(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          ref.read(sheetControllerProvider).show(
                                context: context,
                                scrollControlled: true,
                                child: (context) => const FilterSheet(),
                              );
                        },
                        icon: const Icon(Icons.filter_list),
                      ),
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      const EventsCalendar(),
                      const SizedBox(
                        height: AppPadding.large,
                      ),
                      const ActionRow()
                    ],
                  ),
                ),
              ),
            ),
            SliverConstrainedCrossAxis(
              maxExtent: Breakpoint.medium.value,
              sliver: const EventGrid(),
            ),
          ],
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
