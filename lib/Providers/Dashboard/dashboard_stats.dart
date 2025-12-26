import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// Context built from single pass over responses for stats calculation.
class DashboardContext {
  final int totalResponses;
  final Map<DateTime, int> dailyCounts;
  final Map<int, int> weekdayCounts;
  final int uniqueDays;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DashboardContext._({
    required this.totalResponses,
    required this.dailyCounts,
    required this.weekdayCounts,
    required this.uniqueDays,
    this.firstDate,
    this.lastDate,
  });

  factory DashboardContext.build(List<Response> responses) {
    final Map<DateTime, int> dailyCounts = {};
    final Map<int, int> weekdayCounts = {for (var i = 1; i <= 7; i++) i: 0};
    DateTime? firstDate;
    DateTime? lastDate;

    for (final response in responses) {
      final date = dateFromStamp(response.stamp);
      final dayOnly = DateTime(date.year, date.month, date.day);

      dailyCounts[dayOnly] = (dailyCounts[dayOnly] ?? 0) + 1;
      weekdayCounts[date.weekday] = weekdayCounts[date.weekday]! + 1;

      if (firstDate == null || dayOnly.isBefore(firstDate)) {
        firstDate = dayOnly;
      }
      if (lastDate == null || dayOnly.isAfter(lastDate)) {
        lastDate = dayOnly;
      }
    }

    return DashboardContext._(
      totalResponses: responses.length,
      dailyCounts: dailyCounts,
      weekdayCounts: weekdayCounts,
      uniqueDays: dailyCounts.length,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  static const empty = DashboardContext._(
    totalResponses: 0,
    dailyCounts: {},
    weekdayCounts: {},
    uniqueDays: 0,
  );
}

/// Base sealed class for dashboard stats with display priority.
sealed class DashboardStat {
  int get priority;
  String get label;
  String get value;
  IconData get icon;
  Color? get color;

  const DashboardStat();

  /// Build all stats from context.
  static List<DashboardStat> build(DashboardContext ctx) {
    return [
      TotalEntriesStat.tryBuild(ctx),
      UniqueDaysStat.tryBuild(ctx),
      CurrentStreakStat.tryBuild(ctx),
      LongestStreakStat.tryBuild(ctx),
      AveragePerDayStat.tryBuild(ctx),
    ].whereType<DashboardStat>().toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }
}

/// Total entries stat.
class TotalEntriesStat extends DashboardStat {
  final int count;

  const TotalEntriesStat({required this.count});

  @override
  int get priority => 100;

  @override
  String get label => 'Entries';

  @override
  String get value => count.toString();

  @override
  IconData get icon => Icons.note_alt_outlined;

  @override
  Color? get color => null; // Use primary

  static TotalEntriesStat? tryBuild(DashboardContext ctx) {
    return TotalEntriesStat(count: ctx.totalResponses);
  }
}

/// Unique days stat.
class UniqueDaysStat extends DashboardStat {
  final int days;

  const UniqueDaysStat({required this.days});

  @override
  int get priority => 90;

  @override
  String get label => 'Days';

  @override
  String get value => days.toString();

  @override
  IconData get icon => Icons.calendar_today_outlined;

  @override
  Color? get color => null; // Use secondary

  static UniqueDaysStat? tryBuild(DashboardContext ctx) {
    return UniqueDaysStat(days: ctx.uniqueDays);
  }
}

/// Current streak stat.
class CurrentStreakStat extends DashboardStat {
  final int days;

  const CurrentStreakStat({required this.days});

  @override
  int get priority => 80;

  @override
  String get label => 'Streak';

  @override
  String get value => '$days';

  @override
  IconData get icon => Icons.local_fire_department_outlined;

  @override
  Color? get color => Colors.orange;

  static CurrentStreakStat? tryBuild(DashboardContext ctx) {
    if (ctx.dailyCounts.isEmpty) return const CurrentStreakStat(days: 0);

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    int streak = 0;
    var checkDate = todayOnly;

    // Check from today backwards
    while (ctx.dailyCounts.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // If no entry today, check from yesterday
    if (streak == 0) {
      checkDate = todayOnly.subtract(const Duration(days: 1));
      while (ctx.dailyCounts.containsKey(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return CurrentStreakStat(days: streak);
  }
}

/// Longest streak stat.
class LongestStreakStat extends DashboardStat {
  final int days;

  const LongestStreakStat({required this.days});

  @override
  int get priority => 70;

  @override
  String get label => 'Best';

  @override
  String get value => '$days';

  @override
  IconData get icon => Icons.emoji_events_outlined;

  @override
  Color? get color => Colors.amber;

  static LongestStreakStat? tryBuild(DashboardContext ctx) {
    if (ctx.dailyCounts.isEmpty) return const LongestStreakStat(days: 0);

    final sortedDates = ctx.dailyCounts.keys.toList()..sort();
    int longest = 0;
    int current = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      if (i == 0) {
        current = 1;
      } else {
        final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
        current = diff == 1 ? current + 1 : 1;
      }
      if (current > longest) longest = current;
    }

    return LongestStreakStat(days: longest);
  }
}

/// Average per day stat.
class AveragePerDayStat extends DashboardStat {
  final double average;

  const AveragePerDayStat({required this.average});

  @override
  int get priority => 60;

  @override
  String get label => 'Avg/Day';

  @override
  String get value => average.toStringAsFixed(1);

  @override
  IconData get icon => Icons.trending_up;

  @override
  Color? get color => null; // Use tertiary

  static AveragePerDayStat? tryBuild(DashboardContext ctx) {
    if (ctx.uniqueDays == 0) return const AveragePerDayStat(average: 0);
    return AveragePerDayStat(
      average: ctx.totalResponses / ctx.uniqueDays,
    );
  }
}
