import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

void main() {
  const firstQuestion = Numeric(id: 'pain', prompt: 'Pain', type: 'GI');
  const secondQuestion = Numeric(id: 'nausea', prompt: 'Nausea', type: 'GI');
  final day = DateTime(2026, 10, 6);

  test('category graphs contain recordings and answer graphs retain their identity', () async {
    DetailResponse recording(String? id) => DetailResponse(
      id: id,
      detailType: 'GI',
      stamp: dateToStamp(day),
      responses: [
        NumericResponse(
          question: firstQuestion,
          response: 2,
          stamp: dateToStamp(day),
        ),
        NumericResponse(
          question: secondQuestion,
          response: 3,
          stamp: dateToStamp(day),
        ),
      ],
    );
    final records = [recording('first'), recording('second'), recording(null)];
    final container = _container(
      records,
      const [firstQuestion, secondQuestion],
      [],
      day,
    );
    addTearDown(container.dispose);
    final graphs = await container.read(graphStampsProvider.future);
    final category = graphs.entries.singleWhere(
      (entry) => entry.key.isCategory,
    );
    expect(category.value, records);
    expect(category.value, hasLength(3));
    expect(
      graphs.entries.where((entry) => !entry.key.isCategory),
      hasLength(2),
    );
    for (final record in records) {
      expect(record.responses.map(recordIdentityForResponse).toSet(), {
        recordIdentityForResponse(record),
      });
      expect(recordTimeForResponse(record), isNull);
    }
    expect(records.map(recordIdentityForResponse).toSet(), hasLength(3));
  });

  test(
    'overlapping reviews are visible in counts and time-of-day graphs',
    () async {
      final path = RecordPath(
        name: 'Weekly',
        period: Period.week,
        pages: const [],
      );
      final record = DetailResponse(
        id: 'weekly',
        detailType: 'Weekly',
        stamp: dateToStamp(DateTime(2026, 10, 5)),
        responses: const [],
      );
      for (final axis in [GraphYAxis.number, GraphYAxis.entrytime]) {
        final container = _container(
          [record],
          [],
          [path],
          DateTime(2026, 10, 7),
          axis: axis,
        );
        final graphs = await container.read(graphStampsProvider.future);
        expect(graphs.values.single, [record]);
        expect(graphs.keys.single.isReview, isTrue);
        container.dispose();
      }
    },
  );

  test('numeric average graph still flattens category recordings', () async {
    final record = DetailResponse(
      id: 'record',
      detailType: 'GI',
      stamp: dateToStamp(day),
      responses: [
        NumericResponse(
          question: firstQuestion,
          response: 2,
          stamp: dateToStamp(day),
        ),
        NumericResponse(
          question: secondQuestion,
          response: 3,
          stamp: dateToStamp(day),
        ),
      ],
    );
    final container = _container(
      [record],
      [firstQuestion, secondQuestion],
      [],
      day,
      axis: GraphYAxis.average,
    );
    addTearDown(container.dispose);
    final graphs = await container.read(graphStampsProvider.future);
    expect(graphs, hasLength(2));
    expect(graphs.keys.every((key) => !key.isCategory), isTrue);
    expect(
      graphs.values.expand((value) => value),
      unorderedEquals(record.responses),
    );
  });
}

ProviderContainer _container(
  List<Stamp> stamps,
  List<Question> questions,
  List<RecordPath> paths,
  DateTime day, {
  GraphYAxis axis = GraphYAxis.number,
}) {
  final home = _Home(questions);
  final graph = QuestionGraphBuilder.build(home: home, recordPaths: paths);
  final container = ProviderContainer(
    overrides: [
      stampsStreamProvider.overrideWith((ref) => Stream.value(stamps)),
      questionGraphProvider.overrideWith((ref) async => graph),
      displayDataProvider.overrideWith(
        () => _Settings(
          DisplayDataSettings(
            window: TimeWindow(
              cycle: TimeCycle.day,
              range: DateTimeRange(
                start: day,
                end: DateTime(day.year, day.month, day.day + 1),
              ),
            ),
            axis: axis,
          ),
        ),
      ),
    ],
  );
  container.listen(stampsStreamProvider, (_, _) {});
  container.listen(graphStampsProvider, (_, _) {});
  return container;
}

class _Home extends QuestionHome {
  _Home(List<Question> questions) {
    all = {for (final q in questions) q.id: q};
  }
  @override
  Map<String, List<Question>> byType() => const {};
}

class _Settings extends DisplayDataProvider {
  final DisplayDataSettings settings;
  _Settings(this.settings);
  @override
  DisplayDataSettings build() => settings;
}
