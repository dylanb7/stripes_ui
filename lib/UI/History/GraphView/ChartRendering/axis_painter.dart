import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_animation_state.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_geometry.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_style.dart';

class AxisPainter {
  static void paintXAxis(
    Canvas canvas,
    ChartGeometry geometry,
    AxisLabelsState state,
    double animationValue,
    ChartStyle style,
  ) {
    if (geometry.drawWidth <= 0) return;

    void drawLabel(String text, double normalizedX, double opacity) {
      if (opacity <= 0) return;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.axisLabelStyle.copyWith(
            color: style.axisLabelStyle.color?.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final screenX = geometry.normalizedXToScreen(normalizedX);

      textPainter.paint(
        canvas,
        Offset(
          screenX - textPainter.width / 2,
          geometry.size.height - geometry.bottomMargin + style.axisLabelPadding,
        ),
      );
    }

    if (state.useCrossfade) {
      for (final label in state.previous) {
        drawLabel(label.text, label.normalizedPosition, 1.0 - animationValue);
      }
      for (final label in state.current) {
        drawLabel(label.text, label.normalizedPosition, animationValue);
      }
    } else {
      for (int i = 0; i < state.current.length; i++) {
        final current = state.current[i];
        if (i < state.previous.length) {
          final previous = state.previous[i];

          final normalizedX = ui.lerpDouble(
                previous.normalizedPosition,
                current.normalizedPosition,
                animationValue,
              ) ??
              current.normalizedPosition;

          if (previous.text == current.text) {
            drawLabel(current.text, normalizedX, 1.0);
          } else {
            drawLabel(previous.text, normalizedX, 1.0 - animationValue);
            drawLabel(current.text, normalizedX, animationValue);
          }
        } else {
          drawLabel(current.text, current.normalizedPosition, animationValue);
        }
      }
    }
  }

  static void paintYAxis(
    Canvas canvas,
    ChartGeometry geometry,
    AxisLabelsState state,
    double animationValue,
    ChartStyle style,
  ) {
    if (geometry.drawHeight <= 0) return;

    void drawLabel(String text, double normalizedY, double opacity) {
      if (opacity <= 0) return;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.axisLabelStyle.copyWith(
            color: style.axisLabelStyle.color?.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final screenY = geometry.normalizedYToScreen(normalizedY);

      textPainter.paint(
        canvas,
        Offset(
          geometry.leftMargin - textPainter.width - style.axisLabelPadding,
          screenY - textPainter.height / 2,
        ),
      );
    }

    if (state.useCrossfade) {
      for (final label in state.previous) {
        drawLabel(label.text, label.normalizedPosition, 1.0 - animationValue);
      }
      for (final label in state.current) {
        drawLabel(label.text, label.normalizedPosition, animationValue);
      }
    } else {
      for (int i = 0; i < state.current.length; i++) {
        final current = state.current[i];
        if (i < state.previous.length) {
          final previous = state.previous[i];

          final normalizedY = ui.lerpDouble(
                previous.normalizedPosition,
                current.normalizedPosition,
                animationValue,
              ) ??
              current.normalizedPosition;

          if (previous.text == current.text) {
            drawLabel(current.text, normalizedY, 1.0);
          } else {
            drawLabel(previous.text, normalizedY, 1.0 - animationValue);
            drawLabel(current.text, normalizedY, animationValue);
          }
        } else {
          drawLabel(current.text, current.normalizedPosition, animationValue);
        }
      }
    }
  }

  static void paintAxisLines(
    Canvas canvas,
    ChartGeometry geometry,
    ChartStyle style,
  ) {
    final axisPaint = Paint()
      ..color = style.axisLineColor
      ..strokeWidth = style.axisLineWidth;

    // Left (Y) axis line
    if (style.drawYAxisLine) {
      canvas.drawLine(
        Offset(geometry.leftMargin, geometry.topMargin),
        Offset(
            geometry.leftMargin, geometry.size.height - geometry.bottomMargin),
        axisPaint,
      );
    }

    // Bottom (X) axis line
    if (style.drawXAxisLine) {
      canvas.drawLine(
        Offset(
            geometry.leftMargin, geometry.size.height - geometry.bottomMargin),
        Offset(geometry.size.width - geometry.rightMargin,
            geometry.size.height - geometry.bottomMargin),
        axisPaint,
      );
    }

    // Top axis line
    if (style.drawTopAxisLine) {
      canvas.drawLine(
        Offset(geometry.leftMargin, geometry.topMargin),
        Offset(geometry.size.width - geometry.rightMargin, geometry.topMargin),
        axisPaint,
      );
    }

    // Right axis line
    if (style.drawRightAxisLine) {
      canvas.drawLine(
        Offset(geometry.size.width - geometry.rightMargin, geometry.topMargin),
        Offset(geometry.size.width - geometry.rightMargin,
            geometry.size.height - geometry.bottomMargin),
        axisPaint,
      );
    }
  }

  static void paintGridLines(
    Canvas canvas,
    ChartGeometry geometry,
    AxisLabelsState xAxisState,
    AxisLabelsState yAxisState,
    double animationValue,
    ChartStyle style,
  ) {
    if (!style.showGridLines) return;

    final gridPaint = Paint()
      ..color = style.effectiveGridColor
      ..strokeWidth = style.gridLineWidth;

    final double left = geometry.leftMargin;
    final double right = geometry.size.width - geometry.rightMargin;
    final double top = geometry.topMargin;
    final double bottom = geometry.size.height - geometry.bottomMargin;

    if (yAxisState.useCrossfade) {
      for (final label in yAxisState.previous) {
        final y = geometry.normalizedYToScreen(label.normalizedPosition);
        canvas.drawLine(
          Offset(left, y),
          Offset(right, y),
          gridPaint
            ..color = style.effectiveGridColor.withValues(
                alpha: (1.0 - animationValue) * style.effectiveGridColor.a),
        );
      }
      for (final label in yAxisState.current) {
        final y = geometry.normalizedYToScreen(label.normalizedPosition);
        canvas.drawLine(
          Offset(left, y),
          Offset(right, y),
          gridPaint
            ..color = style.effectiveGridColor
                .withValues(alpha: animationValue * style.effectiveGridColor.a),
        );
      }
    } else {
      // Interpolate positions
      for (int i = 0; i < yAxisState.current.length; i++) {
        final current = yAxisState.current[i];
        double normalizedY = current.normalizedPosition;
        if (i < yAxisState.previous.length) {
          final previous = yAxisState.previous[i];
          normalizedY = ui.lerpDouble(
                previous.normalizedPosition,
                current.normalizedPosition,
                animationValue,
              ) ??
              current.normalizedPosition;
        }
        final y = geometry.normalizedYToScreen(normalizedY);
        canvas.drawLine(Offset(left, y), Offset(right, y),
            gridPaint..color = style.effectiveGridColor);
      }
    }

    // Vertical grid lines (at X label positions)
    if (xAxisState.useCrossfade) {
      for (final label in xAxisState.previous) {
        final x = geometry.normalizedXToScreen(label.normalizedPosition);
        canvas.drawLine(
          Offset(x, top),
          Offset(x, bottom),
          gridPaint
            ..color = style.effectiveGridColor.withValues(
                alpha: (1.0 - animationValue) * style.effectiveGridColor.a),
        );
      }
      for (final label in xAxisState.current) {
        final x = geometry.normalizedXToScreen(label.normalizedPosition);
        canvas.drawLine(
          Offset(x, top),
          Offset(x, bottom),
          gridPaint
            ..color = style.effectiveGridColor
                .withValues(alpha: animationValue * style.effectiveGridColor.a),
        );
      }
    } else {
      for (int i = 0; i < xAxisState.current.length; i++) {
        final current = xAxisState.current[i];
        double normalizedX = current.normalizedPosition;
        if (i < xAxisState.previous.length) {
          final previous = xAxisState.previous[i];
          normalizedX = ui.lerpDouble(
                previous.normalizedPosition,
                current.normalizedPosition,
                animationValue,
              ) ??
              current.normalizedPosition;
        }
        final x = geometry.normalizedXToScreen(normalizedX);
        canvas.drawLine(Offset(x, top), Offset(x, bottom),
            gridPaint..color = style.effectiveGridColor);
      }
    }
  }

  static void paintAxisTitles(
    Canvas canvas,
    ChartGeometry geometry,
    ChartStyle style,
    String? xAxisLabel,
    String? yAxisLabel,
  ) {
    if (xAxisLabel != null) {
      final textPainter = TextPainter(
        text: TextSpan(text: xAxisLabel, style: style.axisTitleStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final x =
          geometry.leftMargin + (geometry.drawWidth - textPainter.width) / 2;
      final y = geometry.size.height - bottomMargin(geometry, style);

      textPainter.paint(canvas, Offset(x, y));
    }

    if (yAxisLabel != null) {
      final textPainter = TextPainter(
        text: TextSpan(text: yAxisLabel, style: style.axisTitleStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = style.axisLabelPadding;
      final y =
          geometry.topMargin + (geometry.drawHeight + textPainter.width) / 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-1.5708); // -90 degrees in radians
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  static double bottomMargin(ChartGeometry geometry, ChartStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: 'Xy', style: style.axisLabelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.height + style.axisLabelPadding;
  }
}
