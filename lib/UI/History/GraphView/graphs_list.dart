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
        SliverToBoxAdapter(
          child: Row(
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
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 6.0)),
        const SliverFloatingHeader(
          child: GraphControlArea(),
        ),
        AsyncValueDefaults(
          value: graphs,
          onData: (data) {
            return SliverList.separated(
              itemBuilder: (context, index) {
                final String key = data.keys.elementAt(index);
                return GraphSymptomRow(
                    responses: data[key]!, title: key, settings: settings);
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: data.keys.length,
            );
          },
          onError: (error) => SliverToBoxAdapter(
            child: Text(
              error.error.toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
          onLoading: (_) => SliverList.separated(
            itemBuilder: (context, index) {
              return Row(
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
                    width: 4.0,
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
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: 5,
          ),
        ),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(
          width: 4.0,
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
      ],
    );
  }
}

class GraphControlArea extends ConsumerWidget {
  const GraphControlArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GraphSettings settings = ref.watch(graphSettingsProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  ref.read(graphSettingsProvider.notifier).state =
                      settings.shift(false);
                },
                icon: const Icon(Icons.keyboard_arrow_left),
              ),
              Text(
                settings.getRangeString(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () {
                  ref.read(graphSettingsProvider.notifier).state =
                      settings.shift(true);
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
          ),
        ],
      ),
    );
  }
}
