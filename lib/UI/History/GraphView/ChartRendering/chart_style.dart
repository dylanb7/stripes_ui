import 'package:flutter/material.dart';

class ChartStyle {
  final TextStyle axisLabelStyle;
  final TextStyle axisTitleStyle;
  final Color axisLineColor;
  final double axisLineWidth;
  final double axisLabelPadding;

  final double lineStrokeWidth;
  final double pointRadius;

  final EdgeInsets chartPadding;

  final bool showGridLines;
  final Color? gridLineColor;
  final double gridLineWidth;

  final TextStyle annotationLabelStyle;
  final Color annotationLineColor;
  final BarChartStyle barChartStyle;
  final CrosshairStyle? crosshairStyle;
  final bool drawXAxisLine;
  final bool drawYAxisLine;
  final bool drawTopAxisLine;
  final bool drawRightAxisLine;
  final bool hasHalfStepPadding;

  const ChartStyle({
    this.drawXAxisLine = true,
    this.drawYAxisLine = true,
    this.drawTopAxisLine = false,
    this.drawRightAxisLine = false,
    this.axisLabelStyle = const TextStyle(color: Colors.grey, fontSize: 10),
    this.axisTitleStyle = const TextStyle(
        color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
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
    this.annotationLabelStyle =
        const TextStyle(color: Colors.grey, fontSize: 10),
    this.annotationLineColor = Colors.grey,
    this.crosshairStyle,
    this.hasHalfStepPadding = false,
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
      axisTitleStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ) ??
          TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
      axisLineColor: colorScheme.outlineVariant,
      annotationLabelStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ) ??
          const TextStyle(),
      annotationLineColor: colorScheme.secondary,
    );
  }

  ChartStyle copyWith({
    TextStyle? axisLabelStyle,
    TextStyle? axisTitleStyle,
    Color? axisLineColor,
    double? axisLineWidth,
    double? axisLabelPadding,
    double? barWidthRatio,
    double? barMaxWidth,
    double? lineStrokeWidth,
    double? pointRadius,
    EdgeInsets? chartPadding,
    bool? showGridLines,
    bool? drawXAxisLine,
    bool? drawYAxisLine,
    bool? drawTopAxisLine,
    bool? drawRightAxisLine,
    Color? gridLineColor,
    double? gridLineWidth,
    BarChartStyle? barChartStyle,
    TextStyle? annotationLabelStyle,
    Color? annotationLineColor,
    CrosshairStyle? crosshairStyle,
    bool? hasHalfStepPadding,
  }) {
    return ChartStyle(
      axisLabelStyle: axisLabelStyle ?? this.axisLabelStyle,
      axisTitleStyle: axisTitleStyle ?? this.axisTitleStyle,
      axisLineColor: axisLineColor ?? this.axisLineColor,
      axisLineWidth: axisLineWidth ?? this.axisLineWidth,
      axisLabelPadding: axisLabelPadding ?? this.axisLabelPadding,
      barChartStyle: barChartStyle ?? this.barChartStyle,
      lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
      pointRadius: pointRadius ?? this.pointRadius,
      chartPadding: chartPadding ?? this.chartPadding,
      showGridLines: showGridLines ?? this.showGridLines,
      drawXAxisLine: drawXAxisLine ?? this.drawXAxisLine,
      drawYAxisLine: drawYAxisLine ?? this.drawYAxisLine,
      drawTopAxisLine: drawTopAxisLine ?? this.drawTopAxisLine,
      drawRightAxisLine: drawRightAxisLine ?? this.drawRightAxisLine,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      annotationLabelStyle: annotationLabelStyle ?? this.annotationLabelStyle,
      annotationLineColor: annotationLineColor ?? this.annotationLineColor,
      crosshairStyle: crosshairStyle ?? this.crosshairStyle,
      hasHalfStepPadding: hasHalfStepPadding ?? this.hasHalfStepPadding,
    );
  }
}

class BarChartStyle {
  final double barWidthRatio;
  final double barMaxWidth;
  final bool stackBars;
  final Color? selectionBorderColor;
  final double selectionBorderWidth;
  final Color? selectionHighlightColor;

  const BarChartStyle({
    this.barWidthRatio = 0.95,
    this.barMaxWidth = 50.0,
    this.stackBars = false,
    this.selectionBorderColor,
    this.selectionBorderWidth = 2.0,
    this.selectionHighlightColor,
  });

  Color get effectiveHighlightColor =>
      selectionHighlightColor ?? Colors.grey.withValues(alpha: 0.2);
}

class CrosshairStyle {
  final Color color;
  final double strokeWidth;
  final bool showX;
  final bool showY;

  const CrosshairStyle({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.showX = true,
    this.showY = true,
  });
}

enum LabelAlignment {
  start,
  center,
  end,
}
