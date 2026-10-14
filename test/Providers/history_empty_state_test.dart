import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/history_empty_state_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';

void main() {
  final settings = DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.day, anchor: DateTime(2026, 10, 12)),
    axis: GraphYAxis.number,
  );

  test('recognizes no available history separately from an empty period', () {
    expect(describeEmptyHistory([], settings).kind, HistoryEmptyKind.noEntries);
    final nearby = _entry('older', DateTime(2026, 10, 11, 21));
    final details = describeEmptyHistory([nearby], settings);
    expect(details.kind, HistoryEmptyKind.noEntriesInPeriod);
    expect(details.closestEntry, same(nearby));
  });

  test('nearest lookup considers both sides of the entire selected period', () {
    final before = _entry('before', DateTime(2026, 10, 11, 21));
    final after = _entry('after', DateTime(2026, 10, 13, 1));
    expect(closestHistoryEntry([before, after], settings), same(after));
    final closerBefore = _entry(
      'closer-before',
      DateTime(2026, 10, 11, 23, 30),
    );
    expect(
      closestHistoryEntry([closerBefore, after], settings),
      same(closerBefore),
    );
  });

  test('equal distances choose earlier entry, independent of input order', () {
    final before = _entry('before', DateTime(2026, 10, 11, 23));
    final after = _entry('after', DateTime(2026, 10, 13, 1));
    expect(closestHistoryEntry([after, before], settings), same(before));
    expect(closestHistoryEntry([before, after], settings), same(before));
  });

  test('same-time ties use stable entry IDs', () {
    final a = _entry('a', DateTime(2026, 10, 11, 23));
    final b = _entry('b', DateTime(2026, 10, 11, 23));
    expect(closestHistoryEntry([b, a], settings), same(a));
  });

  test('nearest preserves category and note filters with OR within a type', () {
    final filters = [
      ...const CategoryContext().createFilters(
        CategoryState(selectedItems: {'Pain', 'Sleep'}),
      ),
      ...const DescriptionContext().createFilters(
        DescriptionState(toggleValue: true, searchText: 'dinner'),
      ),
    ];
    final wrongNote = _entry(
      'wrong-note',
      DateTime(2026, 10, 11, 23),
      description: 'morning',
    );
    final wrongCategory = _entry(
      'wrong-type',
      DateTime(2026, 10, 13),
      type: 'Meals',
      description: 'dinner',
    );
    final matching = _entry(
      'matching',
      DateTime(2026, 10, 10),
      type: 'Sleep',
      description: 'After dinner',
    );
    final filtered = settings.copyWith(filters: filters);
    expect(
      closestHistoryEntry([wrongNote, wrongCategory, matching], filtered),
      same(matching),
    );
    expect(closestHistoryEntry([wrongNote, wrongCategory], filtered), isNull);
  });

  test(
    'filter empty state reports entries available after explicitly clearing',
    () {
      final inPeriod = _entry('entry', DateTime(2026, 10, 12, 14));
      final filtered = settings.copyWith(
        filters: const CategoryContext().createFilters(
          CategoryState(selectedItems: {'Sleep'}),
        ),
      );
      final details = describeEmptyHistory([inPeriod], filtered);
      expect(details.kind, HistoryEmptyKind.noMatchingEntries);
      expect(details.unfilteredPeriodCount, 1);
      expect(details.closestEntry, isNull);
    },
  );

  test(
    'nearest uses occurrence interval for uncertain day and day-part times',
    () {
      final uncertain = _timed(
        'uncertain',
        DateTime(2026, 10, 11),
        RecordTimePrecision.unknown,
      );
      final exact = _entry('exact', DateTime(2026, 10, 13, 1));
      expect(
        closestHistoryEntry([exact, uncertain], settings),
        same(uncertain),
      );

      final evening = _timed(
        'evening',
        DateTime(2026, 10, 11, 18),
        RecordTimePrecision.dayPart,
      );
      final later = _entry('later', DateTime(2026, 10, 13, 4));
      expect(closestHistoryEntry([later, evening], settings), same(evening));
    },
  );

  test('an uncertain date remains in a custom sub-day period', () {
    final day = _timed(
      'uncertain',
      DateTime(2026, 10, 12),
      RecordTimePrecision.unknown,
    );
    final narrow = settings.copyWith(
      range: DateTimeRange(
        start: DateTime(2026, 10, 12, 14),
        end: DateTime(2026, 10, 12, 15),
      ),
      cycle: TimeCycle.custom,
    );
    final filtered = narrow.copyWith(
      filters: const CategoryContext().createFilters(
        CategoryState(selectedItems: {'Sleep'}),
      ),
    );
    expect(describeEmptyHistory([day], filtered).unfilteredPeriodCount, 1);
  });

  test('a review period overlaps even when its anchor is outside the day', () {
    final review = _entry(
      'review',
      DateTime(2026, 10, 1),
      type: 'Monthly check-in',
    );
    final olderPain = _entry('pain', DateTime(2026, 10, 11, 23));
    final reviewPath = RecordPath(
      name: 'Monthly check-in',
      pages: const [],
      period: Period.month,
    );
    final paths = {reviewPath.name: reviewPath};
    final details = describeEmptyHistory(
      [olderPain, review],
      settings,
      reviewPaths: paths,
    );
    expect(details.unfilteredPeriodCount, 1);
    expect(details.closestEntry, same(review));
    expect(details.closestReviewPath, same(reviewPath));

    final filtered = settings.copyWith(
      filters: const CategoryContext().createFilters(
        CategoryState(selectedItems: {'Pain'}),
      ),
    );
    final filteredDetails = describeEmptyHistory(
      [olderPain, review],
      filtered,
      reviewPaths: paths,
    );
    expect(filteredDetails.kind, HistoryEmptyKind.noMatchingEntries);
    expect(filteredDetails.unfilteredPeriodCount, 1);
    expect(filteredDetails.closestEntry, same(olderPain));
    expect(filteredDetails.closestReviewPath, isNull);
  });

  test(
    'nearest review distance uses the full period rather than the anchor',
    () {
      final review = _entry(
        'review',
        DateTime(2026, 9, 1),
        type: 'Monthly check-in',
      );
      final after = _entry('after', DateTime(2026, 10, 25));
      final path = RecordPath(
        name: 'Monthly check-in',
        pages: const [],
        period: Period.month,
      );
      expect(
        closestHistoryEntry(
          [review, after],
          settings,
          reviewPaths: {path.name: path},
        ),
        same(review),
      );
    },
  );

  test(
    'empty-state provider uses review path definitions for filter recovery',
    () async {
      final review = _entry(
        'review',
        DateTime(2026, 10, 1),
        type: 'Monthly check-in',
      );
      final path = RecordPath(
        name: 'Monthly check-in',
        pages: const [],
        period: Period.month,
      );
      final filtered = settings.copyWith(
        filters: const CategoryContext().createFilters(
          CategoryState(selectedItems: {'Pain'}),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          historyArchiveReadyProvider.overrideWith((_) async {}),
          displayDataProvider.overrideWith(() => _Settings(filtered)),
          stampsStreamProvider.overrideWith((_) => Stream.value([review])),
          reviewPathsByTypeProvider.overrideWith(
            (_) async => {path.name: path},
          ),
        ],
      );
      addTearDown(container.dispose);
      final details = await container.read(historyEmptyDetailsProvider.future);
      expect(details.kind, HistoryEmptyKind.noMatchingEntries);
      expect(details.unfilteredPeriodCount, 1);
      expect(details.closestEntry, isNull);
    },
  );

  test(
    'archive lookup waits for refresh before using previously limited data',
    () async {
      final older = _entry('old', DateTime(2026, 8, 1));
      final repository = _ArchiveRepo([older]);
      final container = ProviderContainer(
        overrides: [
          displayDataProvider.overrideWith(() => _Settings(settings)),
          stampProvider.overrideWith((_) async => repository),
          reviewPathsByTypeProvider.overrideWith((_) async => {}),
          entryRepoProvider.overrideWith((_) async => null),
          stampsStreamProvider.overrideWith((_) => repository.stamps),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);
      container.listen(historyEmptyDetailsProvider, (_, _) {});
      await container.pump();
      expect(container.read(historyEmptyDetailsProvider).isLoading, isTrue);
      repository.release.complete();
      final details = await container.read(historyEmptyDetailsProvider.future);
      expect(repository.earliest, SigDates.minDate);
      expect(details.closestEntry, same(older));
      expect(details.kind, HistoryEmptyKind.noEntriesInPeriod);
    },
  );

  test(
    'failed archive lookup remains an error instead of no history',
    () async {
      final container = ProviderContainer(
        overrides: [
          historyArchiveReadyProvider.overrideWith(
            (_) async => throw StateError('unavailable'),
          ),
          displayDataProvider.overrideWith(() => _Settings(settings)),
          stampsStreamProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(historyEmptyDetailsProvider.future),
        throwsStateError,
      );
    },
  );
}

DetailResponse _entry(
  String id,
  DateTime date, {
  String type = 'Pain',
  String? description,
}) => DetailResponse(
  id: id,
  detailType: type,
  description: description,
  stamp: dateToStamp(date),
  responses: const [],
);

TimedDetailResponse _timed(
  String id,
  DateTime date,
  RecordTimePrecision precision,
) {
  final response = _entry(id, date);
  final timing = RecordTime(
    precision: precision,
    exactTime: TimeOfDay.fromDateTime(date),
    dayPart: precision == RecordTimePrecision.dayPart
        ? RecordDayPart.evening
        : null,
  );
  final entry = detailResponseToEntry(response, 'profile').copyWith(
    timeOfDay: timing.storagePrecision,
    data: {recordTimeField: timing.toJson(date)},
  );
  return TimedDetailResponse(response: response, entry: entry);
}

class _Settings extends DisplayDataProvider {
  final DisplayDataSettings settings;
  _Settings(this.settings);
  @override
  DisplayDataSettings build() => settings;
}

final _profile = SubUser(
  id: 'profile',
  name: 'Profile',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

class _ArchiveRepo extends StampRepo<Stamp> {
  final List<Stamp> archive;
  final release = Completer<void>();
  final _changes = StreamController<List<Stamp>>.broadcast();
  List<Stamp> _current = [];

  _ArchiveRepo(this.archive)
    : super(
        authUser: const AuthUser.uid(uid: 'user'),
        currentUser: _profile,
        questionRepo: TestQuestionRepo(subUser: _profile),
        earliest: DateTime(2026, 10, 1),
      );

  @override
  Stream<List<Stamp>> get stamps async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<void> refresh() async {
    await release.future;
    _current = archive;
    _changes.add(_current);
  }

  @override
  Future<void> refreshCheckins({Iterable<String>? types}) async {}
  @override
  Future<RepoResult<Stamp?>> addStamp(Stamp stamp) =>
      throw UnimplementedError();
  @override
  Future<RepoResult<void>> removeStamp(Stamp stamp) =>
      throw UnimplementedError();
  @override
  Future<RepoResult<Stamp?>> updateStamp(Stamp stamp) =>
      throw UnimplementedError();
  Future<void> dispose() => _changes.close();
}
