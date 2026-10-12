import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/UI/History/Insights/insight_features.dart';
import 'package:stripes_ui/Insights/insights.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';

void main() {
  TimedDetailResponse record(TimeOfDayEntry precision) {
    final stamp = DateTime(2026, 10, 5, 23);
    return TimedDetailResponse(
      response: DetailResponse(
        id: precision.name,
        stamp: dateToStamp(stamp),
        detailType: 'GI',
        responses: const [],
      ),
      entry: Entry(
        subUserId: 'profile',
        stamp: stamp,
        entityType: InputCategory.event.name,
        timeOfDay: precision,
        data: const {
          recordTimeField: {'localDate': '2026-10-06', 'dayPart': 'morning'},
        },
      ),
    );
  }

  test('hourly and delay features exclude approximate sorting anchors', () {
    const hourly = HourlyCountFeature();
    const timestamps = CategoryTimestampFeature();
    final hours = hourly.createInitialState();
    final times = timestamps.createInitialState();
    for (final precision in [TimeOfDayEntry.morning, TimeOfDayEntry.notSure]) {
      hourly.reduce(hours, record(precision));
      timestamps.reduce(times, record(precision));
    }
    expect(hours, isEmpty);
    expect(times, isEmpty);
    final exact = record(TimeOfDayEntry.exact);
    hourly.reduce(hours, exact);
    timestamps.reduce(times, exact);
    expect(hours, {23: 1});
    expect(times['GI'], [DateTime(2026, 10, 5, 23)]);
  });

  test(
    'daily features retain the recorded occurrence date for unknown time',
    () {
      final unknown = record(TimeOfDayEntry.notSure);
      const weekdays = WeekdayCountFeature();
      const days = DayCategoryFeature();
      expect(weekdays.reduce({}, unknown), {DateTime.tuesday: 1});
      expect(days.reduce({}, unknown), {
        DateTime(2026, 10, 6): {'GI': 1},
      });
    },
  );

  test(
    'active finding engine preserves date precision and excludes unknown hours',
    () {
      final run = runFindingsFromResponses(
        responses: [
          record(TimeOfDayEntry.exact),
          record(TimeOfDayEntry.notSure),
          record(TimeOfDayEntry.morning),
        ],
        windows: FindingWindows(
          focus: InsightTimeWindow(
            start: DateTime(2026, 10, 1),
            endExclusive: DateTime(2026, 10, 8),
          ),
        ),
        catalog: const InsightAnalysisCatalog.empty(),
        rules: const [
          PeakHourRule(
            policy: LoggingRhythmPolicy(minimumEntries: 1, minimumSpanDays: 1),
          ),
        ],
      );
      final entries = run.dataset.entries().toList();
      expect(entries, hasLength(3));
      final unknown = entries.singleWhere(
        (entry) => entry.entryId == TimeOfDayEntry.notSure.name,
      );
      expect(unknown.occurredAt, DateTime(2026, 10, 6));
      expect(unknown.timePrecision, InsightTimePrecision.day);
      final finding = run.accepted.single.finding as PeakHourFinding;
      expect(finding.hourCounts, {23: 1});
      expect(finding.totalEntries, 1);
    },
  );
}
