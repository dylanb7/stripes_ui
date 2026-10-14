import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';

class _ScopeSettings extends DisplayDataProvider {
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.day, anchor: DateTime(2026, 10, 7)),
    axis: GraphYAxis.number,
  );
}

class _ScopeHome extends QuestionHome {
  _ScopeHome(List<Question> questions) {
    all = {for (final question in questions) question.id: question};
  }

  @override
  Map<String, List<Question>> byType() => const {};
}

DetailResponse _record(
  String id,
  String category,
  DateTime date, {
  int answers = 1,
}) {
  final stamp = dateToStamp(date);
  return DetailResponse(
    id: id,
    detailType: category,
    stamp: stamp,
    responses: [
      for (var i = 0; i < answers; i++)
        NumericResponse(
          question: Numeric(
            id: '$category-question-$i',
            prompt: 'Answer $i',
            type: category,
          ),
          stamp: stamp,
          response: i + 2,
        ),
    ],
  );
}

ProviderContainer _container(
  List<DetailResponse> records, {
  required bool overview,
  void Function()? onReviewLookup,
}) {
  final reviewPath = RecordPath(
    name: 'Weekly',
    period: Period.week,
    pages: const [],
  );
  final graph = QuestionGraphBuilder.build(
    home: _ScopeHome([
      for (final record in records)
        for (final response in record.responses) response.question,
    ]),
    recordPaths: [reviewPath],
  );
  final container = ProviderContainer(
    overrides: [
      configProvider.overrideWith(
        (ref) => StripesConfig.sandbox(
          betaUi: BetaUiConfig.disabled(historyOverview: overview),
        ),
      ),
      displayDataProvider.overrideWith(_ScopeSettings.new),
      stampsStreamProvider.overrideWith((ref) => Stream.value(records)),
      questionGraphProvider.overrideWith((ref) async => graph),
      reviewPathsByTypeProvider.overrideWith((ref) async {
        onReviewLookup?.call();
        return graph.reviewPathsByType();
      }),
    ],
  );
  container.listen(availableStampsProvider, (_, _) {});
  addTearDown(container.dispose);
  return container;
}

void main() {
  for (final overview in [false, true]) {
    test(
      'period-overlapping reviews join the collection only in beta: $overview',
      () async {
        final review = _record(
          'review',
          'Weekly',
          DateTime(2026, 10, 5),
          answers: 2,
        );
        final event = _record(
          'event',
          'Pain',
          DateTime(2026, 10, 7, 12),
          answers: 3,
        );
        final oldEvent = _record(
          'old-event',
          'Pain',
          DateTime(2026, 10, 6, 23),
        );
        final nextReview = _record(
          'next-review',
          'Weekly',
          DateTime(2026, 10, 12),
        );
        var reviewLookups = 0;
        final container = _container(
          [review, event, oldEvent, nextReview],
          overview: overview,
          onReviewLookup: () => reviewLookups++,
        );

        final available = await container.read(availableStampsProvider.future);
        expect(available, overview ? [review, event] : [event]);
        expect(await container.read(inRangeProvider.future), available);
        expect(reviewLookups, overview ? 1 : 0);
        // Each selected record remains one entry, regardless of answer count.
        expect(
          available.whereType<DetailResponse>(),
          hasLength(overview ? 2 : 1),
        );
        expect(available.contains(event.responses.first), isFalse);
      },
    );
  }

  test('beta collection agrees with count graph source recordings', () async {
    final review = _record(
      'review',
      'Weekly',
      DateTime(2026, 10, 5),
      answers: 2,
    );
    final event = _record(
      'event',
      'Pain',
      DateTime(2026, 10, 7, 12),
      answers: 3,
    );
    final records = [review, event];
    final container = _container(records, overview: true);

    final available = await container.read(availableStampsProvider.future);
    final graphs = await container.read(graphStampsProvider.future);
    final graphRecordings = graphs.entries
        .where((entry) => entry.key.isCategory)
        .expand((entry) => entry.value)
        .toList();
    expect(graphRecordings, unorderedEquals(available));
    expect(graphRecordings, hasLength(2));
  });

  test('filters restrict the selected overlapping review collection', () async {
    final review = _record(
      'review',
      'Weekly',
      DateTime(2026, 10, 5),
      answers: 2,
    );
    final event = _record(
      'event',
      'Pain',
      DateTime(2026, 10, 7, 12),
      answers: 3,
    );
    final outside = _record('outside', 'Weekly', DateTime(2026, 10, 12));
    final container = _container([review, event, outside], overview: true);

    expect(await container.read(availableStampsProvider.future), [
      review,
      event,
    ]);
    container
        .read(displayDataProvider.notifier)
        .updateFilters(
          const CategoryContext().createFilters(
            CategoryState(selectedItems: {'Weekly'}),
          ),
        );
    expect(await container.read(inRangeProvider.future), [review, event]);
    expect(await container.read(availableStampsProvider.future), [review]);
    final graphs = await container.read(graphStampsProvider.future);
    expect(graphs.entries.where((entry) => entry.key.isCategory).single.value, [
      review,
    ]);

    container
        .read(displayDataProvider.notifier)
        .updateFilters(
          const CategoryContext().createFilters(
            CategoryState(selectedItems: {'Pain'}),
          ),
        );
    expect(await container.read(availableStampsProvider.future), [event]);
    container.read(displayDataProvider.notifier).updateFilters(const []);
    expect(await container.read(availableStampsProvider.future), [
      review,
      event,
    ]);
  });
}
