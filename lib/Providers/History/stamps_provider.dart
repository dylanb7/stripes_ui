import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';

import 'package:stripes_ui/Providers/Auth/auth_provider.dart';

final stampProvider = FutureProvider<StampRepo<Stamp>?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final sub = await ref.watch(
    subHolderProvider.selectAsync((value) => value.selected),
  );
  final questions = await ref.watch(questionsProvider.future);
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (AuthUser.isEmpty(auth) || subEmpty || questions == null) {
    return null;
  }
  return ref
      .watch(reposProvider)
      .stamp(user: auth, subUser: sub, questionRepo: questions);
});

final stampsStreamProvider = StreamProvider<List<Stamp>>((ref) async* {
  final home = await ref.watch(questionHomeProvider.future);
  final entries = await ref.watch(entriesStreamProvider.future);
  final entriesById = {
    for (final entry in entries)
      if (entry.id != null) entry.id!: entry,
  };
  final StampRepo? repo = await ref.watch(stampProvider.future);
  if (repo == null) {
    yield [];
  } else {
    yield* repo.stamps.map((stamps) {
      final seen = <String>{};
      final merged = <Stamp>[
        for (final stamp in stamps)
          if (stamp is DetailResponse && entriesById[stamp.id] != null)
            TimedDetailResponse(
              response:
                  entriesById[stamp.id]!.data.containsKey(recordBatchIdField)
                  ? entriesById[stamp.id]!.toDetailResponse(home)
                  : stamp,
              entry: entriesById[stamp.id]!,
            )
          else
            stamp,
      ];
      for (final stamp in stamps) {
        if (stamp.id != null) seen.add(stamp.id!);
      }
      // Some embedding repositories expose independent legacy and Entry
      // stores. Include new recordings without duplicating projected entries.
      for (final entry in entries) {
        if (entry.id == null ||
            seen.contains(entry.id) ||
            (!entry.data.containsKey(recordTimeField) &&
                !entry.data.containsKey(recordBatchIdField)) ||
            entry.data['responses'] is! List ||
            entry.category == InputCategory.test) {
          continue;
        }
        merged.add(
          TimedDetailResponse(
            response: entry.toDetailResponse(home),
            entry: entry,
          ),
        );
      }
      return merged;
    });
  }
});

final baselinesStreamProvider = StreamProvider<List<Stamp>>((ref) async* {
  final StampRepo? repo = await ref.watch(stampProvider.future);
  if (repo == null || repo is! BaselineMixin) {
    await Completer<void>().future;
    return;
  }
  yield* repo.baselines;
});

void _updateRepoEarliest(StampRepo repo, DateTime time) {
  if (repo.earliest == null || time.isBefore(repo.earliest!)) {
    repo.earliestDate = time;
  }
}

void changeEarliestDate(Ref ref, DateTime time) {
  final AsyncData<StampRepo<Stamp>?>? current = ref.read(stampProvider).asData;
  if (current == null || !current.hasValue) return;
  final StampRepo? repo = current.value;
  if (repo != null) {
    _updateRepoEarliest(repo, time);
  }
}

void changeEarliestDateWidget(WidgetRef ref, DateTime time) {
  final AsyncData<StampRepo<Stamp>?>? current = ref.read(stampProvider).asData;
  if (current == null || !current.hasValue) return;
  final StampRepo? repo = current.value;
  if (repo != null) {
    _updateRepoEarliest(repo, time);
  }
}
