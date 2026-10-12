import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';

void main() {
  late _Replay<List<Entry>> entries;
  late _HistoryRepo repository;
  late ProviderContainer container;

  setUp(() {
    entries = _Replay(const []);
    repository = _HistoryRepo();
    container = ProviderContainer(
      overrides: [
        questionHomeProvider.overrideWith((_) => Stream.value(_QuestionHome())),
        stampProvider.overrideWith((_) async => repository),
        entriesStreamProvider.overrideWith((_) => entries.stream),
      ],
    );
    container.listen(stampsStreamProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await entries.close();
    await repository.close();
  });

  Future<List<Stamp>> history() async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    return container.read(stampsStreamProvider.future);
  }

  test(
    'batch entries appear with precision on parent and question responses',
    () async {
      entries.add([_entry('batch-entry', precision: TimeOfDayEntry.afternoon)]);

      final stamps = await history();
      expect(stamps, hasLength(1));
      final response = stamps.single as TimedDetailResponse;
      expect(response.id, 'batch-entry');
      expect(response.recordTime.precision, RecordTimePrecision.dayPart);
      expect(response.recordTime.dayPart, RecordDayPart.afternoon);
      expect(hasApproximateRecordTime(response), isTrue);
      expect(hasApproximateRecordTime(response.responses.single), isTrue);
      expect(
        recordTimeForResponse(response.responses.single)?.dayPart,
        RecordDayPart.afternoon,
      );
    },
  );

  test(
    'an Entry replaces its stale legacy projection without duplication',
    () async {
      repository.values.add([_response('shared-id', value: 1)]);
      entries.add([
        _entry('shared-id', value: 5, precision: TimeOfDayEntry.notSure),
      ]);

      final stamps = await history();
      expect(stamps, hasLength(1));
      final response = stamps.single as TimedDetailResponse;
      expect((response.responses.single as NumericResponse).response, 5);
      expect(response.recordTime.precision, RecordTimePrecision.unknown);
    },
  );

  test(
    'legacy responses without Entry metadata retain their existing values',
    () async {
      final legacy = _response('legacy', value: 2);
      repository.values.add([legacy]);
      entries.add([_entry('new-entry')]);

      final stamps = await history();
      expect(stamps, hasLength(2));
      expect(stamps.first, same(legacy));
      expect(hasApproximateRecordTime(legacy), isFalse);
    },
  );

  test('Entry stream adds, edits, and removals update History without invalidation', () async {
    expect(await history(), isEmpty);

    entries.add([_entry('entry', value: 2)]);
    var stamps = await history();
    expect(stamps, hasLength(1));
    expect((stamps.single as TimedDetailResponse).id, 'entry');

    entries.add([_entry('entry', value: 4, precision: TimeOfDayEntry.evening)]);
    stamps = await history();
    final updated = stamps.single as TimedDetailResponse;
    expect((updated.responses.single as NumericResponse).response, 4);
    expect(updated.recordTime.dayPart, RecordDayPart.evening);

    entries.add(const []);
    expect(await history(), isEmpty);
  });

  test(
    'legacy stream changes keep independent batch entries visible once',
    () async {
      entries.add([_entry('entry')]);
      expect(await history(), hasLength(1));

      repository.values.add([
        _response('legacy'),
        _response('entry', value: 1),
      ]);
      var stamps = await history();
      expect(stamps, hasLength(2));
      expect(stamps.where((stamp) => stamp.id == 'entry'), hasLength(1));
      expect(stamps.whereType<TimedDetailResponse>().single.id, 'entry');

      repository.values.add(const []);
      stamps = await history();
      expect(stamps, hasLength(1));
      expect(stamps.single.id, 'entry');
    },
  );
}

const _question = Numeric(
  id: 'pain-rating',
  prompt: 'Pain rating',
  type: 'Pain',
  min: 0,
  max: 10,
);

DetailResponse _response(String id, {int value = 3}) => DetailResponse(
  id: id,
  detailType: 'Pain',
  stamp: DateTime.utc(2026, 10, 6, 12).millisecondsSinceEpoch,
  responses: [
    NumericResponse(
      question: _question,
      response: value,
      stamp: DateTime.utc(2026, 10, 6, 12).millisecondsSinceEpoch,
    ),
  ],
);

Entry _entry(
  String id, {
  int value = 3,
  TimeOfDayEntry precision = TimeOfDayEntry.morning,
}) {
  final entry = detailResponseToEntry(_response(id, value: value), 'profile');
  return entry.copyWith(
    sessionId: 'batch',
    timeOfDay: precision,
    data: {...entry.data, recordBatchIdField: 'batch'},
  );
}

class _QuestionHome extends QuestionHome {
  _QuestionHome() {
    all = {_question.id: _question};
  }

  @override
  Map<String, List<Question>> byType() => {
    'Pain': [_question],
  };
}

final _profile = SubUser(
  id: 'profile',
  name: 'Profile',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

class _HistoryRepo extends StampRepo<Stamp> {
  final values = _Replay<List<Stamp>>(const []);

  _HistoryRepo()
    : super(
        authUser: const AuthUser.uid(uid: 'user'),
        currentUser: _profile,
        questionRepo: TestQuestionRepo(subUser: _profile),
      );

  @override
  Stream<List<Stamp>> get stamps => values.stream;

  @override
  Future<RepoResult<Stamp?>> addStamp(Stamp stamp) async {
    values.add([...values.value, stamp]);
    return Success(stamp);
  }

  @override
  Future<RepoResult<void>> removeStamp(Stamp stamp) async {
    values.add(values.value.where((value) => value.id != stamp.id).toList());
    return const Success(null);
  }

  @override
  Future<RepoResult<Stamp?>> updateStamp(Stamp stamp) async {
    values.add([
      for (final value in values.value)
        if (value.id == stamp.id) stamp else value,
    ]);
    return Success(stamp);
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshCheckins({Iterable<String>? types}) async {}

  Future<void> close() => values.close();
}

class _Replay<T> {
  T value;
  final _changes = StreamController<T>.broadcast();

  _Replay(this.value);

  Stream<T> get stream => Stream<T>.multi((controller) {
    controller.add(value);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  void add(T value) {
    this.value = value;
    _changes.add(value);
  }

  Future<void> close() => _changes.close();
}
