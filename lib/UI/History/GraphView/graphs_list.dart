import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/graph_packets.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';

class GraphsList extends ConsumerWidget {
  const GraphsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GraphSettings settings = ref.watch(graphSettingsProvider);

    final AsyncValue<Map<String, List<Response>>> graphs =
        ref.watch(graphStampsProvider);
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);
    return PageWrap(
        actions: [
          if (!isSmall)
            ...TabOption.values.map((tab) => LargeNavButton(
                  tab: tab,
                  selected: TabOption.history,
                )),
          const SizedBox(
            width: 8.0,
          ),
          const UserProfileButton()
        ],
        bottomNav: isSmall
            ? const SmallLayout(
                selected: TabOption.history,
              )
            : null,
        child: AddIndicator(
          builder: (context, hasIndicator) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: RefreshWidget(
                  depth: RefreshDepth.authuser,
                  scrollable: AsyncValueDefaults(
                    value: graphs,
                    onData: (data) {
                      return ListView(
                          padding: const EdgeInsets.only(
                              top: 20, left: 20, right: 20),
                          children: [
                            Row(
                              children: [
                                const Expanded(child: PatientChanger()),
                                const SizedBox(
                                  width: 4.0,
                                ),
                                IconButton(
                                    onPressed: () {
                                      context.pushNamed(Routes.HISTORY);
                                    },
                                    icon: const Icon(Icons.calendar_month))
                              ],
                            ),
                            const SizedBox(
                              height: 6.0,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    ref
                                        .read(graphSettingsProvider.notifier)
                                        .state = settings.shift(false);
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_left),
                                ),
                                Text(
                                  settings.getRangeString(context),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ref
                                        .read(graphSettingsProvider.notifier)
                                        .state = settings.shift(true);
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_right),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DropdownMenu<GraphSpan>(
                                    initialSelection: settings.span,
                                    onSelected: (value) {
                                      if (value == null) return;
                                      ref
                                              .read(graphSettingsProvider.notifier)
                                              .state =
                                          GraphSettings.from(
                                              span: value, axis: settings.axis);
                                    },
                                    dropdownMenuEntries: GraphSpan.values
                                        .map(
                                          (value) => DropdownMenuEntry(
                                              value: value, label: value.value),
                                        )
                                        .toList()),
                                DropdownMenu<GraphYAxis>(
                                    initialSelection: settings.axis,
                                    onSelected: (value) {
                                      if (value == null) return;
                                      ref
                                          .read(graphSettingsProvider.notifier)
                                          .state = settings.copyWith(axis: value);
                                    },
                                    dropdownMenuEntries: GraphYAxis.values
                                        .map(
                                          (value) => DropdownMenuEntry(
                                              value: value, label: value.value),
                                        )
                                        .toList()),
                              ],
                            ),
                            const SizedBox(
                              height: 6.0,
                            ),
                            ...data.keys
                                .map(
                                  (title) => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(title),
                                      ),
                                      Container(
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(6.0))),
                                        child: GraphSymptom(
                                            responses: [data[title]!],
                                            settings: settings,
                                            isDetailed: false),
                                      ),
                                    ],
                                  ),
                                )
                                .separated(by: const Divider()),
                          ]);
                    },
                    onLoading: (_) => ListView(
                      children: List.generate(
                        5,
                        (_) => Container(
                          color: Theme.of(context).disabledColor,
                        ),
                      ).separated(
                          by: const SizedBox(
                        height: 5.0,
                      )),
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }
}
