import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_context_caption.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_hero.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/palette.dart' as palette;
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class GraphViewParams {
  final GraphKey graphKey;
  final List<GraphKey> initialAdditions;

  const GraphViewParams({
    required this.graphKey,
    this.initialAdditions = const [],
  });

  Map<String, dynamic> toJson() => {
    '__type': 'GraphViewParams',
    'graphKey': graphKey.toJson()..['__type'] = 'GraphKey',
    'initialAdditions': initialAdditions
        .map((k) => k.toJson()..['__type'] = 'GraphKey')
        .toList(),
  };

  factory GraphViewParams.fromJson(Map<String, dynamic> json) {
    return GraphViewParams(
      graphKey: GraphKey.fromJson(json['graphKey'] as Map<String, dynamic>),
      initialAdditions:
          (json['initialAdditions'] as List<dynamic>?)
              ?.map((e) => GraphKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class GraphViewScreen extends ConsumerStatefulWidget {
  final GraphKey graphKey;

  final List<GraphKey> initialAdditions;

  const GraphViewScreen({
    required this.graphKey,
    this.initialAdditions = const [],
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _GraphViewScreenState();
  }
}

class _GraphViewScreenState extends ConsumerState<GraphViewScreen> {
  late final List<GraphKey> additions;
  final Map<GraphKey, Color> colorKeys = {};
  final Map<GraphKey, String> customLabels = {};
  final GraphSelectionController _selectionController =
      GraphSelectionController();
  GraphComparison _overviewMode = GraphComparison.stacked;

  @override
  void initState() {
    super.initState();
    additions = List<GraphKey>.from(widget.initialAdditions);
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final AsyncValue<Map<GraphKey, List<Response>>> graphData = ref.watch(
      graphStampsProvider,
    );
    final Map<GraphKey, List<Response>> loadedData =
        graphData.asData?.value ?? const <GraphKey, List<Response>>{};
    final Map<GraphKey, List<Response>> forGraph = <GraphKey, List<Response>>{
      for (final GraphKey key in <GraphKey>[widget.graphKey, ...additions])
        if (loadedData.containsKey(key)) key: loadedData[key]!,
    };
    final GraphComparison effectiveComparison = _resolveComparison(
      requested: _overviewMode,
      axis: settings.axis,
      responses: forGraph,
    );
    final bool canOverlay =
        _resolveComparison(
          requested: GraphComparison.overlaid,
          axis: settings.axis,
          responses: forGraph,
        ) ==
        GraphComparison.overlaid;
    final bool canStack =
        _resolveComparison(
          requested: GraphComparison.stacked,
          axis: settings.axis,
          responses: forGraph,
        ) ==
        GraphComparison.stacked;

    // Watch review paths to build reviewKeys map
    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap = reviewPathsAsync.when(
      data: (value) => value,
      loading: () => const {},
      error: (_, _) => const {},
    );

    return GraphScreenWrap(
      scrollable: ListView(
        children: [
          GraphViewHeader(
            selectionController: _selectionController,
            settings: settings,
            baseKey: widget.graphKey,
            additions: additions,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppPadding.large,
              right: AppPadding.large,
              top: AppPadding.small,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartCard = Material(
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.shadow
                      .withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRounding.small),
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.tiny),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRounding.tiny),
                      ),
                      child: graphData.when(
                        data: (_) => Hero(
                          tag: widget.graphKey,
                          flightShuttleBuilder: graphHeroShuttle,
                          child: GraphSymptom(
                            responses: forGraph,
                            isDetailed: true,
                            forExport: false,
                            colorKeys: colorKeys,
                            customLabels: customLabels,
                            selectionController: _selectionController,
                            mode: effectiveComparison,
                            reviewPaths: reviewPathsMap,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 190,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => const SizedBox(
                          height: 190,
                          child: Center(child: Text('Unable to load graph')),
                        ),
                      ),
                    ),
                  ),
                );

                // Inline data panel — AnimatedSize so it never causes a shift
                // above the chart card when transitioning idle <-> selecting.
                final dataPanel = ChartDataPanel(
                  selectionController: _selectionController,
                  axis: settings.axis,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chartCard,
                    dataPanel,
                    Card(
                      margin: const EdgeInsets.only(top: AppPadding.small),
                      child: GraphContextCaption(
                        graph: GraphPreparer.prepare(
                          responses: forGraph,
                          settings: settings,
                          comparison: effectiveComparison,
                          colorResolver: palette.forGraphKey,
                          colorOverrides: colorKeys,
                          labelOverrides: customLabels,
                          reviewPaths: reviewPathsMap,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppPadding.small),
          if (additions.isEmpty) ...[
            // Single layer: compact action bar + hint to compare
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap \u002b to compare with another symptom',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  AsyncValueDefaults(
                    value: graphData,
                    onData: (loadedData) {
                      final bool hasValuesToAdd = loadedData.keys
                          .where((e) => ![widget.graphKey].contains(e))
                          .isNotEmpty;
                      return IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Layer',
                        onPressed: hasValuesToAdd
                            ? () async {
                                final GraphKey? result = await toggleKeySelect(
                                  context,
                                  ref,
                                );
                                if (result != null) {
                                  setState(() => additions.add(result));
                                }
                              }
                            : null,
                      );
                    },
                    onLoading: (_) => const IconButton(
                      icon: Icon(Icons.add),
                      onPressed: null,
                    ),
                    onError: (_) => const IconButton(
                      icon: Icon(Icons.add),
                      onPressed: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Share Graph',
                    onPressed: () {
                      ref
                          .read(sheetControllerProvider)
                          .show(
                            context: context,
                            scrollControlled: true,
                            child: (context) => GraphExportSheet(
                              graphKey: widget.graphKey,
                              additions: additions,
                              colorKeys: colorKeys,
                              customLabels: customLabels,
                              mode: effectiveComparison,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
            // Editable row for the single base symptom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),
            SymptomListItem(
              graphKey: widget.graphKey,
              color:
                  colorKeys[widget.graphKey] ??
                  palette.forGraphKey(widget.graphKey),
              label:
                  customLabels[widget.graphKey] ??
                  widget.graphKey.toLocalizedString(context),
              graphData: graphData,
              onTap: () async {
                final GraphEditResult? res = await ref
                    .read(sheetControllerProvider)
                    .show<GraphEditResult>(
                      context: context,
                      scrollControlled: true,
                      child: (context) => ColorPickerSheet(
                        currentColor:
                            colorKeys[widget.graphKey] ??
                            palette.forGraphKey(widget.graphKey),
                        currentLabel:
                            customLabels[widget.graphKey] ??
                            widget.graphKey.toLocalizedString(context),
                      ),
                    );
                if (res != null) {
                  setState(() {
                    colorKeys[widget.graphKey] = res.color;
                    if (res.label != null) {
                      customLabels[widget.graphKey] = res.label!;
                    }
                  });
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),
          ] else ...[
            // Multi-layer: full "Displaying" section with category headers
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.large,
                vertical: AppPadding.small,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Displaying',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Mode selector
                  PopupMenuButton<GraphComparison>(
                    icon: Icon(
                      effectiveComparison == GraphComparison.stacked
                          ? Icons.stacked_bar_chart
                          : effectiveComparison == GraphComparison.separate
                          ? Icons.view_stream
                          : Icons.layers,
                    ),
                    tooltip: 'Change display mode',
                    onSelected: (GraphComparison value) {
                      setState(() => _overviewMode = value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: GraphComparison.separate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_stream,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            const Flexible(child: Text('Separate rows')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: GraphComparison.stacked,
                        enabled: canStack,
                        child: Row(
                          children: [
                            Icon(
                              Icons.stacked_bar_chart,
                              color: canStack
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).disabledColor,
                            ),
                            const SizedBox(width: 12),
                            const Flexible(child: Text('Stacked reports')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: GraphComparison.overlaid,
                        enabled: canOverlay,
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers,
                              color: canOverlay
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).disabledColor,
                            ),
                            const SizedBox(width: 12),
                            const Flexible(child: Text('Overlaid')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Add Layer button
                  AsyncValueDefaults(
                    value: graphData,
                    onData: (loadedData) {
                      final bool hasValuesToAdd = loadedData.keys
                          .where(
                            (e) => ![...additions, widget.graphKey].contains(e),
                          )
                          .isNotEmpty;
                      return IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Layer',
                        onPressed: hasValuesToAdd
                            ? () async {
                                final GraphKey? result = await toggleKeySelect(
                                  context,
                                  ref,
                                );
                                if (result != null) {
                                  setState(() => additions.add(result));
                                }
                              }
                            : null,
                      );
                    },
                    onLoading: (_) => const IconButton(
                      icon: Icon(Icons.add),
                      onPressed: null,
                    ),
                    onError: (_) => const IconButton(
                      icon: Icon(Icons.add),
                      onPressed: null,
                    ),
                  ),
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Share Graph',
                    onPressed: () {
                      ref
                          .read(sheetControllerProvider)
                          .show(
                            context: context,
                            scrollControlled: true,
                            child: (context) => GraphExportSheet(
                              graphKey: widget.graphKey,
                              additions: additions,
                              colorKeys: colorKeys,
                              customLabels: customLabels,
                              mode: effectiveComparison,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
            // Grouped item rows with category headers
            ..._buildDisplayingSection(context, graphData),
          ],
          const SizedBox(height: AppPadding.large),
        ],
      ),
    );
  }

  GraphComparison _resolveComparison({
    required GraphComparison requested,
    required GraphYAxis axis,
    required Map<GraphKey, List<Response>> responses,
  }) {
    if (requested == GraphComparison.stacked &&
        (axis != GraphYAxis.number ||
            responses.keys
                    .where((key) => !key.isReview)
                    .map((key) => key.isCategory)
                    .toSet()
                    .length >
                1)) {
      return GraphComparison.separate;
    }
    if (requested != GraphComparison.overlaid || axis != GraphYAxis.average) {
      return requested;
    }

    final List<(double, double)> domains = <(double, double)>[];
    for (final List<Response> series in responses.values) {
      Numeric? question;
      for (final Response response in series) {
        if (response is NumericResponse) {
          question = response.question;
          break;
        }
      }
      if (question?.min == null || question?.max == null) {
        return GraphComparison.separate;
      }
      domains.add((question!.min!.toDouble(), question.max!.toDouble()));
    }
    if (domains.length < 2) return requested;
    final (double, double) first = domains.first;
    return domains.skip(1).every((domain) => domain == first)
        ? requested
        : GraphComparison.separate;
  }

  /// Builds the "Displaying" item list grouped by [GraphKey.type], inserting
  /// a [_DisplayCategoryHeader] at the start of each new category group.
  /// This mirrors the category grouping in the main symptom browse list.
  List<Widget> _buildDisplayingSection(
    BuildContext context,
    AsyncValue<Map<GraphKey, List<Response>>> graphData,
  ) {
    final List<GraphKey> displayKeys = [widget.graphKey, ...additions];
    final QuestionsLocalizations? loc = QuestionsLocalizations.of(context);

    // Group keys in insertion order, preserving first-encounter category order
    final Map<String, List<GraphKey>> grouped = {};
    for (final key in displayKeys) {
      final String cat = key.type ?? key.title;
      grouped.putIfAbsent(cat, () => []).add(key);
    }

    final List<Widget> result = [];

    // Top border before first group
    result.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
        child: Divider(height: 1, color: Theme.of(context).dividerColor),
      ),
    );

    for (final catEntry in grouped.entries) {
      final String rawCat = catEntry.key;
      final String catLabel = loc?.value(rawCat) ?? rawCat;
      final List<GraphKey> catKeys = catEntry.value;

      result.add(_DisplayCategoryHeader(label: catLabel, rawName: rawCat));

      for (int i = 0; i < catKeys.length; i++) {
        final GraphKey key = catKeys[i];
        final String label =
            customLabels[key] ?? key.toLocalizedString(context);

        result.add(
          SymptomListItem(
            graphKey: key,
            color: colorKeys[key] ?? palette.forGraphKey(key),
            label: label,
            graphData: graphData,
            onTap: () async {
              final GraphEditResult? res = await ref
                  .read(sheetControllerProvider)
                  .show<GraphEditResult>(
                    context: context,
                    scrollControlled: true,
                    child: (context) => ColorPickerSheet(
                      currentColor: colorKeys[key] ?? palette.forGraphKey(key),
                      currentLabel:
                          customLabels[key] ?? key.toLocalizedString(context),
                    ),
                  );
              if (res != null) {
                setState(() {
                  colorKeys[key] = res.color;
                  if (res.label != null) customLabels[key] = res.label!;
                });
              }
            },
            onRemove: key != widget.graphKey
                ? () => setState(() {
                    additions.remove(key);
                    colorKeys.remove(key);
                    customLabels.remove(key);
                  })
                : null,
          ),
        );

        result.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
            child: Divider(height: 1, color: Theme.of(context).dividerColor),
          ),
        );
      }
    }

    return result;
  }

  Future<GraphKey?> toggleKeySelect(BuildContext context, WidgetRef ref) {
    return ref
        .read(sheetControllerProvider)
        .show<GraphKey?>(
          context: context,
          scrollControlled: true,
          sheetBuilder: (context, controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header for the bottom sheet
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppPadding.large,
                  AppPadding.medium,
                  AppPadding.small,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Layer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // List of available layers
              Flexible(
                child: ListSection(
                  controller: controller,
                  onSelect: (key) {
                    Navigator.pop(context, key);
                  },
                  excludedKeys: [widget.graphKey, ...additions],
                ),
              ),
            ],
          ),
        );
  }
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
  final List<Color> colorPalette = [...Colors.primaries];
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
    final List<Color> colorPalette = [...Colors.primaries];

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Layer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
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
      ),
    );
  }
}

class GraphExportSheet extends ConsumerStatefulWidget {
  final GraphKey graphKey;
  final List<GraphKey> additions;
  final Map<GraphKey, Color> colorKeys;
  final Map<GraphKey, String> customLabels;
  final GraphComparison mode;

  const GraphExportSheet({
    required this.graphKey,
    required this.additions,
    required this.colorKeys,
    required this.customLabels,
    this.mode = GraphComparison.separate,
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
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/graph_export.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;

      final RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Graph Export',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share this graph. Please try again.'),
          ),
        );
      }
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
    final AsyncValue<Map<GraphKey, List<Response>>> graphData = ref.watch(
      graphStampsProvider,
    );

    // Watch review paths to build reviewKeys map
    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap = reviewPathsAsync.when(
      data: (value) => value,
      loading: () => const {},
      error: (_, _) => const {},
    );

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Export Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          // Constrain height and add scrolling for tall shared-axis charts
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Container(
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
                        constraints: BoxConstraints(
                          maxWidth: Breakpoint.medium.value,
                        ),
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.all(AppPadding.medium),
                          child: AsyncValueDefaults(
                            value: graphData,
                            onData: (loadedData) {
                              Map<GraphKey, List<Response>> forGraph = {};
                              for (final GraphKey key in [
                                widget.graphKey,
                                ...widget.additions,
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
                                mode: widget.mode,
                                reviewPaths: reviewPathsMap,
                              );
                            },
                            onLoading: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
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
          ),
          const SizedBox(height: AppPadding.medium),
          FilledButton.icon(
            onPressed: _isSharing || !graphData.hasValue ? null : _shareImage,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(_isSharing ? 'Preparing...' : 'Share'),
          ),
        ],
      ),
    );
  }
}

class ChartDataPanel extends StatelessWidget {
  final GraphSelectionController selectionController;
  final GraphYAxis axis;

  const ChartDataPanel({
    super.key,
    required this.selectionController,
    required this.axis,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = QuestionsLocalizations.of(context);

    return ValueListenableBuilder<GraphSelectionState>(
      valueListenable: selectionController,
      builder: (context, state, _) {
        final items = state.items;
        final selecting = !state.isEmpty;

        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: selecting
              ? Container(
                  margin: const EdgeInsets.only(top: AppPadding.tiny),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.medium,
                    vertical: AppPadding.small,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRounding.small),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectionDateLabel(context, state),
                              style: tt.labelMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Clear selection',
                            onPressed: selectionController.clear,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: AppPadding.small,
                            color: cs.outline.withValues(alpha: 0.15),
                          ),
                        _HitRow(
                          item: items[i],
                          loc: loc,
                          tt: tt,
                          cs: cs,
                          axis: axis,
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _HitRow extends StatelessWidget {
  final GraphSelectionItem item;
  final QuestionsLocalizations? loc;
  final TextTheme tt;
  final ColorScheme cs;
  final GraphYAxis axis;

  const _HitRow({
    required this.item,
    required this.loc,
    required this.tt,
    required this.cs,
    required this.axis,
  });

  @override
  Widget build(BuildContext context) {
    final String valueStr = _chartValueString(context, item, loc, axis);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.series.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.series.label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppPadding.tiny),
              _AnswerPreview(item: item, fallback: valueStr, loc: loc),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerPreview extends StatelessWidget {
  final GraphSelectionItem item;
  final String fallback;
  final QuestionsLocalizations? loc;

  const _AnswerPreview({required this.item, required this.fallback, this.loc});

  @override
  Widget build(BuildContext context) {
    final answers = _flattenEvidence(item.datum.evidence);
    final style = Theme.of(context).textTheme.bodyMedium;
    final numeric = answers.whereType<NumericResponse>().toList();
    final choices = _choiceCountsFrom(answers);
    final texts = answers
        .whereType<OpenResponse>()
        .map((a) => a.response)
        .toSet();
    final selected = answers.whereType<Selected>().length;
    Widget badge(String label, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.series.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: item.series.color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
    final details = <Widget>[];
    if (!item.series.id.isCategory) {
      if (selected > 0) {
        details.add(
          badge(
            selected == 1 ? 'Selected' : 'Selected $selected times',
            Icons.check_circle_outline,
          ),
        );
      }
      for (final choice in choices.entries) {
        details.add(
          badge(
            '${loc?.value(choice.key) ?? choice.key} · ${choice.value}',
            Icons.label_outline,
          ),
        );
      }
      if (numeric.isNotEmpty) {
        final values = numeric.map((a) => a.response.toDouble()).toList()
          ..sort();
        String number(double value) => NumberFormat('0.##').format(value);
        final average = values.reduce((a, b) => a + b) / values.length;
        final question = numeric.first.question;
        details.add(
          Text(
            values.length == 1
                ? number(values.first)
                : '${number(average)} average · ${number(values.first)}–${number(values.last)} range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
        final min = question.min;
        final max = question.max;
        if (min != null && max != null && max > min) {
          details.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: ((average - min) / (max - min)).clamp(0, 1),
                  color: item.series.color,
                  minHeight: 6,
                ),
                Text(
                  '${number(min.toDouble())}–${number(max.toDouble())} scale',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }
      }
      for (final answer in texts) {
        details.add(Text(answer, style: style));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details.isNotEmpty) ...[
          Wrap(spacing: 6, runSpacing: 6, children: details),
          const SizedBox(height: 6),
        ],
        Text(
          fallback,
          style: details.isEmpty
              ? style?.copyWith(fontWeight: FontWeight.w700)
              : Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

String _chartValueString(
  BuildContext context,
  GraphSelectionItem item,
  QuestionsLocalizations? loc,
  GraphYAxis axis,
) {
  final PreparedDatum datum = item.datum;
  final GraphDatumSummary summary = datum.summary;
  final double? value = datum.value;

  String fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  final count = summary.reportCount;
  final reports = '$count ${count == 1 ? 'entry' : 'entries'}';
  if (datum.timing == GraphTiming.unknown) {
    final average = summary.numericAverage;
    return '${AppLocalizations.of(context)!.recordTimeUnknown} · $reports${axis == GraphYAxis.average && average != null ? ' · average ${fmt(average)}' : ''}';
  }
  if (datum.timing == GraphTiming.dayPart) {
    final responses = datum.evidence.whereType<Response>();
    final time = responses.isEmpty
        ? null
        : recordTimeForResponse(responses.first);
    final label =
        time?.label(context, includeRange: true) ?? 'Approximate time';
    final average = summary.numericAverage;
    return '$label · $reports${axis == GraphYAxis.average && average != null ? ' · average ${fmt(average)}' : ''}';
  }
  if (datum.timing == GraphTiming.reviewPeriod ||
      item.series.mark == GraphMark.range) {
    final MaterialLocalizations dates = MaterialLocalizations.of(context);
    final DateTime visibleEnd = datum.xEnd.isAfter(datum.xStart)
        ? datum.xEnd.subtract(const Duration(microseconds: 1))
        : datum.xEnd;
    final String start = dates.formatMediumDate(datum.xStart);
    final String end = dates.formatMediumDate(visibleEnd);
    return start == end
        ? 'Check-in period · $start · $reports'
        : 'Check-in period · $start – $end · $reports';
  }

  if (value == null) return 'No value';

  if (axis == GraphYAxis.entrytime) {
    final int minuteOfDay = ((value % 24) * 60).round() % (24 * 60);
    final time = TimeOfDay(
      hour: minuteOfDay ~/ 60,
      minute: minuteOfDay % 60,
    ).format(context);
    return count > 1 ? '$time · $reports' : time;
  }

  final List<Response> flat = _flattenEvidence(datum.evidence);
  final Map<String, int> choiceCounts = summary.choiceCounts.isNotEmpty
      ? summary.choiceCounts
      : _choiceCountsFrom(flat);
  final String? breakdown = _formatBreakdown(choiceCounts, loc);

  if (axis == GraphYAxis.number) {
    final int count = value.round();
    final String unit = item.series.id.isCategory ? 'event' : 'answer';
    final String text = '$count $unit${count == 1 ? '' : 's'}';
    if (breakdown == null) return text;
    return '$text · $breakdown';
  }

  if (breakdown != null) return breakdown;

  final List<num> numericValues = flat
      .whereType<NumericResponse>()
      .map((r) => r.response)
      .toList();
  final double? average =
      summary.numericAverage ??
      (numericValues.isEmpty
          ? null
          : numericValues.fold<double>(
                  0,
                  (total, number) => total + number.toDouble(),
                ) /
                numericValues.length);
  if (average != null) {
    final int count = summary.uniqueEntryCount > 0
        ? summary.uniqueEntryCount
        : numericValues.length;
    final String averageText = fmt(average);
    return count > 1 ? 'avg $averageText ($count entries)' : averageText;
  }

  final String unit = item.series.unit?.trim() ?? '';
  return unit.isEmpty ? fmt(value) : '${fmt(value)} $unit';
}

String _selectionDateLabel(BuildContext context, GraphSelectionState state) {
  final item = state.items.first;
  final datum = item.datum;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dateFormat = DateFormat.yMMMd(locale);
  if (item.series.mark == GraphMark.point ||
      datum.timing == GraphTiming.dayPart ||
      datum.timing == GraphTiming.unknown) {
    final response = datum.evidence.whereType<Response>().firstOrNull;
    return dateFormat.format(
      response == null ? datum.xStart : occurrenceTimeForResponse(response),
    );
  }
  final isRange = item.series.mark == GraphMark.range;
  final start = isRange ? datum.xStart : state.bin?.start ?? datum.xStart;
  final end = isRange ? datum.xEnd : state.bin?.end ?? datum.xEnd;
  final visibleEnd = end.isAfter(start)
      ? end.subtract(const Duration(microseconds: 1))
      : end;
  if (!DateUtils.isSameDay(start, visibleEnd)) {
    return '${dateFormat.format(start)} – ${dateFormat.format(visibleEnd)}';
  }
  if (start.hour != 0 ||
      start.minute != 0 ||
      (end.isAfter(start) && DateUtils.isSameDay(start, end))) {
    String time(DateTime value) =>
        TimeOfDay.fromDateTime(value).format(context);
    return '${dateFormat.format(start)} · ${time(start)} – ${time(end)}';
  }
  return dateFormat.format(start);
}

List<Response> _flattenEvidence(List<Stamp> evidence) {
  final List<Response> flat = [];
  for (final Stamp stamp in evidence) {
    if (stamp is DetailResponse) {
      flat.addAll(stamp.responses.whereType<Response>());
    } else if (stamp is Response) {
      flat.add(stamp);
    }
  }
  return flat;
}

Map<String, int> _choiceCountsFrom(List<Response> responses) {
  final Map<String, int> counts = {};
  for (final Response response in responses) {
    if (response is MultiResponse) {
      counts[response.choice] = (counts[response.choice] ?? 0) + 1;
    } else if (response is AllResponse) {
      for (final String choice in response.choices) {
        counts[choice] = (counts[choice] ?? 0) + 1;
      }
    }
  }
  return counts;
}

String? _formatBreakdown(Map<String, int> counts, QuestionsLocalizations? loc) {
  if (counts.isEmpty) return null;

  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) {
        final label = loc?.value(e.key) ?? e.key;
        return e.value > 1 ? '$label (${e.value})' : label;
      })
      .join(', ');
}

class _DisplayCategoryHeader extends ConsumerWidget {
  final String label;
  final String rawName;
  const _DisplayCategoryHeader({required this.label, required this.rawName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bool themed = ref.watch(configProvider).betaUi.useCategoryTheme;
    final bool colored = ref.watch(configProvider).betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(rawName);

    final Color dividerColor = colored ? appearance.color : cs.primary;
    final Color bgColor = colored
        ? appearance.color.withValues(alpha: 0.15)
        : cs.primaryContainer.withValues(alpha: 0.20);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.small,
        AppPadding.large,
        AppPadding.small,
      ),
      child: Row(
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
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: dividerColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
