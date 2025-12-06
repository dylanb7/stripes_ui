import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/export.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/UI/History/UnifiedView/bottom_sheet_calendar.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/Providers/sheet_provider.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class EventsView extends ConsumerWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ViewMode mode = ref.watch(viewModeProvider);
    final StripesConfig config = ref.watch(configProvider);
    return AddIndicator(builder: (context, hasIndicator) {
      return RefreshWidget(
        depth: RefreshDepth.authuser,
        scrollable: CustomScrollView(
            controller: ref.watch(historyScrollControllerProvider),
            slivers: [
              SliverCrossAxisGroup(
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
                          children: [
                            const Expanded(
                              child: PatientChanger(
                                tab: TabOption.history,
                              ),
                            ),
                            const SizedBox(
                              width: AppPadding.tiny,
                            ),
                            if (config.hasGraphing)
                              IconButton.outlined(
                                  onPressed: () {
                                    ref.read(viewModeProvider.notifier).state =
                                        mode == ViewMode.graph
                                            ? ViewMode.events
                                            : ViewMode.graph;
                                  },
                                  icon: mode == ViewMode.graph
                                      ? const Icon(Icons.list)
                                      : const Icon(Icons.bar_chart))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              /*const SliverFloatingHeader(
                    child: SizedBox.expand(
                  child: FiltersRow(),
                )),*/

              const SliverPadding(
                padding: EdgeInsetsGeometry.only(
                    left: AppPadding.large,
                    right: AppPadding.large,
                    bottom: AppPadding.tiny),
                sliver: SliverToBoxAdapter(
                  child: FiltersRow(),
                ),
              ),
              const SliverToBoxAdapter(
                child: CurrentFilters(),
              ),
              SliverFloatingHeader(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface),
                  child: const Column(
                    children: [
                      DateRangeButton(),
                      Divider(
                        height: 1.0,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: AppPadding.tiny),
                sliver: SliverToBoxAdapter(
                  child: mode == ViewMode.events
                      ? const EventGridHeader()
                      : const GraphHeader(),
                ),
              ),
              mode == ViewMode.events
                  ? SliverCrossAxisGroup(
                      slivers: [
                        SliverConstrainedCrossAxis(
                          maxExtent: Breakpoint.medium.value,
                          sliver: const EventGrid(),
                        ),
                      ],
                    )
                  : GraphSliverList(onSelect: (key) {
                      context.pushNamed(RouteName.SYMPTOMTREND, extra: key);
                    }),
            ]),
      );
    });
  }
}

class EventGridHeader extends ConsumerWidget {
  const EventGridHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> eventsCount = ref.watch(availableStampsProvider
        .select((stamps) => stamps.whenData((data) => data.length)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AsyncValueDefaults(
            value: eventsCount,
            onData: (value) => Text(
              "$value Results",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
            onError: (error) => const SizedBox.shrink(),
            onLoading: (_) => const SizedBox.shrink(),
          ),
          const Export(),
        ],
      ),
    );
  }
}

class GraphHeader extends ConsumerWidget {
  const GraphHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.xl, vertical: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Name",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            child: DropdownButtonFormField<GraphYAxis>(
              decoration: const InputDecoration(
                  labelText: "Y Axis",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
              initialValue: settings.axis,
              onChanged: (value) {
                if (value == null) return;
                ref.read(displayDataProvider.notifier).setAxis(value);
              },
              items: GraphYAxis.values
                  .map((axis) => DropdownMenuItem(
                        value: axis,
                        child: Text(axis.value),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class FiltersRow extends ConsumerWidget {
  const FiltersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SegmentedButton<DisplayTimeCycle>(
            segments: [
              DisplayTimeCycle.day,
              DisplayTimeCycle.week,
              DisplayTimeCycle.month,
            ]
                .map(
                  (cycle) => ButtonSegment(
                    value: cycle,
                    label: Text(cycle.value),
                  ),
                )
                .toList(),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (newValue) {
              ref.read(displayDataProvider.notifier).setCycle(newValue.first);
            },
            selected: {settings.cycle}),
        const Spacer(),
        IconButton.filled(
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
      ],
    );
  }
}

class DateRangeButton extends ConsumerStatefulWidget {
  const DateRangeButton({super.key});

  @override
  ConsumerState<DateRangeButton> createState() => _DateRangeButtonState();
}

class _DateRangeButtonState extends ConsumerState<DateRangeButton> {
  double _dragOffset = 0.0;
  String? _previewText;
  static const double _threshold = 80.0;

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final bool hasPreview = _previewText != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.comfortable,
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: !settings.canGoPrev
              ? null
              : () {
                  ref.read(displayDataProvider.notifier).shift(forward: false);
                },
        ),
        const SizedBox(
          width: AppPadding.tiny,
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dx;
                final bool forward = _dragOffset < 0;
                if (forward && !settings.canGoNext) {
                  _dragOffset = 0;
                  return;
                }
                if (!forward && !settings.canGoPrev) {
                  _dragOffset = 0;
                  return;
                }

                if (_dragOffset.abs() > _threshold) {
                  final nextRange = ref
                      .read(displayDataProvider.notifier)
                      .getNextRangeString(forward: forward, context: context);
                  _previewText = nextRange;
                } else {
                  _previewText = null;
                }
              });
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffset.abs() > _threshold) {
                ref
                    .read(displayDataProvider.notifier)
                    .shift(forward: _dragOffset < 0);
              } else if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 1000) {
                // Fast swipe support
                final bool forward = details.primaryVelocity! < 0;
                if ((forward && settings.canGoNext) ||
                    (!forward && settings.canGoPrev)) {
                  ref
                      .read(displayDataProvider.notifier)
                      .shift(forward: forward);
                }
              }
              setState(() {
                _dragOffset = 0;
                _previewText = null;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragOffset = 0;
                _previewText = null;
              });
            },
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Opacity(
                opacity: 1.0 -
                    (_dragOffset.abs() / (_threshold * 2)).clamp(0.0, 0.5),
                child: InkWell(
                  onTap: () {
                    ref.read(sheetControllerProvider).show(
                        context: context,
                        scrollControlled: true,
                        child: (context) => const BottomSheetCalendar());
                  },
                  borderRadius: BorderRadius.circular(AppRounding.small),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.tiny),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: Durations.short3,
                          child: Text(
                            _previewText ?? settings.getRangeString(context),
                            key: ValueKey(_previewText ?? settings.range),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: hasPreview
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: hasPreview
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppPadding.tiny),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: hasPreview
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: AppPadding.tiny,
        ),
        IconButton(
          visualDensity: VisualDensity.comfortable,
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          icon: const Icon(Icons.keyboard_arrow_right),
          onPressed: !settings.canGoNext
              ? null
              : () {
                  ref.read(displayDataProvider.notifier).shift(forward: true);
                },
        ),
      ],
    );
  }
}
