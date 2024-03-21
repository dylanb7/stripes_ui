import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

final testProvider = FutureProvider<TestsRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final questions = await ref.watch(questionsProvider.future);
  final stamps = await ref.watch(stampProvider.future);
  final SubUser? sub = ref
      .watch(subHolderProvider.select((value) => value.valueOrNull?.selected));
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (stamps == null || subEmpty) return null;
  return ref.watch(reposProvider).test(
      user: auth, subUser: sub, stampRepo: stamps, questionRepo: questions);
});

final testStreamProvider = StreamProvider<List<TestObj>>((ref) async* {
  final TestsRepo? repo = await ref.watch(testProvider.future);
  if (repo == null) {
    yield [];
  } else {
    yield* repo.objects;
  }
});

T? getTest<T extends Test>(AsyncValue<TestsRepo?> repo) {
  if (!repo.hasValue || repo.value == null) return null;
  final List<T> tests = repo.value!.tests.whereType<T>().toList();
  return tests.isEmpty ? null : tests[0];
}

K? getObject<K extends TestObj>(AsyncValue<List<TestObj>> values) {
  final List<TestObj> tests = values.map(
      data: (data) => data.value,
      error: (error) => [],
      loading: (loading) => []);
  final List<K> value = tests.whereType<K>().toList();
  return value.firstOrNull;
}
