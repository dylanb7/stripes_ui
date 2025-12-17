import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history/stamps_provider.dart';

/// Provides aggregated entry counts by day for the contribution graph.
/// Only fetches the last 30 days of data for performance.
/// Returns a Map<DateTime, int> where DateTime is normalized to midnight.
final contributionDataProvider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime cutoff = today.subtract(const Duration(days: 30));

  final Map<DateTime, int> counts = {};

  for (final stamp in stamps) {
    final DateTime date = dateFromStamp(stamp.stamp);
    final DateTime normalized = DateTime(date.year, date.month, date.day);

    // Only count entries from the last 30 days
    if (normalized.isBefore(cutoff)) continue;

    counts[normalized] = (counts[normalized] ?? 0) + 1;
  }

  return counts;
});

/// Provides stats for the dashboard.
/// Stats are based on the last 30 days of data.
class DashboardStats {
  final int totalEntriesThisMonth;
  final int entriesThisWeek;
  final int currentStreak;
  final int bestStreakThisMonth;
  final DateTime? lastEntryDate;
  final double averagePerDay;

  const DashboardStats({
    required this.totalEntriesThisMonth,
    required this.entriesThisWeek,
    required this.currentStreak,
    required this.bestStreakThisMonth,
    required this.lastEntryDate,
    required this.averagePerDay,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalEntriesThisMonth: 0,
        entriesThisWeek: 0,
        currentStreak: 0,
        bestStreakThisMonth: 0,
        lastEntryDate: null,
        averagePerDay: 0,
      );
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final Map<DateTime, int> data =
      await ref.watch(contributionDataProvider.future);

  if (data.isEmpty) {
    return DashboardStats.empty();
  }

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime weekAgo = today.subtract(const Duration(days: 7));

  int totalEntriesThisMonth = 0;
  int entriesThisWeek = 0;
  DateTime? lastEntryDate;

  final List<DateTime> sortedDates = data.keys.toList()..sort();

  for (final entry in data.entries) {
    totalEntriesThisMonth += entry.value;

    if (!entry.key.isBefore(weekAgo)) {
      entriesThisWeek += entry.value;
    }

    if (lastEntryDate == null || entry.key.isAfter(lastEntryDate)) {
      lastEntryDate = entry.key;
    }
  }

  // Calculate current streak (from today backwards)
  int currentStreak = 0;
  DateTime checkDate = today;
  while (data.containsKey(checkDate) && data[checkDate]! > 0) {
    currentStreak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }

  // If no entry today, check if yesterday had one (streak is still valid)
  if (currentStreak == 0) {
    checkDate = today.subtract(const Duration(days: 1));
    while (data.containsKey(checkDate) && data[checkDate]! > 0) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
  }

  // Calculate best streak this month
  int bestStreakThisMonth = 0;
  int tempStreak = 0;
  for (int i = 0; i < sortedDates.length; i++) {
    if (i == 0) {
      tempStreak = 1;
    } else {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        tempStreak = 1;
      }
    }
    if (tempStreak > bestStreakThisMonth) {
      bestStreakThisMonth = tempStreak;
    }
  }

  // Calculate average per day (only days with entries)
  final int daysWithData = data.length;
  final double average =
      daysWithData > 0 ? totalEntriesThisMonth / daysWithData : 0;

  return DashboardStats(
    totalEntriesThisMonth: totalEntriesThisMonth,
    entriesThisWeek: entriesThisWeek,
    currentStreak: currentStreak,
    bestStreakThisMonth: bestStreakThisMonth,
    lastEntryDate: lastEntryDate,
    averagePerDay: average,
  );
});
