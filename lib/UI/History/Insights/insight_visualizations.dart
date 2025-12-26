import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/Insights/insight_base.dart';
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
    final localizations = QuestionsLocalizations.of(context);
    final name1 = localizations?.value(insight.item1) ?? insight.item1;
    final name2 = localizations?.value(insight.item2) ?? insight.item2;

    final totalDays = insight.totalDays;
    // Width ratio of the gradient bar to the total bar
    final overlapRatio = totalDays > 0 ? insight.occurrences / totalDays : 1.0;

    return SizedBox(
      height: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Full-width background bar with centered gradient overlay
          Stack(
            alignment: Alignment.center,
            children: [
              // Background bar (full width, represents total days)
              Container(
                height: AppPadding.large,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRounding.tiny),
                ),
              ),
              FractionallySizedBox(
                widthFactor: overlapRatio,
                child: Container(
                  height: AppPadding.large,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppRounding.tiny),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name1,
                  style: TextStyle(
                      fontSize: 10,
                      color: colors.primary,
                      fontWeight: FontWeight.w500)),
              Text('${insight.occurrences} of $totalDays days',
                  style:
                      TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
              Text(name2,
                  style: TextStyle(
                      fontSize: 10,
                      color: colors.secondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class SymptomLinkVisualization extends StatelessWidget {
  final SymptomLinkInsight insight;

  const SymptomLinkVisualization({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.symptom1Values.length < 2) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: CustomPaint(
        size: const Size(double.infinity, 48),
        painter: CorrelationLinePainter(
          values1: insight.symptom1Values,
          values2: insight.symptom2Values,
          color1: colors.primary,
          color2: colors.secondary,
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
                valueColor: AlwaysStoppedAnimation(colors.primary),
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
                    colorA: colors.primary,
                    colorB: colors.secondary,
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
