import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/Insights/insights.dart';

export 'package:stripes_ui/UI/History/Insights/insights.dart';

class ResponseStats {
  final int totalEntries;
  final int uniqueDays;
  final int categoryCount;
  final Map<String, int> entriesByType;
  final double averagePerDay;

  const ResponseStats({
    required this.totalEntries,
    required this.uniqueDays,
    required this.categoryCount,
    required this.entriesByType,
    required this.averagePerDay,
  });

  factory ResponseStats.calculate(List<Response> responses) {
    final Map<String, int> entriesByType = {};
    final Set<DateTime> uniqueDates = {};

    for (final response in responses) {
      entriesByType[response.type] = (entriesByType[response.type] ?? 0) + 1;
      final date = dateFromStamp(response.stamp);
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }

    final avgPerDay =
        uniqueDates.isNotEmpty ? responses.length / uniqueDates.length : 0.0;

    return ResponseStats(
      totalEntries: responses.length,
      uniqueDays: uniqueDates.length,
      categoryCount: entriesByType.length,
      entriesByType: entriesByType,
      averagePerDay: avgPerDay,
    );
  }

  static const empty = ResponseStats(
    totalEntries: 0,
    uniqueDays: 0,
    categoryCount: 0,
    entriesByType: {},
    averagePerDay: 0,
  );
}

final responseStatsProvider = Provider<ResponseStats>((ref) {
  final responses = ref.watch(availableStampsProvider).valueOrNull ?? [];
  if (responses.isEmpty) return ResponseStats.empty;
  return ResponseStats.calculate(responses);
});

class InsightsProps {
  final int? maxInsights;
  const InsightsProps({this.maxInsights});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightsProps && maxInsights == other.maxInsights;

  @override
  int get hashCode => maxInsights.hashCode;
}

final insightsProvider =
    Provider.family<List<Insight>, InsightsProps>((ref, props) {
  final List<Response> responses =
      ref.watch(availableStampsProvider).valueOrNull ?? [];
  if (responses.isEmpty) return [];

  final settings = ref.watch(displayDataProvider);
  final List<Insight> insights = Insight.fromResponses(
    responses,
    timeCycle: settings.cycle,
    range: settings.range,
    filter: InsightPurpose.dashboard,
  );

  if (props.maxInsights != null && insights.length > props.maxInsights!) {
    return insights.take(props.maxInsights!).toList();
  }

  return insights;
});

final allInsightsProvider = Provider<List<Insight>>((ref) {
  return ref.watch(insightsProvider(const InsightsProps()));
});
