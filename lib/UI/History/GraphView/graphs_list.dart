import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';

import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/UI/History/Timeline/review_period_data.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import '../../../Util/Design/paddings.dart';

class GraphsList extends ConsumerWidget {
  const GraphsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GraphScreenWrap(
      scrollable: ListSection(
        onSelect: (GraphKey key) {
          context.pushNamed(RouteName.SYMPTOMTREND, extra: key);
        },
      ),
    );
  }
}

class ListSection extends ConsumerWidget {
  final bool includesControls;

  final List<GraphKey> excludedKeys;

  final Function(GraphKey) onSelect;

  final ScrollController? controller;

  const ListSection(
      {required this.onSelect,
      this.includesControls = true,
      this.excludedKeys = const [],
      this.controller,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      controller: controller,
      physics: includesControls ? null : const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      slivers: [
        if (includesControls)
          SliverPadding(
            padding: const EdgeInsets.only(
                left: AppPadding.large,
                right: AppPadding.large,
                top: AppPadding.large),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                      child: PatientChanger(
                    tab: TabOption.history,
                  )),
                  const SizedBox(
                    width: AppPadding.tiny,
                  ),
                  IconButton(
                      onPressed: () {
                        context.pushNamed(RouteName.HISTORY);
                      },
                      icon: const Icon(Icons.calendar_month))
                ],
              ),
            ),
          ),
        if (includesControls)
          const SliverFloatingHeader(
            child: GraphControlArea(),
          ),
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.small)),
        GraphSliverList(onSelect: onSelect, excludedKeys: excludedKeys),
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.xxl)),
      ],
    );
  }
}

class GraphSliverList extends ConsumerWidget {
  final Function(GraphKey) onSelect;
  final List<GraphKey> excludedKeys;
  const GraphSliverList(
      {required this.onSelect, this.excludedKeys = const [], super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    final AsyncValue<Map<GraphKey, List<Response>>> graphs =
        ref.watch(graphStampsProvider);

    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap =
        reviewPathsAsync.valueOrNull ?? {};

    return AsyncValueDefaults(
      value: graphs,
      onData: (data) {
        final Map<GraphKey, List<Response>> withKeysRemoved = Map.fromEntries(
          data.keys.where((key) => !excludedKeys.contains(key)).map(
                (key) => MapEntry(key, data[key]!),
              ),
        );
        if (withKeysRemoved.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "No symptoms ${settings.axis == GraphYAxis.average ? "with number entries " : ""}recorded",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final bool isLargeScreen =
            MediaQuery.of(context).size.width > Breakpoint.medium.value;

        if (isLargeScreen) {
          int crossAxisCount = (MediaQuery.of(context).size.width / 400).ceil();
          if (crossAxisCount < 2) crossAxisCount = 2;

          final List<GraphKey> keys = withKeysRemoved.keys.toList();
          final int rowCount = (keys.length / crossAxisCount).ceil();

          return SliverList.builder(
            itemCount: rowCount,
            itemBuilder: (context, rowIndex) {
              final int startIndex = rowIndex * crossAxisCount;
              final int endIndex =
                  (startIndex + crossAxisCount).coerceAtMost(keys.length);
              final List<GraphKey> rowKeys = keys.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppPadding.large),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...rowKeys.map((key) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small),
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  onSelect(key);
                                },
                                child: GraphSymptomRow(
                                  responses: withKeysRemoved[key]!,
                                  graphKey: key,
                                  useRowLayout: false,
                                  reviewPaths: reviewPathsMap,
                                ),
                              ),
                            ),
                          )),
                      ...List.generate(
                        crossAxisCount - rowKeys.length,
                        (_) => const Expanded(child: SizedBox()),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return SliverList.separated(
          itemBuilder: (context, index) {
            final GraphKey key = withKeysRemoved.keys.elementAt(index);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                onSelect(key);
              },
              child: MergeSemantics(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                  child: GraphSymptomRow(
                    responses: withKeysRemoved[key]!,
                    graphKey: key,
                    useRowLayout: true,
                    reviewPaths: reviewPathsMap,
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const Divider(),
          itemCount: withKeysRemoved.keys.length,
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
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 24,
                    color:
                        Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(
                  width: AppPadding.small,
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .disabledColor
                            .withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(AppRounding.tiny))),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: 5,
      ),
    );
  }
}

class GraphSymptomRow extends StatelessWidget {
  final List<Response> responses;

  final GraphKey graphKey;

  final bool hasHero;

  final bool useRowLayout;

  final Map<String, RecordPath>? reviewPaths;

  const GraphSymptomRow(
      {required this.responses,
      required this.graphKey,
      this.hasHero = true,
      this.useRowLayout = false,
      this.reviewPaths,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (useRowLayout) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                graphKey.toLocalizedString(context),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(
              width: AppPadding.tiny,
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRounding.tiny),
                  ),
                ),
                child: hasHero
                    ? Hero(
                        tag: graphKey,
                        flightShuttleBuilder: (flightContext, animation,
                            flightDirection, fromHeroContext, toHeroContext) {
                          return ClipRect(child: toHeroContext.widget);
                        },
                        child: GraphSymptom(
                          responses: {graphKey: responses},
                          isDetailed: false,
                          reviewPaths: reviewPaths,
                        ),
                      )
                    : GraphSymptom(
                        responses: {graphKey: responses},
                        isDetailed: false,
                        reviewPaths: reviewPaths,
                      ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right,
              size: 24.0,
            )
          ],
        ),
      );
    }
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    graphKey.toLocalizedString(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: AppPadding.medium),
            AspectRatio(
              aspectRatio: 2.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                  vertical: AppPadding.tiny,
                ),
                child: hasHero
                    ? Hero(
                        tag: graphKey,
                        flightShuttleBuilder: (flightContext, animation,
                            flightDirection, fromHeroContext, toHeroContext) {
                          return ClipRect(child: toHeroContext.widget);
                        },
                        child: GraphSymptom(
                          responses: {graphKey: responses},
                          isDetailed: false,
                          reviewPaths: reviewPaths,
                        ),
                      )
                    : GraphSymptom(
                        responses: {graphKey: responses},
                        isDetailed: false,
                        reviewPaths: reviewPaths,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphControlArea extends ConsumerStatefulWidget {
  final bool showsSpan, showsYAxis, showsDateChange, hasDivider;

  const GraphControlArea(
      {this.showsDateChange = true,
      this.showsSpan = true,
      this.showsYAxis = true,
      this.hasDivider = true,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _GraphControlAreaState();
  }
}

class _GraphControlAreaState extends ConsumerState<GraphControlArea> {
  bool acceptedSwipe = false;

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    Widget constrain({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoint.small.value,
          ),
          child: child,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: widget.hasDivider
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.showsDateChange) ...[
            const SizedBox(
              height: AppPadding.small,
            ),
            Center(
              child: constrain(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRounding.tiny),
                    ),
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      if (acceptedSwipe) {
                        setState(() {
                          acceptedSwipe = false;
                        });
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (acceptedSwipe) return;
                      const dragSpeed = 4;
                      if (details.delta.dx > dragSpeed && settings.canGoPrev) {
                        ref
                            .read(displayDataProvider.notifier)
                            .shift(forward: false);
                      } else if (details.delta.dx < -dragSpeed &&
                          settings.canGoNext) {
                        ref
                            .read(displayDataProvider.notifier)
                            .shift(forward: true);
                      }
                      setState(() {
                        acceptedSwipe = true;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Previous Range',
                          onPressed: settings.canGoPrev
                              ? () {
                                  ref
                                      .read(displayDataProvider.notifier)
                                      .shift(forward: false);
                                }
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_left),
                        ),
                        Text(
                          settings.getRangeString(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          tooltip: 'Next Range',
                          onPressed: settings.canGoNext
                              ? () {
                                  ref
                                      .read(displayDataProvider.notifier)
                                      .shift(forward: true);
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
          ],
          if (widget.showsSpan) ...[
            const SizedBox(
              height: AppPadding.small,
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppPadding.large),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<TimeCycle>(
                  segments: TimeCycle.values
                      .map((cycle) => ButtonSegment<TimeCycle>(
                            value: cycle,
                            label: Text(cycle.value),
                          ))
                      .toList(),
                  selected: {settings.cycle},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      ref
                          .read(displayDataProvider.notifier)
                          .setCycle(newSelection.first);
                    }
                  },
                  showSelectedIcon: false,
                ),
              ),
            ),
          ],
          if (widget.showsYAxis) ...[
            const SizedBox(
              height: AppPadding.small,
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppPadding.large),
              child: Text(
                "Display Mode",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: AppPadding.tiny),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<GraphYAxis>(
                  segments: GraphYAxis.values
                      .map((axis) => ButtonSegment<GraphYAxis>(
                            value: axis,
                            icon: Icon(axis.icon, size: 18),
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
                ),
              ),
            ),
            // Show notice when Average mode filters to numeric only
            if (settings.axis == GraphYAxis.average)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.large,
                  right: AppPadding.large,
                  top: AppPadding.tiny,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppPadding.tiny),
                    Expanded(
                      child: Text(
                        "Showing numeric scale responses only",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(
            height: AppPadding.tiny,
          ),
        ],
      ),
    );
  }
}

class GraphScreenWrap extends StatelessWidget {
  final Widget scrollable;

  const GraphScreenWrap({required this.scrollable, super.key});

  @override
  Widget build(BuildContext context) {
    return AddIndicator(
      builder: (context, hasIndicator) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
            child: RefreshWidget(
                depth: RefreshDepth.subuser, scrollable: scrollable),
          ),
        );
      },
    );
  }
}

class GraphEditResult {
  final Color color;
  final String? label;

  GraphEditResult({required this.color, this.label});
}

class GraphViewHeader extends StatelessWidget {
  final AsyncValue<Map<GraphKey, List<Response>>> graphData;
  final ChartSelectionController<GraphPoint, DateTime> selectionController;
  final DisplayDataSettings settings;
  final GraphKey baseKey;
  final List<GraphKey> additions;
  final Map<GraphKey, String> customLabels;
  final Map<GraphKey, Color> colorKeys;

  const GraphViewHeader({
    super.key,
    required this.graphData,
    required this.selectionController,
    required this.settings,
    required this.baseKey,
    required this.additions,
    required this.customLabels,
    required this.colorKeys,
  });

  @override
  Widget build(BuildContext context) {
    final String mainTitle = additions.isEmpty
        ? baseKey.toLocalizedString(context)
        : (additions.length == 1 ? "Symptom Comparison" : "Combined Trends");

    return Stack(
      children: [
        // Top-right Close Button
        Positioned(
          top: 0,
          right: AppPadding.small,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large, right: 48, top: AppPadding.small),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<
                    ChartSelectionState<GraphPoint, DateTime>>(
                  valueListenable: selectionController,
                  builder: (context, selectionState, child) {
                    final hits = selectionState.results;

                    if (hits.isEmpty) {
                      return SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            settings.getRangeString(context),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                      );
                    }

                    final Offset? hoverPos = selectionState.hoverPosition;
                    final ChartHitTestResult<GraphPoint, DateTime> hit =
                        hits.first;
                    final bool isScatter =
                        settings.axis == GraphYAxis.entrytime;
                    final DateTime date = isScatter
                        ? dateFromStamp(hit.item.data.first.stamp)
                        : hit.xValue;
                    DateFormat format = DateFormat.MMMEd();
                    if (settings.cycle == TimeCycle.day || isScatter) {
                      format.add_jm();
                    }

                    final dateTag = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        format.format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                      ),
                    );

                    return LayoutBuilder(builder: (context, constraints) {
                      final double xInHeader = hoverPos?.dx ?? 0;

                      const double tagHalfWidth = 55.0;
                      final double clampedCenter = xInHeader.clamp(
                          tagHalfWidth, constraints.maxWidth - tagHalfWidth);
                      final double shiftFromCenter =
                          clampedCenter - (constraints.maxWidth / 2);

                      return SizedBox(
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Transform.translate(
                              offset: Offset(shiftFromCenter, 0),
                              child: Center(
                                child: dateTag,
                              ),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SymptomListItem extends StatelessWidget {
  final GraphKey graphKey;
  final Color color;
  final String label;
  final ValueListenable<ChartSelectionState<GraphPoint, DateTime>>
      selectionController;
  final AsyncValue<Map<GraphKey, List<Response>>> graphData;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const SymptomListItem({
    super.key,
    required this.graphKey,
    required this.color,
    required this.label,
    required this.selectionController,
    required this.graphData,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Edit color and label for $label',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.large,
            vertical: AppPadding.small,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<ChartSelectionState<GraphPoint, DateTime>>(
                valueListenable: selectionController,
                builder: (context, selectionState, child) {
                  final hits = selectionState.results;
                  return Container(
                    width: 28.0,
                    height: 28.0,
                    margin: const EdgeInsets.only(right: AppPadding.medium),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: hits.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          )
                        : null,
                  );
                },
              ),
              Expanded(
                child: AsyncValueDefaults(
                  value: graphData,
                  onData: (loadedData) {
                    final bool hasData = loadedData.containsKey(graphKey);

                    return ValueListenableBuilder<
                        ChartSelectionState<GraphPoint, DateTime>>(
                      valueListenable: selectionController,
                      builder: (context, selectionState, child) {
                        final hits = selectionState.results;
                        String detailText = "";

                        if (hits.isNotEmpty) {
                          for (final h in hits) {
                            final myResponses = loadedData[graphKey];
                            if (myResponses != null &&
                                myResponses
                                    .any((r) => h.item.data.contains(r))) {
                              final isScatter = h.yValue > 0 &&
                                  h.yValue.toInt() != h.yValue.toDouble();
                              final String valStr = isScatter
                                  ? h.yValue.toStringAsFixed(1)
                                  : h.yValue.toInt().toString();

                              final List<Stamp> stamps = h.item.data;
                              List<Response> flat = [];
                              for (final s in stamps) {
                                if (s
                                    case DetailResponse(
                                      :List<Response> responses
                                    )) {
                                  flat.addAll(responses);
                                } else if (s case Response()) {
                                  flat.add(s);
                                }
                              }
                              if (flat.isEmpty &&
                                  stamps.isNotEmpty &&
                                  stamps.first is Response) {
                                flat = stamps.whereType<Response>().toList();
                              }

                              String? summary;
                              if (flat.isNotEmpty) {
                                summary = _formatResponseSummary(context, flat);
                              }
                              detailText =
                                  "$valStr${summary != null ? ' ($summary)' : ''}";
                              break;
                            }
                          }
                        }

                        final labelText = RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: hasData
                                      ? null
                                      : Theme.of(context).disabledColor,
                                ),
                            children: [
                              TextSpan(text: label),
                            ],
                          ),
                        );

                        // Only show detail if present, no reserved space
                        if (detailText.isEmpty) return labelText;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            labelText,
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                detailText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onError: (_) => Text(
                    graphKey.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
              ValueListenableBuilder<ChartSelectionState<GraphPoint, DateTime>>(
                valueListenable: selectionController,
                builder: (context, selectionState, child) {
                  final hits = selectionState.results;
                  if (onRemove == null || hits.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    tooltip: 'Remove symptom from graph',
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatResponseSummary(BuildContext context, List<Response> flat) {
    if (flat.isEmpty) return null;

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final first = flat.first;
    if (first is NumericResponse) {
      if (flat.length > 1) {
        final double avg = flat
                .whereType<NumericResponse>()
                .map((e) => e.response)
                .reduce((a, b) => a + b) /
            flat.length;
        return "Avg: ${avg.toStringAsFixed(1)}";
      }
      return null;
    }

    final Map<String, int> counts = {};
    for (final res in flat) {
      if (res is MultiResponse) {
        if (res.index < res.question.choices.length) {
          final choice = res.question.choices[res.index];
          counts[choice] = (counts[choice] ?? 0) + 1;
        }
      } else if (res is AllResponse) {
        for (final index in res.responses) {
          if (index < res.question.choices.length) {
            final choice = res.question.choices[index];
            counts[choice] = (counts[choice] ?? 0) + 1;
          }
        }
      }
    }

    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final String tops = sorted.take(2).map((e) {
      final String choiceLabel = localizations?.value(e.key) ?? e.key;
      return "$choiceLabel: ${e.value}";
    }).join(", ");

    return tops.isEmpty ? null : tops;
  }
}
