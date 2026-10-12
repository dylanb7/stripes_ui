import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/questions/questions_provider.dart';

final _reviewTypesProvider = FutureProvider<Set<String>>((ref) async {
  final reviewPaths = await ref.watch(
      questionGraphProvider.selectAsync((value) => value.reviewPathsByType()));
  return reviewPaths.keys.toSet();
});

final todayResponsesProvider = FutureProvider<List<Response>>((ref) async {
  final stamps = await ref.watch(stampsStreamProvider.future);
  final reviewTypes = await ref.watch(_reviewTypesProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  return stamps
      .whereType<Response>()
      .where((r) =>
          !dateFromStamp(r.stamp).isBefore(todayStart) &&
          !reviewTypes.contains(r.type))
      .toList()
    ..sort((a, b) => b.stamp.compareTo(a.stamp));
});

final todayCategoryCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final responses = await ref.watch(todayResponsesProvider.future);
  final Map<String, int> counts = {};
  for (final r in responses) {
    counts[r.type] = (counts[r.type] ?? 0) + 1;
  }
  return counts;
});

final recentEntriesProvider = FutureProvider<List<Response>>((ref) async {
  final stamps = await ref.watch(stampsStreamProvider.future);
  final reviewTypes = await ref.watch(_reviewTypesProvider.future);
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  return stamps
      .whereType<Response>()
      .where((r) =>
          dateFromStamp(r.stamp).isAfter(cutoff) &&
          !reviewTypes.contains(r.type))
      .toList()
    ..sort((a, b) => b.stamp.compareTo(a.stamp));
});
