import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/Insights/insight_base.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class PeakActivityVisualization extends StatelessWidget {
  final PeakActivityInsight insight;

  const PeakActivityVisualization({super.key, required this.insight});

  bool _isInPeak(int hour) {
    if (insight.peak.startHour <= insight.peak.endHour) {
      return hour >= insight.peak.startHour && hour <= insight.peak.endHour;
    } else {
      return hour >= insight.peak.startHour || hour <= insight.peak.endHour;
    }
  }

  String _formatHour(BuildContext context, int hour) {
    final time = DateTime(2000, 1, 1, hour % 24);
    return DateFormat.j().format(time);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxCount = insight.hourlyList.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (hour) {
                final count = insight.hourlyList[hour];
                final heightRatio = count / maxCount;
                final isPeak = _isInPeak(hour);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: AppPadding.tiny + (heightRatio * 28),
                    decoration: BoxDecoration(
                      color: isPeak
                          ? colors.primary
                          : colors.onSurfaceVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppPadding.tiny),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatHour(context, 0),
                  style:
                      TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
              Text(_formatHour(context, 23),
                  style:
                      TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class MostActiveDayVisualization extends StatelessWidget {
  final MostActiveDayInsight insight;

  const MostActiveDayVisualization({super.key, required this.insight});

  List<String> _getLocalizedDayLabels(BuildContext context) {
    final DateFormat dateFormat = DateFormat.E();

    return List.generate(7, (index) {
      final DateTime day = DateTime(2026, 1, 5 + index);
      final String label = dateFormat.format(day);

      return label.isNotEmpty ? label[0].toUpperCase() : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int maxCount = insight.weekdayCounts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();

    final List<String> dayLabels = _getLocalizedDayLabels(context);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final int dayIndex = index + 1;
          final int count = insight.weekdayCounts[index];
          final double heightRatio = maxCount > 0 ? count / maxCount : 0.0;
          final bool isPeak = dayIndex == insight.peakWeekday;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.1 + (heightRatio * 0.9),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isPeak
                                ? colors.primary
                                : colors.onSurfaceVariant
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                      color: isPeak ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ActivityTrendVisualization extends StatelessWidget {
  final ActivityTrendInsight insight;

  const ActivityTrendVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.dailyValues.length < 2) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final dayCount = insight.dailyValues.length;

    return SizedBox(
      height: 52,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: TrendSparklinePainter(
                values: insight.dailyValues,
                slope: insight.slope,
                intercept: insight.intercept,
                lineColor: colors.onSurfaceVariant.withValues(alpha: 0.3),
                trendColor: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppPadding.tiny),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day 1',
                  style:
                      TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
              Text('Day $dayCount',
                  style:
                      TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class WeeklyPatternVisualization extends StatelessWidget {
  final WeeklyPatternInsight insight;

  const WeeklyPatternVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxAvg = insight.weekdayAvg > insight.weekendAvg
        ? insight.weekdayAvg
        : insight.weekendAvg;
    if (maxAvg == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBar(colors, 'Weekdays', insight.weekdayAvg, maxAvg,
              !insight.moreOnWeekend),
          _buildBar(colors, 'Weekends', insight.weekendAvg, maxAvg,
              insight.moreOnWeekend),
        ],
      ),
    );
  }

  Widget _buildBar(ColorScheme colors, String label, double value,
      double maxAvg, bool isHighlighted) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / maxAvg,
            child: Container(
              height: AppPadding.large,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRounding.tiny),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)}/day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Correlation Insight Visualizations
// =============================================================================

class CommonPairingVisualization extends StatelessWidget {
  final CommonPairingInsight insight;

  const CommonPairingVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color1 = CategoryTheme.resolve(insight.item1).color;
    final color2 = CategoryTheme.resolve(insight.item2).color;

    if (insight.dailyPresence.isEmpty) return const SizedBox.shrink();

    // Show most recent days, cap at 21
    final days = insight.dailyPresence.length > 21
        ? insight.dailyPresence
            .sublist(insight.dailyPresence.length - 21)
        : insight.dailyPresence;

    // Derive counts from displayed days to stay in sync
    final displayedOverlap = days.where((d) => d.hasBoth).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: item1 (color matches the first name in the description)
        Row(
          children: List.generate(days.length, (i) {
            final day = days[i];
            final present = day.hasItem1;
            final overlap = day.hasBoth;
            return Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: present
                      ? (overlap
                          ? color1
                          : color1.withValues(alpha: 0.3))
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 3),
        // Row 2: item2 (color matches the second name in the description)
        Row(
          children: List.generate(days.length, (i) {
            final day = days[i];
            final present = day.hasItem2;
            final overlap = day.hasBoth;
            return Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: present
                      ? (overlap
                          ? color2
                          : color2.withValues(alpha: 0.3))
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppPadding.small),
        // Footer — derived from displayed days
        Text(
          'Together $displayedOverlap/${days.length} days',
          style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class SymptomLinkVisualization extends StatelessWidget {
  final SymptomLinkInsight insight;

  const SymptomLinkVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.symptom1Values.length < 2) return const SizedBox.shrink();

    final color1 = CategoryTheme.resolve(
        insight.category1 ?? insight.symptom1).color;
    final color2 = CategoryTheme.resolve(
        insight.category2 ?? insight.symptom2).color;

    return SizedBox(
      height: 48,
      child: CustomPaint(
        size: const Size(double.infinity, 48),
        painter: CorrelationLinePainter(
          values1: insight.symptom1Values,
          values2: insight.symptom2Values,
          color1: color1,
          color2: color2,
        ),
      ),
    );
  }
}

class SymptomTrendVisualization extends StatelessWidget {
  final SymptomTrendInsight insight;

  const SymptomTrendVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.dailyValues.length < 2) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final trendColor = colors.primary;

    final String significance;
    final Color significanceColor;
    if (insight.strength > 0.85) {
      significance = 'High Significance';
      significanceColor = colors.primary;
    } else if (insight.strength > 0.7) {
      significance = 'Medium Significance';
      significanceColor = colors.secondary;
    } else {
      significance = 'Low Significance';
      significanceColor = colors.outline;
    }

    return Column(
      children: [
        SizedBox(
          height: 64,
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      insight.dailyValues
                          .reduce((a, b) => a > b ? a : b)
                          .toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 8, color: colors.onSurfaceVariant)),
                  Text(
                      insight.dailyValues
                          .reduce((a, b) => a < b ? a : b)
                          .toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 8, color: colors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 64),
                  painter: SymptomTrendPainter(
                    values: insight.dailyValues,
                    lineColor: colors.onSurfaceVariant.withValues(alpha: 0.1),
                    trendColor: trendColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              significance,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: significanceColor,
              ),
            ),
            Text(
              '${insight.dayCount} days',
              style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class MostTrackedCategoryVisualization extends StatelessWidget {
  final MostTrackedCategoryInsight insight;

  const MostTrackedCategoryVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final catColor = CategoryTheme.resolve(insight.categoryName).color;

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRounding.tiny),
              child: LinearProgressIndicator(
                value: insight.percentage / 100,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(catColor),
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: AppPadding.small),
          Text(
            '${insight.count} of ${insight.totalCount} entries',
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Advanced Insight Visualizations
// =============================================================================

class AbnormalEntryVisualization extends StatelessWidget {
  final AbnormalEntryInsight insight;

  const AbnormalEntryVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.mean == null ||
        insight.stdDev == null ||
        insight.outlierValue == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final mean = insight.mean!;
    final stdDev = insight.stdDev!;
    final val = insight.outlierValue!;

    // Range to show: mean +/- 3 stdDev
    final min = mean - 3 * stdDev;
    final max = mean + 3 * stdDev;
    final range = max - min;

    final ratio = range > 0 ? (val - min) / range : 0.5;

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Normal range background (mean +/- 1 stdDev)
              FractionallySizedBox(
                widthFactor: (2 * stdDev) / range,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Thin line for the full range
              Container(
                height: 1,
                width: double.infinity,
                color: colors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
              // Outlier point
              Align(
                alignment: Alignment(ratio * 2 - 1, 0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.error.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lower',
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
            Text('Average',
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
            Text('Higher',
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class TimeRelationVisualization extends StatelessWidget {
  final TimeRelationInsight insight;

  const TimeRelationVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.points.isEmpty) return const SizedBox.shrink();

    final colorA = CategoryTheme.resolve(insight.factorA).color;
    final colorB = CategoryTheme.resolve(insight.factorB).color;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            children: [
              // Y-Axis: Time of Day
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(const TimeOfDay(hour: 0, minute: 0).format(context),
                      style: TextStyle(fontSize: 8, color: colors.outline)),
                  Text(const TimeOfDay(hour: 12, minute: 0).format(context),
                      style: TextStyle(fontSize: 8, color: colors.outline)),
                  Text(const TimeOfDay(hour: 23, minute: 0).format(context),
                      style: TextStyle(fontSize: 8, color: colors.outline)),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: TemporalShiftPainter(
                    points: insight.points,
                    colorA: colorA,
                    colorB: colorB,
                    onSurfaceColor: colors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Custom Painters
// =============================================================================

class TrendSparklinePainter extends CustomPainter {
  final List<double> values;
  final double slope;
  final double intercept;
  final Color lineColor;
  final Color trendColor;

  TrendSparklinePainter({
    required this.values,
    required this.slope,
    required this.intercept,
    required this.lineColor,
    required this.trendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    const padding = AppPadding.tiny;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = padding + (i / (values.length - 1)) * drawWidth;
      final y = padding + (1 - (values[i] - minVal) / range) * drawHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final trendPaint = Paint()
      ..color = trendColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startTrendY = intercept;
    final endTrendY = intercept + slope * (values.length - 1);
    final startY = padding + (1 - (startTrendY - minVal) / range) * drawHeight;
    final endY = padding + (1 - (endTrendY - minVal) / range) * drawHeight;

    canvas.drawLine(
      Offset(padding, startY.clamp(padding, size.height - padding)),
      Offset(size.width - padding, endY.clamp(padding, size.height - padding)),
      trendPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TrendSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.slope != slope ||
        oldDelegate.trendColor != trendColor;
  }
}

class CorrelationLinePainter extends CustomPainter {
  final List<double> values1;
  final List<double> values2;
  final Color color1;
  final Color color2;

  CorrelationLinePainter({
    required this.values1,
    required this.values2,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values1.isEmpty || values2.isEmpty) return;

    const padding = AppPadding.tiny;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    List<double> normalize(List<double> values) {
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final range = max - min;
      if (range == 0) return values.map((v) => 0.5).toList();
      return values.map((v) => (v - min) / range).toList();
    }

    final norm1 = normalize(values1);
    final norm2 = normalize(values2);

    final paint1 = Paint()
      ..color = color1
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    for (int i = 0; i < norm1.length; i++) {
      final x = padding + (i / (norm1.length - 1)) * drawWidth;
      final y = padding + (1 - norm1[i]) * drawHeight;
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = color2
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    for (int i = 0; i < norm2.length; i++) {
      final x = padding + (i / (norm2.length - 1)) * drawWidth;
      final y = padding + (1 - norm2[i]) * drawHeight;
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CorrelationLinePainter oldDelegate) {
    return oldDelegate.values1 != values1 ||
        oldDelegate.values2 != values2 ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2;
  }
}

class SymptomTrendPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color trendColor;

  SymptomTrendPainter({
    required this.values,
    required this.lineColor,
    required this.trendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    const padding = AppPadding.tiny;
    final drawWidth = size.width - 2 * padding;
    final drawHeight = size.height - 2 * padding;

    final linePaint = Paint()
      ..color = trendColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = padding + (i / (values.length - 1)) * drawWidth;
      final y = padding + (1 - (values[i] - minVal) / range) * drawHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SymptomTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.trendColor != trendColor;
  }
}

class TemporalShiftPainter extends CustomPainter {
  final List<TimePoint> points;
  final Color colorA;
  final Color colorB;
  final Color onSurfaceColor;

  TemporalShiftPainter({
    required this.points,
    required this.colorA,
    required this.colorB,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final drawWidth = size.width;
    final drawHeight = size.height;

    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shadedPaint = Paint()
      ..color = colorA.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw 24h grid lines (dashed or light)
    for (int h = 0; h <= 24; h += 6) {
      final y = (h / 24.0) * drawHeight;
      canvas.drawLine(Offset(0, y), Offset(drawWidth, y), gridPaint);
    }

    // Sort points by date
    final sortedPoints = List<TimePoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    final pathA = Path();
    final pathB = Path();

    // We draw the shaded area segment by segment to handle wrap-around correctly
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final p1 = sortedPoints[i];
      final p2 = sortedPoints[i + 1];

      final x1 = (i / (sortedPoints.length - 1)) * drawWidth;
      final x2 = ((i + 1) / (sortedPoints.length - 1)) * drawWidth;

      final yA1 = (p1.timeA / 24.0) * drawHeight;
      final yB1 = (p1.timeB / 24.0) * drawHeight;
      final yA2 = (p2.timeA / 24.0) * drawHeight;
      final yB2 = (p2.timeB / 24.0) * drawHeight;

      if (i == 0) pathA.moveTo(x1, yA1);
      pathA.lineTo(x2, yA2);

      if (i == 0) pathB.moveTo(x1, yB1);
      pathB.lineTo(x2, yB2);

      // Construct shaded region for this segment
      final segmentPath = Path();
      if (p1.timeB >= p1.timeA && p2.timeB >= p2.timeA) {
        // Simple case: no wrap around
        segmentPath.moveTo(x1, yA1);
        segmentPath.lineTo(x2, yA2);
        segmentPath.lineTo(x2, yB2);
        segmentPath.lineTo(x1, yB1);
        segmentPath.close();
        canvas.drawPath(segmentPath, shadedPaint);
      } else if (p1.timeB < p1.timeA && p2.timeB < p2.timeA) {
        // Wrap around case: both cross midnight
        segmentPath.moveTo(x1, yA1);
        segmentPath.lineTo(x2, yA2);
        segmentPath.lineTo(x2, drawHeight);
        segmentPath.lineTo(x1, drawHeight);
        segmentPath.close();
        canvas.drawPath(segmentPath, shadedPaint);

        final segmentPath2 = Path();
        segmentPath2.moveTo(x1, 0);
        segmentPath2.lineTo(x2, 0);
        segmentPath2.lineTo(x2, yB2);
        segmentPath2.lineTo(x1, yB1);
        segmentPath2.close();
        canvas.drawPath(segmentPath2, shadedPaint);
      } else {
        // Transition case
        segmentPath.moveTo(x1, yA1);
        segmentPath.lineTo(x2, yA2);
        segmentPath.lineTo(x2, yB2);
        segmentPath.lineTo(x1, yB1);
        segmentPath.close();
        canvas.drawPath(segmentPath, shadedPaint);
      }
    }
    canvas.drawPath(pathA, paintA);
    canvas.drawPath(pathB, paintB);

    // Draw discrete points
    final dotPaintA = Paint()
      ..color = colorA
      ..style = PaintingStyle.fill;
    final dotPaintB = Paint()
      ..color = colorB
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      final x = (i / (sortedPoints.length - 1)) * drawWidth;
      final yA = (p.timeA / 24.0) * drawHeight;
      final yB = (p.timeB / 24.0) * drawHeight;
      canvas.drawCircle(Offset(x, yA), 3, dotPaintA);
      canvas.drawCircle(Offset(x, yB), 3, dotPaintB);
    }
  }

  @override
  bool shouldRepaint(covariant TemporalShiftPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB;
  }
}

// =============================================================================
// New Insight Visualizations
// =============================================================================

class DominantChoiceVisualization extends StatelessWidget {
  final DominantChoiceInsight insight;

  const DominantChoiceVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);

    // Sorted distribution entries, limit to 5 with "Other" bucket
    final entries = insight.distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, int>> displayEntries;
    if (entries.length > 5) {
      displayEntries = entries.take(4).toList();
      final otherCount = entries.skip(4).fold(0, (sum, e) => sum + e.value);
      displayEntries.add(MapEntry('Other', otherCount));
    } else {
      displayEntries = entries;
    }

    final maxCount = displayEntries.first.value;

    return Column(
      children: displayEntries.asMap().entries.map((indexed) {
        final i = indexed.key;
        final entry = indexed.value;
        final isDominant = i == 0;
        final pct =
            (entry.value / insight.totalForQuestion * 100).round();
        final widthFactor = maxCount > 0 ? entry.value / maxCount : 0.0;
        final choiceName = entry.key == 'Other'
            ? 'Other'
            : (localizations?.value(entry.key) ?? entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  choiceName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isDominant ? FontWeight.bold : FontWeight.normal,
                    color: isDominant
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppPadding.tiny),
              Expanded(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: Container(
                    height: isDominant ? 10 : 6,
                    decoration: BoxDecoration(
                      color: isDominant
                          ? colors.primary
                          : colors.onSurfaceVariant
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.tiny),
              SizedBox(
                width: 32,
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isDominant ? FontWeight.bold : FontWeight.normal,
                    color: isDominant
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BurstDetectionVisualization extends StatelessWidget {
  final BurstDetectionInsight insight;

  const BurstDetectionVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final List<Widget> strips = [];

    // Show top 2 cluster days
    for (int i = 0; i < insight.clusterDays.length && i < 2; i++) {
      final day = insight.clusterDays[i];
      strips.add(_buildStrip(
        context,
        label: DateFormat.MMMd().format(day.date),
        timestamps: day.hourTimestamps,
        clusterStart: day.clusterStartHour,
        clusterEnd: day.clusterEndHour,
        isCluster: true,
      ));
      if (i < 1 && insight.clusterDays.length > 1) {
        strips.add(const SizedBox(height: 4));
      }
    }

    // Show typical day for contrast
    if (insight.typicalDayTimestamps != null) {
      strips.add(const SizedBox(height: 4));
      strips.add(_buildStrip(
        context,
        label: 'Typical',
        timestamps: insight.typicalDayTimestamps!,
        isCluster: false,
      ));
    }

    return Column(
      children: [
        ...strips,
        const SizedBox(height: AppPadding.tiny),
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12am',
                      style: TextStyle(
                          fontSize: 9, color: colors.onSurfaceVariant)),
                  Text('12pm',
                      style: TextStyle(
                          fontSize: 9, color: colors.onSurfaceVariant)),
                  Text('12am',
                      style: TextStyle(
                          fontSize: 9, color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrip(
    BuildContext context, {
    required String label,
    required List<double> timestamps,
    double? clusterStart,
    double? clusterEnd,
    required bool isCluster,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCluster ? FontWeight.bold : FontWeight.normal,
                color: isCluster ? colors.primary : colors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppPadding.tiny),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 20),
              painter: StripPlotPainter(
                timestamps: timestamps,
                clusterStart: clusterStart,
                clusterEnd: clusterEnd,
                isCluster: isCluster,
                dotColor: isCluster ? colors.primary : colors.onSurfaceVariant,
                highlightColor: colors.primaryContainer,
                trackColor:
                    colors.onSurfaceVariant.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StripPlotPainter extends CustomPainter {
  final List<double> timestamps;
  final double? clusterStart;
  final double? clusterEnd;
  final bool isCluster;
  final Color dotColor;
  final Color highlightColor;
  final Color trackColor;

  StripPlotPainter({
    required this.timestamps,
    this.clusterStart,
    this.clusterEnd,
    required this.isCluster,
    required this.dotColor,
    required this.highlightColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Draw track line
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, centerY), Offset(size.width, centerY), trackPaint);

    // Draw cluster highlight band
    if (isCluster && clusterStart != null && clusterEnd != null) {
      final startX = (clusterStart! / 24.0) * size.width;
      final endX = (clusterEnd! / 24.0) * size.width;
      final bandPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
              startX - 6, 0, endX + 6, size.height),
          const Radius.circular(4),
        ),
        bandPaint,
      );
    }

    // Draw dots at timestamp positions
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    final greyDotPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final hour in timestamps) {
      final x = (hour / 24.0) * size.width;
      final isInCluster = isCluster &&
          clusterStart != null &&
          clusterEnd != null &&
          hour >= clusterStart! &&
          hour <= clusterEnd!;
      canvas.drawCircle(
        Offset(x, centerY),
        isInCluster ? 4.0 : 3.0,
        isInCluster ? dotPaint : (isCluster ? greyDotPaint : dotPaint),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StripPlotPainter oldDelegate) {
    return oldDelegate.timestamps != timestamps ||
        oldDelegate.clusterStart != clusterStart ||
        oldDelegate.dotColor != dotColor;
  }
}

class RecordingConsistencyVisualization extends StatelessWidget {
  final RecordingConsistencyInsight insight;

  const RecordingConsistencyVisualization(
      {super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final presence = insight.dailyPresence;

    // Use multi-row grid if > 21 days, single strip otherwise
    if (presence.length > 21) {
      return _buildGrid(context);
    }
    return _buildStrip(context);
  }

  Widget _buildStrip(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final presence = insight.dailyPresence;

    return Column(
      children: [
        Row(
          children: List.generate(presence.length, (i) {
            final present = presence[i];
            final isInStreak =
                i >= presence.length - insight.currentStreak;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 12,
                decoration: BoxDecoration(
                  color: present
                      ? (isInStreak
                          ? colors.primary
                          : colors.primary
                              .withValues(alpha: 0.4))
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppPadding.tiny),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${insight.daysRecorded}/${insight.totalDays} days',
              style: TextStyle(
                  fontSize: 9, color: colors.onSurfaceVariant),
            ),
            if (insight.currentStreak > 0)
              Text(
                'streak: ${insight.currentStreak}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final presence = insight.dailyPresence;

    // Pad to complete weeks (multiple of 7)
    final int paddedLength = ((presence.length + 6) ~/ 7) * 7;
    final int padCount = paddedLength - presence.length;
    final paddedPresence = [
      ...List.filled(padCount, false),
      ...presence,
    ];
    final int weeks = paddedPresence.length ~/ 7;

    return Column(
      children: [
        // Day headers
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 9,
                              color: colors.onSurfaceVariant)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        // Week rows
        ...List.generate(weeks, (week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: List.generate(7, (day) {
                final idx = week * 7 + day;
                final isPadding = idx < padCount;
                final present = paddedPresence[idx];
                final originalIdx = idx - padCount;
                final isInStreak = !isPadding &&
                    originalIdx >=
                        presence.length - insight.currentStreak;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 12,
                    decoration: BoxDecoration(
                      color: isPadding
                          ? Colors.transparent
                          : present
                              ? (isInStreak
                                  ? colors.primary
                                  : colors.primary
                                      .withValues(alpha: 0.4))
                              : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: AppPadding.tiny),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${insight.daysRecorded}/${insight.totalDays} days',
              style: TextStyle(
                  fontSize: 9, color: colors.onSurfaceVariant),
            ),
            if (insight.currentStreak > 0)
              Text(
                'streak: ${insight.currentStreak}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
