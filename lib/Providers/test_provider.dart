import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

final testProvider = Provider<TestsRepo?>((ref) {
  final StampRepo? repo = ref.watch(stampProvider);
  final SubUser sub =
      ref.watch(subHolderProvider.select((value) => value.current));
  final QuestionRepo questions = ref.watch(questionsProvider);
  if (repo == null) return null;
  return ref.watch(reposProvider).test(
      user: repo.authUser,
      subUser: sub,
      stampRepo: repo,
      questionRepo: questions);
});

final testHolderProvider = ChangeNotifierProvider<TestNotifier>(
  (ref) => TestNotifier(ref.read(testProvider)),
);

class TestNotifier extends ChangeNotifier with EquatableMixin {
  final TestsRepo? repo;

  List<TestObj> objects = [];

  TestNotifier(this.repo) {
    if (repo != null) {
      repo!.objects.listen((event) {
        objects = event;
        notifyListeners();
      });
    }
  }

  List<Test> getTests() {
    return repo?.tests ?? [];
  }

  T? getTest<T extends Test>() {
    final List<T> tests = repo?.tests.whereType<T>().toList() ?? [];
    return tests.isEmpty ? null : tests[0];
  }

  K? getObject<K extends TestObj>() {
    final List<K> objs = objects.whereType<K>().toList();
    return objs.isEmpty ? null : objs[0];
  }

  @override
  List<Object?> get props => [repo];
}
