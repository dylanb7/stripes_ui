import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
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
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

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
                          sliver: const CheckinSection(),
                        ),
                      ],
                    )
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
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
            behavior: HitTestBehavior.opaque,
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
                        vertical: AppPadding.medium),
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

/// Displays completed check-ins within the selected date range.
class CheckinSection extends ConsumerWidget {
  const CheckinSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get display settings for range
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    // Get check-in path types and periods
    const RecordPathProps pathProps =
        RecordPathProps(filterEnabled: true, type: PathProviderType.checkin);
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
