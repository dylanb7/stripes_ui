import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/UI/History/Insights/insights.dart';

import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Dashboard/dashboard_state_provider.dart';

final weekRangeProvider = Provider<DateTimeRange>((ref) {
  return ref.watch(dashboardStateProvider.select((state) => state.range));
});

final weekResponsesProvider = Provider<List<Response>>((ref) {
  final stamps = ref
      .watch(stampsStreamProvider)
      .when(
        data: (value) => value,
        loading: () => const <Stamp>[],
        error: (_, _) => const <Stamp>[],
      );
  final range = ref.watch(weekRangeProvider);
  final start = range.start;
  final endExclusive = DateRangeUtils.exclusiveEndOfDay(range.end);
  return stamps.whereType<Response>().where((r) {
    final d = dateFromStamp(r.stamp);
    return !d.isBefore(start) && d.isBefore(endExclusive);
  }).toList();
});

class WeekStats {
  final int entries;
  final int days;
  final Set<DateTime> activeDates;
  const WeekStats({
    required this.entries,
    required this.days,
    required this.activeDates,
  });
}

final weekStatsProvider = Provider<WeekStats>((ref) {
  final responses = ref.watch(weekResponsesProvider);
  if (responses.isEmpty) {
    return const WeekStats(entries: 0, days: 0, activeDates: {});
  }

  final daySet = <DateTime>{};
  for (final r in responses) {
    final d = dateFromStamp(r.stamp);
    daySet.add(DateTime(d.year, d.month, d.day));
  }

  return WeekStats(
    entries: responses.length,
    days: daySet.length,
    activeDates: daySet,
  );
});

final streakProvider = Provider<int>((ref) {
  final allStamps = ref
      .watch(stampsStreamProvider)
      .when(
        data: (value) => value,
        loading: () => const <Stamp>[],
        error: (_, _) => const <Stamp>[],
      );
  final allDays = <DateTime>{};
  for (final s in allStamps.whereType<Response>()) {
    final d = dateFromStamp(s.stamp);
    allDays.add(DateTime(d.year, d.month, d.day));
  }
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  int streak = 0;
  var check = today;
  while (allDays.contains(check)) {
    streak++;
    check = DateRangeUtils.shiftCalendarDays(check, -1);
  }
  if (streak == 0) {
    check = DateRangeUtils.shiftCalendarDays(today, -1);
    while (allDays.contains(check)) {
      streak++;
      check = DateRangeUtils.shiftCalendarDays(check, -1);
    }
  }
  return streak;
});

final weekInsightsProvider = Provider<List<Insight>>((ref) {
  final responses = ref.watch(weekResponsesProvider);
  if (responses.isEmpty) return [];
  final range = ref.watch(weekRangeProvider);
  final days = ref.watch(dashboardStateProvider.select((s) => s.periodDays));
  final timeCycle = days == 7
      ? TimeCycle.week
      : (days == 30 ? TimeCycle.month : TimeCycle.custom);
  return Insight.fromResponses(
    responses,
    timeCycle: timeCycle,
    range: DateTimeRange(
      start: range.start,
      end: DateRangeUtils.exclusiveEndOfDay(range.end),
    ),
  );
});

final dashboardCheckinsProvider = FutureProvider<List<ReviewItem>>((ref) async {
  const pathProps = RecordPathProps(
    filterEnabled: true,
    type: PathProviderType.review,
  );
  final List<RecordPath> paths = await ref.watch(recordPaths(pathProps).future);
  final List<Stamp> stamps = await ref.watch(stampsStreamProvider.future);
  final range = ref.watch(weekRangeProvider);

  final rangeStart = range.start;
  final rangeEndExclusive = DateRangeUtils.exclusiveEndOfDay(range.end);

  final List<ReviewItem> completed = [];
  for (final recordPath in paths) {
    final searchType = recordPath.name;
    final List<Stamp> valid = stamps.where((element) {
      final DateTime stampTime = dateFromStamp(element.stamp);
      return element.type == searchType &&
          !stampTime.isBefore(rangeStart) &&
          stampTime.isBefore(rangeEndExclusive);
    }).toList();

    for (final stamp in valid) {
      completed.add(
        ReviewItem(
          path: recordPath,
          type: searchType,
          response: stamp as DetailResponse,
        ),
      );
    }
  }

  completed.sort((a, b) {
    if (a.response == null || b.response == null) return 0;
    return b.response!.stamp.compareTo(a.response!.stamp);
  });

  return completed;
});

// =============================================================================
// Sticky header delegate — reusable for "Today" and "This Week" sections
// =============================================================================

class DashboardSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const DashboardSectionHeaderDelegate({
    required this.child,
    this.height = 56.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(DashboardSectionHeaderDelegate old) =>
      old.child != child || old.height != height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: shrinkOffset > 0 ? 1 : 0,
      child: SizedBox.expand(child: child),
    );
  }
}

// =============================================================================
// Staggered fade-in animation wrapper
// =============================================================================

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInSlide({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    super.key,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// =============================================================================
// Global streak badge
// =============================================================================

class GlobalStreakBadge extends ConsumerWidget {
  const GlobalStreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    if (streak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8922A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8922A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: Color(0xFFE8922A),
          ),
          const SizedBox(width: 4),
          Text(
            '$streak day streak',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE8922A),
            ),
          ),
        ],
      ),
    );
  }
}
