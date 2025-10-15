import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/graph_packets.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/show_stripes_sheet.dart';

import '../../../Util/paddings.dart';

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
  List<GraphKey> additions = [];

  @override
  Widget build(BuildContext context) {
    final GraphSettings settings = ref.watch(graphSettingsProvider);
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
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large,
              right: AppPadding.large,
              top: AppPadding.large),
          child: Row(
            children: [
              IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(Icons.keyboard_arrow_left)),
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
        const GraphControlArea(
          showsYAxis: false,
          hasDivider: false,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppPadding.large,
              right: AppPadding.large,
              top: AppPadding.small),
          child: AspectRatio(
            aspectRatio: 2.0,
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
                          settings: settings,
                          isDetailed: true),
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
                      final GraphKey? result = await toggleKeySelect(context);
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
              FilledButton.icon(
                onPressed: () {},
                label: const Text("Share"),
                icon: const Icon(Icons.upload),
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
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.large,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                        color: forGraphKey(key), shape: BoxShape.circle),
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
                          key.toLocalizedString(context),
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
                  key != widget.graphKey
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              additions.remove(key);
                            });
                          },
                          icon: const Icon(Icons.remove_circle),
                        )
                      : SizedBox(
                          height:
                              (Theme.of(context).iconTheme.size ?? 24) + 16.0,
                        ),
                ],
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

  Future<GraphKey?> toggleKeySelect(BuildContext context) {
    return showStripesSheet<GraphKey?>(
        context: context,
        scrollControlled: true,
        sheetBuilder: (context, controller) {
          return ListSection(
            controller: controller,
            onSelect: (key) {
              Navigator.pop(context, key);
            },
            includesControls: false,
            excludedKeys: [widget.graphKey, ...additions],
          );
        });
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
    final GraphSettings settings = ref.watch(graphSettingsProvider);

    final AsyncValue<Map<GraphKey, List<Response>>> graphs =
        ref.watch(graphStampsProvider);

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
        AsyncValueDefaults(
          value: graphs,
          onData: (data) {
            final Map<GraphKey, List<Response>> withKeysRemoved =
                Map.fromEntries(
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
            return SliverList.separated(
              itemBuilder: (context, index) {
                final GraphKey key = withKeysRemoved.keys.elementAt(index);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    onSelect(key);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                    child: GraphSymptomRow(
                        responses: withKeysRemoved[key]!,
                        graphKey: key,
                        settings: settings),
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
                        color: Theme.of(context)
                            .disabledColor
                            .withValues(alpha: 0.3),
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
        ),
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.xxl)),
      ],
    );
  }
}

class GraphSymptomRow extends StatelessWidget {
  final List<Response> responses;

  final GraphKey graphKey;

  final GraphSettings settings;

  final bool hasHero;

  const GraphSymptomRow(
      {required this.responses,
      required this.graphKey,
      required this.settings,
      this.hasHero = true,
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
          child: AspectRatio(
            aspectRatio: 2.0,
            child: Container(
              height: 80.0,
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
                          settings: settings,
                          isDetailed: false),
                    )
                  : GraphSymptom(
                      responses: {graphKey: responses},
                      settings: settings,
                      isDetailed: false),
            ),
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
    final GraphSettings settings = ref.watch(graphSettingsProvider);

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
                      if (details.delta.dx > dragSpeed &&
                          settings.canShift(forward: false)) {
                        ref.read(graphSettingsProvider.notifier).state =
                            settings.shift(false);
                      } else if (details.delta.dx < -dragSpeed &&
                          settings.canShift(forward: true)) {
                        ref.read(graphSettingsProvider.notifier).state =
                            settings.shift(true);
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
                          onPressed: settings.canShift(forward: false)
                              ? () {
                                  ref
                                      .read(graphSettingsProvider.notifier)
                                      .state = settings.shift(false);
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
                                  ref
                                      .read(graphSettingsProvider.notifier)
                                      .state = settings.shift(true);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: AppPadding.large,
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
                        width: AppPadding.tiny,
                      )),
                ],
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: AppPadding.large,
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
                        width: AppPadding.tiny,
                      )),
                ],
              ),
            ),
          ],
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
