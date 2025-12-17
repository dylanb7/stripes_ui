import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// A GitHub-style contribution graph widget showing entry activity over time.
/// Each cell represents a day, with color intensity based on entry count.
class ContributionGraph extends StatelessWidget {
  /// Map of dates to entry counts
  final Map<DateTime, int> data;

  /// Start date for the graph (defaults to 1 month ago)
  final DateTime? startDate;

  /// End date for the graph (defaults to today)
  final DateTime? endDate;

  /// Callback when a date cell is tapped
  final void Function(DateTime date, int count)? onDateTapped;

  /// Maximum entries for full color intensity (auto-calculated if null)
  final int? maxValue;

  const ContributionGraph({
    super.key,
    required this.data,
    this.startDate,
    this.endDate,
    this.onDateTapped,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime end = endDate ?? DateTime.now();
    final DateTime start = startDate ?? end.subtract(const Duration(days: 30));

    // Calculate weeks to display
    final int totalDays = end.difference(start).inDays + 1;
    final int numWeeks = (totalDays / 7).ceil() + 1;

    // Calculate max value for color intensity
    final int calculatedMax = maxValue ??
        (data.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b));
    final int effectiveMax = calculatedMax < 1 ? 1 : calculatedMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels row
        _MonthLabelsRow(start: start, numWeeks: numWeeks),
        const SizedBox(height: AppPadding.tiny),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day of week labels
            _DayLabelsColumn(),
            const SizedBox(width: AppPadding.tiny),
            // Grid of cells
            Expanded(
              child: _ContributionGrid(
                start: start,
                end: end,
                numWeeks: numWeeks,
                data: data,
                maxValue: effectiveMax,
                primaryColor: colors.primary,
                onDateTapped: onDateTapped,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.small),
        // Legend
        _ContributionLegend(primaryColor: colors.primary),
      ],
    );
  }
}

class _MonthLabelsRow extends StatelessWidget {
  final DateTime start;
  final int numWeeks;

  const _MonthLabelsRow({required this.start, required this.numWeeks});

  @override
  Widget build(BuildContext context) {
    final List<Widget> labels = [];
    final DateFormat monthFormat = DateFormat.MMM();

    int currentMonth = -1;
    for (int week = 0; week < numWeeks; week++) {
      final DateTime weekStart = start.add(Duration(days: week * 7));
      if (weekStart.month != currentMonth) {
        currentMonth = weekStart.month;
        labels.add(
          SizedBox(
            width: 14,
            child: Text(
              monthFormat.format(weekStart),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      } else {
        labels.add(const SizedBox(width: 14));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24), // Align with grid
      child: Row(children: labels),
    );
  }
}

class _DayLabelsColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );

    // Show Mon, Wed, Fri labels
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14), // Mon
        SizedBox(height: 14, child: Text('M', style: labelStyle)),
        const SizedBox(height: 14), // Tue
        SizedBox(height: 14, child: Text('W', style: labelStyle)),
        const SizedBox(height: 14), // Thu
        SizedBox(height: 14, child: Text('F', style: labelStyle)),
        const SizedBox(height: 14), // Sat
      ],
    );
  }
}

class _ContributionGrid extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int numWeeks;
  final Map<DateTime, int> data;
  final int maxValue;
  final Color primaryColor;
  final void Function(DateTime date, int count)? onDateTapped;

  const _ContributionGrid({
    required this.start,
    required this.end,
    required this.numWeeks,
    required this.data,
    required this.maxValue,
    required this.primaryColor,
    this.onDateTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(numWeeks, (weekIndex) {
          return Column(
            children: List.generate(7, (dayIndex) {
              final DateTime date = _getDateForCell(weekIndex, dayIndex);
              if (date.isBefore(start) || date.isAfter(end)) {
                return const _EmptyCell();
              }
              final int count = _getCountForDate(date);
              return _ContributionCell(
                date: date,
                count: count,
                maxValue: maxValue,
                primaryColor: primaryColor,
                onTap: onDateTapped != null
                    ? () => onDateTapped!(date, count)
                    : null,
              );
            }),
          );
        }),
      ),
    );
  }

  DateTime _getDateForCell(int week, int dayOfWeek) {
    // Adjust to align with week start (Sunday = 0)
    final int startWeekday = start.weekday % 7;
    final int daysFromStart = (week * 7) + dayOfWeek - startWeekday;
    return DateTime(start.year, start.month, start.day + daysFromStart);
  }

  int _getCountForDate(DateTime date) {
    // Normalize to date only (no time)
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    for (final entry in data.entries) {
      final DateTime entryDate = DateTime(
        entry.key.year,
        entry.key.month,
        entry.key.day,
      );
      if (entryDate == normalized) {
        return entry.value;
      }
    }
    return 0;
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 14, height: 14);
  }
}

class _ContributionCell extends StatelessWidget {
  final DateTime date;
  final int count;
  final int maxValue;
  final Color primaryColor;
  final VoidCallback? onTap;

  const _ContributionCell({
    required this.date,
    required this.count,
    required this.maxValue,
    required this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double intensity = count / maxValue;
    final Color cellColor = _getCellColor(context, intensity);

    return Tooltip(
      message: '${DateFormat.yMMMd().format(date)}: $count entries',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _getCellColor(BuildContext context, double intensity) {
    final Color baseColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    if (count == 0) {
      return baseColor;
    }

    // 4 levels of intensity like GitHub
    if (intensity <= 0.25) {
      return Color.lerp(baseColor, primaryColor, 0.3)!;
    } else if (intensity <= 0.5) {
      return Color.lerp(baseColor, primaryColor, 0.5)!;
    } else if (intensity <= 0.75) {
      return Color.lerp(baseColor, primaryColor, 0.7)!;
    } else {
      return primaryColor;
    }
  }
}

class _ContributionLegend extends StatelessWidget {
  final Color primaryColor;

  const _ContributionLegend({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final Color baseColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final TextStyle? labelStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: labelStyle),
        const SizedBox(width: AppPadding.tiny),
        _LegendCell(color: baseColor),
        _LegendCell(color: Color.lerp(baseColor, primaryColor, 0.3)!),
        _LegendCell(color: Color.lerp(baseColor, primaryColor, 0.5)!),
        _LegendCell(color: Color.lerp(baseColor, primaryColor, 0.7)!),
        _LegendCell(color: primaryColor),
        const SizedBox(width: AppPadding.tiny),
        Text('More', style: labelStyle),
      ],
    );
  }
}

class _LegendCell extends StatelessWidget {
  final Color color;

  const _LegendCell({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
