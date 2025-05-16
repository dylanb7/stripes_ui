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

    Widget wrap({required Widget child}) {
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
                    depth: RefreshDepth.authuser, scrollable: child),
              ),
            );
          },
        ),
      );
    }

    return wrap(
        child: CustomScrollView(
      scrollDirection: Axis.vertical,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                    child: PatientChanger(
                  tab: TabOption.history,
                )),
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
          ),
        ),
        const SliverFloatingHeader(
          child: GraphControlArea(),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 6.0)),
        AsyncValueDefaults(
          value: graphs,
          onData: (data) {
            if (data.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No symptoms ${settings.axis == GraphYAxis.average ? "with number entries " : ""}recorded",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }
            return SliverList.separated(
              itemBuilder: (context, index) {
                final String key = data.keys.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GraphSymptomRow(
                      responses: data[key]!, title: key, settings: settings),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: data.keys.length,
            );
          },
          onError: (error) => SliverToBoxAdapter(
            child: Center(
              child: Text(
                error.error.toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          onLoading: (_) => SliverList.separated(
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 24,
                        color: Theme.of(context)
                            .disabledColor
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(
                      width: 6.0,
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 80.0,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .disabledColor
                                .withValues(alpha: 0.3),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(6.0))),
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: 5,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 40.0)),
      ],
    ));
  }
}

class GraphSymptomRow extends StatelessWidget {
  final List<Response> responses;

  final String title;

  final GraphSettings settings;

  const GraphSymptomRow(
      {required this.responses,
      required this.title,
      required this.settings,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(
          width: 6.0,
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 80.0,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.all(Radius.circular(6.0))),
            child: GraphSymptom(
                responses: [responses], settings: settings, isDetailed: false),
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_right,
          size: 32.0,
        )
      ],
    );
  }
}

class GraphControlArea extends ConsumerWidget {
  const GraphControlArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GraphSettings settings = ref.watch(graphSettingsProvider);

    Widget constrain({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoint.tiny.value,
          ),
          child: child,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 6.0,
          ),
          constrain(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(6.0),
                  ),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 8 &&
                        settings.canShift(forward: false)) {
                      ref.read(graphSettingsProvider.notifier).state =
                          settings.shift(false);
                    } else if (details.delta.dx < -8 &&
                        settings.canShift(forward: true)) {
                      ref.read(graphSettingsProvider.notifier).state =
                          settings.shift(true);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: settings.canShift(forward: false)
                            ? () {
                                ref.read(graphSettingsProvider.notifier).state =
                                    settings.shift(false);
                              }
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_left),
                      ),
                      Text(
                        settings.getRangeString(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: settings.canShift(forward: true)
                            ? () {
                                ref.read(graphSettingsProvider.notifier).state =
                                    settings.shift(true);
                              }
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 6.0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              "span",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 20,
                ),
                ...GraphSpan.values
                    .map(
                      (span) => FilterChip(
                        label: Text(span.value),
                        selected: span == settings.span,
                        onSelected: (value) {
                          if (!value) return;
                          ref.read(graphSettingsProvider.notifier).state =
                              GraphSettings.from(
                                  span: span, axis: settings.axis);
                        },
                        showCheckmark: false,
                      ),
                    )
                    .separated(
                        by: const SizedBox(
                      width: 5.0,
                    )),
              ],
            ),
          ),
          const SizedBox(
            height: 6.0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              "showing",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 20,
                ),
                ...GraphYAxis.values
                    .map(
                      (axis) => FilterChip(
                        label: Text(axis.value),
                        selected: axis == settings.axis,
                        onSelected: (value) {
                          if (!value) return;
                          ref.read(graphSettingsProvider.notifier).state =
                              settings.copyWith(axis: axis);
                        },
                        showCheckmark: false,
                      ),
                    )
                    .separated(
                        by: const SizedBox(
                      width: 5.0,
                    )),
              ],
            ),
          ),
          /*Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownMenu<GraphSpan>(
                  initialSelection: settings.span,
                  onSelected: (value) {
                    if (value == null) return;
                    ref.read(graphSettingsProvider.notifier).state =
                        GraphSettings.from(span: value, axis: settings.axis);
                  },
                  dropdownMenuEntries: GraphSpan.values
                      .map(
                        (value) =>
                            DropdownMenuEntry(value: value, label: value.value),
                      )
                      .toList()),
              DropdownMenu<GraphYAxis>(
                  initialSelection: settings.axis,
                  onSelected: (value) {
                    if (value == null) return;
                    ref.read(graphSettingsProvider.notifier).state =
                        settings.copyWith(axis: value);
                  },
                  dropdownMenuEntries: GraphYAxis.values
                      .map(
                        (value) =>
                            DropdownMenuEntry(value: value, label: value.value),
                      )
                      .toList()),
            ],
          ),*/
        ],
      ),
    );
  }
}
