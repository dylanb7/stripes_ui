import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:collection/collection.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
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

class GraphViewScreen extends ConsumerStatefulWidget {
  final GraphKey graphKey;

  const GraphViewScreen({required this.graphKey, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _GraphViewScreenState();
  }
}

class _GraphViewScreenState extends ConsumerState<GraphViewScreen> {
  final List<GraphKey> additions = [];
  final Map<GraphKey, Color> colorKeys = {};
  final Map<GraphKey, String> customLabels = {};
  final ChartSelectionController<GraphPoint, DateTime> _selectionController =
      ChartSelectionController();

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final AsyncValue<Map<GraphKey, List<Response>>> graphData =
        ref.watch(graphStampsProvider);

    Widget addLayerButton({void Function()? onPressed}) {
      return FilledButton.icon(
        onPressed: onPressed,
        label: const Text("Add Layer"),
        icon: const Icon(Icons.add),
      );
    }

    return GraphScreenWrap(
        scrollable: ListView(
      children: [
        GraphViewHeader(
          graphData: graphData,
          selectionController: _selectionController,
          settings: settings,
          baseKey: widget.graphKey,
          additions: additions,
          customLabels: customLabels,
          colorKeys: colorKeys,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large,
              right: AppPadding.large,
              top: AppPadding.small),
          child: Hero(
            tag: widget.graphKey,
            child: AsyncValueDefaults(
              value: graphData,
              onData: (loadedData) {
                Map<GraphKey, List<Response>> forGraph = {};
                for (final GraphKey key in [widget.graphKey, ...additions]) {
                  if (loadedData.containsKey(key)) {
                    forGraph[key] = loadedData[key]!;
                  }
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                        Radius.circular(AppRounding.tiny)),
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.tiny),
                    child: GraphSymptom(
                      responses: forGraph,
                      isDetailed: true,
                      forExport: false,
                      colorKeys: colorKeys,
                      selectionController: _selectionController,
                    ),
                  ),
                );
              },
              onLoading: (_) {
                return DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(AppRounding.small)),
                        color: Theme.of(context).disabledColor));
              },
            ),
          ),
        ),
        const SizedBox(
          height: AppPadding.medium,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large,
              right: AppPadding.large,
              top: AppPadding.small),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AsyncValueDefaults(
                value: graphData,
                onData: (loadedData) {
                  final Iterable<GraphKey> keys = loadedData.keys;
                  final bool hasValuesToAdd = keys
                      .where((element) =>
                          ![...additions, widget.graphKey].contains(element))
                      .isNotEmpty;
                  if (!hasValuesToAdd) return addLayerButton();
                  return addLayerButton(
                    onPressed: () async {
                      final GraphKey? result =
                          await toggleKeySelect(context, ref);
                      if (result != null) {
                        setState(() {
                          additions.add(result);
                        });
                      }
                    },
                  );
                },
                onLoading: (_) => addLayerButton(),
                onError: (_) => addLayerButton(),
              ),
              Tooltip(
                message: 'Share Graph',
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(sheetControllerProvider).show(
                          context: context,
                          scrollControlled: true,
                          child: (context) => GraphExportSheet(
                            graphKey: widget.graphKey,
                            additions: additions,
                            colorKeys: colorKeys,
                            customLabels: customLabels,
                          ),
                        );
                  },
                  label: const Text("Share"),
                  icon: const Icon(
                    Icons.ios_share,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: AppPadding.medium,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large, right: AppPadding.large),
          child: Text(
            "displaying",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ),
        ...[widget.graphKey, ...additions].map(
          (key) {
            final String label =
                customLabels[key] ?? key.toLocalizedString(context);
            return Tooltip(
              message: 'Edit color and label for $label',
              child: InkWell(
                onTap: () async {
                  final GraphEditResult? result = await ref
                      .read(sheetControllerProvider)
                      .show<GraphEditResult>(
                        context: context,
                        scrollControlled: true,
                        child: (context) => ColorPickerSheet(
                          currentColor: colorKeys[key] ?? forGraphKey(key),
                          currentLabel: customLabels[key] ??
                              key.toLocalizedString(context),
                        ),
                      );

                  if (result != null) {
                    setState(() {
                      colorKeys[key] = result.color;
                      if (result.label != null) {
                        customLabels[key] = result.label!;
                      }
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.large,
                    vertical: AppPadding.tiny,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                            color: colorKeys[key] ?? forGraphKey(key),
                            shape: BoxShape.circle),
                        child: Center(
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: (colorKeys[key] ?? forGraphKey(key))
                                        .computeLuminance() >
                                    0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppPadding.medium,
                      ),
                      Expanded(
                        child: AsyncValueDefaults(
                          value: graphData,
                          onData: (loadedData) {
                            final bool hasData = loadedData.containsKey(key);

                            return Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: hasData
                                          ? null
                                          : Theme.of(context).disabledColor),
                            );
                          },
                          onError: (_) => Text(
                            key.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          onLoading: (_) => Text(
                            key.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppPadding.medium,
                      ),
                      if (key != widget.graphKey)
                        IconButton(
                          tooltip: 'Remove symtpom from graph',
                          onPressed: () {
                            setState(() {
                              additions.remove(key);
                              colorKeys.remove(key);
                              customLabels.remove(key);
                            });
                          },
                          icon: const Icon(Icons.remove_circle),
                        )
                    ],
                  ),
                ),
              ),
            );
          },
        ).separated(by: const Divider(), includeEnds: true),
        const SizedBox(
          height: AppPadding.xxl,
        )
      ],
    ));
  }

  Future<GraphKey?> toggleKeySelect(BuildContext context, WidgetRef ref) {
    return ref.read(sheetControllerProvider).show<GraphKey?>(
          context: context,
          scrollControlled: true,
          sheetBuilder: (context, controller) => ListSection(
            controller: controller,
            onSelect: (key) {
              Navigator.pop(context, key);
            },
            includesControls: false,
            excludedKeys: [widget.graphKey, ...additions],
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
            MediaQuery.of(context).size.width > Breakpoint.large.value;

        if (isLargeScreen) {
          int crossAxisCount = (MediaQuery.of(context).size.width / 500).ceil();
          if (crossAxisCount < 1) crossAxisCount = 1;

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
                                  compact: false,
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
                    compact: true,
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

  final bool compact;

  const GraphSymptomRow(
      {required this.responses,
      required this.graphKey,
      this.hasHero = true,
      this.compact = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (compact) {
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
                        child: GraphSymptom(
                            responses: {graphKey: responses},
                            isDetailed: false),
                      )
                    : GraphSymptom(
                        responses: {graphKey: responses}, isDetailed: false),
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
              aspectRatio: 2.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
                padding: const EdgeInsets.all(AppPadding.small),
                child: hasHero
                    ? Hero(
                        tag: graphKey,
                        child: GraphSymptom(
                            responses: {graphKey: responses},
                            isDetailed: false),
                      )
                    : GraphSymptom(
                        responses: {graphKey: responses}, isDetailed: false),
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
            maxWidth: Breakpoint.tiny.value,
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
                "showing",
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
                child: SegmentedButton<GraphYAxis>(
                  segments: GraphYAxis.values
                      .map((axis) => ButtonSegment<GraphYAxis>(
                            value: axis,
                            label: Text(axis.value),
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

class ColorPickerSheet extends StatefulWidget {
  final Color currentColor;
  final String currentLabel;

  const ColorPickerSheet({
    required this.currentColor,
    required this.currentLabel,
    super.key,
  });

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  Color? selectedColor;
  final List<Color> colorPalette = [
    ...Colors.primaries,
  ];
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colorPalette = [
      ...Colors.primaries,
    ];

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'Edit Layer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ]),
          const SizedBox(height: AppPadding.medium),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppPadding.medium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: AppPadding.small,
              mainAxisSpacing: AppPadding.small,
            ),
            itemCount: colorPalette.length,
            itemBuilder: (context, index) {
              final color = colorPalette[index];
              final isSelected =
                  (selectedColor ?? widget.currentColor).toARGB32() ==
                      color.toARGB32();
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(AppRounding.small),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRounding.small),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: AppPadding.medium),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                GraphEditResult(
                  color: selectedColor ?? widget.currentColor,
                  label: _controller.text != widget.currentLabel
                      ? _controller.text
                      : null,
                ),
              );
            },
            child: const Center(child: Text('Save')),
          ),
        ],
      ),
    );
  }
}

class GraphExportSheet extends ConsumerStatefulWidget {
  final GraphKey graphKey;
  final List<GraphKey> additions;
  final Map<GraphKey, Color> colorKeys;
  final Map<GraphKey, String> customLabels;

  const GraphExportSheet({
    required this.graphKey,
    required this.additions,
    required this.colorKeys,
    required this.customLabels,
    super.key,
  });

  @override
  ConsumerState<GraphExportSheet> createState() => _GraphExportSheetState();
}

class _GraphExportSheetState extends ConsumerState<GraphExportSheet> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/graph_export.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;

      final RenderBox? box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<GraphKey, List<Response>>> graphData =
        ref.watch(graphStampsProvider);

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Export Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRounding.small),
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: Breakpoint.medium.value),
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.all(AppPadding.medium),
                        child: AsyncValueDefaults(
                          value: graphData,
                          onData: (loadedData) {
                            Map<GraphKey, List<Response>> forGraph = {};
                            for (final GraphKey key in [
                              widget.graphKey,
                              ...widget.additions
                            ]) {
                              if (loadedData.containsKey(key)) {
                                forGraph[key] = loadedData[key]!;
                              }
                            }
                            return GraphSymptom(
                              responses: forGraph,
                              isDetailed: true,
                              forExport: true,
                              colorKeys: widget.colorKeys,
                              customLabels: widget.customLabels,
                            );
                          },
                          onLoading: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          onError: (_) =>
                              const Center(child: Text("Error loading data")),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          FilledButton.icon(
            onPressed: _isSharing ? null : _shareImage,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.ios_share,
                  ),
            label: Text(_isSharing ? 'Preparing...' : 'Share'),
          ),
        ],
      ),
    );
  }
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
    return Padding(
      padding: const EdgeInsets.only(
          left: AppPadding.large,
          right: AppPadding.large,
          top: AppPadding.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              tooltip: 'Back',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.keyboard_arrow_left)),
          const SizedBox(
            width: AppPadding.tiny,
          ),
          Expanded(
            child: AsyncValueDefaults(
              value: graphData,
              onData: (loadedData) {
                return ValueListenableBuilder<
                    ChartSelectionState<GraphPoint, DateTime>>(
                  valueListenable: selectionController,
                  builder: (context, selectionState, child) {
                    final List<ChartHitTestResult<GraphPoint, DateTime>> hits =
                        selectionState.results;
                    final Offset? hoverPos = selectionState.hoverPosition;

                    if (hits.isEmpty) {
                      String titleText = "Symptom Trends";
                      if (additions.isEmpty) {
                        titleText = baseKey.toLocalizedString(context);
                      } else if (additions.length == 1) {
                        titleText = "Symptom Comparison";
                      } else {
                        titleText = "Combined Insights";
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titleText,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            settings.getRangeString(context),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }

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

                    final List<Widget> detailLines = [];
                    for (final h in hits) {
                      final String valStr = isScatter
                          ? h.yValue.toStringAsFixed(1)
                          : h.yValue.toInt().toString();

                      final GraphKey graphKey =
                          loadedData.keys.elementAt(h.datasetIndex);
                      final String label = customLabels[graphKey] ??
                          graphKey.toLocalizedString(context);

                      final List<Stamp> stamps = h.item.data;
                      List<Response> flat = [];
                      for (final s in stamps) {
                        if (s case DetailResponse(:List<Response> responses)) {
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

                      String? detailLine;
                      if (flat.isNotEmpty) {
                        detailLine = _formatResponseSummary(
                            context, flat, stamps.length);
                      }
                      final color =
                          colorKeys[graphKey] ?? forGraphKey(graphKey);
                      detailLines.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "$label: $valStr${detailLine != null ? ' ($detailLine)' : ''}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final Widget details = IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: detailLines,
                      ),
                    );

                    final dateTag = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        format.format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    );

                    return LayoutBuilder(builder: (context, constraints) {
                      final double halfWidth = constraints.maxWidth / 2;

                      // Correction factor: Chart is indented by (P.large + P.tiny) = 20
                      // Header Expanded starts after (P.tiny + button + P.tiny) = 56
                      // Diff is 36. To align hoverPos.dx (relative to chart) with header x:
                      // headerX = hoverPos.dx - 36
                      final double xInHeader =
                          hoverPos != null ? hoverPos.dx - 36 : halfWidth;

                      final double shift = xInHeader - halfWidth;

                      // Clamp shift to keep pill within header
                      // Pill is approx 100px wide
                      const double pillHalfWidth = 50.0;
                      final double maxShift = halfWidth - pillHalfWidth - 8;
                      final double clampedShift =
                          shift.clamp(-maxShift, maxShift);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(clampedShift, 0),
                            child: dateTag,
                          ),
                          const SizedBox(height: 6),
                          details,
                        ],
                      );
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(
            width: AppPadding.tiny,
          ),
          SizedBox(
            width: IconTheme.of(context).size ?? 24.0 + 16.0,
          ),
        ],
      ),
    );
  }

  String? _formatResponseSummary(
      BuildContext context, List<Response> flat, int totalStamps) {
    if (flat.isEmpty) return null;

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final first = flat.first;
    switch (first) {
      case NumericResponse():
        final double avg =
            flat.whereType<NumericResponse>().map((e) => e.response).average;
        return "Avg: ${avg.toStringAsFixed(1)}";
      case MultiResponse():
      case AllResponse():
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
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final String tops = sorted.take(2).map((e) {
          final String choiceLabel = localizations?.value(e.key) ?? e.key;
          return "$choiceLabel: ${e.value}";
        }).join(", ");
        return tops;
      case BlueDyeResp():
      case OpenResponse():
      case Selected():
      default:
        return "Total: $totalStamps";
    }
  }
}
