import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_selection_controller.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/UI/History/Timeline/review_period_data.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

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
  GraphOverviewMode _overviewMode = GraphOverviewMode.stacked;
  bool _heroComplete = false;

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for route animation to complete
    _routeAnimation?.removeStatusListener(_onAnimationStatus);
    _routeAnimation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != null && !_heroComplete) {
      if (_routeAnimation!.isCompleted) {
        _heroComplete = true;
      } else {
        _routeAnimation!.addStatusListener(_onAnimationStatus);
      }
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _heroComplete = true;
      });
      _routeAnimation?.removeStatusListener(_onAnimationStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onAnimationStatus);
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final AsyncValue<Map<GraphKey, List<Response>>> graphData =
        ref.watch(graphStampsProvider);

    // Watch review paths to build reviewKeys map
    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap =
        reviewPathsAsync.valueOrNull ?? {};

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
          child: LayoutBuilder(builder: (context, constraints) {
            // Build the forGraph map synchronously using valueOrNull
            final loadedData = graphData.valueOrNull ?? {};
            Map<GraphKey, List<Response>> forGraph = {};
            for (final GraphKey key in [widget.graphKey, ...additions]) {
              if (loadedData.containsKey(key)) {
                forGraph[key] = loadedData[key]!;
              }
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRounding.tiny)),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.tiny),
                child: Hero(
                  tag: widget.graphKey,
                  flightShuttleBuilder: (flightContext, animation,
                      flightDirection, fromHeroContext, toHeroContext) {
                    // Use ClipRect to prevent overflow during animation
                    return ClipRect(
                      child: toHeroContext.widget,
                    );
                  },
                  child: GraphSymptom(
                    responses: forGraph,
                    isDetailed: _heroComplete,
                    forExport: false,
                    colorKeys: colorKeys,
                    selectionController: _selectionController,
                    mode: _overviewMode,
                    reviewPaths: reviewPathsMap,
                  ),
                ),
              ),
            );
          }),
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
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mode selector - icon only with popup menu
              if (additions.isNotEmpty)
                PopupMenuButton<GraphOverviewMode>(
                  icon: Icon(
                    _overviewMode == GraphOverviewMode.stacked
                        ? Icons.stacked_bar_chart
                        : _overviewMode == GraphOverviewMode.shared
                            ? Icons.view_stream
                            : Icons.layers,
                  ),
                  tooltip: 'Change display mode',
                  onSelected: (GraphOverviewMode value) {
                    setState(() {
                      _overviewMode = value;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: GraphOverviewMode.stacked,
                      child: Row(
                        children: [
                          Icon(Icons.stacked_bar_chart,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          const Text('Stacked'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: GraphOverviewMode.shared,
                      child: Row(
                        children: [
                          Icon(Icons.view_stream,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          const Text('Lanes'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: GraphOverviewMode.overlayed,
                      child: Row(
                        children: [
                          Icon(Icons.layers,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          const Text('Overlay'),
                        ],
                      ),
                    ),
                  ],
                ),
              // Add Layer button - icon only
              AsyncValueDefaults(
                value: graphData,
                onData: (loadedData) {
                  final Iterable<GraphKey> keys = loadedData.keys;
                  final bool hasValuesToAdd = keys
                      .where((element) =>
                          ![...additions, widget.graphKey].contains(element))
                      .isNotEmpty;
                  return IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Layer',
                    onPressed: hasValuesToAdd
                        ? () async {
                            final GraphKey? result =
                                await toggleKeySelect(context, ref);
                            if (result != null) {
                              setState(() {
                                additions.add(result);
                              });
                            }
                          }
                        : null,
                  );
                },
                onLoading: (_) => const IconButton(
                  icon: Icon(Icons.add),
                  tooltip: 'Add Layer',
                  onPressed: null,
                ),
                onError: (_) => const IconButton(
                  icon: Icon(Icons.add),
                  tooltip: 'Add Layer',
                  onPressed: null,
                ),
              ),
              // Share button - icon only
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Share Graph',
                onPressed: () {
                  ref.read(sheetControllerProvider).show(
                        context: context,
                        scrollControlled: true,
                        child: (context) => GraphExportSheet(
                          graphKey: widget.graphKey,
                          additions: additions,
                          colorKeys: colorKeys,
                          customLabels: customLabels,
                          mode: _overviewMode,
                        ),
                      );
                },
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
        // Display list with dividers
        ...([widget.graphKey, ...additions].asMap().entries.map(
          (entry) {
            final index = entry.key;
            final key = entry.value;
            final String label =
                customLabels[key] ?? key.toLocalizedString(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.large),
                    child: Divider(
                        height: 1, color: Theme.of(context).dividerColor),
                  ),
                SymptomListItem(
                  graphKey: key,
                  color: colorKeys[key] ?? forGraphKey(key),
                  label: label,
                  selectionController: _selectionController,
                  graphData: graphData,
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
                  onRemove: key != widget.graphKey
                      ? () {
                          setState(() {
                            additions.remove(key);
                            colorKeys.remove(key);
                            customLabels.remove(key);
                          });
                        }
                      : null,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.large),
                  child:
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                ),
              ],
            );
          },
        )),
        const SizedBox(
          height: AppPadding.large,
        ),
      ],
    ));
  }

  Future<GraphKey?> toggleKeySelect(BuildContext context, WidgetRef ref) {
    return ref.read(sheetControllerProvider).show<GraphKey?>(
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
                    Text(
                      'Add Layer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
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
                  includesControls: false,
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
  final GraphOverviewMode mode;

  const GraphExportSheet({
    required this.graphKey,
    required this.additions,
    required this.colorKeys,
    required this.customLabels,
    this.mode = GraphOverviewMode.stacked,
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

    // Watch review paths to build reviewKeys map
    final reviewPathsAsync = ref.watch(reviewPathsByTypeProvider);
    final Map<String, RecordPath> reviewPathsMap =
        reviewPathsAsync.valueOrNull ?? {};

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
                                mode: widget.mode,
                                reviewPaths: reviewPathsMap,
                              );
                            },
                            onLoading: (_) => const Center(
                                child: CircularProgressIndicator()),
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
