import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/Dashboard/insight_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Insights/insight_widgets.dart';
import 'package:stripes_ui/Util/Helpers/date_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/control_bar.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_range_selector.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/Export/export.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';

class EventsView extends ConsumerStatefulWidget {
  const EventsView({super.key});

  @override
  ConsumerState<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends ConsumerState<EventsView> {
  final GlobalKey _dateRangeKey = GlobalKey();
  bool _showBottomBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ScrollController controller =
          ref.read(historyScrollControllerProvider);
      controller.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final ScrollController controller =
        ref.read(historyScrollControllerProvider);

    final bool shouldShow = controller.offset > 350;

    if (shouldShow != _showBottomBar) {
      setState(() {
        _showBottomBar = shouldShow;
      });
    }
  }

  void _recalculateBottomBar() {
    if (!mounted) return;
    final ScrollController controller =
        ref.read(historyScrollControllerProvider);

    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      if (_showBottomBar) {
        setState(() {
          _showBottomBar = false;
        });
      }
      return;
    }

    final bool hasEnoughScroll = controller.offset > 350;
    final bool hasEnoughContent = controller.position.maxScrollExtent > 350;

    final bool shouldShow = hasEnoughScroll && hasEnoughContent;

    if (shouldShow != _showBottomBar) {
      setState(() {
        _showBottomBar = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ViewMode mode = ref.watch(viewModeProvider);
    final StripesConfig config = ref.watch(configProvider);
    final List<Insight> insights = ref.watch(historyInsightsProvider);
    final bool shouldUseToolbar =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);

    ref.listen(displayDataProvider, (previous, next) {
      if (previous?.range != next.range) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recalculateBottomBar();
        });
      }
    });

    ref.listen(stampProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        changeEarliestDateWidget(
            ref, ref.read(displayDataProvider).range.start);
      }
    });

    return AddIndicator(builder: (context, hasIndicator) {
      return RefreshWidget(
        depth: RefreshDepth.authuser,
        scrollable: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: ref.watch(historyScrollControllerProvider),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: AppPadding.xl,
                      right: AppPadding.xl,
                      top: AppPadding.xl,
                      bottom: AppPadding.small),
                  sliver: SliverToBoxAdapter(
                    child: _ResponsiveHeader(
                      hasGraphing: config.hasGraphing,
                      mode: mode,
                      onModeChanged: (newMode) {
                        ref.read(viewModeProvider.notifier).state = newMode;
                      },
                    ),
                  ),
                ),
                if (shouldUseToolbar) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.small,
                    ),
                    sliver: SliverToBoxAdapter(
                      key: _dateRangeKey,
                      child: _DesktopControlBar(
                        hasGraphing: config.hasGraphing,
                        mode: mode,
                        onModeChanged: (newMode) {
                          ref.read(viewModeProvider.notifier).state = newMode;
                        },
                      ),
                    ),
                  ),
                  if (insights.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(
                          left: AppPadding.medium,
                          right: AppPadding.medium,
                          bottom: AppPadding.tiny),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: Breakpoint.small.value),
                            child: InsightsList(
                              insights: insights,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Desktop content header (results + export, or graph axis selector)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: AppPadding.tiny),
                    sliver: SliverToBoxAdapter(
                      child: switch (mode) {
                        ViewMode.events => const EventGridHeader(),
                        ViewMode.graph => const GraphHeader(),
                      },
                    ),
                  ),
                ] else ...[
                  // Mobile: ControlBar with just date range + filter chips
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.small,
                    ),
                    sliver: SliverToBoxAdapter(
                      key: _dateRangeKey,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: Breakpoint.small.value),
                          child: const ControlBar(
                            children: [
                              Expanded(child: DateRangeButton()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (insights.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(
                          left: AppPadding.medium,
                          right: AppPadding.medium,
                          bottom: AppPadding.tiny),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: Breakpoint.small.value),
                            child: InsightsList(
                              insights: insights,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: AppPadding.tiny),
                    sliver: SliverToBoxAdapter(
                      child: switch (mode) {
                        ViewMode.events => const EventGridHeader(),
                        ViewMode.graph => const GraphHeader(),
                      },
                    ),
                  ),
                ],
                // Content slivers based on mode
                ...switch (mode) {
                  ViewMode.events => [
                      SliverCrossAxisGroup(
                        slivers: [
                          SliverConstrainedCrossAxis(
                            maxExtent: Breakpoint.large.value,
                            sliver: const EventGrid(),
                          ),
                        ],
                      ),
                    ],
                  ViewMode.graph => [
                      GraphSliverList(onSelect: (key) {
                        context.pushNamed(RouteName.SYMPTOMTREND, extra: key);
                      }),
                    ],
                },

                if (_showBottomBar)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 72),
                  ),
              ],
            ),
            // Persistent bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: Durations.medium1,
                curve: Curves.easeOut,
                offset: _showBottomBar ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: Durations.medium1,
                  opacity: _showBottomBar ? 1.0 : 0.0,
                  child: const _PersistentDateBar(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PersistentDateBar extends StatelessWidget {
  const _PersistentDateBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRounding.small),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
            child: const DateRangeButton(),
          ),
        ),
      ),
    );
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
    final bool isDesktop =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.large, vertical: AppPadding.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (isDesktop)
            SegmentedButton<GraphYAxis>(
              segments: GraphYAxis.values
                  .map((axis) => ButtonSegment<GraphYAxis>(
                        value: axis,
                        icon: Icon(axis.icon, size: 16),
                        label: Text(axis.label),
                        tooltip: axis.description,
                      ))
                  .toList(),
              selected: {settings.axis},
              onSelectionChanged: (newSelection) {
                if (newSelection.isNotEmpty) {
                  ref
                      .read(displayDataProvider.notifier)
                      .setAxis(newSelection.first);
                }
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else
            _DropdownChip<GraphYAxis>(
              value: settings.axis,
              items: GraphYAxis.values,
              labelBuilder: (axis) => axis.label,
              iconBuilder: (axis) => axis.icon,
              onChanged: (value) {
                if (value != null) {
                  ref.read(displayDataProvider.notifier).setAxis(value);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> hasFilters = ref.watch(hasAvailableFiltersProvider);
    final bool filtersEnabled = hasFilters.valueOrNull ?? false;

    return IconButton.filled(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: filtersEnabled
          ? () {
              ref.read(sheetControllerProvider).show(
                    context: context,
                    scrollControlled: true,
                    sheetBuilder: (context, controller) =>
                        FilterSheet(scrollController: controller),
                  );
            }
          : null,
      tooltip: filtersEnabled ? 'Filters' : 'No filters available',
      icon: const Icon(Icons.filter_list),
    );
  }
}

class _ResponsiveHeader extends ConsumerWidget {
  final bool hasGraphing;
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  const _ResponsiveHeader({
    required this.hasGraphing,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool shouldUseToolbar =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    final bool isTiny = getBreakpoint(context).isLessThan(Breakpoint.tiny);
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    Widget buildViewModeToggle() => _DropdownChip<ViewMode>(
          value: mode,
          items: ViewMode.values,
          labelBuilder: (m) => switch (m) {
            ViewMode.events => 'List',
            ViewMode.graph => 'Graph',
          },
          iconBuilder: (m) => switch (m) {
            ViewMode.events => Icons.list,
            ViewMode.graph => Icons.bar_chart,
          },
          onChanged: (m) {
            if (m != null) onModeChanged(m);
          },
        );

    Widget buildTimeCycleToggle() => SegmentedButton<TimeCycle>(
          segments: [
            TimeCycle.day,
            TimeCycle.week,
            TimeCycle.month,
          ]
              .map(
                (cycle) => ButtonSegment(
                  value: cycle,
                  label: Text(cycle.value),
                ),
              )
              .toList(),
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onSelectionChanged: (newValue) {
            if (newValue.isNotEmpty) {
              ref.read(displayDataProvider.notifier).setCycle(newValue.first);
            }
          },
          selected: settings.cycle == TimeCycle.custom ? {} : {settings.cycle},
        );

    if (shouldUseToolbar) {
      return const PatientChanger(
        tab: TabOption.history,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PatientChanger(
          tab: TabOption.history,
        ),
        const SizedBox(height: AppPadding.small),
        // Row 2: filter + D|W|M on left, view mode on right
        Row(
          children: [
            const _FilterButton(),
            const SizedBox(width: AppPadding.small),
            if (isTiny)
              _DropdownChip<TimeCycle>(
                iconBuilder: (_) => Icons.date_range,
                value:
                    settings.cycle == TimeCycle.custom ? null : settings.cycle,
                items: const [
                  TimeCycle.day,
                  TimeCycle.week,
                  TimeCycle.month,
                ],
                labelBuilder: (cycle) => cycle.value,
                onChanged: (cycle) {
                  if (cycle != null) {
                    ref.read(displayDataProvider.notifier).setCycle(cycle);
                  }
                },
              )
            else
              buildTimeCycleToggle(),
            const Spacer(),
            if (hasGraphing) buildViewModeToggle(),
          ],
        ),
      ],
    );
  }
}

class _DesktopControlBar extends ConsumerWidget {
  final bool hasGraphing;
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  const _DesktopControlBar({
    required this.hasGraphing,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    final bool isLarge = getBreakpoint(context).isGreaterThan(Breakpoint.large);

    if (isLarge) {
      return ControlBar(
        children: [
          const _FilterButton(),
          const SizedBox(width: AppPadding.small),
          SegmentedButton<TimeCycle>(
            segments: [
              TimeCycle.day,
              TimeCycle.week,
              TimeCycle.month,
            ]
                .map((cycle) => ButtonSegment(
                      value: cycle,
                      label: Text(cycle.value),
                    ))
                .toList(),
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (newValue) {
              if (newValue.isNotEmpty) {
                ref.read(displayDataProvider.notifier).setCycle(newValue.first);
              }
            },
            selected:
                settings.cycle == TimeCycle.custom ? {} : {settings.cycle},
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const DateRangeButton(),
              ),
            ),
          ),
          if (hasGraphing)
            _DropdownChip<ViewMode>(
              iconBuilder: (m) => switch (m) {
                ViewMode.events => Icons.list,
                ViewMode.graph => Icons.bar_chart,
              },
              value: mode,
              items: ViewMode.values,
              labelBuilder: (m) => switch (m) {
                ViewMode.events => 'List',
                ViewMode.graph => 'Graph',
              },
              onChanged: (m) {
                if (m != null) onModeChanged(m);
              },
            ),
        ],
      );
    }

    return ControlBar(
      children: [
        const _FilterButton(),
        const SizedBox(width: AppPadding.small),
        _DropdownChip<TimeCycle>(
          iconBuilder: (_) => Icons.date_range,
          value: settings.cycle == TimeCycle.custom ? null : settings.cycle,
          items: const [TimeCycle.day, TimeCycle.week, TimeCycle.month],
          labelBuilder: (cycle) => cycle.value,
          onChanged: (cycle) {
            if (cycle != null) {
              ref.read(displayDataProvider.notifier).setCycle(cycle);
            }
          },
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: const DateRangeButton(),
            ),
          ),
        ),
        if (hasGraphing)
          _DropdownChip<ViewMode>(
            iconBuilder: (m) => switch (m) {
              ViewMode.events => Icons.list,
              ViewMode.graph => Icons.bar_chart,
            },
            value: mode,
            items: ViewMode.values,
            labelBuilder: (m) => switch (m) {
              ViewMode.events => 'List',
              ViewMode.graph => 'Graph',
            },
            onChanged: (m) {
              if (m != null) onModeChanged(m);
            },
          ),
      ],
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final IconData Function(T) iconBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownChip({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.tiny,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: colors.onPrimary,
        ),
        dropdownColor: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRounding.medium),
        onChanged: onChanged,
        selectedItemBuilder: (context) => items
            .map((item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconBuilder(item), size: 16, color: colors.onPrimary),
                    const SizedBox(width: AppPadding.tiny),
                    Text(
                      labelBuilder(item),
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: colors.onPrimary),
                    ),
                  ],
                ))
            .toList(),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconBuilder(item), size: 16),
                      const SizedBox(width: AppPadding.tiny),
                      Text(
                        labelBuilder(item),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class DateRangeButton extends ConsumerWidget {
  const DateRangeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    return DateRangeSelector(
      rangeText: settings.getRangeString(context),
      canGoPrev: settings.canGoPrev,
      canGoNext: settings.canGoNext,
      onPrev: () =>
          ref.read(displayDataProvider.notifier).shift(forward: false),
      onNext: () => ref.read(displayDataProvider.notifier).shift(forward: true),
      onTap: () {
        ref.read(sheetControllerProvider).show(
            context: context,
            scrollControlled: true,
            child: (context) => const BottomSheetCalendar());
      },
      getPreviewText: (forward) {
        return ref
            .read(displayDataProvider.notifier)
            .getNextRangeString(forward: forward, context: context);
      },
    );
  }
}

class CheckinSection extends ConsumerWidget {
  const CheckinSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    const RecordPathProps pathProps =
        RecordPathProps(filterEnabled: true, type: PathProviderType.review);
    final AsyncValue<List<RecordPath>> pathsAsync =
        ref.watch(recordPaths(pathProps));

    final AsyncValue<List<Stamp>> allStampsAsync =
        ref.watch(stampsStreamProvider);

    if (allStampsAsync.isLoading || pathsAsync.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final List<RecordPath> paths = pathsAsync.valueOrNull ?? [];
    final List<Stamp> allStamps = allStampsAsync.valueOrNull ?? [];

    final Map<String, dynamic> typeToPeriod = {
      for (var path in paths) path.name: path.period!
    };

    final List<Response> checkinStamps = [];
    for (final stamp in allStamps) {
      if (stamp is! Response) continue;
      final dynamic period = typeToPeriod[stamp.type];
      if (period == null) continue;

      final DateTime stampDate = dateFromStamp(stamp.stamp);
      final DateTimeRange checkinRange = period.getRange(stampDate);

      if (checkinRange.overlaps(settings.range)) {
        checkinStamps.add(stamp);
      }
    }

    if (checkinStamps.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    checkinStamps.sort((a, b) => b.stamp.compareTo(a.stamp));

    final Map<String, List<Response>> stampsByPeriodGroup = {};
    final Map<String, DateTime> periodStartForSorting = {};

    for (final stamp in checkinStamps) {
      final dynamic period = typeToPeriod[stamp.type];
      final String periodString =
          period?.getRangeString(DateTime.now(), context) ?? "Other";

      if (!stampsByPeriodGroup.containsKey(periodString)) {
        stampsByPeriodGroup[periodString] = [];
        // Capture start time for sorting groups
        final DateTime stampDate = dateFromStamp(stamp.stamp);
        final DateTimeRange range = period.getRange(stampDate);
        periodStartForSorting[periodString] = range.start;
      }
      stampsByPeriodGroup[periodString]!.add(stamp);
    }

    // 2. Sort groups chronologically
    final List<String> sortedPeriodStrings = stampsByPeriodGroup.keys.toList()
      ..sort((a, b) {
        final DateTime? startA = periodStartForSorting[a];
        final DateTime? startB = periodStartForSorting[b];
        if (startA == null || startB == null) return 0;
        return startA.compareTo(startB);
      });

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.xl, vertical: AppPadding.tiny),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check-ins',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppPadding.tiny),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none, // Allow shadow/blooms to show
              child: IntrinsicHeight(
                // align headers/items nicely if needed
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedPeriodStrings.map((periodString) {
                    final List<Response> groupStamps =
                        stampsByPeriodGroup[periodString]!;

                    // Group by type within this period
                    final Map<String, List<Response>> stampsByType =
                        groupStamps.groupBy((s) => s.type);
                    final List<String> sortedTypes = stampsByType.keys.toList()
                      ..sort();

                    return Padding(
                      padding: const EdgeInsets.only(right: AppPadding.large),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (periodString != "Other")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                periodString,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          Wrap(
                            spacing: AppPadding.tiny,
                            runSpacing: AppPadding.tiny,
                            children: sortedTypes.map((type) {
                              final List<Response> typeStamps =
                                  stampsByType[type]!;
                              final String name =
                                  localizations?.value(type) ?? type;

                              String label = name;
                              if (typeStamps.length > 1) {
                                label += ' • ${typeStamps.length}';
                              }

                              // Match "Completed" style from Record Screen
                              return ActionChip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                avatar: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colors.outline,
                                ),
                                label: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                backgroundColor: colors.surfaceContainerLow,
                                side: BorderSide(
                                  color: colors.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  // Find start index in the full sorted list
                                  final int startIndex =
                                      checkinStamps.indexOf(typeStamps.first);

                                  ref.read(sheetControllerProvider).show(
                                        context: context,
                                        scrollControlled: true,
                                        child: (context) => CheckinDetailPager(
                                          stamps:
                                              checkinStamps, // Pass ALL stamps
                                          initialIndex:
                                              startIndex == -1 ? 0 : startIndex,
                                          typeToPeriod: typeToPeriod,
                                        ),
                                      );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppPadding.small),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}

class CheckinDetailPager extends ConsumerStatefulWidget {
  final List<Response> stamps;
  final int initialIndex;
  final Map<String, dynamic> typeToPeriod;

  const CheckinDetailPager({
    required this.stamps,
    required this.initialIndex,
    required this.typeToPeriod,
    super.key,
  });

  @override
  ConsumerState<CheckinDetailPager> createState() => _CheckinDetailPagerState();
}

class _CheckinDetailPagerState extends ConsumerState<CheckinDetailPager> {
  late PageController _controller;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.75;
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    // Current Stamp Data
    final stamp = widget.stamps[_currentIndex];
    final detailStamp = stamp as DetailResponse;
    final String name = localizations?.value(stamp.type) ?? stamp.type;
    final DateTime stampDate = dateFromStamp(stamp.stamp);
    final dynamic period = widget.typeToPeriod[stamp.type];

    return SizedBox(
      height: sheetHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.large, vertical: AppPadding.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Text(
                          name,
                          key: ValueKey<String>(name),
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Text(
                          period?.getRangeString(stampDate, context) ??
                              dateToMDY(stampDate, context),
                          key: ValueKey<String>(
                              stamp.id ?? ''), // Unique per stamp
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Text(
                          "Updated ${dateToMDY(stampDate, context)}",
                          key: ValueKey<String>("updated-${stamp.id ?? ''}"),
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.pop(context); // Close modal
                        context.pushNamed(
                          'recordType',
                          pathParameters: {'type': stamp.type},
                          extra: QuestionsListener(
                            responses: detailStamp.responses,
                            editId: detailStamp.id,
                            submitTime: stampDate,
                            description: detailStamp.description,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    const SizedBox(width: AppPadding.tiny),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Swipeable Content
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.stamps.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final pageStamp = widget.stamps[index];
                final pageDetail = pageStamp as DetailResponse;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: DetailDisplay(detail: pageDetail),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Bottom Navigation Bar
          if (widget.stamps.length > 1)
            Padding(
              padding: const EdgeInsets.all(AppPadding.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0
                        ? () {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.stamps.length, (i) {
                      final bool isSelected = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        height: 6.0,
                        width: 6.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: _currentIndex < widget.stamps.length - 1
                        ? () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
