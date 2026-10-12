import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_entry_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';

void main() {
  late _FaultingEntryRepo repository;
  late EntryRepoRecordSessionWriter writer;

  setUp(() {
    repository = _FaultingEntryRepo(
      const AuthUser.uid(uid: 'auth-user'),
      SubUser(
        id: 'sub-user',
        name: 'Profile',
        gender: '',
        birthYear: 2000,
        isControl: false,
      ),
    );
    writer = EntryRepoRecordSessionWriter(repository);
  });

  tearDown(() => repository.dispose());

  test('classifies Entry categories from typed record-path metadata', () {
    expect(
      RecordPath(
        name: 'custom-baseline',
        pages: const [],
        isBaseline: true,
      ).inputCategory,
      InputCategory.baseline,
    );
    expect(
      RecordPath(
        name: 'custom-checkin',
        pages: const [],
        period: Period.week,
      ).inputCategory,
      InputCategory.form,
    );
    expect(
      RecordPath(
        name: 'category.SEIZURE_INTERIM',
        pages: const [],
        fromBaseline: 'some-baseline',
      ).inputCategory,
      InputCategory.event,
    );
  });

  test('creates typed entries sharing one recording session', () async {
    final result = await writer.createSession(
      sessionId: 'record-session',
      entries: [
        _entry(type: 'Pain', timeOfDay: TimeOfDayEntry.exact),
        _entry(type: 'Bowel Movement', timeOfDay: TimeOfDayEntry.afternoon),
      ],
    );

    expect(result, isA<Success<List<Entry>>>());
    final saved = (result as Success<List<Entry>>).data;
    expect(saved, hasLength(2));
    expect(saved.map((entry) => entry.id), everyElement(isNotEmpty));
    expect(
      saved.map((entry) => entry.sessionId),
      everyElement('record-session'),
    );
    expect(saved.last.timeOfDay, TimeOfDayEntry.afternoon);
    expect(
      saved.map((entry) => entry.data[recordBatchIdField]),
      everyElement('record-session'),
    );

    final stored = await repository.findBySession('record-session');
    expect(stored, saved);
  });

  test(
    'updates entry data while retaining persisted session metadata',
    () async {
      final created = await writer.createSession(
        sessionId: 'record-session',
        entries: [_entry(type: 'Pain', timeOfDay: TimeOfDayEntry.morning)],
      );
      final original = (created as Success<List<Entry>>).data.single;
      final replacement = Entry(
        id: original.id,
        subUserId: original.subUserId,
        stamp: original.stamp.add(const Duration(hours: 1)),
        entityType: original.entityType,
        data: {...original.data, 'description': 'Updated'},
        timeOfDay: TimeOfDayEntry.exact,
      );

      final result = await writer.updateSession(entries: [replacement]);

      expect(result, isA<Success<List<Entry>>>());
      final updated = (result as Success<List<Entry>>).data.single;
      expect(updated.sessionId, 'record-session');
      expect(updated.timeOfDay, TimeOfDayEntry.exact);
      expect(updated.data['description'], 'Updated');
    },
  );

  test('removes the entries written by a session', () async {
    final created = await writer.createSession(
      sessionId: 'record-session',
      entries: [_entry(type: 'Pain', timeOfDay: TimeOfDayEntry.notSure)],
    );
    final saved = (created as Success<List<Entry>>).data;

    final result = await writer.removeEntries(entries: saved);

    expect(result, isA<Success<void>>());
    expect(await repository.findBySession('record-session'), isEmpty);
  });

  test(
    'preserves study links separately from recording batch identity',
    () async {
      final result = await writer.createSession(
        sessionId: 'batch',
        preserveEntrySessionIds: true,
        entries: [
          _entry(id: 'pain', type: 'Pain'),
          _entry(id: 'bm', type: 'BM', sessionId: 'blue-dye-run'),
        ],
      );
      final saved = (result as Success<List<Entry>>).data;

      expect(saved.first.sessionId, 'batch');
      expect(saved.last.sessionId, 'blue-dye-run');
      expect(
        saved.map((entry) => entry.data[recordBatchIdField]),
        everyElement('batch'),
      );
      expect(await repository.findBySession('blue-dye-run'), [saved.last]);
    },
  );

  test('legacy create still assigns the requested session ID', () async {
    final result = await writer.createSession(
      sessionId: 'requested-session',
      entries: [_entry(type: 'Pain', sessionId: 'old-session')],
    );

    expect(
      (result as Success<List<Entry>>).data.single.sessionId,
      'requested-session',
    );
  });

  test('retry reuses identical stable entries without another add', () async {
    final entries = [
      _entry(id: 'pain', type: 'Pain'),
      _entry(id: 'bm', type: 'BM'),
    ];
    final first = await writer.createSession(
      sessionId: 'batch',
      entries: entries,
    );
    final retry = await writer.createSession(
      sessionId: 'batch',
      entries: entries,
    );

    expect(
      (retry as Success<List<Entry>>).data,
      (first as Success<List<Entry>>).data,
    );
    expect(repository.addCalls, 2);
    expect(await repository.entries.first, hasLength(2));
  });

  test('checks conflicting IDs before writing any entries', () async {
    final existing = _entry(id: 'bm', type: 'Existing');
    await repository.addEntry(existing);

    final result = await writer.createSession(
      sessionId: 'batch',
      entries: [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
      ],
    );

    expect(result, isA<Failure<List<Entry>>>());
    expect(repository.addCalls, 1);
    expect(await repository.entries.first, [existing]);
  });

  test(
    'failed second write compensates and the same draft can retry',
    () async {
      final entries = [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
      ];
      repository.failAdds.add('bm');
      final failed = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );

      expect(failed, isA<Failure<List<Entry>>>());
      expect(await repository.entries.first, isEmpty);
      expect(repository.removedIds, ['pain']);

      repository.failAdds.clear();
      final retry = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );
      expect(retry, isA<Success<List<Entry>>>());
      expect(await repository.entries.first, hasLength(2));
    },
  );

  test(
    'failed rollback is explicit and retry does not duplicate its survivor',
    () async {
      final entries = [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
      ];
      repository.failAdds.add('bm');
      repository.failRemoves.add('pain');
      final failed = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );

      final recovery =
          (failed as Failure<List<Entry>>).error as RecordSessionWriteRecovery;
      expect(recovery.remainingEntryIds, ['pain']);
      expect(recovery.rollbackFailures.keys, ['pain']);
      expect(await repository.entries.first, hasLength(1));

      repository.failAdds.clear();
      repository.failRemoves.clear();
      final retry = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );
      expect(retry, isA<Success<List<Entry>>>());
      expect(repository.addCalls, 3);
      expect(
        (await repository.entries.first).map((entry) => entry.id).toSet(),
        {'pain', 'bm'},
      );
      expect(await repository.entries.first, hasLength(2));
    },
  );

  test(
    'another failed retry does not roll back previously saved matches',
    () async {
      final entries = [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
      ];
      repository.failAdds.add('bm');
      repository.failRemoves.add('pain');
      await writer.createSession(sessionId: 'batch', entries: entries);
      repository.failRemoves.clear();
      repository.removedIds.clear();

      final retry = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );
      final recovery =
          (retry as Failure<List<Entry>>).error as RecordSessionWriteRecovery;
      expect(recovery.remainingEntryIds, ['pain']);
      expect(await repository.entries.first, hasLength(1));
      expect(repository.removedIds, isEmpty);
    },
  );

  test(
    'retry reports survivors later in the batch even if its first write fails',
    () async {
      final entries = [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
        _entry(id: 'meal', type: 'Meal'),
      ];
      repository.failAdds.add('meal');
      repository.failRemoves.add('bm');
      await writer.createSession(sessionId: 'batch', entries: entries);
      expect((await repository.entries.first).single.id, 'bm');

      repository.failAdds.add('pain');
      repository.failRemoves.clear();
      repository.removedIds.clear();
      final retry = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );

      final recovery =
          (retry as Failure<List<Entry>>).error as RecordSessionWriteRecovery;
      expect(recovery.remainingEntryIds, ['bm']);
      expect(repository.removedIds, isEmpty);
      expect((await repository.entries.first).single.id, 'bm');
    },
  );

  test(
    'a conflicting retry keeps its existing batch marked for recovery',
    () async {
      final entries = [
        _entry(id: 'pain', type: 'Pain'),
        _entry(id: 'bm', type: 'BM'),
      ];
      repository.failAdds.add('bm');
      repository.failRemoves.add('pain');
      await writer.createSession(sessionId: 'batch', entries: entries);
      final saved = (await repository.entries.first).single;
      final changed = saved.copyWith(
        data: {...saved.data, 'description': 'Edited elsewhere'},
      );
      await repository.updateEntry(changed);

      final retry = await writer.createSession(
        sessionId: 'batch',
        entries: entries,
      );
      final recovery =
          (retry as Failure<List<Entry>>).error as RecordSessionWriteRecovery;

      expect(recovery.remainingEntryIds, ['pain']);
      expect(repository.addCalls, 2);
      expect((await repository.entries.first).single, changed);
    },
  );

  test(
    'reconciles a failed acknowledgement after the entry committed',
    () async {
      repository.failAdds.add('bm');
      repository.commitFailedAdds = true;
      final result = await writer.createSession(
        sessionId: 'batch',
        entries: [
          _entry(id: 'pain', type: 'Pain'),
          _entry(id: 'bm', type: 'BM'),
        ],
      );

      expect(result, isA<Failure<List<Entry>>>());
      expect(await repository.entries.first, isEmpty);
      expect(repository.removedIds, ['bm', 'pain']);
    },
  );

  test('rejects duplicate IDs and a different profile before writes', () async {
    final duplicate = await writer.createSession(
      sessionId: 'batch',
      entries: [
        _entry(id: 'same', type: 'Pain'),
        _entry(id: 'same', type: 'BM'),
      ],
    );
    expect(duplicate, isA<Failure<List<Entry>>>());

    final wrongProfile = await writer.createSession(
      sessionId: 'batch',
      entries: [
        _entry(id: 'pain', type: 'Pain').copyWith(subUserId: 'other-user'),
      ],
    );
    expect(wrongProfile, isA<Failure<List<Entry>>>());
    expect(repository.addCalls, 0);
  });

  test(
    'legacy edits retain precision and recording metadata they omit',
    () async {
      final result = await writer.createSession(
        sessionId: 'batch',
        preserveEntrySessionIds: true,
        entries: [
          _entry(
            id: 'bm',
            type: 'BM',
            timeOfDay: TimeOfDayEntry.morning,
            sessionId: 'blue-dye-run',
          ).copyWith(
            data: {
              'type': 'BM',
              'responses': const [],
              'recordTime': {'precision': 'earlyMorning', 'date': '2026-08-30'},
              'repositoryMetadata': 'retained',
            },
          ),
        ],
      );
      final original = (result as Success<List<Entry>>).data.single;
      final edited = Entry(
        id: original.id,
        subUserId: original.subUserId,
        stamp: original.stamp,
        entityType: original.entityType,
        data: {'type': 'BM', 'responses': const [], 'description': 'New note'},
      );

      final updated = await writer.updateSession(entries: [edited]);
      final saved = (updated as Success<List<Entry>>).data.single;
      expect(saved.timeOfDay, TimeOfDayEntry.morning);
      expect(saved.sessionId, 'blue-dye-run');
      expect(saved.data[recordBatchIdField], 'batch');
      expect(saved.data['recordTime'], original.data['recordTime']);
      expect(saved.data['repositoryMetadata'], 'retained');
      expect(saved.data['description'], 'New note');
    },
  );
}

Entry _entry({
  String? id,
  required String type,
  TimeOfDayEntry timeOfDay = TimeOfDayEntry.exact,
  String? sessionId,
}) {
  return Entry(
    id: id,
    subUserId: 'sub-user',
    stamp: DateTime(2026, 8, 30, 10),
    entityType: InputCategory.event.name,
    data: {'type': type, 'responses': const <Map<String, dynamic>>[]},
    timeOfDay: timeOfDay,
    sessionId: sessionId,
  );
}

class _FaultingEntryRepo extends TestEntryRepo {
  final Set<String> failAdds = {};
  final Set<String> failRemoves = {};
  final List<String> removedIds = [];
  int addCalls = 0;
  bool commitFailedAdds = false;

  _FaultingEntryRepo(super.user, super.subUser);

  @override
  Future<RepoResult<Entry>> addEntry(Entry entry) async {
    addCalls++;
    if (failAdds.contains(entry.id)) {
      if (commitFailedAdds) await super.addEntry(entry);
      return const Failure(message: 'Save failed', type: FailureType.storage);
    }
    return super.addEntry(entry);
  }

  @override
  Future<RepoResult<void>> removeEntry(String entryId) async {
    removedIds.add(entryId);
    if (failRemoves.contains(entryId)) {
      return const Failure(message: 'Remove failed', type: FailureType.storage);
    }
    return super.removeEntry(entryId);
  }
}
