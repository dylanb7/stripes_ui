import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/Insights/insight_visualizations.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Util/Helpers/stats.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import 'package:stripes_ui/UI/History/Insights/insight_features.dart';

export 'package:stripes_ui/UI/History/Insights/insight_features.dart';

typedef InsightBuilder = List<Insight> Function(HistoryContext);

class InsightRegistration {
  final InsightBuilder builder;
  final Set<ReducibleFeature> features;
  const InsightRegistration(this.builder, this.features);
}

enum InsightPurpose { dashboard, report }

abstract class Insight {
  int get priority;
  double get significance;
  String getTitle(BuildContext? context);
  String getDescription(BuildContext? context);
  TextSpan getDescriptionSpan(BuildContext context) =>
      TextSpan(text: getDescription(context));
  IconData? get icon;
  Widget? buildVisualization(BuildContext context) => null;

  Set<InsightPurpose> get purposes =>
      {InsightPurpose.dashboard, InsightPurpose.report};

  const Insight();

  static List<Insight> fromResponses(
    List<Response> responses, {
    TimeCycle? timeCycle,
    DateTimeRange? range,
    InsightPurpose? filter,
  }) {
    final Set<ReducibleFeature> allFeatures = <ReducibleFeature>{};
    for (final reg in _registrations) {
      allFeatures.addAll(reg.features);
    }

    final HistoryContext ctx = HistoryContext.build(
      responses: responses,
      features: allFeatures.toList(),
      timeCycle: timeCycle ?? TimeCycle.custom,
      range: range,
    );
    return tryBuildAll(ctx, filter: filter);
  }

  static List<Insight> tryBuildAll(HistoryContext ctx,
      {InsightPurpose? filter}) {
    final List<Insight> results = [];
    for (final reg in _registrations) {
      final List<Insight> insights = reg.builder(ctx);
      if (filter != null) {
        results.addAll(insights.where((i) => i.purposes.contains(filter)));
      } else {
        results.addAll(insights);
      }
    }
    // Combined rank: Lower is better (Higher in list)
    // Category priority provides the base, Significance allows bubbling (up to 20 points)
    return results
      ..sort((a, b) => (a.priority - a.significance * 20.0)
          .compareTo(b.priority - b.significance * 20.0));
  }

  static const List<InsightRegistration> _registrations = [
    PeakActivityInsight.registration,
    MostActiveDayInsight.registration,
    ActivityTrendInsight.registration,
    WeeklyPatternInsight.registration,
    CommonPairingInsight.registration,
    SymptomLinkInsight.registration,
    SymptomTrendInsight.registration,
    MostTrackedCategoryInsight.registration,
    AbnormalEntryInsight.registration,
    TimeRelationInsight.registration,
  ];
}

class PeakActivityInsight extends Insight {
  final PeakWindow peak;
  final int percentage;
  final double timesExpected;
  final List<int> hourlyList;
  @override
  final double significance;

  const PeakActivityInsight({
    required this.peak,
    required this.percentage,
    required this.timesExpected,
    required this.hourlyList,
    required this.significance,
  });

  static const registration = InsightRegistration(
    PeakActivityInsight.tryBuild,
    {HourlyCountFeature(), TotalResponsesFeature()},
  );

  @override
  int get priority => 100;

  @override
  String getTitle(BuildContext? context) => 'Peak Activity';

  @override
  String getDescription(BuildContext? context) {
    final hourRange =
        '${_formatHour(peak.startHour)} - ${_formatHour(peak.endHour + 1)}';
    return '$hourRange ($percentage% of entries, ${timesExpected.toStringAsFixed(1)}× expected)';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hourRange =
        '${_formatHour(peak.startHour)} - ${_formatHour(peak.endHour + 1)}';
    final multiplier = '${timesExpected.toStringAsFixed(1)}×';

    return TextSpan(
      children: [
        TextSpan(text: '$hourRange ($percentage% of entries, '),
        TextSpan(
          text: multiplier,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' expected)'),
      ],
    );
  }

  @override
  IconData get icon => Icons.schedule;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      PeakActivityVisualization(insight: this);

  static List<PeakActivityInsight> tryBuild(HistoryContext ctx) {
    final hourCounts = ctx.use(const HourlyCountFeature());
    if (hourCounts.isEmpty) return [];
    final hourlyList = List.generate(24, (h) => hourCounts[h] ?? 0);
    final peak = findPeakWindow(hourlyList);
    if (peak.count <= 0) return [];
    final totalResponses = ctx.totalResponses;
    final percentage = (peak.count / totalResponses * 100).round();
    final expectedCount = totalResponses * peak.duration / 24;
    final timesExpected = expectedCount > 0 ? peak.count / expectedCount : 1.0;
    return [
      PeakActivityInsight(
        peak: peak,
        percentage: percentage,
        timesExpected: timesExpected,
        hourlyList: hourlyList,
        significance: (timesExpected / 3.0).clamp(0.0, 1.0),
      )
    ];
  }

  static String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12am';
    if (hour == 12) return '12pm';
    if (hour < 12) return '${hour}am';
    return '${hour - 12}pm';
  }
}

class MostActiveDayInsight extends Insight {
  final int peakWeekday;
  final String dayName;
  final int count;
  final int percentage;
  final double timesExpected;
  final List<int> weekdayCounts;
  @override
  final double significance;

  const MostActiveDayInsight({
    required this.peakWeekday,
    required this.dayName,
    required this.count,
    required this.percentage,
    required this.timesExpected,
    required this.weekdayCounts,
    required this.significance,
  });

  static const registration = InsightRegistration(
    MostActiveDayInsight.tryBuild,
    {WeekdayCountFeature(), TotalResponsesFeature()},
  );

  @override
  int get priority => 90;

  @override
  String getTitle(BuildContext? context) => 'Most Active Day';

  @override
  String getDescription(BuildContext? context) =>
      '$dayName ($percentage% of entries, ${timesExpected.toStringAsFixed(1)}× expected)';

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final multiplier = '${timesExpected.toStringAsFixed(1)}×';
    return TextSpan(
      children: [
        TextSpan(text: '$dayName ($percentage% of entries, '),
        TextSpan(
          text: multiplier,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' expected)'),
      ],
    );
  }

  @override
  IconData get icon => Icons.calendar_today;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      MostActiveDayVisualization(insight: this);

  static List<MostActiveDayInsight> tryBuild(HistoryContext ctx) {
    final dayCounts = ctx.use(const WeekdayCountFeature());
    if (dayCounts.isEmpty) return [];
    if (ctx.timeCycle == TimeCycle.day) return [];
    final weekdayCounts = List.generate(7, (i) => dayCounts[i + 1] ?? 0);
    final sortedDays = dayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakDay = sortedDays.first.key;
    final peakDayCount = sortedDays.first.value;
    final totalResponses = ctx.totalResponses;
    final percentage = (peakDayCount / totalResponses * 100).round();
    final expectedCount = totalResponses / 7;
    final timesExpected =
        expectedCount > 0 ? peakDayCount / expectedCount : 1.0;
    return [
      MostActiveDayInsight(
        peakWeekday: peakDay,
        dayName: _dayName(peakDay),
        count: peakDayCount,
        percentage: percentage,
        timesExpected: timesExpected,
        weekdayCounts: weekdayCounts,
        significance: ((timesExpected - 1.0) / 1.0).clamp(0.0, 1.0),
      )
    ];
  }

  static String _dayName(int weekday) => switch (weekday) {
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday',
        7 => 'Sunday',
        _ => 'Unknown',
      };
}

class ActivityTrendInsight extends Insight {
  final double slope;
  final double percentChangePerUnit;
  final List<double> dailyValues;
  final double intercept;

  const ActivityTrendInsight({
    required this.slope,
    required this.percentChangePerUnit,
    required this.dailyValues,
    required this.intercept,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    ActivityTrendInsight.tryBuild,
    {DailyCountFeature()},
  );

  @override
  int get priority => 70;

  @override
  String getTitle(BuildContext? context) => 'Activity Trend';

  @override
  String getDescription(BuildContext? context) {
    final direction = slope > 0 ? 'increasing' : 'decreasing';
    final pct = percentChangePerUnit.abs().toStringAsFixed(0);
    return 'Recording frequency $direction by ~$pct% per day';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final direction = slope > 0 ? 'increasing' : 'decreasing';
    final pct = '~${percentChangePerUnit.abs().toStringAsFixed(0)}%';
    return TextSpan(
      children: [
        const TextSpan(text: 'Recording frequency '),
        TextSpan(
          text: direction,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' by '),
        TextSpan(
          text: pct,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' per day'),
      ],
    );
  }

  @override
  IconData get icon => slope > 0 ? Icons.trending_up : Icons.trending_down;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      ActivityTrendVisualization(insight: this);

  static List<ActivityTrendInsight> tryBuild(HistoryContext ctx) {
    final dailyCounts = ctx.use(const DailyCountFeature());
    if (dailyCounts.length < 3) return [];
    // Activity trends require multiple days of data
    if (ctx.timeCycle == TimeCycle.day) return [];
    final sortedDates = dailyCounts.keys.toList()..sort();
    final firstDay = sortedDates.first;
    final xValues = sortedDates
        .map((d) => d.difference(firstDay).inDays.toDouble())
        .toList();
    final yValues = sortedDates.map((d) => dailyCounts[d]!.toDouble()).toList();
    final regression = linearRegression(xValues, yValues);
    if (regression == null || regression.percentChangePerUnit.abs() < 10) {
      return [];
    }
    return [
      ActivityTrendInsight(
        slope: regression.slope,
        percentChangePerUnit: regression.percentChangePerUnit,
        dailyValues: yValues,
        intercept: regression.intercept,
        significance:
            (regression.percentChangePerUnit.abs() / 50.0).clamp(0.0, 1.0),
      )
    ];
  }
}

class WeeklyPatternInsight extends Insight {
  final bool moreOnWeekend;
  final double ratio;
  final double weekdayAvg;
  final double weekendAvg;

  const WeeklyPatternInsight({
    required this.moreOnWeekend,
    required this.ratio,
    required this.weekdayAvg,
    required this.weekendAvg,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    WeeklyPatternInsight.tryBuild,
    {WeekdayCountFeature()},
  );

  @override
  int get priority => 60;

  @override
  String getTitle(BuildContext? context) => 'Weekly Pattern';

  @override
  String getDescription(BuildContext? context) =>
      '${ratio.toStringAsFixed(1)}× more active on ${moreOnWeekend ? "weekends" : "weekdays"}';

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final multiplier = '${ratio.toStringAsFixed(1)}×';
    return TextSpan(
      children: [
        TextSpan(
          text: multiplier,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        TextSpan(
            text: ' more active on ${moreOnWeekend ? "weekends" : "weekdays"}'),
      ],
    );
  }

  @override
  IconData get icon => Icons.trending_up;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      WeeklyPatternVisualization(insight: this);

  static List<WeeklyPatternInsight> tryBuild(HistoryContext ctx) {
    final dayCounts = ctx.use(const WeekdayCountFeature());
    if (dayCounts.isEmpty) return [];
    // Need multiple weeks to detect a weekly pattern
    if (ctx.timeCycle == TimeCycle.day || ctx.timeCycle == TimeCycle.week) {
      return [];
    }
    int weekdayCount = 0;
    int weekendCount = 0;
    for (final entry in dayCounts.entries) {
      if (entry.key >= 6) {
        weekendCount += entry.value;
      } else {
        weekdayCount += entry.value;
      }
    }
    final weekdayAvg = weekdayCount / 5;
    final weekendAvg = weekendCount / 2;
    if (weekdayAvg <= 0 && weekendAvg <= 0) return [];
    final moreOnWeekend = weekendAvg > weekdayAvg;
    final higher = moreOnWeekend ? weekendAvg : weekdayAvg;
    final lower = moreOnWeekend ? weekdayAvg : weekendAvg;
    final ratio = lower > 0 ? higher / lower : 1.0;
    if (ratio < 1.3) return [];
    return [
      WeeklyPatternInsight(
        moreOnWeekend: moreOnWeekend,
        ratio: ratio,
        weekdayAvg: weekdayAvg,
        weekendAvg: weekendAvg,
        significance: ((ratio - 1.3) / (2.5 - 1.3)).clamp(0.0, 1.0),
      )
    ];
  }
}

class CommonPairingInsight extends Insight {
  final String item1;
  final String item2;
  final int occurrences;
  final int percentage;
  final int item1Count;
  final int item2Count;
  final int totalDays;

  const CommonPairingInsight({
    required this.item1,
    required this.item2,
    required this.occurrences,
    required this.percentage,
    required this.item1Count,
    required this.item2Count,
    required this.totalDays,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    CommonPairingInsight.tryBuild,
    {DayCategoryFeature(), TotalResponsesFeature()},
  );

  @override
  int get priority => 50;

  @override
  String getTitle(BuildContext? context) => 'Common Pairing';

  @override
  String getDescription(BuildContext? context) {
    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    final name1 = localizations?.value(item1) ?? item1;
    final name2 = localizations?.value(item2) ?? item2;
    return '$name1 + $name2 appear together $percentage% of days';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final name1 = localizations?.value(item1) ?? item1;
    final name2 = localizations?.value(item2) ?? item2;
    return TextSpan(
      children: [
        TextSpan(
          text: name1,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' + '),
        TextSpan(
          text: name2,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: colors.secondary),
        ),
        const TextSpan(text: ' appear together '),
        TextSpan(
          text: '$percentage%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ' of days'),
      ],
    );
  }

  @override
  IconData get icon => Icons.link;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      CommonPairingVisualization(insight: this);

  static List<CommonPairingInsight> tryBuild(HistoryContext ctx) {
    if (ctx.totalResponses < 10) return [];

    if (ctx.timeCycle == TimeCycle.day) return [];

    final Map<DateTime, Map<String, int>> categoriesByDay =
        ctx.use(const DayCategoryFeature());
    final coOccurrence = findTopCoOccurrence(
        categoriesByDay.map((date, items) => MapEntry(date, items.keys)));
    if (coOccurrence == null || coOccurrence.occurrences < 3) {
      return [];
    }

    final totalDays = ctx.totalDaysInRange;
    final percentage = totalDays > 0
        ? (coOccurrence.occurrences / totalDays * 100).round()
        : coOccurrence.percentage.round();
    if (percentage < 30) return [];

    int item1Count = 0;
    int item2Count = 0;
    for (final items in categoriesByDay.values) {
      if (items.containsKey(coOccurrence.item1)) item1Count++;
      if (items.containsKey(coOccurrence.item2)) item2Count++;
    }
    return [
      CommonPairingInsight(
        item1: coOccurrence.item1,
        item2: coOccurrence.item2,
        occurrences: coOccurrence.occurrences,
        percentage: percentage,
        item1Count: item1Count,
        item2Count: item2Count,
        totalDays: totalDays,
        significance: (percentage / 100.0).clamp(0.0, 1.0),
      )
    ];
  }
}

class SymptomLinkInsight extends Insight {
  final String symptom1;
  final String symptom2;
  final double rho;
  final String strength;
  final bool positive;
  final List<double> symptom1Values;
  final List<double> symptom2Values;

  const SymptomLinkInsight({
    required this.symptom1,
    required this.symptom2,
    required this.rho,
    required this.strength,
    required this.positive,
    required this.symptom1Values,
    required this.symptom2Values,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    SymptomLinkInsight.tryBuild,
    {DaySymptomFeature(), TotalResponsesFeature()},
  );

  @override
  int get priority => 40;

  @override
  String getTitle(BuildContext? context) => 'Symptom Link';

  @override
  String getDescription(BuildContext? context) {
    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    final name1 = localizations?.value(symptom1) ?? symptom1;
    final name2 = localizations?.value(symptom2) ?? symptom2;
    final linkType =
        positive ? 'tend to increase together' : 'move in opposite directions';
    return '$name1 & $name2 $linkType ($strength)';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final name1 = localizations?.value(symptom1) ?? symptom1;
    final name2 = localizations?.value(symptom2) ?? symptom2;
    final linkType = positive ? 'increase together' : 'move opposite';
    return TextSpan(
      children: [
        TextSpan(
          text: name1,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' & '),
        TextSpan(
          text: name2,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: colors.secondary),
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: linkType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: ' ($strength)'),
      ],
    );
  }

  @override
  IconData get icon => Icons.insights;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      SymptomLinkVisualization(insight: this);

  static List<SymptomLinkInsight> tryBuild(HistoryContext ctx) {
    if (ctx.totalResponses < 10) return [];
    // Symptom correlations require multiple days of data
    if (ctx.timeCycle == TimeCycle.day) return [];
    final Map<String, List<double>> symptomDailyAvgs = {};
    final symptomsByDay = ctx.use(const DaySymptomFeature());
    final sortedDays = symptomsByDay.keys.toList()..sort();
    for (final day in sortedDays) {
      final dayData = symptomsByDay[day]!;
      for (final symptom in dayData.keys) {
        final values = dayData[symptom]!;
        final avg = values.reduce((a, b) => a + b) / values.length;
        symptomDailyAvgs.putIfAbsent(symptom, () => []).add(avg);
      }
    }
    SpearmanResult? bestCorrelation;
    String? bestPair1;
    String? bestPair2;
    final symptoms = symptomDailyAvgs.keys.toList();
    for (int i = 0; i < symptoms.length - 1; i++) {
      for (int j = i + 1; j < symptoms.length; j++) {
        final vals1 = symptomDailyAvgs[symptoms[i]]!;
        final vals2 = symptomDailyAvgs[symptoms[j]]!;
        final minLen =
            vals1.length < vals2.length ? vals1.length : vals2.length;
        if (minLen < 5) continue;
        final result = spearmanCorrelation(
          vals1.sublist(0, minLen),
          vals2.sublist(0, minLen),
        );
        if (result != null && result.rho.abs() > 0.4) {
          if (bestCorrelation == null ||
              result.rho.abs() > bestCorrelation.rho.abs()) {
            bestCorrelation = result;
            bestPair1 = symptoms[i];
            bestPair2 = symptoms[j];
          }
        }
      }
    }
    if (bestCorrelation == null) return [];
    final vals1 = symptomDailyAvgs[bestPair1]!;
    final vals2 = symptomDailyAvgs[bestPair2]!;
    final minLen = vals1.length < vals2.length ? vals1.length : vals2.length;
    return [
      SymptomLinkInsight(
        symptom1: bestPair1!,
        symptom2: bestPair2!,
        rho: bestCorrelation.rho,
        strength: bestCorrelation.strength,
        positive: bestCorrelation.rho > 0,
        symptom1Values: vals1.sublist(0, minLen),
        symptom2Values: vals2.sublist(0, minLen),
        significance: bestCorrelation.rho.abs().clamp(0.0, 1.0),
      )
    ];
  }
}

class SymptomTrendInsight extends Insight {
  final String symptomName;
  final double percentChange;
  final bool isDecreasing;
  final List<double> dailyValues;
  final int dayCount;
  final double startValue;
  final double endValue;
  final double strength; // Spearman correlation absolute value

  const SymptomTrendInsight({
    required this.symptomName,
    required this.percentChange,
    required this.isDecreasing,
    required this.dailyValues,
    required this.dayCount,
    required this.startValue,
    required this.endValue,
    required this.strength,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    SymptomTrendInsight.tryBuild,
    {DaySymptomFeature()},
  );

  @override
  int get priority => 35;

  @override
  String getTitle(BuildContext? context) => 'Symptom Trend';

  @override
  String getDescription(BuildContext? context) {
    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    final name = localizations?.value(symptomName) ?? symptomName;
    final direction = isDecreasing ? 'decreasing' : 'increasing';
    final absPercent = percentChange.abs().round();
    return '$name $direction ~$absPercent% over $dayCount days';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final name = localizations?.value(symptomName) ?? symptomName;
    final direction = isDecreasing ? 'decreasing' : 'increasing';
    final absPercent = percentChange.abs().round();
    return TextSpan(
      children: [
        TextSpan(
          text: name,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: direction,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
        TextSpan(text: ' ~$absPercent% over $dayCount days'),
      ],
    );
  }

  @override
  IconData get icon => isDecreasing ? Icons.trending_down : Icons.trending_up;

  @override
  @override
  Widget buildVisualization(BuildContext context) =>
      SymptomTrendVisualization(insight: this);

  static List<SymptomTrendInsight> tryBuild(HistoryContext ctx) {
    final symptomsByDay = ctx.use(const DaySymptomFeature());
    if (symptomsByDay.isEmpty || symptomsByDay.length < 5) return [];
    if (ctx.timeCycle == TimeCycle.day) return [];

    final Map<String, List<double>> symptomDailyAvgs = {};
    final sortedDays = symptomsByDay.keys.toList()..sort();
    for (final day in sortedDays) {
      final dayData = symptomsByDay[day]!;
      for (final symptom in dayData.keys) {
        final values = dayData[symptom]!;
        final avg = values.reduce((a, b) => a + b) / values.length;
        symptomDailyAvgs.putIfAbsent(symptom, () => []).add(avg);
      }
    }

    final List<SymptomTrendInsight> results = [];

    for (final entry in symptomDailyAvgs.entries) {
      if (entry.value.length < 5) continue;
      final List<double> values = entry.value;

      final x = List.generate(values.length, (i) => i.toDouble());
      final rhoResult = spearmanCorrelation(x, values);
      final strength = rhoResult?.rho.abs() ?? 0;

      final double first = values.first;
      final double last = values.last;
      if (first == 0) continue;
      final double actualPercentChange = ((last - first) / first) * 100;

      // Only include significant trends (strength > 0.70)
      if (actualPercentChange.abs() > 15 && strength > 0.7) {
        results.add(SymptomTrendInsight(
          symptomName: entry.key,
          percentChange: actualPercentChange,
          isDecreasing: last < first,
          dailyValues: values,
          dayCount: values.length,
          startValue: first,
          endValue: last,
          strength: strength,
          significance: strength.clamp(0.0, 1.0),
        ));
      }
    }
    return results;
  }
}

// =============================================================================
// Category Insights
// =============================================================================

class MostTrackedCategoryInsight extends Insight {
  final String categoryName;
  final int count;
  final int totalCount;
  final int percentage;

  const MostTrackedCategoryInsight({
    required this.categoryName,
    required this.count,
    required this.totalCount,
    required this.percentage,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    MostTrackedCategoryInsight.tryBuild,
    {DayCategoryFeature(), TotalResponsesFeature()},
  );

  @override
  int get priority => 60;

  @override
  String getTitle(BuildContext? context) => 'Most Tracked';

  @override
  String getDescription(BuildContext? context) {
    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    final name = localizations?.value(categoryName) ?? categoryName;
    return '$name is your most tracked item ($percentage%)';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final name = localizations?.value(categoryName) ?? categoryName;
    return TextSpan(
      children: [
        TextSpan(
          text: name,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: ' is your most tracked item ('),
        TextSpan(
          text: '$percentage%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ')'),
      ],
    );
  }

  @override
  IconData get icon => Icons.category_outlined;

  @override
  Widget buildVisualization(BuildContext context) =>
      MostTrackedCategoryVisualization(insight: this);

  static List<MostTrackedCategoryInsight> tryBuild(HistoryContext ctx) {
    final Map<DateTime, Map<String, int>> categoriesByDay =
        ctx.use(const DayCategoryFeature());
    if (categoriesByDay.isEmpty) return [];
    final Map<String, int> categoryCounts = {};
    int totalCount = 0;
    for (final categories in categoriesByDay.values) {
      for (final cat in categories.keys) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + categories[cat]!;
        totalCount += categories[cat]!;
      }
    }
    if (categoryCounts.isEmpty) return [];
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final percentage = (top.value / totalCount * 100).round();
    if (sorted.length < 2) return [];
    return [
      MostTrackedCategoryInsight(
        categoryName: top.key,
        count: top.value,
        totalCount: totalCount,
        percentage: percentage,
        significance: (percentage / 100.0).clamp(0.0, 1.0),
      )
    ];
  }
}

class AbnormalEntryInsight extends Insight {
  final String description;
  final IconData? customIcon;
  final double? mean;
  final double? stdDev;
  final double? outlierValue;
  final String? symptomName;

  const AbnormalEntryInsight({
    required this.description,
    this.customIcon,
    this.mean,
    this.stdDev,
    this.outlierValue,
    this.symptomName,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    AbnormalEntryInsight.tryBuild,
    {
      GlobalSymptomValueFeature(),
      DayCategoryFeature(),
      TotalResponsesFeature()
    },
  );

  @override
  int get priority => 20;

  @override
  String getTitle(BuildContext? context) => 'Unusual Activity';

  @override
  String getDescription(BuildContext? context) {
    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    if (customIcon == Icons.new_releases_outlined) {
      final name = localizations?.value(description) ?? description;
      return 'You logged "$name" for the first time recently.';
    }
    return description;
  }

  @override
  IconData get icon => customIcon ?? Icons.warning_amber_rounded;

  @override
  Widget? buildVisualization(BuildContext context) =>
      AbnormalEntryVisualization(insight: this);

  static List<AbnormalEntryInsight> tryBuild(HistoryContext ctx) {
    final categoryCounts = ctx.use(const DayCategoryFeature());
    final totalDays = ctx.daysWithData;
    if (totalDays > 10) {
      final Map<String, int> counts = {};
      for (final cats in categoryCounts.values) {
        for (final cat in cats.entries) {
          counts[cat.key] = (counts[cat.key] ?? 0) + cat.value;
        }
      }
      for (final entry in counts.entries) {
        if (entry.value == 1) {
          return [
            AbnormalEntryInsight(
              description: entry.key,
              customIcon: Icons.new_releases_outlined,
              significance: 0.8,
            )
          ];
        }
      }
    }

    final allSymptomValues = ctx.use(const GlobalSymptomValueFeature());
    for (final entry in allSymptomValues.entries) {
      final values = entry.value;
      if (values.length < 10) continue;

      final mean = calculateMean(values);
      final stdDev = calculateStandardDeviation(values);
      if (stdDev == 0) continue;

      final lastValue = values.last;
      final zScore = (lastValue - mean).abs() / stdDev;

      if (zScore > 1.4) {
        final level = lastValue > mean ? 'high' : 'low';
        return [
          AbnormalEntryInsight(
            description:
                'Your most recent ${entry.key} level was unusually $level.',
            mean: mean,
            stdDev: stdDev,
            outlierValue: lastValue,
            symptomName: entry.key,
            significance: (zScore / 5.0).clamp(0.4, 1.0),
          )
        ];
      }
    }

    return [];
  }
}

class TimePoint {
  final DateTime date;
  final double timeA;
  final double timeB;
  const TimePoint(this.date, this.timeA, this.timeB);
}

class TimeRelationInsight extends Insight {
  final String factorA;
  final String factorB;
  final double averageLagHours;
  final double stdDevLag;
  final List<TimePoint> points;

  const TimeRelationInsight({
    required this.factorA,
    required this.factorB,
    required this.averageLagHours,
    required this.stdDevLag,
    required this.points,
    required this.significance,
  });

  @override
  final double significance;

  static const registration = InsightRegistration(
    TimeRelationInsight.tryBuild,
    {CategoryTimestampFeature()},
  );

  @override
  int get priority => 30;

  @override
  String getTitle(BuildContext? context) => 'Temporal Link';

  @override
  String getDescription(BuildContext? context) {
    final totalMinutes = (averageLagHours * 60).round();
    final roundedMinutes = ((totalMinutes / 10).round() * 10);
    final hours = roundedMinutes ~/ 60;
    final mins = roundedMinutes % 60;

    String timeStr;
    if (hours > 0 && mins > 0) {
      timeStr = '$hours hours and $mins minutes';
    } else if (hours > 0) {
      timeStr = '$hours hours';
    } else {
      timeStr = '$mins minutes';
    }

    final localizations =
        context != null ? QuestionsLocalizations.of(context) : null;
    final nameA = localizations?.value(factorA) ?? factorA;
    final nameB = localizations?.value(factorB) ?? factorB;
    return '$nameB tends to happen $timeStr after $nameA.';
  }

  @override
  TextSpan getDescriptionSpan(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);
    final nameA = localizations?.value(factorA) ?? factorA;
    final nameB = localizations?.value(factorB) ?? factorB;

    final totalMinutes = (averageLagHours * 60).round();
    final roundedMinutes = ((totalMinutes / 10).round() * 10);
    final hours = roundedMinutes ~/ 60;
    final mins = roundedMinutes % 60;

    final List<TextSpan> timeSpans = [];
    if (hours > 0) {
      timeSpans.add(TextSpan(
        text: '$hours hours',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
    }
    if (hours > 0 && mins > 0) {
      timeSpans.add(const TextSpan(text: ' and '));
    }
    if (mins > 0 || (hours == 0 && mins == 0)) {
      timeSpans.add(TextSpan(
        text: '$mins minutes',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
    }

    return TextSpan(
      children: [
        TextSpan(
          text: nameB,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: colors.secondary),
        ),
        const TextSpan(text: ' tends to happen '),
        ...timeSpans,
        const TextSpan(text: ' after '),
        TextSpan(
          text: nameA,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const TextSpan(text: '.'),
      ],
    );
  }

  @override
  IconData get icon => Icons.timer_outlined;

  @override
  Widget? buildVisualization(BuildContext context) =>
      TimeRelationVisualization(insight: this);

  static List<TimeRelationInsight> tryBuild(HistoryContext ctx) {
    final timestampsMap = ctx.use(const CategoryTimestampFeature());
    if (timestampsMap.length < 2) return [];

    final categories = timestampsMap.keys.toList();
    for (int i = 0; i < categories.length; i++) {
      for (int j = 0; j < categories.length; j++) {
        if (i == j) continue;
        final catA = categories[i];
        final catB = categories[j];

        final timesA = timestampsMap[catA]!;
        final timesB = timestampsMap[catB]!;

        if (timesA.length < 3 || timesB.length < 3) continue;

        final List<double> lags = [];
        final List<TimePoint> points = [];
        for (final timeA in timesA) {
          // Find the first timeB after timeA within 24 hours
          DateTime? nextB;
          for (final timeB in timesB) {
            if (timeB.isAfter(timeA)) {
              final diff = timeB.difference(timeA).inMinutes / 60.0;
              if (diff <= 24) {
                if (nextB == null || timeB.isBefore(nextB)) {
                  nextB = timeB;
                }
              }
            }
          }
          if (nextB != null) {
            final lag = nextB.difference(timeA).inMinutes / 60.0;
            lags.add(lag);
            final dayOnly = DateTime(timeA.year, timeA.month, timeA.day);
            points.add(TimePoint(
              dayOnly,
              timeA.hour + timeA.minute / 60.0,
              nextB.hour + nextB.minute / 60.0,
            ));
          }
        }

        if (lags.length >= 4 && lags.length >= timesA.length * 0.5) {
          final meanLag = calculateMean(lags);
          final stdDev = calculateStandardDeviation(lags);

          if (meanLag > 0.5 && (stdDev / meanLag) < 0.35) {
            return [
              TimeRelationInsight(
                factorA: catA,
                factorB: catB,
                averageLagHours: meanLag,
                stdDevLag: stdDev,
                points: points,
                significance: (1.0 - (stdDev / meanLag) / 0.35).clamp(0.0, 1.0),
              )
            ];
          }
        }
      }
    }
    return [];
  }
}
