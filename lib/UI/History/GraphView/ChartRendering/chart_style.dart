import 'package:flutter/material.dart';

class ChartStyle {
  final TextStyle axisLabelStyle;
  final Color axisLineColor;
  final double axisLineWidth;
  final double axisLabelPadding;

  final double lineStrokeWidth;
  final double pointRadius;

  final EdgeInsets chartPadding;

  final bool showGridLines;
  final Color? gridLineColor;
  final double gridLineWidth;

  final BarChartStyle barChartStyle;

  const ChartStyle({
    this.axisLabelStyle = const TextStyle(color: Colors.grey, fontSize: 10),
    this.axisLineColor = Colors.grey,
    this.axisLineWidth = 1.0,
    this.axisLabelPadding = 5.0,
    this.lineStrokeWidth = 2.0,
    this.pointRadius = 3.0,
    this.chartPadding = const EdgeInsets.only(top: 5.0, right: 5.0),
    this.showGridLines = false,
    this.gridLineColor,
    this.gridLineWidth = 0.5,
    this.barChartStyle = const BarChartStyle(),
  });

  Color get effectiveGridColor =>
      gridLineColor ?? axisLineColor.withValues(alpha: 0.3);

  factory ChartStyle.fromTheme(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChartStyle(
      axisLabelStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ) ??
          TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
      axisLineColor: colorScheme.outlineVariant,
    );
  }

  ChartStyle copyWith({
    TextStyle? axisLabelStyle,
    Color? axisLineColor,
    double? axisLineWidth,
    double? axisLabelPadding,
    double? barWidthRatio,
    double? barMaxWidth,
    double? lineStrokeWidth,
    double? pointRadius,
    EdgeInsets? chartPadding,
    bool? showGridLines,
    Color? gridLineColor,
    double? gridLineWidth,
    BarChartStyle? barChartStyle,
  }) {
    return ChartStyle(
      axisLabelStyle: axisLabelStyle ?? this.axisLabelStyle,
      axisLineColor: axisLineColor ?? this.axisLineColor,
      axisLineWidth: axisLineWidth ?? this.axisLineWidth,
      axisLabelPadding: axisLabelPadding ?? this.axisLabelPadding,
      barChartStyle: barChartStyle ?? this.barChartStyle,
      lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
      pointRadius: pointRadius ?? this.pointRadius,
      chartPadding: chartPadding ?? this.chartPadding,
      showGridLines: showGridLines ?? this.showGridLines,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
    );
  }
}

class BarChartStyle {
  final double barWidthRatio;
  final double barMaxWidth;
  final bool stackBars;

  const BarChartStyle(
      {this.barWidthRatio = 0.8,
      this.barMaxWidth = 50.0,
      this.stackBars = false});
}
