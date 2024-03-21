import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

import 'auth_provider.dart';

final stampProvider = FutureProvider<StampRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final questions = await ref.watch(questionsProvider.future);
  final sub = ref
      .watch(subHolderProvider.select((value) => value.valueOrNull?.selected));
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (AuthUser.isEmpty(auth) || subEmpty) {
    return null;
  }
  return ref
      .watch(reposProvider)
      .stamp(user: auth, subUser: sub, questionRepo: questions);
});

final stampsStreamProvider = StreamProvider<List<Stamp>>((ref) {
  return ref
          .watch(stampProvider)
          .mapOrNull(data: (data) => data.value!.stamps) ??
      const Stream.empty();
});

final stampHolderProvider =
    AsyncNotifierProvider<StampNotifier, List<Stamp>>(StampNotifier.new);

class StampNotifier extends AsyncNotifier<List<Stamp>> {
  @override
  FutureOr<List<Stamp>> build() async {
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
