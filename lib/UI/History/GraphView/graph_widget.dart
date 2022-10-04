import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/graph_data_provider.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/button_style.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

final selectedGraphProvider = StateProvider<String?>((_) => null);

class GraphWidget extends ConsumerWidget {
  const GraphWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<GraphData> behaviorFetch = ref.watch(orderedBehaviorProvider);
    GraphData? graphData = behaviorFetch.whenOrNull(data: (data) => data);
    if (graphData == null) {
      return const Center(
        child: LoadingWidget(),
      );
    }
    if (graphData == GraphData.empty()) return const SizedBox.shrink();

    List<String> behaviors = graphData.behaviorBarData.keys.toList();

    final String selectedValue =
        ref.watch(selectedGraphProvider) ?? behaviors.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 14.0,
        ),
        FittedBox(
          fit: BoxFit.contain,
          child: Text(
            'Behavior Frequency',
            maxLines: 1,
            style: darkBackgroundScreenHeaderStyle.copyWith(fontSize: 34.0),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          height: 30,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buttonWrap(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Back',
                    onPressed: () {
                      _shift(ref, ShiftDirection.past);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_left,
                      color: darkIconButton,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _openBehaviorOverlay(ref, behaviors, selectedValue);
                  },
                  style: historyButtonStyle,
                  child: Text(
                    'Change Behavior',
                    style: buttonText,
                  ),
                ),
                _buttonWrap(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Forward',
                    onPressed: () {
                      _shift(ref, ShiftDirection.future);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_right,
                      color: darkIconButton,
                    ),
                  ),
                ),
              ]),
        ),
        const SizedBox(
          height: 8,
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          elevation: 6.0,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  selectedValue,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: lightBackgroundHeaderStyle,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                graphData.isEmpty
                    ? const Center(
                        child: Text(
                          'No Data',
                          style: lightBackgroundHeaderStyle,
                        ),
                      )
                    : BarGraph(graphData: graphData),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttonWrap({required Widget child}) => Card(
        margin: EdgeInsets.zero,
        shape: const CircleBorder(),
        elevation: 6.0,
        child: child,
      );

  _shift(WidgetRef ref, ShiftDirection direction) {
    final Filters currentFilters = ref.read(filtersProvider);
    final GraphChoice graphChoice = ref.read(historyLocationProvider).graph;
    final ShiftAmount shiftAmount = graphToShift[graphChoice]!;
    final Filters newFilters = currentFilters.shift(shiftAmount, direction);
    if ((newFilters.end?.isAfter(DateTime.now()) ?? false) &&
        direction == ShiftDirection.future) return;
    ref.read(filtersProvider.notifier).state = newFilters;
  }

  _openBehaviorOverlay(WidgetRef ref, List<String> options, String selected) {
    ref.read(overlayProvider.notifier).state = OverlayQuery(
        widget: SelectBehaviorOverlay(
      options: options,
      selected: selected,
    ));
  }
}

class BarGraph extends ConsumerStatefulWidget {
  final GraphData graphData;
  const BarGraph({required this.graphData, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BarGraphState();
  }
}

class _BarGraphState extends ConsumerState<BarGraph> {
  int touchedIndex = -1;

  late GraphBarData graphBarData;

  late final GraphBarData defaultData;

  @override
  void initState() {
    defaultData = widget.graphData.behaviorBarData.values.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String? selected = ref.watch(selectedGraphProvider);
    graphBarData = selected == null
        ? defaultData
        : widget.graphData.behaviorBarData[selected] ?? defaultData;
    const Color severe = lightIconButton;
    Color mild = lightIconButton.withOpacity(0.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${dateToMDYAbr(widget.graphData.start!)} - ${dateToMDYAbr(widget.graphData.end!)}',
                overflow: TextOverflow.fade,
                style: lightBackgroundHeaderStyle,
              ),
            ),
            if (graphBarData.isSeverity) ...[
              const VerticalDivider(
                width: 8.0,
                thickness: 2,
                indent: 25,
                endIndent: 2,
                color: Colors.black54,
              ),
              const SizedBox(
                width: 8.0,
              ),
              ColorKey(keys: [
                'Severe(${(graphBarData.maxSeverity ?? 5.0)}):',
                'Mild(${graphBarData.minSeverity ?? 1.0}):'
              ], values: [
                severe,
                mild
              ]),
              const SizedBox(
                width: 8.0,
              ),
            ],
          ],
        ),
        const SizedBox(
          height: 8.0,
        ),
        AspectRatio(
          aspectRatio: 2.2,
          child: BarChart(
            BarChartData(
              barGroups: _makeChartData(
                graphBarData.barData,
                severe,
                mild,
              ),
              maxY: graphBarData.maxHeight + 1.0,
              gridData: FlGridData(
                show: true,
                getDrawingVerticalLine: (value) => FlLine(
                    color: backgroundLight.withOpacity(0.6), dashArray: [4, 8]),
                getDrawingHorizontalLine: (value) => FlLine(
                    color: backgroundLight.withOpacity(0.6), dashArray: [4, 8]),
              ),
              borderData: FlBorderData(
                  show: true,
                  border: const Border(
                      bottom: BorderSide(color: backgroundLight, width: 1.0),
                      right: BorderSide(color: backgroundLight, width: 1.0))),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: _getTooltipItem,
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = response.spot!.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: _getTitles(),
            ),
          ),
        ),
      ],
    );
  }

  FlTitlesData? _getTitles() {
    const SideTitleWidget empty = SideTitleWidget(
      axisSide: AxisSide.bottom,
      child: SizedBox(),
    );
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double val, TitleMeta meta) {
            if (val != val.ceilToDouble()) return empty;
            return SideTitleWidget(
                axisSide: AxisSide.right, child: Text('$val'));
          },
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameSize: 25.0,
        axisNameWidget: Text(
          widget.graphData.axisLabel,
          style: lightBackgroundHeaderStyle,
        ),
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double val, TitleMeta meta) {
            final GraphLabel? label = widget.graphData.labels[val.toInt()];
            return label == null
                ? empty
                : Tooltip(
                    message: label.value,
                    showDuration: Duration.zero,
                    child: SideTitleWidget(
                        axisSide: AxisSide.bottom, child: Text(label.abr)),
                  );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _makeChartData(
      List<BarData> bars, Color high, Color low) {
    List<BarChartGroupData> data = [];

    final double width = graphBarData.barData.length > 15.0 ? 10.0 : 22.0;

    for (int i = 0; i < bars.length; i++) {
      final BarData curr = bars[i];
      double sev = 0.5;
      final bool severity = graphBarData.isSeverity;
      if (severity) {
        sev = (curr.severity ?? 3.0 - (graphBarData.minSeverity ?? 1.0)) /
            (graphBarData.maxSeverity ??
                5.0 - (graphBarData.minSeverity ?? 1.0));
      }
      data.add(
        _makeGroupData(
            i,
            curr.height.toDouble(),
            severity
                ? Color.lerp(low, high, sev) ?? lightIconButton
                : lightIconButton,
            width: width,
            isTouched: touchedIndex == i),
      );
    }
    return data;
  }

  BarTooltipItem? _getTooltipItem(BarChartGroupData group, int groupIndex,
      BarChartRodData rod, int rodIndex) {
    BarData data = graphBarData.barData[groupIndex];
    String severity = data.severity == null ? '' : '\nLevel: ${data.severity}';
    return BarTooltipItem(
      '${data.height}',
      darkBackgroundStyle,
      children: [TextSpan(text: severity)],
    );
  }

  BarChartGroupData _makeGroupData(
    int x,
    double y,
    Color barColor, {
    bool isTouched = false,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + (graphBarData.maxHeight * 0.05) : y,
          color: isTouched ? _darken(barColor) : barColor,
          width: width,
          borderRadius: BorderRadius.zero,
        ),
      ],
      showingTooltipIndicators: showTooltips,
      barsSpace: 0,
    );
  }

  Color _darken(Color color, [int percent = 40]) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(color.alpha, (color.red * value).round(),
        (color.green * value).round(), (color.blue * value).round());
  }
}

class SelectBehaviorOverlay extends ConsumerWidget {
  final List<String> options;

  final String selected;

  const SelectBehaviorOverlay(
      {required this.options, required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double height = MediaQuery.of(context).size.height;
    return OverlayBackdrop(
      child: SizedBox(
        height: min(400, height - 50),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                  color: darkBackgroundText,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 35,
                      ),
                      const Spacer(),
                      const Text(
                        'Select Behavior',
                        style: lightBackgroundHeaderStyle,
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 35,
                        onPressed: () {
                          _close(ref);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: darkIconButton,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        final String option = options[index];
                        return ListTile(
                          title: Text(
                            option,
                            style: lightBackgroundStyle,
                          ),
                          tileColor: darkBackgroundText,
                          selectedTileColor: darkIconButton.withOpacity(0.6),
                          style: ListTileStyle.drawer,
                          trailing: selected == option
                              ? const Icon(
                                  Icons.check,
                                  color: darkIconButton,
                                )
                              : null,
                          onTap: () {
                            if (option != selected) {
                              ref.read(selectedGraphProvider.notifier).state =
                                  option;
                            }
                            _close(ref);
                          },
                          selected: option == selected,
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.black54,
                      ),
                      itemCount: options.length,
                      controller: ScrollController(keepScrollOffset: true),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _close(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}

class ColorKey extends StatelessWidget {
  final List<String> keys;
  final List<Color> values;
  const ColorKey({
    required this.keys,
    required this.values,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: keys
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Text(
                      text,
                      style: lightBackgroundStyle,
                    ),
                  ),
                )
                .toList()),
        const SizedBox(
          width: 4.0,
        ),
        Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: values
                .map(
                  (color) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Container(
                        width: 25.0,
                        height: 25.0,
                        color: color,
                      )),
                )
                .toList()),
      ],
    );
  }
}
