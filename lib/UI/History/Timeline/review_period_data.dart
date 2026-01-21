import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

/// Represents a review/check-in period with its time range and associated data.
@immutable
class ReviewPeriod extends Equatable {
  /// The type/name of the review (e.g., "Weekly Check-in")
  final String type;

  /// The date range this review covers
  final DateTimeRange range;

  /// The original stamp/response data
  final Response stamp;

  /// The record path (contains period info)
  final RecordPath? path;

  const ReviewPeriod({
    required this.type,
    required this.range,
    required this.stamp,
    this.path,
  });

  /// Check if this period contains a given date
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return !dateOnly.isBefore(range.start) && !dateOnly.isAfter(range.end);
  }

  /// Check if this period overlaps with another date range
  bool overlaps(DateTimeRange other) {
    return range.start.isBefore(other.end) && range.end.isAfter(other.start);
  }

  @override
  List<Object?> get props => [type, range.start, range.end, stamp.id];
}

/// Provider that computes active review periods from stamps within the display range.
/// Uses the existing recordPaths provider from questions_provider.dart.
final reviewPeriodsProvider = FutureProvider<List<ReviewPeriod>>((ref) async {
  final DisplayDataSettings settings = ref.watch(displayDataProvider);

  // Use existing recordPaths provider for review types
  final List<RecordPath> paths = await ref.watch(
    recordPaths(const RecordPathProps(
      filterEnabled: true,
      type: PathProviderType.review,
    )).future,
  );

  final List<Stamp> allStamps = await ref.watch(stampsStreamProvider.future);

  // Build type -> path mapping
  final Map<String, RecordPath> typeToPath = {
    for (var path in paths) path.name: path
  };

  final List<ReviewPeriod> periods = [];

  for (final stamp in allStamps) {
    if (stamp is! Response) continue;

    final RecordPath? path = typeToPath[stamp.type];
    if (path == null || path.period == null) continue;

    final DateTime stampDate = dateFromStamp(stamp.stamp);
    final DateTimeRange periodRange = path.period!.getRange(stampDate);

    // Only include if it overlaps with current display range
    if (!periodRange.start.isBefore(settings.range.end) ||
        !periodRange.end.isAfter(settings.range.start)) {
      continue;
    }

    periods.add(ReviewPeriod(
      type: stamp.type,
      range: periodRange,
      stamp: stamp,
      path: path,
    ));
  }

  // Sort by start date
  periods.sort((a, b) => a.range.start.compareTo(b.range.start));

  return periods;
});

/// Provider that maps stamp types to their RecordPath (for checking if a type is a review).
final reviewPathsByTypeProvider =
    FutureProvider<Map<String, RecordPath>>((ref) async {
  final List<RecordPath> paths = await ref.watch(
    recordPaths(const RecordPathProps(
      filterEnabled: true,
      type: PathProviderType.review,
    )).future,
  );

  return {for (var path in paths) path.name: path};
});

/// Provider to find which review periods contain a specific date.
final activePeriodsForDateProvider =
    FutureProvider.family<List<ReviewPeriod>, DateTime>((ref, date) async {
  final periods = await ref.watch(reviewPeriodsProvider.future);
  return periods.where((p) => p.containsDate(date)).toList();
});
