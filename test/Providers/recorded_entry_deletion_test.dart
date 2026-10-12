import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_entry_repo.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';

void main() {
  late _EntryRepo entries;
  late RecordSessionWriter writer;
  late Entry saved;

  setUp(() async {
    entries = _EntryRepo();
    writer = EntryRepoRecordSessionWriter(entries);
    final result = await writer.createSession(
      sessionId: 'batch',
      entries: [
        Entry(
          id: 'record',
          subUserId: _profile.uid,
          stamp: DateTime.utc(2026, 10, 6),
          entityType: InputCategory.event.name,
          data: {'type': 'Pain', 'responses': const []},
        ),
      ],
    );
    saved = (result as Success<List<Entry>>).data.single;
  });

  tearDown(() => entries.dispose());

  test(
    'removes an independent legacy copy without touching other records',
    () async {
      final stamps = _StampRepo(entries: entries, projectsEntries: false);
      stamps.values = [_response('record'), _response('unrelated')];

      final result = await removeRecordedEntry(
        writer: writer,
        entry: saved,
        stampRepo: stamps,
      );

      expect(result, isA<Success<void>>());
      expect(await entries.entries.first, isEmpty);
      expect(stamps.values.map((stamp) => stamp.id), ['unrelated']);
      expect(stamps.removedIds, ['record']);
      expect(stamps.refreshes, 1);
    },
  );

  test('does not remove a unified projection twice after refresh', () async {
    final stamps = _StampRepo(entries: entries, projectsEntries: true);
    await stamps.refresh();
    expect(stamps.values, hasLength(1));

    final result = await removeRecordedEntry(
      writer: writer,
      entry: saved,
      stampRepo: stamps,
    );

    expect(result, isA<Success<void>>());
    expect(await entries.entries.first, isEmpty);
    expect(stamps.values, isEmpty);
    expect(stamps.removedIds, isEmpty);
  });

  test('works when no legacy repository is available', () async {
    final result = await removeRecordedEntry(writer: writer, entry: saved);

    expect(result, isA<Success<void>>());
    expect(await entries.entries.first, isEmpty);
  });

  test('does not remove legacy data when the Entry removal fails', () async {
    entries.failRemove = true;
    final stamps = _StampRepo(entries: entries, projectsEntries: false);
    stamps.values = [_response('record')];

    final result = await removeRecordedEntry(
      writer: writer,
      entry: saved,
      stampRepo: stamps,
    );

    expect(result, isA<Failure<void>>());
    expect(await entries.entries.first, hasLength(1));
    expect(stamps.values, hasLength(1));
    expect(stamps.removedIds, isEmpty);
    expect(stamps.refreshes, 0);
  });
}

final _profile = SubUser(
  id: 'profile',
  name: 'Profile',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

DetailResponse _response(String id) => DetailResponse(
  id: id,
  stamp: DateTime.utc(2026, 10, 6).millisecondsSinceEpoch,
  detailType: 'Pain',
  responses: const [],
);

class _EntryRepo extends TestEntryRepo {
  bool failRemove = false;

  _EntryRepo() : super(const AuthUser.uid(uid: 'user'), _profile);

  @override
  Future<RepoResult<void>> removeEntry(String entryId) async {
    if (failRemove) return const Failure(message: 'Remove failed');
    return super.removeEntry(entryId);
  }
}

class _StampRepo extends StampRepo<Stamp> {
  final EntryRepo entries;
  final bool projectsEntries;
  List<Stamp> values = [];
  final List<String?> removedIds = [];
  int refreshes = 0;

  _StampRepo({required this.entries, required this.projectsEntries})
    : super(
        authUser: const AuthUser.uid(uid: 'user'),
        currentUser: _profile,
        questionRepo: TestQuestionRepo(subUser: _profile),
      );

  @override
  Stream<List<Stamp>> get stamps => Stream.value(values);

  @override
  Future<void> refresh() async {
    refreshes++;
    if (projectsEntries) {
      values = [
        for (final entry in await entries.entries.first) _response(entry.id!),
      ];
    }
  }

  @override
  Future<RepoResult<void>> removeStamp(Stamp stamp) async {
    removedIds.add(stamp.id);
    if (projectsEntries) {
      return const Failure(message: 'Projected entry was already removed');
    }
    values = values.where((value) => value.id != stamp.id).toList();
    return const Success(null);
  }

  @override
  Future<RepoResult<Stamp?>> addStamp(Stamp stamp) async =>
      throw UnimplementedError();

  @override
  Future<RepoResult<Stamp?>> updateStamp(Stamp stamp) async =>
      throw UnimplementedError();

  @override
  Future<void> refreshCheckins({Iterable<String>? types}) => refresh();
}
