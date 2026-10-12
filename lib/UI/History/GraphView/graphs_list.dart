import 'package:stripes_ui/UI/History/GraphView/graph_hero.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom_type_chip.dart';

import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';

import 'package:stripes_ui/Util/extensions.dart';

import '../../../Util/Design/paddings.dart';

import 'package:stripes_ui/Util/Design/palette.dart' as palette;
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';

class ListSection extends StatelessWidget {
  final List<GraphKey> excludedKeys;
  final Function(GraphKey) onSelect;

  /// Called when a category header is tapped with all the individual question
  /// keys under that category.  When null, category headers are not tappable.
  final void Function(List<GraphKey> keys)? onCategorySelect;
  final ScrollController? controller;

  const ListSection({
    required this.onSelect,
    this.onCategorySelect,
    this.excludedKeys = const [],
    this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.small)),
        GraphSliverList(
          onSelect: onSelect,
          onCategorySelect: onCategorySelect,
          excludedKeys: excludedKeys,
        ),
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.xxl)),
      ],
    );
  }
}

class GraphSliverList extends ConsumerStatefulWidget {
  final Function(GraphKey) onSelect;

  final void Function(List<GraphKey> keys)? onCategorySelect;
  final List<GraphKey> excludedKeys;

  const GraphSliverList({
    required this.onSelect,
    this.onCategorySelect,
    this.excludedKeys = const [],
    super.key,
  });

  @override
  ConsumerState<GraphSliverList> createState() => _GraphSliverListState();
}

class _GraphSliverListState extends ConsumerState<GraphSliverList> {
  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);

    final AsyncValue<Map<GraphKey, List<Response>>> graphs = ref.watch(
      graphStampsProvider,
    );

    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap = reviewPathsAsync.value ?? {};

    return AsyncValueDefaults(
      value: graphs,
      onData: (data) {
        final Map<GraphKey, List<Response>> withKeysRemoved = Map.fromEntries(
          data.keys
              .where((key) => !widget.excludedKeys.contains(key))
              .map((key) => MapEntry(key, data[key]!)),
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

        // Group keys by category (key.type), preserving order of first encounter
        final QuestionsLocalizations? loc = QuestionsLocalizations.of(context);
        final List<GraphKey> allKeys = withKeysRemoved.keys.toList();

        final bool isLargeScreen =
            MediaQuery.of(context).size.width > Breakpoint.medium.value &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;

        // Build ordered list of (categoryName, [keys]) groups
        final Map<String, List<GraphKey>> grouped = {};
        // Collect category-level aggregate keys keyed by their raw type
        final Map<String, GraphKey> categoryKeys = {};
        for (final key in allKeys) {
          final String cat = key.type ?? key.title;
          if (key.isCategory) {
            categoryKeys[cat] = key;
            grouped.putIfAbsent(cat, () => []);
          } else {
            grouped.putIfAbsent(cat, () => []).add(key);
          }
        }

        // A saved event can have no answers. Keep its category visible without
        // duplicating category graphs beside ordinary question graphs.
        for (final category in grouped.entries) {
          if (category.value.isEmpty && categoryKeys[category.key] != null) {
            category.value.add(categoryKeys[category.key]!);
          }
        }
        int eventCount(String category, List<GraphKey> keys) {
          final parentResponses = withKeysRemoved[categoryKeys[category]];
          if (parentResponses != null) return parentResponses.length;
          return {
            for (final key in keys)
              for (final response in withKeysRemoved[key] ?? <Response>[])
                recordIdentityForResponse(response),
          }.length;
        }

        final List<String> labels = grouped.entries
            .map((e) => loc?.value(e.key) ?? e.key)
            .toList()
            .cast<String>();

        if (isLargeScreen) {
          // Large screen: section label row above each category grid block
          int crossAxisCount = (MediaQuery.of(context).size.width / 400).ceil();
          if (crossAxisCount < 2) crossAxisCount = 2;

          final List<Widget> outerSlivers = [];
          int labelIdx = 0;
          for (final entry in grouped.entries) {
            final String rawCat = entry.key;
            final String catLabel = labels[labelIdx++];
            final List<GraphKey> catKeys = entry.value;
            final int rowCount = (catKeys.length / crossAxisCount).ceil();
            final List<Widget> categorySlivers = [];

            // Section label
            categorySlivers.add(
              _categoryHeaderSliver(
                _CategoryHeader(
                  label: catLabel,
                  rawName: rawCat,
                  entryCount: eventCount(rawCat, catKeys),
                  onCategoryTap: widget.onCategorySelect != null
                      ? () => widget.onCategorySelect!(catKeys)
                      : null,
                ),
              ),
            );

            // Grid rows for this category
            categorySlivers.add(
              SliverList.builder(
                itemCount: rowCount,
                itemBuilder: (context, rowIndex) {
                  final int startIndex = rowIndex * crossAxisCount;
                  final int endIndex = (startIndex + crossAxisCount)
                      .coerceAtMost(catKeys.length);
                  final List<GraphKey> rowKeys = catKeys.sublist(
                    startIndex,
                    endIndex,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppPadding.large),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.xl,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...rowKeys.map(
                            (key) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small,
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => widget.onSelect(key),
                                  child: GraphSymptomRow(
                                    responses: withKeysRemoved[key]!,
                                    graphKey: key,
                                    useRowLayout: false,
                                    reviewPaths: reviewPathsMap,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ...List.generate(
                            crossAxisCount - rowKeys.length,
                            (_) => const Expanded(child: SizedBox()),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );

            outerSlivers.add(SliverMainAxisGroup(slivers: categorySlivers));
          }

          return SliverMainAxisGroup(slivers: outerSlivers);
        }

        final List<Widget> outerSlivers = [];
        int labelIdx = 0;
        for (final entry in grouped.entries) {
          final String rawCat = entry.key;
          final String catLabel = labels[labelIdx++];
          final List<GraphKey> catKeys = entry.value;
          final List<Widget> categorySlivers = [];

          categorySlivers.add(
            _categoryHeaderSliver(
              _CategoryHeader(
                label: catLabel,
                rawName: rawCat,
                entryCount: eventCount(rawCat, catKeys),
                onCategoryTap: widget.onCategorySelect != null
                    ? () => widget.onCategorySelect!(catKeys)
                    : null,
              ),
            ),
          );

          // Items within this category
          categorySlivers.add(
            SliverList.separated(
              itemCount: catKeys.length,
              itemBuilder: (context, index) {
                final GraphKey key = catKeys[index];
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onSelect(key),
                  child: MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.xl,
                      ),
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
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppPadding.xl),
                child: Divider(height: 1),
              ),
            ),
          );

          outerSlivers.add(SliverMainAxisGroup(slivers: categorySlivers));
        }

        return SliverMainAxisGroup(slivers: outerSlivers);
      },
      onError: (error) => SliverToBoxAdapter(
        child: Center(
          child: Text(
            error.error.toString(),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      onLoading: (_) => SliverList.separated(
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.xl,
              vertical: AppPadding.tiny,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 0.9),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              onEnd: null,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: ((index % 2 == 0) ? opacity : (1.1 - opacity)).clamp(
                    0.3,
                    0.9,
                  ),
                  child: child,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 88.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor
                            .withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRounding.small),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: 5,
      ),
    );
  }
}

class GraphSymptomRow extends ConsumerWidget {
  final List<Response> responses;

  final GraphKey graphKey;

  final bool hasHero;

  final bool useRowLayout;

  final Map<String, RecordPath>? reviewPaths;

  const GraphSymptomRow({
    required this.responses,
    required this.graphKey,
    this.hasHero = true,
    this.useRowLayout = false,
    this.reviewPaths,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool colored = ref.watch(configProvider).betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(
      graphKey.type ?? graphKey.title,
    );

    if (useRowLayout) {
      final Color keyColor = palette.forGraphKey(graphKey);
      final Color chartBg = colored
          ? appearance.color.withValues(alpha: 0.12)
          : keyColor.withValues(alpha: 0.06);
      final chart = Container(
        decoration: BoxDecoration(
          color: chartBg,
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasHero
            ? Hero(
                tag: graphKey,
                flightShuttleBuilder: graphHeroShuttle,
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
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.medium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  graphKey.toLocalizedString(context),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: stacked ? null : 2,
                  overflow: stacked ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppPadding.tiny),
                _GraphMetadata(
                  responses: responses,
                  isCategory: graphKey.isCategory,
                ),
              ],
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: AppPadding.tiny),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: AppPadding.medium),
                  chart,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 4, child: heading),
                const SizedBox(width: AppPadding.small),
                Expanded(flex: 3, child: chart),
                const SizedBox(width: AppPadding.tiny),
                const Icon(Icons.chevron_right, size: 20),
              ],
            );
          },
        ),
      );
    }
    // Card layout (tablet grid)
    final Color keyColor = palette.forGraphKey(graphKey);
    final Color chartBg = colored
        ? appearance.color.withValues(alpha: 0.18)
        : keyColor.withValues(alpha: 0.10);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        graphKey.toLocalizedString(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _GraphMetadata(
                        responses: responses,
                        isCategory: graphKey.isCategory,
                      ),
                    ],
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
                  color: chartBg,
                  borderRadius: BorderRadius.circular(AppRounding.small),
                  boxShadow: [
                    BoxShadow(
                      color: keyColor.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                  vertical: AppPadding.tiny,
                ),
                child: hasHero
                    ? Hero(
                        tag: graphKey,
                        flightShuttleBuilder: graphHeroShuttle,
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

class _GraphMetadata extends StatelessWidget {
  final List<Response> responses;
  final bool isCategory;

  const _GraphMetadata({required this.responses, required this.isCategory});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppPadding.small,
      runSpacing: AppPadding.tiny,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!isCategory) SymptomTypeChip(responses: responses),
        if (responses.isNotEmpty)
          Text(
            '${responses.length} ${isCategory ? 'events' : 'answers'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
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
              depth: RefreshDepth.subuser,
              scrollable: scrollable,
            ),
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
  final GraphSelectionController selectionController;
  final DisplayDataSettings settings;
  final GraphKey baseKey;
  final List<GraphKey> additions;

  const GraphViewHeader({
    super.key,
    required this.selectionController,
    required this.settings,
    required this.baseKey,
    required this.additions,
  });

  @override
  Widget build(BuildContext context) {
    final String mainTitle = additions.isEmpty
        ? baseKey.toLocalizedString(context)
        : (additions.length == 1 ? 'Symptom Comparison' : 'Combined Trends');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.small,
        AppPadding.small,
        AppPadding.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ValueListenableBuilder<GraphSelectionState>(
              valueListenable: selectionController,
              builder: (context, state, _) {
                final selectedBin = state.bin;
                final selecting = state.items.isNotEmpty && selectedBin != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      selecting
                          ? selectedBin.label
                          : settings.getRangeString(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selecting
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: selecting ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Close graph',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class SymptomListItem extends StatelessWidget {
  final GraphKey graphKey;
  final Color color;
  final String label;
  final AsyncValue<Map<GraphKey, List<Response>>> graphData;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const SymptomListItem({
    super.key,
    required this.graphKey,
    required this.color,
    required this.label,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Color dot — shows edit icon; color dot is always visible
              Container(
                width: 28.0,
                height: 28.0,
                margin: const EdgeInsets.only(right: AppPadding.medium),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
              // Label + type chip + count — always the idle state
              Expanded(
                child: AsyncValueDefaults(
                  value: graphData,
                  onData: (loadedData) {
                    final List<Response> responses = loadedData[graphKey] ?? [];
                    final bool hasData = loadedData.containsKey(graphKey);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: hasData
                                    ? null
                                    : Theme.of(context).disabledColor,
                              ),
                        ),
                        const SizedBox(height: AppPadding.tiny),
                        _GraphMetadata(
                          responses: responses,
                          isCategory: graphKey.isCategory,
                        ),
                      ],
                    );
                  },
                  onError: (_) => Text(
                    graphKey.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              ),
              // Remove button — always visible for removable layers
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove symptom from graph',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section label with an optional tappable link to open all questions under
/// this category as separate datasets in a comparison graph.
class _CategoryHeader extends ConsumerWidget {
  final String label;
  final String rawName;

  /// Distinct saved events in this category.
  final int entryCount;

  /// Called when the category link is tapped. Null disables the link.
  final VoidCallback? onCategoryTap;
  const _CategoryHeader({
    required this.label,
    required this.rawName,
    this.entryCount = 0,
    this.onCategoryTap,
  });

  ({bool stacked, double height}) layout(BuildContext context, double width) {
    final textTheme = Theme.of(context).textTheme;
    Size measure(
      String text,
      TextStyle? style, [
      double maxWidth = double.infinity,
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout(maxWidth: maxWidth);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    // Reserve the category icon even when it is disabled so changing its
    // appearance never causes the pinned heading to clip.
    final available = math.max(
      1.0,
      width - 40 - 4 - 8 - 26 - (onCategoryTap == null ? 0 : 18),
    );
    final titleStyle = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    );
    final countStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final title = measure(label, titleStyle);
    final count = onCategoryTap == null
        ? Size.zero
        : measure('$entryCount events', countStyle);
    final stacked = title.width + count.width + 8 > available;
    final titleHeight = measure(
      label,
      titleStyle,
      stacked ? available : math.max(1, available - count.width - 8),
    ).height;
    final countHeight = count == Size.zero
        ? 0.0
        : measure('$entryCount events', countStyle, available).height;
    return (
      stacked: stacked,
      height:
          16 +
          math.max(
            20,
            stacked
                ? titleHeight + (countHeight > 0 ? countHeight + 2 : 0)
                : math.max(titleHeight, countHeight),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bool themed = ref.watch(configProvider).betaUi.useCategoryTheme;
    final bool colored = ref.watch(configProvider).betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(rawName);

    final Color dividerColor = colored ? appearance.color : cs.primary;
    final Color baseSurface = Theme.of(context).colorScheme.surface;
    final Color bgColor = Color.alphaBlend(
      (colored ? appearance.color : cs.primaryContainer).withValues(
        alpha: colored ? 0.15 : 0.20,
      ),
      baseSurface,
    );

    return GestureDetector(
      onTap: onCategoryTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(
          AppPadding.xl,
          AppPadding.small,
          AppPadding.xl,
          AppPadding.small,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = layout(context, constraints.maxWidth + 40).stacked;
            final title = Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: dividerColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            );
            final count = Text(
              '$entryCount events',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: dividerColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                if (themed) ...[
                  CategoryIcon(appearance: appearance, size: 18),
                  const SizedBox(width: AppPadding.small),
                ],
                Expanded(
                  child: stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            if (onCategoryTap != null) ...[
                              const SizedBox(height: 2),
                              count,
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: title),
                            if (onCategoryTap != null) ...[
                              const SizedBox(width: AppPadding.small),
                              count,
                            ],
                          ],
                        ),
                ),
                if (onCategoryTap != null) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: dividerColor),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _categoryHeaderSliver(_CategoryHeader header) {
  return SliverLayoutBuilder(
    builder: (context, constraints) => SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryHeaderDelegate(
        extent: header.layout(context, constraints.crossAxisExtent).height,
        child: header,
      ),
    ),
  );
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;
  const _CategoryHeaderDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(_CategoryHeaderDelegate old) =>
      old.child != child || old.extent != extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }
}
