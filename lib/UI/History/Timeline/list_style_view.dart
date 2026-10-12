import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Insights/finding_widgets.dart';
import 'package:stripes_ui/Util/Helpers/date_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/control_bar.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_range_selector.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/Export/export.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_view_screen.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class EventsView extends ConsumerStatefulWidget {
  const EventsView({super.key});

  @override
  ConsumerState<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends ConsumerState<EventsView> {
  final GlobalKey _dateRangeKey = GlobalKey();
  late final ScrollController _historyController;
  double _lastScrollOffset = 0;
  double _calendarThreshold = double.infinity;

  @override
  void initState() {
    super.initState();
    _historyController = ref.read(historyScrollControllerProvider);
    _historyController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _historyController.removeListener(_onScroll);
    super.dispose();
  }

  void _measureCalendarThreshold() {
    if (!mounted || !_historyController.hasClients) return;
    final renderObject = _dateRangeKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;
    _calendarThreshold =
        viewport.getOffsetToReveal(renderObject, 0).offset +
        renderObject.size.height;
    _lastScrollOffset = _boundedScrollOffset;
    if (_lastScrollOffset <= _calendarThreshold) _setCalendarVisible(false);
  }

  void _setCalendarVisible(bool visible) {
    // Restoring a position can notify during layout. Publish after that frame.
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(historyCalendarNavVisibleProvider.notifier)
              .setVisible(visible);
        }
      });
    } else {
      ref.read(historyCalendarNavVisibleProvider.notifier).setVisible(visible);
    }
  }

  double get _boundedScrollOffset {
    final position = _historyController.position;
    // The spring returning from iOS overscroll is not a direction change.
    return position.pixels.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  void _onScroll() {
    if (!mounted || !_historyController.hasClients) return;
    final current = _boundedScrollOffset;
    final delta = current - _lastScrollOffset;
    if (current <= _calendarThreshold) {
      _setCalendarVisible(false);
    } else if (delta.abs() >= 2) {
      _setCalendarVisible(delta < 0);
    }
    if (delta.abs() >= 2) _lastScrollOffset = current;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final requestedMode = ref.watch(viewModeProvider);
    final mode = config.betaUi.hasGraphing ? requestedMode : ViewMode.events;
    final findingFeedAsync = config.display.insightsEnabled
        ? ref.watch(historyFindingsProvider)
        : null;
    final findingFeed = findingFeedAsync?.value;
    final showFindingSurface = findingFeed != null
        ? findingFeed.state != FindingFeedState.noData
        : findingFeedAsync?.hasError ?? false;
    final useDesktopToolbar = _useHistoryToolbar(context);
    final hasBottomCalendar = getBreakpoint(context)
        .isLessThan(Breakpoint.medium);
    final calendarClearance = hasBottomCalendar
        ? _FloatingHistoryCalendar.height(
            context,
            ref.watch(displayDataProvider),
          )
        : 0.0;
    final entries = ref.watch(availableStampsProvider);
    final reviews = ref.watch(reviewPaths(const ReviewPathsProps()));
    // Wait for real content before restoring the saved scroll position.
    final waitingForEntries =
        mode == ViewMode.events &&
        ((entries.isLoading && !entries.hasValue) ||
            (reviews.isLoading && !reviews.hasValue));

    ref.listen(displayDataProvider.select((settings) => settings.range), (
      previous,
      next,
    ) {
      if (previous != next) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCalendarThreshold(),
        );
      }
    });
    ref.listen(stampProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        changeEarliestDateWidget(
          ref,
          ref.read(displayDataProvider).range.start,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureCalendarThreshold(),
    );

    void changeMode(ViewMode mode) {
      ref.read(viewModeProvider.notifier).setMode(mode);
    }

    return PageStorage(
      bucket: ref.watch(historyPageStorageProvider),
      child: AddIndicator(
        builder: (context, hasIndicator) => waitingForEntries
            ? const LoadingWidget()
            : Stack(
                fit: StackFit.expand,
                children: [
                  RefreshWidget(
                    depth: RefreshDepth.authuser,
                    scrollable: CustomScrollView(
                      key: const PageStorageKey('history-scroll'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _historyController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            left: AppPadding.xl,
                            right: AppPadding.xl,
                            top: AppPadding.xl,
                            bottom: AppPadding.small,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _ResponsiveHeader(
                              hasGraphing: config.betaUi.hasGraphing,
                              mode: mode,
                              onModeChanged: changeMode,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.medium,
                            vertical: AppPadding.small,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: KeyedSubtree(
                              key: _dateRangeKey,
                              child: useDesktopToolbar
                                  ? _DesktopControlBar(
                                      hasGraphing: config.betaUi.hasGraphing,
                                      mode: mode,
                                      onModeChanged: changeMode,
                                    )
                                  : Align(
                                      alignment: Alignment.centerLeft,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: Breakpoint.small.value,
                                        ),
                                        child: const ControlBar(
                                          children: [
                                            Expanded(child: DateRangeButton()),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (showFindingSurface)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.xl,
                              vertical: AppPadding.tiny,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: Breakpoint.small.value,
                                  ),
                                  child:
                                      findingFeed != null &&
                                          findingFeed.findings.isNotEmpty
                                      ? EngineFindingsPanel(
                                          findings: findingFeed.findings,
                                          dataset: findingFeed.run.dataset,
                                        )
                                      : EngineFindingsNotice(
                                          state:
                                              findingFeed?.state ??
                                              FindingFeedState.unavailable,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: switch (mode) {
                            ViewMode.events => const EventGridHeader(),
                            ViewMode.graph => const GraphHeader(),
                          },
                        ),
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
                            GraphSliverList(
                              onSelect: (key) {
                                context.pushNamed(
                                  RouteName.SYMPTOMTREND,
                                  extra: key,
                                );
                              },
                              onCategorySelect: (keys) {
                                if (keys.isEmpty) return;
                                context.pushNamed(
                                  RouteName.SYMPTOMTREND,
                                  extra: GraphViewParams(
                                    graphKey: keys.first,
                                    initialAdditions: keys.skip(1).toList(),
                                  ),
                                );
                              },
                            ),
                          ],
                        },
                        SliverToBoxAdapter(
                          child: SizedBox(
                            // Keep the last entry clear of the overlay without
                            // changing the scroll extent as the row animates.
                            height:
                                calendarClearance +
                                (hasIndicator
                                    ? AppPadding.xxxl
                                    : AppPadding.large),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasBottomCalendar)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _FloatingHistoryCalendar(),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Paints above the tab bar without resizing the history viewport.
class _FloatingHistoryCalendar extends ConsumerWidget {
  const _FloatingHistoryCalendar();

  static double height(BuildContext context, DisplayDataSettings settings) {
    return DateRangeSelector.heightFor(
          context,
          _dateRangeLabel(settings, settings.range, context),
          MediaQuery.sizeOf(context).width,
        ) +
        1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(historyCalendarNavVisibleProvider);
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : Durations.short4,
        reverseDuration: reducedMotion ? Duration.zero : Durations.short4,
        layoutBuilder: (child, previous) => Stack(
          alignment: Alignment.bottomCenter,
          children: [...previous, ?child],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        ),
        child: !visible
            ? const SizedBox.shrink(key: ValueKey('calendar-hidden'))
            : SizedBox(
                key: const ValueKey('calendar-visible'),
                height: height(context, ref.watch(displayDataProvider)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: const Material(
                    type: MaterialType.transparency,
                    child: DateRangeButton(
                      key: ValueKey('history-floating-date'),
                    ),
                  ),
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
    final AsyncValue<int> eventsCount = ref.watch(
      availableStampsProvider.select(
        (stamps) => stamps.whenData((data) => data.length),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AsyncValueDefaults(
            value: eventsCount,
            onData: (value) => Text(
              context.translate.historyEntryCount(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
    final bool isDesktop = _useHistoryToolbar(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.large,
        vertical: AppPadding.small,
      ),
      child: Wrap(
        spacing: AppPadding.small,
        runSpacing: AppPadding.small,
        children: [
          if (isDesktop)
            SegmentedButton<GraphYAxis>(
              segments: GraphYAxis.values
                  .map(
                    (axis) => ButtonSegment<GraphYAxis>(
                      value: axis,
                      icon: Icon(axis.icon, size: 16),
                      label: Text(axis.label),
                      tooltip: axis.description,
                    ),
                  )
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
              menuLabel: 'Graph measure',
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
    final filterCount = ref.watch(
      displayDataProvider.select((settings) => settings.filters.length),
    );
    final bool filtersEnabled = (hasFilters.value ?? false) || filterCount > 0;

    return IconButton(
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size(48, 48),
      ),
      onPressed: filtersEnabled
          ? () {
              ref
                  .read(sheetControllerProvider)
                  .show(
                    context: context,
                    scrollControlled: true,
                    sheetBuilder: (context, controller) =>
                        FilterSheet(scrollController: controller),
                  );
            }
          : null,
      tooltip: filterCount > 0
          ? 'Filters ($filterCount active)'
          : filtersEnabled
          ? 'Filters'
          : 'No filters available',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list),
          if (filterCount > 0) const SizedBox(width: AppPadding.tiny),
          ExcludeSemantics(
            // The button's tooltip announces the complete active count.
            child: Badge.count(
              count: filterCount,
              isLabelVisible: filterCount > 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
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
    final bool shouldUseToolbar = _useHistoryToolbar(context);
    final bool isTiny = getBreakpoint(context).isLessThan(Breakpoint.tiny);
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    Widget buildViewModeToggle() => _DropdownChip<ViewMode>(
      menuLabel: 'History view',
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
      segments: [TimeCycle.day, TimeCycle.week, TimeCycle.month]
          .map((cycle) => ButtonSegment(value: cycle, label: Text(cycle.value)))
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
      return const PatientChanger(tab: TabOption.history);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PatientChanger(tab: TabOption.history),
        const SizedBox(height: AppPadding.small),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppPadding.small,
          runSpacing: AppPadding.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _FilterButton(),
            if (isTiny || MediaQuery.textScalerOf(context).scale(14) > 18)
              _DropdownChip<TimeCycle>(
                menuLabel: 'Time range',
                iconBuilder: (_) => Icons.date_range,
                hintIcon: Icons.date_range,
                value: settings.cycle == TimeCycle.custom
                    ? null
                    : settings.cycle,
                items: const [TimeCycle.day, TimeCycle.week, TimeCycle.month],
                labelBuilder: (cycle) => cycle.value,
                onChanged: (cycle) {
                  if (cycle != null) {
                    ref.read(displayDataProvider.notifier).setCycle(cycle);
                  }
                },
              )
            else
              buildTimeCycleToggle(),
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
            segments: [TimeCycle.day, TimeCycle.week, TimeCycle.month]
                .map(
                  (cycle) =>
                      ButtonSegment(value: cycle, label: Text(cycle.value)),
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
            selected: settings.cycle == TimeCycle.custom
                ? {}
                : {settings.cycle},
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
              menuLabel: 'History view',
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
          menuLabel: 'Time range',
          iconBuilder: (_) => Icons.date_range,
          hintIcon: Icons.date_range,
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
            menuLabel: 'History view',
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

bool _useHistoryToolbar(BuildContext context) =>
    getBreakpoint(context).isGreaterThan(Breakpoint.medium) &&
    MediaQuery.textScalerOf(context).scale(14) <= 18;

class _DropdownChip<T> extends ConsumerWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final IconData Function(T) iconBuilder;
  final ValueChanged<T?> onChanged;
  final String menuLabel;
  final String hint;
  final IconData? hintIcon;

  const _DropdownChip({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onChanged,
    required this.menuLabel,
    this.hint = 'Custom',
    this.hintIcon,
  });

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final selected = await ref
        .read(sheetControllerProvider)
        .show<T>(
          context: context,
          scrollControlled: true,
          child: (sheetContext) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppPadding.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.large,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            menuLabel,
                            style: Theme.of(sheetContext).textTheme.titleMedium,
                          ),
                        ),
                        const CloseButton(),
                      ],
                    ),
                  ),
                  for (final item in items)
                    ListTile(
                      leading: Icon(iconBuilder(item)),
                      title: Text(labelBuilder(item)),
                      selected: item == value,
                      trailing: item == value ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(sheetContext).pop(item),
                    ),
                ],
              ),
            ),
          ),
        );
    if (selected != null && context.mounted) onChanged(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final selected = value;
    final label = selected == null ? hint : labelBuilder(selected);
    final icon = selected == null ? hintIcon : iconBuilder(selected);
    return Semantics(
      label: menuLabel,
      child: TextButton(
        onPressed: () => _choose(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          backgroundColor: colors.surfaceContainerLow,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRounding.small),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppPadding.small),
            ],
            Flexible(child: Text(label)),
            const SizedBox(width: AppPadding.tiny),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

String _dateRangeLabel(
  DisplayDataSettings settings,
  DateTimeRange range,
  BuildContext context,
) => settings.cycle == TimeCycle.month
    ? DateFormat.yMMM(Localizations.localeOf(context).languageCode)
          .format(range.start.toLocal())
    : settings.getRangeStringFromCustom(range, context);

class DateRangeButton extends ConsumerWidget {
  const DateRangeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    String label(DateTimeRange range) =>
        _dateRangeLabel(settings, range, context);

    return DateRangeSelector(
      rangeText: label(settings.range),
      canGoPrev: settings.canGoPrev,
      canGoNext: settings.canGoNext,
      onPrev: () =>
          ref.read(displayDataProvider.notifier).shift(forward: false),
      onNext: () => ref.read(displayDataProvider.notifier).shift(forward: true),
      onTap: () {
        ref
            .read(sheetControllerProvider)
            .show(
              context: context,
              scrollControlled: true,
              child: (context) => const BottomSheetCalendar(),
            );
      },
      getPreviewText: (forward) {
        return label(
          ref.read(displayDataProvider.notifier).getNextRange(forward: forward),
        );
      },
    );
  }
}

class CheckinSection extends ConsumerWidget {
  const CheckinSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    const RecordPathProps pathProps = RecordPathProps(
      filterEnabled: true,
      type: PathProviderType.review,
    );
    final AsyncValue<List<RecordPath>> pathsAsync = ref.watch(
      recordPaths(pathProps),
    );

    final AsyncValue<List<Stamp>> allStampsAsync = ref.watch(
      stampsStreamProvider,
    );

    if (allStampsAsync.isLoading || pathsAsync.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final List<RecordPath> paths = pathsAsync.value ?? [];
    final List<Stamp> allStamps = allStampsAsync.value ?? [];

    final Map<String, dynamic> typeToPeriod = {
      for (var path in paths) path.name: path.period!,
    };

    final List<Response> checkinStamps = [];
    for (final stamp in allStamps) {
      if (stamp is! Response) continue;
      final dynamic period = typeToPeriod[stamp.type];
      if (period == null) continue;

      final DateTime stampDate = occurrenceTimeForResponse(stamp);
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
        final DateTime stampDate = occurrenceTimeForResponse(stamp);
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

    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.xl,
        vertical: AppPadding.tiny,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check-ins',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
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
                    final Map<String, List<Response>> stampsByType = groupStamps
                        .groupBy((s) => s.type);
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
                                style: Theme.of(context).textTheme.labelSmall
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
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                backgroundColor: colors.surfaceContainerLow,
                                side: BorderSide(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                onPressed: () {
                                  // Find start index in the full sorted list
                                  final int startIndex = checkinStamps.indexOf(
                                    typeStamps.first,
                                  );

                                  ref
                                      .read(sheetControllerProvider)
                                      .show(
                                        context: context,
                                        scrollControlled: true,
                                        child: (context) => CheckinDetailPager(
                                          stamps:
                                              checkinStamps, // Pass ALL stamps
                                          initialIndex: startIndex == -1
                                              ? 0
                                              : startIndex,
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
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    // Current Stamp Data
    final stamp = widget.stamps[_currentIndex];
    final detailStamp = stamp as DetailResponse;
    final String name = localizations?.value(stamp.type) ?? stamp.type;
    final DateTime stampDate = occurrenceTimeForResponse(stamp);
    final dynamic period = widget.typeToPeriod[stamp.type];

    return SizedBox(
      height: sheetHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.large,
              vertical: AppPadding.medium,
            ),
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
                                opacity: animation,
                                child: child,
                              );
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
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
                            stamp.id ?? '',
                          ), // Unique per stamp
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
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
                          extra: SessionData(
                            responses: {
                              for (final r in detailStamp.responses)
                                r.question.id: r,
                            },
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
