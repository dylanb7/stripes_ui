import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:uuid/uuid.dart';

/// Distinguishes one recording batch from a study run in [Entry.sessionId].
const String recordBatchIdField = 'recordBatchId';

/// Recovery information when a failed write could not be fully compensated.
///
/// Keep the draft and its entry IDs for retry. Entries listed in
/// [remainingEntryIds] either remain saved or could not be verified as removed.
class RecordSessionWriteRecovery {
  final Failure<dynamic> cause;
  final List<String> remainingEntryIds;
  final Map<String, Failure<dynamic>> rollbackFailures;

  RecordSessionWriteRecovery({
    required this.cause,
    required Iterable<String> remainingEntryIds,
    Map<String, Failure<dynamic>> rollbackFailures = const {},
  }) : remainingEntryIds = List.unmodifiable(remainingEntryIds.toSet()),
       rollbackFailures = Map.unmodifiable(rollbackFailures);
}

/// Entry persistence boundary for one user recording flow.
///
/// The UI may still collect answers in one or more SessionGraphs, but it
/// converts their final snapshots to strongly typed [Entry] objects before
/// calling this writer.
abstract interface class RecordSessionWriter {
  Future<RepoResult<List<Entry>>> createSession({
    required String sessionId,
    required List<Entry> entries,
    bool preserveEntrySessionIds = false,
  });

  Future<RepoResult<List<Entry>>> updateSession({required List<Entry> entries});

  Future<RepoResult<void>> removeEntries({required List<Entry> entries});
}

/// Implements session writes over the Entry repository contract.
///
/// EntryRepo does not yet expose a transactional batch operation. This writer
/// therefore compensates for a failed create by removing entries it added and
/// compensates for a failed update by restoring entries it already changed.
class EntryRepoRecordSessionWriter implements RecordSessionWriter {
  final EntryRepo repository;

  const EntryRepoRecordSessionWriter(this.repository);

  @override
  Future<RepoResult<List<Entry>>> createSession({
    required String sessionId,
    required List<Entry> entries,
    bool preserveEntrySessionIds = false,
  }) async {
    if (sessionId.trim().isEmpty) {
      return const Failure(
        message: 'A record session ID is required',
        type: FailureType.validation,
      );
    }
    if (entries.isEmpty) {
      return const Failure(
        message: 'A record session must contain at least one entry',
        type: FailureType.validation,
      );
    }

    // Callers that retry a draft must supply stable IDs. Generated IDs retain
    // compatibility with older callers that only create one entry at a time.
    final prepared = [
      for (final candidate in entries)
        candidate.copyWith(
          id: candidate.id ?? const Uuid().v4(),
          sessionId:
              preserveEntrySessionIds &&
                  candidate.sessionId != null &&
                  candidate.sessionId!.isNotEmpty
              ? candidate.sessionId
              : sessionId,
          data: {...candidate.data, recordBatchIdField: sessionId},
        ),
    ];
    final validation = _validateEntries(prepared);
    if (validation != null) return validation;

    final Map<String, Entry> existing;
    try {
      existing = await _entriesById();
    } catch (error, stackTrace) {
      return _exceptionFailure(error, stackTrace);
    }

    // Check every collision before mutating anything. Retry may reuse an
    // identical entry from this batch, but must never overwrite another entry.
    final retained = [
      for (final candidate in prepared)
        if (existing[candidate.id] case final Entry original)
          if (original.data[recordBatchIdField] == sessionId) original,
    ];
    for (final candidate in prepared) {
      final original = existing[candidate.id];
      if (original != null && !_sameRecord(candidate, original)) {
        return _recoveryFailure(
          Failure(
            message: 'Entry ${candidate.id} already exists with different data',
            type: FailureType.validation,
          ),
          retained.map((entry) => entry.id!),
          const {},
        );
      }
    }

    final saved = <Entry>[];
    final created = <Entry>[];
    for (final candidate in prepared) {
      final original = existing[candidate.id];
      if (original != null) {
        saved.add(original);
        continue;
      }
      final result = await _write(() => repository.addEntry(candidate));
      switch (result) {
        case Success(data: final entry):
          saved.add(entry);
          created.add(entry);
        case Failure():
          return _recoverCreateFailure(
            result,
            attempted: candidate,
            created: created,
            retained: retained,
          );
      }
    }
    return Success(List.unmodifiable(saved));
  }

  @override
  Future<RepoResult<List<Entry>>> updateSession({
    required List<Entry> entries,
  }) async {
    if (entries.isEmpty) {
      return const Failure(
        message: 'A record session must contain at least one entry',
        type: FailureType.validation,
      );
    }
    final validation = _validateEntries(entries);
    if (validation != null) return validation;

    // Some repository packages construct EntryRepo lazily with an initially
    // empty stream. Refresh before resolving originals so the first edit does
    // not mistake that seed value for a missing persisted entry.
    final Map<String, Entry> originalsById;
    try {
      originalsById = await _entriesById();
    } catch (error, stackTrace) {
      return _exceptionFailure(error, stackTrace);
    }
    final originals = <Entry>[];
    final saved = <Entry>[];

    for (final candidate in entries) {
      if (originalsById[candidate.id] == null) {
        return Failure(
          message: 'Entry ${candidate.id} was not found',
          type: FailureType.validation,
        );
      }
    }

    for (final candidate in entries) {
      final original = originalsById[candidate.id]!;
      final result = await _write(
        () =>
            repository.updateEntry(_withExistingMetadata(candidate, original)),
      );
      switch (result) {
        case Success(data: final entry):
          originals.add(original);
          saved.add(entry);
        case Failure():
          // Include the failed operation: its acknowledgement may have failed
          // after the repository committed the update.
          final failures = await _rollbackUpdated([...originals, original]);
          return _recoveryFailure(result, failures.keys, failures);
      }
    }
    return Success(List.unmodifiable(saved));
  }

  @override
  Future<RepoResult<void>> removeEntries({required List<Entry> entries}) async {
    final validation = _validateEntries(entries);
    if (validation != null) {
      return Failure(message: validation.message, type: validation.type);
    }
    for (final entry in entries.reversed) {
      final id = entry.id;
      if (id == null || id.isEmpty) {
        return const Failure(
          message: 'Cannot remove an entry without an ID',
          type: FailureType.validation,
        );
      }
      final result = await _write(() => repository.removeEntry(id));
      if (result case Failure()) return result;
    }
    return const Success(null);
  }

  Entry _withExistingMetadata(Entry candidate, Entry original) {
    return Entry(
      id: candidate.id,
      subUserId: candidate.subUserId,
      group: candidate.group ?? original.group,
      stamp: candidate.stamp,
      entityType: candidate.entityType,
      data: {
        ...original.data,
        ...candidate.data,
        if (original.data.containsKey(recordBatchIdField))
          recordBatchIdField: original.data[recordBatchIdField],
      },
      timeOfDay: candidate.timeOfDay ?? original.timeOfDay,
      sessionId: candidate.sessionId ?? original.sessionId,
      createdAt: candidate.createdAt ?? original.createdAt,
      updatedAt: candidate.updatedAt ?? original.updatedAt,
    );
  }

  Future<Map<String, Failure<dynamic>>> _rollbackCreated(
    List<Entry> entries,
  ) async {
    final failures = <String, Failure<dynamic>>{};
    for (final entry in entries.reversed) {
      final id = entry.id;
      if (id == null) continue;
      final result = await _write(() => repository.removeEntry(id));
      if (result case Failure()) failures[id] = result;
    }
    return failures;
  }

  Future<Map<String, Failure<dynamic>>> _rollbackUpdated(
    List<Entry> entries,
  ) async {
    final failures = <String, Failure<dynamic>>{};
    for (final entry in entries.reversed) {
      final result = await _write(() => repository.updateEntry(entry));
      if (result case Failure()) failures[entry.id!] = result;
    }
    return failures;
  }

  Future<RepoResult<List<Entry>>> _recoverCreateFailure(
    Failure<dynamic> failure, {
    required Entry attempted,
    required List<Entry> created,
    required Iterable<Entry> retained,
  }) async {
    final unresolved = <String>{};
    // A failed request may nevertheless have committed. Reconcile its stable
    // ID before compensating so retry does not create a second copy.
    try {
      final afterFailure = (await _entriesById())[attempted.id];
      if (afterFailure != null) {
        if (_sameRecord(attempted, afterFailure)) {
          created.add(afterFailure);
        } else {
          unresolved.add(attempted.id!);
        }
      }
    } catch (_) {
      unresolved.add(attempted.id!);
    }
    final failures = await _rollbackCreated(created);
    return _recoveryFailure(failure, {
      for (final entry in retained) entry.id!,
      ...unresolved,
      ...failures.keys,
    }, failures);
  }

  Future<Map<String, Entry>> _entriesById() async {
    await repository.refresh();
    final entries = await repository.entries.first;
    return {
      for (final entry in entries)
        if (entry.id != null) entry.id!: entry,
    };
  }

  Failure<List<Entry>>? _validateEntries(List<Entry> entries) {
    final ids = <String>{};
    for (final entry in entries) {
      if (entry.id == null || entry.id!.trim().isEmpty) {
        return const Failure(
          message: 'Every entry must have an ID',
          type: FailureType.validation,
        );
      }
      if (!ids.add(entry.id!)) {
        return const Failure(
          message: 'A recording batch cannot contain duplicate entry IDs',
          type: FailureType.validation,
        );
      }
      if (entry.subUserId != repository.currentUser.uid) {
        return const Failure(
          message: 'The recording profile does not match this repository',
          type: FailureType.validation,
        );
      }
    }
    return null;
  }

  bool _sameRecord(Entry a, Entry b) =>
      a.id == b.id &&
      a.subUserId == b.subUserId &&
      a.group == b.group &&
      a.stamp == b.stamp &&
      a.entityType == b.entityType &&
      (a.timeOfDay ?? TimeOfDayEntry.exact) ==
          (b.timeOfDay ?? TimeOfDayEntry.exact) &&
      a.sessionId == b.sessionId &&
      const DeepCollectionEquality().equals(a.data, b.data);

  Future<RepoResult<T>> _write<T>(
    Future<RepoResult<T>> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      return _exceptionFailure(error, stackTrace);
    }
  }

  Failure<T> _exceptionFailure<T>(Object error, StackTrace stackTrace) =>
      Failure(
        message: 'Unable to complete the record operation',
        error: error,
        stackTrace: stackTrace,
      );

  Failure<List<Entry>> _recoveryFailure(
    Failure<dynamic> failure,
    Iterable<String> remaining,
    Map<String, Failure<dynamic>> rollbackFailures,
  ) {
    final remainingIds = remaining.toSet();
    if (remainingIds.isEmpty) return _listFailure(failure);
    return Failure(
      message:
          '${failure.message}. Some entries remain saved or could not be '
          'verified. Keep this recording and retry to reconcile the save.',
      type: failure.type,
      error: RecordSessionWriteRecovery(
        cause: failure,
        remainingEntryIds: remainingIds,
        rollbackFailures: rollbackFailures,
      ),
      stackTrace: failure.stackTrace,
    );
  }

  Failure<List<Entry>> _listFailure(Failure<dynamic> failure) => Failure(
    message: failure.message,
    type: failure.type,
    error: failure.error,
    stackTrace: failure.stackTrace,
  );
}

/// Deletes an Entry and any independent legacy copy of that same record.
///
/// Refresh first so repositories that project Entries as stamps do not receive
/// a second removal for an already-deleted record.
Future<RepoResult<void>> removeRecordedEntry({
  required RecordSessionWriter writer,
  required Entry entry,
  StampRepo<Stamp>? stampRepo,
}) async {
  try {
    final result = await writer.removeEntries(entries: [entry]);
    if (result case Failure()) return result;
    if (stampRepo == null) return const Success(null);

    await stampRepo.refresh();
    final stamps = await stampRepo.stamps.first;
    for (final legacy in stamps.where((stamp) => stamp.id == entry.id)) {
      final legacyResult = await stampRepo.removeStamp(legacy);
      if (legacyResult case Failure()) return legacyResult;
    }
    return const Success(null);
  } catch (error, stackTrace) {
    return Failure(
      message: 'Unable to finish removing the record',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Direct access to the rich Entry repository. Existing stamp providers remain
/// available for the legacy flow and compatibility projections.
final entryRepoProvider = FutureProvider<EntryRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final sub = await ref.watch(
    subHolderProvider.selectAsync((state) => state.selected),
  );
  if (AuthUser.isEmpty(auth) || sub == null || SubUser.isEmpty(sub)) {
    return null;
  }
  return ref.watch(reposProvider).entry(user: auth, subUser: sub);
});

final entriesStreamProvider = StreamProvider<List<Entry>>((ref) async* {
  final repository = await ref.watch(entryRepoProvider.future);
  if (repository == null) {
    yield const [];
    return;
  }
  yield* repository.entries;
});

final recordSessionWriterProvider = FutureProvider<RecordSessionWriter?>((
  ref,
) async {
  final repository = await ref.watch(entryRepoProvider.future);
  return repository == null ? null : EntryRepoRecordSessionWriter(repository);
});
