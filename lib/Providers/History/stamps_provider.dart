import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/questions/questions_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

import 'package:stripes_ui/Providers/Auth/auth_provider.dart';

final stampProvider = FutureProvider<StampRepo<Stamp>?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final sub =
      await ref.watch(subHolderProvider.selectAsync((value) => value.selected));
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
  final StampRepo? repo = await ref.watch(stampProvider.future);
  if (repo == null) {
    yield [];
  } else {
    yield* repo.stamps;
  }
});

final baselinesStreamProvider = StreamProvider<List<Stamp>>((ref) async* {
  final StampRepo? repo = await ref.watch(stampProvider.future);
  if (repo == null || repo is! BaselineMixin) {
    yield [];
  } else {
    yield* repo.baselines;
  }
});

final stampHolderProvider =
    AsyncNotifierProvider<StampNotifier, List<Stamp>>(StampNotifier.new);

class StampNotifier extends AsyncNotifier<List<Stamp>> {
  @override
  FutureOr<List<Stamp>> build() async {
    await ref.watch(questionHomeProvider.future);
    return await ref.watch(stampsStreamProvider.future);
  }

  changeEarliest(DateTime time) {
    final AsyncData<StampRepo<Stamp>?>? current =
        ref.read(stampProvider).asData;
    if (current == null || !current.hasValue) return;
    final StampRepo repo = current.value!;
    if (repo.earliest != null && time.isBefore(repo.earliest!)) {
      repo.earliestDate = time;
    }
  }

  @override
  String toString() {
    return state
        .map<List<Stamp>>(
            data: (data) => data.value,
            error: (error) => [],
            loading: (loading) => [])
        .map((e) => e.type)
        .join(' ');
  }
}
