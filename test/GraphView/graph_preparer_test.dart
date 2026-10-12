import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

void main() {
  timingRegressionTests();
  test('time-of-day graphs retain exact, approximate and unknown timing', () {
    const question = Numeric(
      id: 'pain',
      prompt: 'Pain',
      type: 'GI',
      min: 0,
      max: 10,
    );
    final day = DateTime(2026, 10, 6);
    final morningAnchor = DateTime(2026, 10, 6, 6);
    final exactTime = DateTime(2026, 10, 6, 9, 15);
    final approximateChild = NumericResponse(
      question: question,
      stamp: dateToStamp(morningAnchor),
      response: 4,
    );
    final nestedApproximateChild = NumericResponse(
      question: question,
      stamp: dateToStamp(morningAnchor),
      response: 6,
    );
    final exactChild = NumericResponse(
      question: question,
      stamp: dateToStamp(exactTime),
      response: 2,
    );

    TimedDetailResponse timedRecord({
      required DateTime stamp,
      required TimeOfDayEntry precision,
      required List<Response> responses,
    }) => TimedDetailResponse(
      response: DetailResponse(
        stamp: dateToStamp(stamp),
        detailType: 'GI',
        responses: responses,
      ),
      entry: Entry(
        subUserId: 'profile',
        stamp: stamp,
        entityType: InputCategory.event.name,
        data: const {},
        timeOfDay: precision,
      ),
    );

    final approximateRecord = timedRecord(
      stamp: morningAnchor,
      precision: TimeOfDayEntry.morning,
      responses: [
        approximateChild,
        DetailResponse(
          stamp: dateToStamp(morningAnchor),
          detailType: 'Nested symptoms',
          responses: [nestedApproximateChild],
        ),
      ],
    );
    final unknownRecord = timedRecord(
      stamp: day,
      precision: TimeOfDayEntry.notSure,
      responses: const [],
    );
    final exactRecord = timedRecord(
      stamp: exactTime,
      precision: TimeOfDayEntry.exact,
      responses: [exactChild],
    );
    const categoryKey = GraphKey(
      title: 'GI records',
      isCategory: true,
      type: 'GI',
    );
    const questionKey = GraphKey(
      title: 'Pain',
      isCategory: false,
      qid: 'pain',
      type: 'GI',
    );
    final graph = GraphPreparer.prepare(
      responses: {
        categoryKey: [approximateRecord, unknownRecord, exactRecord],
        // Question-level graph queries flatten wrappers before preparation.
        questionKey: [approximateChild, nestedApproximateChild, exactChild],
      },
      settings: DisplayDataSettings(
        window: TimeWindow(
          range: DateTimeRange(start: day, end: DateTime(2026, 10, 7)),
          cycle: TimeCycle.week,
        ),
        axis: GraphYAxis.entrytime,
      ),
      comparison: GraphComparison.separate,
      colorResolver: (_) => Colors.blue,
    );

    expect(graph.query.metric, GraphMetric.timeOfDay);
    final points = graph.series
        .where((s) => s.mark == GraphMark.point)
        .toList();
    expect(points, hasLength(2));
    for (final series in points) {
      expect(series.data, hasLength(2));
      final exact = series.data.singleWhere(
        (d) => d.timing == GraphTiming.exact,
      );
      final approximate = series.data.singleWhere(
        (d) => d.timing == GraphTiming.dayPart,
      );
      expect(exact.value, 9.25);
      expect(exact.valueEnd, isNull);
      expect(approximate.value, 6);
      expect(approximate.valueEnd, 12);
      expect(approximate.xStart, DateTime(2026, 10, 6, 12));
    }
    final unknown = graph.series.singleWhere(
      (s) => s.id.timing == GraphTiming.unknown,
    );
    expect(unknown.data.single.xStart, day);
    expect(unknown.data.single.xEnd, DateTime(2026, 10, 7));
    expect(unknown.data.single.evidence, [unknownRecord]);
    expect(graph.isEmpty, isFalse);
  });

  test('preparation preserves missing averages and its response input', () {
    const Numeric question = Numeric(
      id: 'pain',
      prompt: 'Pain',
      type: 'GI',
      min: 0,
      max: 10,
    );
    final List<Response> source = <Response>[
      NumericResponse(
        question: question,
        stamp: dateToStamp(DateTime(2025, 1, 1, 12, 40)),
        response: 6,
      ),
      NumericResponse(
        question: question,
        stamp: dateToStamp(DateTime(2025, 1, 1, 12, 10)),
        response: 2,
      ),
    ];
    final List<int> originalOrder = source
        .map((Response response) => response.stamp)
        .toList();
    const GraphKey key = GraphKey(
      title: 'Pain',
      isCategory: false,
      qid: 'pain',
      type: 'GI',
    );
    final DisplayDataSettings settings = DisplayDataSettings(
      window: TimeWindow(
        range: DateTimeRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 1, 2),
        ),
        cycle: TimeCycle.day,
      ),
      axis: GraphYAxis.average,
    );

    final PreparedGraph graph = GraphPreparer.prepare(
      responses: <GraphKey, List<Response>>{key: source},
      settings: settings,
      comparison: GraphComparison.stacked,
      colorResolver: (_) => Colors.blue,
    );

    expect(graph.query.comparison, GraphComparison.separate);
    expect(graph.query.bins, hasLength(24));
    final List<PreparedDatum> populated = graph.series.single.data
        .where((PreparedDatum datum) => datum.value != null)
        .toList();
    expect(populated, hasLength(1));
    expect(populated.single.value, 4);
    expect(populated.single.summary.reportCount, 2);
    expect(
      graph.series.single.data
          .where((PreparedDatum datum) => datum.id != populated.single.id)
          .every((PreparedDatum datum) => datum.value == null),
      isTrue,
    );
    expect(
      source.map((Response response) => response.stamp),
      orderedEquals(originalOrder),
    );
  });
}

const _category = GraphKey(title: 'GI', isCategory: true, type: 'GI');
const _questionKey = GraphKey(
  title: 'Pain',
  isCategory: false,
  type: 'GI',
  qid: 'pain',
);
const _numeric = Numeric(
  id: 'pain',
  prompt: 'Pain',
  type: 'GI',
  min: 0,
  max: 10,
);

TimedDetailResponse _timed(
  String id, {
  RecordTimePrecision precision = RecordTimePrecision.exact,
  RecordDayPart? part,
  int value = 2,
  DateTime? stamp,
  String? localDate,
}) {
  final timing = RecordTime(
    precision: precision,
    dayPart: part,
    exactTime: const TimeOfDay(hour: 9, minute: 15),
  );
  final date = DateTime(2026, 10, 6);
  final recordedStamp = stamp ?? timing.stampOn(date);
  return TimedDetailResponse(
    response: DetailResponse(
      id: id,
      detailType: 'GI',
      stamp: dateToStamp(recordedStamp),
      responses: [
        NumericResponse(
          question: _numeric,
          response: value,
          stamp: dateToStamp(recordedStamp),
        ),
      ],
    ),
    entry: Entry(
      id: id,
      subUserId: 'profile',
      stamp: recordedStamp,
      entityType: InputCategory.event.name,
      timeOfDay: timing.storagePrecision,
      data: {
        recordTimeField: {
          ...timing.toJson(date),
          if (localDate != null) 'localDate': localDate,
        },
      },
    ),
  );
}

PreparedGraph _prepare(
  Map<GraphKey, List<Response>> responses, {
  GraphYAxis axis = GraphYAxis.number,
  TimeCycle cycle = TimeCycle.day,
  DateTimeRange? range,
  GraphComparison comparison = GraphComparison.separate,
  Map<String, RecordPath>? reviews,
}) => GraphPreparer.prepare(
  responses: responses,
  settings: DisplayDataSettings(
    axis: axis,
    window: TimeWindow(
      cycle: cycle,
      range:
          range ??
          DateTimeRange(
            start: DateTime(2026, 10, 6),
            end: DateTime(2026, 10, 7),
          ),
    ),
  ),
  comparison: comparison,
  colorResolver: (_) => Colors.blue,
  reviewPaths: reviews,
);

void timingRegressionTests() {
  test(
    'intraday counts retain approximate ranges without placing them in hours',
    () {
      final exact = _timed('exact');
      final morning = _timed(
        'morning',
        precision: RecordTimePrecision.dayPart,
        part: RecordDayPart.morning,
      );
      final unknown = _timed('unknown', precision: RecordTimePrecision.unknown);
      final graph = _prepare({
        _category: [exact, morning, unknown],
      });
      final bars = graph.series.singleWhere((s) => s.mark == GraphMark.bar);
      expect(bars.data.fold<double>(0, (sum, d) => sum + d.value!), 1);
      expect(bars.data.where((d) => d.value == 1).single.evidence, [exact]);
      expect(graph.lanes.first.scaleKind, GraphScaleKind.count);
      final ranges = graph.series
          .where((s) => s.mark == GraphMark.range)
          .toList();
      expect(ranges, hasLength(2));
      final approximate = ranges
          .singleWhere((s) => s.id.timing == GraphTiming.dayPart)
          .data
          .single;
      expect(approximate.xStart, DateTime(2026, 10, 6, 6));
      expect(approximate.xEnd, DateTime(2026, 10, 6, 12));
      expect(approximate.evidence, [morning]);
      expect(
        ranges
            .singleWhere((s) => s.id.timing == GraphTiming.unknown)
            .data
            .single
            .evidence,
        [unknown],
      );
      expect(graph.series.map((s) => s.id).toSet(), hasLength(3));
    },
  );

  test('intraday averages use exact answers and daily averages retain every answer', () {
    final exact = _timed('exact', value: 2);
    final morning = _timed(
      'morning',
      precision: RecordTimePrecision.dayPart,
      part: RecordDayPart.morning,
      value: 8,
    );
    final unknown = _timed(
      'unknown',
      precision: RecordTimePrecision.unknown,
      value: 5,
    );
    final responses = {
      _questionKey: [
        exact.responses.single,
        morning.responses.single,
        unknown.responses.single,
      ],
    };
    final intraday = _prepare(responses, axis: GraphYAxis.average);
    final values = intraday.series
        .singleWhere((s) => s.mark == GraphMark.bar)
        .data
        .where((d) => d.hasValue);
    expect(values.single.value, 2);
    expect(values.single.summary.reportCount, 1);
    expect(
      intraday.series.where((s) => s.mark == GraphMark.range),
      hasLength(2),
    );
    final daily = _prepare(
      responses,
      axis: GraphYAxis.average,
      cycle: TimeCycle.week,
    );
    expect(daily.series.single.data.single.value, 5);
    expect(daily.series.single.data.single.summary.reportCount, 3);
  });

  test('daily counts include all precisions once and preserve simultaneous distinct entries', () {
    final first = _timed('first', precision: RecordTimePrecision.unknown);
    final second = _timed('second', precision: RecordTimePrecision.unknown);
    final morning = _timed(
      'morning',
      precision: RecordTimePrecision.dayPart,
      part: RecordDayPart.morning,
    );
    final exact = _timed('exact');
    final graph = _prepare({
      _category: [first, second, morning, exact],
    }, cycle: TimeCycle.week);
    expect(graph.series, hasLength(1));
    expect(graph.series.single.data.single.value, 4);
    expect(graph.series.single.data.single.summary.uniqueEntryCount, 4);
    final repeated = _prepare({
      _category: [first, first, second],
    }, cycle: TimeCycle.week);
    expect(repeated.series.single.data.single.value, 2);
  });

  test(
    'approximate calendar date takes precedence over a shifted timestamp',
    () {
      final unknown = _timed(
        'unknown',
        precision: RecordTimePrecision.unknown,
        stamp: DateTime(2026, 10, 5, 21),
        localDate: '2026-10-06',
      );
      final graph = _prepare({
        _category: [unknown],
      }, cycle: TimeCycle.week);
      expect(graph.series.single.data.single.value, 1);
      expect(graph.series.single.data.single.bin!.start, DateTime(2026, 10, 6));
      expect(
        responseOverlapsWindow(
          unknown,
          TimeWindow(
            cycle: TimeCycle.day,
            range: DateTimeRange(
              start: DateTime(2026, 10, 6, 14),
              end: DateTime(2026, 10, 6, 16),
            ),
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'only unknown timing still has visible evidence and empty data is empty',
    () {
      final unknown = _timed('unknown', precision: RecordTimePrecision.unknown);
      final graph = _prepare({
        _category: [unknown],
      }, axis: GraphYAxis.entrytime);
      expect(graph.isEmpty, isFalse);
      expect(
        graph.series.where((s) => s.mark == GraphMark.point).single.data,
        isEmpty,
      );
      expect(
        graph.series
            .where((s) => s.mark == GraphMark.range)
            .single
            .data
            .single
            .timing,
        GraphTiming.unknown,
      );
      expect(_prepare({_category: []}).isEmpty, isTrue);
    },
  );

  test(
    'check-in periods remain visible when the anchor lies before the query',
    () {
      final path = RecordPath(
        name: 'Weekly',
        pages: const [],
        period: Period.week,
      );
      final record = DetailResponse(
        id: 'review',
        detailType: 'Weekly',
        stamp: dateToStamp(DateTime(2026, 10, 5)),
        responses: const [],
      );
      const key = GraphKey(
        title: 'Weekly',
        type: 'Weekly',
        isCategory: true,
        isReview: true,
      );
      final range = DateTimeRange(
        start: DateTime(2026, 10, 7),
        end: DateTime(2026, 10, 8),
      );
      expect(
        responseOverlapsWindow(
          record,
          TimeWindow(cycle: TimeCycle.day, range: range),
          reviewPath: path,
        ),
        isTrue,
      );
      for (final axis in [GraphYAxis.number, GraphYAxis.entrytime]) {
        final graph = _prepare(
          {
            key: [record],
          },
          axis: axis,
          range: range,
          reviews: {'Weekly': path},
        );
        final datum = graph.series.single.data.single;
        expect(graph.series.single.mark, GraphMark.range);
        expect(datum.timing, GraphTiming.reviewPeriod);
        expect(datum.xStart, DateTime(2026, 10, 5));
        expect(datum.xEnd, DateTime(2026, 10, 12));
      }
      expect(
        responseOverlapsWindow(
          record,
          TimeWindow(
            cycle: TimeCycle.day,
            range: DateTimeRange(
              start: DateTime(2026, 10, 12),
              end: DateTime(2026, 10, 13),
            ),
          ),
          reviewPath: path,
        ),
        isFalse,
      );
    },
  );

  test(
    'month bins align to boundaries without drifting from a partial month',
    () {
      final graph = _prepare(
        {_category: []},
        cycle: TimeCycle.year,
        range: DateTimeRange(
          start: DateTime(2025, 1, 31, 15),
          end: DateTime(2025, 5, 14, 9),
        ),
      );
      expect(graph.query.bins.map((b) => b.start), [
        DateTime(2025, 1, 31, 15),
        DateTime(2025, 2, 1),
        DateTime(2025, 3, 1),
        DateTime(2025, 4, 1),
        DateTime(2025, 5, 1),
      ]);
      expect(graph.query.bins.last.end, DateTime(2025, 5, 14, 9));
      expect(graph.query.bins.map((b) => b.label).toSet(), hasLength(5));
    },
  );

  test('custom day bins use midnight and clipped query edges', () {
    final graph = _prepare(
      {_category: []},
      cycle: TimeCycle.custom,
      range: DateTimeRange(
        start: DateTime(2026, 10, 5, 14),
        end: DateTime(2026, 10, 10, 11),
      ),
    );
    expect(graph.query.bins.first.start, DateTime(2026, 10, 5, 14));
    expect(graph.query.bins.first.end, DateTime(2026, 10, 6));
    expect(graph.query.bins[1].start, DateTime(2026, 10, 6));
    expect(graph.query.bins.last.end, DateTime(2026, 10, 10, 11));
  });

  test('mixed recording and answer counts cannot stack', () {
    final record = _timed('record');
    final graph = _prepare({
      _category: [record],
      _questionKey: record.responses,
    }, comparison: GraphComparison.stacked);
    expect(graph.query.comparison, GraphComparison.separate);
  });
}
