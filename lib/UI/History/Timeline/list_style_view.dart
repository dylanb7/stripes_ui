import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/Dashboard/insight_provider.dart';
import 'package:stripes_ui/UI/History/DashboardView/dashboard_screen.dart';
import 'package:stripes_ui/Util/Helpers/date_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Providers/questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
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
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

class EventsView extends ConsumerWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ViewMode mode = ref.watch(viewModeProvider);
    final StripesConfig config = ref.watch(configProvider);
    final List<Insight> insights =
        ref.watch(insightsProvider(const InsightsProps()));
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
                              PopupMenuButton<ViewMode>(
                                initialValue: mode,
                                tooltip: 'Switch View Mode',
                                onSelected: (newMode) {
                                  ref.read(viewModeProvider.notifier).state =
                                      newMode;
                                },
                                icon: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppRounding.small),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppPadding.small),
                                    child: Icon(
                                      switch (mode) {
                                        ViewMode.events => Icons.list,
                                        ViewMode.reviews => Icons.event_repeat,
                                        ViewMode.graph => Icons.bar_chart,
                                      },
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: ViewMode.events,
                                    child: ListTile(
                                      leading: Icon(Icons.list),
                                      title: Text('Events'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: ViewMode.reviews,
                                    child: ListTile(
                                      leading: Icon(Icons.event_repeat),
                                      title: Text('Reviews'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: ViewMode.graph,
                                    child: ListTile(
                                      leading: Icon(Icons.bar_chart),
                                      title: Text('Graphs'),
                                    ),
                                  ),
                                ],
                              )
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

              SliverCrossAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                        left: AppPadding.xl,
                        right: AppPadding.xl,
                        bottom: AppPadding.tiny),
                    sliver: SliverConstrainedCrossAxis(
                      maxExtent: Breakpoint.medium.value,
                      sliver: SliverToBoxAdapter(
                        child: FiltersRow(),
                      ),
                    ),
                  ),
                ],
              ),
              const SliverToBoxAdapter(
                child: CurrentFilters(),
              ),
              PinnedHeaderSliver(
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
              SliverCrossAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                        left: AppPadding.xl,
                        right: AppPadding.xl,
                        bottom: AppPadding.tiny),
                    sliver: SliverConstrainedCrossAxis(
                      maxExtent: Breakpoint.medium.value,
                      sliver: SliverToBoxAdapter(
                        child: InsightsList(
                          insights: insights,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: AppPadding.tiny),
                sliver: SliverToBoxAdapter(
                  child: switch (mode) {
                    ViewMode.events => const EventGridHeader(),
                    ViewMode.reviews => const ReviewsHeader(),
                    ViewMode.graph => const GraphHeader(),
                  },
                ),
              ),
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
                ViewMode.reviews => [
                    SliverCrossAxisGroup(
                      slivers: [
                        SliverConstrainedCrossAxis(
                          maxExtent: Breakpoint.large.value,
                          sliver: const ReviewsView(),
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
        SegmentedButton<TimeCycle>(
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
            selected:
                settings.cycle == TimeCycle.custom ? {} : {settings.cycle}),
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
          tooltip: 'Filters',
          icon: const Icon(Icons.filter_list),
        ),
      ],
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

/// Displays completed check-ins within the selected date range.
class CheckinSection extends ConsumerWidget {
  const CheckinSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get display settings for range
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    // Get check-in path types and periods
    const RecordPathProps pathProps =
        RecordPathProps(filterEnabled: true, type: PathProviderType.review);
    final AsyncValue<List<RecordPath>> pathsAsync =
        ref.watch(recordPaths(pathProps));

    // Get all stamps (unfiltered by date, because we need custom overlap logic)
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

    // Filter stamps: Must be a check-in type AND its period range must overlap the selected range
    final List<Response> checkinStamps = [];
    for (final stamp in allStamps) {
      if (stamp is! Response) continue;
      // Is it a check-in type?
      final dynamic period = typeToPeriod[stamp.type];
      if (period == null) continue;

      // Check overlap
      final DateTime stampDate = dateFromStamp(stamp.stamp);
      final DateTimeRange checkinRange = period.getRange(stampDate);

      if (checkinRange.overlaps(settings.range)) {
        checkinStamps.add(stamp);
      }
    }

    if (checkinStamps.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Sort all stamps by date descending (newest first)
    checkinStamps.sort((a, b) => b.stamp.compareTo(a.stamp));

    // 1. Group by Period String
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
                            desc: detailStamp.description,
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

/// Header for reviews view
class ReviewsHeader extends ConsumerWidget {
  const ReviewsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Reviews",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

/// Period-based reviews view - groups by period type
class ReviewsView extends ConsumerWidget {
  const ReviewsView({super.key});

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
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final List<RecordPath> paths = pathsAsync.valueOrNull ?? [];
    final List<Stamp> allStamps = allStampsAsync.valueOrNull ?? [];

    if (paths.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.xl),
          child: Center(
            child: Text(
              "No reviews configured",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    // Group paths by period duration
    final Map<String, List<RecordPath>> pathsByPeriodType = {};
    for (final path in paths) {
      final String periodType = _getPeriodTypeName(path.period!);
      pathsByPeriodType.putIfAbsent(periodType, () => []).add(path);
    }

    // Collect all review entries within range
    final Map<String, dynamic> typeToPeriod = {
      for (var path in paths) path.name: path.period!
    };

    final List<Response> reviewStamps = [];
    for (final stamp in allStamps) {
      if (stamp is! Response) continue;
      final dynamic period = typeToPeriod[stamp.type];
      if (period == null) continue;

      final DateTime stampDate = dateFromStamp(stamp.stamp);
      final DateTimeRange reviewRange = period.getRange(stampDate);
      if (reviewRange.overlaps(settings.range)) {
        reviewStamps.add(stamp);
      }
    }

    reviewStamps.sort((a, b) => b.stamp.compareTo(a.stamp));

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Order: Daily, Weekly, Monthly, Annual
    final List<String> orderedTypes = ['Daily', 'Weekly', 'Monthly', 'Annual'];
    final List<String> sortedKeys = pathsByPeriodType.keys.toList()
      ..sort((a, b) {
        final aIdx = orderedTypes.indexOf(a);
        final bIdx = orderedTypes.indexOf(b);
        if (aIdx == -1 && bIdx == -1) return a.compareTo(b);
        if (aIdx == -1) return 1;
        if (bIdx == -1) return -1;
        return aIdx.compareTo(bIdx);
      });

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.xl, vertical: AppPadding.small),
      sliver: SliverList.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final String periodType = sortedKeys[index];
          final List<RecordPath> typePaths = pathsByPeriodType[periodType]!;

          return _ReviewPeriodSection(
            periodType: periodType,
            paths: typePaths,
            reviewStamps: reviewStamps,
            typeToPeriod: typeToPeriod,
            localizations: localizations,
            colors: colors,
          );
        },
      ),
    );
  }

  String _getPeriodTypeName(dynamic period) {
    // Infer from period duration
    final DateTimeRange range = period.getRange(DateTime.now());
    final int days = range.duration.inDays;
    if (days <= 1) return 'Daily';
    if (days <= 7) return 'Weekly';
    if (days <= 31) return 'Monthly';
    return 'Annual';
  }
}

class _ReviewPeriodSection extends ConsumerWidget {
  final String periodType;
  final List<RecordPath> paths;
  final List<Response> reviewStamps;
  final Map<String, dynamic> typeToPeriod;
  final QuestionsLocalizations? localizations;
  final ColorScheme colors;

  const _ReviewPeriodSection({
    required this.periodType,
    required this.paths,
    required this.reviewStamps,
    required this.typeToPeriod,
    required this.localizations,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period type header
          Text(
            '$periodType Reviews',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppPadding.small),
          // List of review types in this period
          ...paths.map((path) {
            final String name = localizations?.value(path.name) ?? path.name;
            final List<Response> typeStamps =
                reviewStamps.where((s) => s.type == path.name).toList();
            final int count = typeStamps.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.tiny),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    count > 0
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: count > 0 ? colors.primary : colors.outline,
                  ),
                  title: Text(name),
                  subtitle: count > 0
                      ? Text('$count in range')
                      : Text(
                          'Not completed',
                          style: TextStyle(color: colors.outline),
                        ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: count > 0
                      ? () {
                          ref.read(sheetControllerProvider).show(
                                context: context,
                                scrollControlled: true,
                                child: (context) => CheckinDetailPager(
                                  stamps: typeStamps,
                                  initialIndex: 0,
                                  typeToPeriod: typeToPeriod,
                                ),
                              );
                        }
                      : null,
                ),
              ),
            );
          }),
          const Divider(),
        ],
      ),
    );
  }
}
