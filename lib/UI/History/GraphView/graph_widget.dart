import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Providers/graph_data_provider.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';

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
            style: Theme.of(context).textTheme.headlineMedium,
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
                ElevatedButton(
                  onPressed: () {
                    _openBehaviorOverlay(ref, behaviors, selectedValue);
                  },
                  child: const Text(
                    'Change Behavior',
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
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  selectedValue,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                graphData.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: Text(
                            'No Data',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ))
                    : BarGraph(graphData: graphData),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 35.0,
        )
      ],
    );
  }

  _openBehaviorOverlay(WidgetRef ref, List<String> options, String selected) {
    ref.read(overlayProvider.notifier).state = CurrentOverlay(
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
    Color severe = Theme.of(context).colorScheme.error;
    Color mild = Theme.of(context).colorScheme.tertiary.withOpacity(0.5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (graphBarData.isSeverity) ...[
              const SizedBox(
                width: 8.0,
              ),
              ColorKey(keys: const ['High', 'Low'], values: [severe, mild]),
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
                show: false,
                getDrawingVerticalLine: (value) =>
                    const FlLine(dashArray: [4, 8]),
                getDrawingHorizontalLine: (value) =>
                    const FlLine(dashArray: [4, 8]),
              ),
              borderData: FlBorderData(
                  show: true,
                  border: const Border(
                      bottom: BorderSide(width: 1.0),
                      right: BorderSide(width: 1.0))),
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
              titlesData: _getTitles(context),
            ),
          ),
        ),
      ],
    );
  }

  FlTitlesData? _getTitles(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    GraphChoice choice = widget.graphData.period;
    Widget getDateString(DateTime time) {
      switch (choice) {
        case GraphChoice.day:
          return SideTitleWidget(
              axisSide: AxisSide.bottom,
              child: Text(DateFormat.Hm(locale).format(time)));
        case GraphChoice.week:
          return SideTitleWidget(
              axisSide: AxisSide.bottom,
              child: Text(DateFormat.E(locale).format(time)));
        case GraphChoice.month:
          final String day = DateFormat.EEEE(locale).format(time);
          return Tooltip(
            message: day,
            showDuration: Duration.zero,
            child: SideTitleWidget(
                axisSide: AxisSide.bottom, child: Text(day.substring(0, 1))),
          );
        case GraphChoice.year:
          return SideTitleWidget(
              axisSide: AxisSide.bottom,
              child: Text(DateFormat.MMM(locale).format(time)));
      }
    }

    String? getLabel() {
      final DateTime? refDate = widget.graphData.end;
      if (refDate == null) return null;
      final DateFormat yearFormat = DateFormat.yMMMd(locale);

      switch (choice) {
        case GraphChoice.day:
          return yearFormat.format(refDate);
        case GraphChoice.week:
          final DateTime? startDate = widget.graphData.start;
          if (startDate == null) {
            return yearFormat.format(refDate);
          }
          final bool sameYear = refDate.year == startDate.year;
          final bool sameMonth = sameYear && refDate.month == startDate.month;
          final String firstPortion = sameYear
              ? DateFormat.MMMd(locale).format(startDate)
              : yearFormat.format(startDate);
          final String lastPortion = sameMonth
              ? '${DateFormat.d(locale).format(refDate)}, ${DateFormat.y(locale).format(refDate)}'
              : yearFormat.format(refDate);
          return '$firstPortion - $lastPortion';
        case GraphChoice.month:
          return DateFormat.yMMM(locale).format(refDate);
        case GraphChoice.year:
          return DateFormat.y(locale).format(refDate);
      }
    }

    const SideTitleWidget empty = SideTitleWidget(
      axisSide: AxisSide.bottom,
      child: SizedBox(),
    );
    return FlTitlesData(
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24.0,
          getTitlesWidget: (double val, TitleMeta meta) {
            if (val != val.ceilToDouble()) return empty;
            return SideTitleWidget(
                axisSide: AxisSide.right, child: Text('${val.toInt()}'));
          },
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameSize: 20.0,
        axisNameWidget: Text(
          getLabel() ?? "",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        sideTitles: SideTitles(
          reservedSize: 24.0,
          showTitles: true,
          getTitlesWidget: (double val, TitleMeta meta) {
            final DateTime? time = widget.graphData.labels[val.toInt()];
            if (time == null) return empty;
            return getDateString(time);
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
        _makeGroupData(i, curr.height.toDouble(),
            severity ? Color.lerp(low, high, sev) ?? low : low,
            width: width, isTouched: touchedIndex == i),
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
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
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
            child: Card(
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
                      Text(
                        'Select Behavior',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 35,
                        onPressed: () {
                          _close(ref);
                        },
                        icon: const Icon(
                          Icons.close,
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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          style: ListTileStyle.drawer,
                          trailing: selected == option
                              ? const Icon(
                                  Icons.check,
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
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 15.0,
          height: 45.0,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: values,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)))),
      const SizedBox(
        width: 4.0,
      ),
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: keys
              .map(
                (text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.left,
                  ),
                ),
              )
              .toList()),
    ]);
  }
}
