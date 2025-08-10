import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/entry.dart';

final testProvider = FutureProvider<TestsRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);

  final stamps = await ref.watch(stampProvider.future);
  final SubUser? sub = ref
      .watch(subHolderProvider.select((value) => value.valueOrNull?.selected));
  final questions = await ref.watch(questionsProvider.future);
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (stamps == null || subEmpty || questions == null) return null;
  return ref.watch(reposProvider).test(
      user: auth, subUser: sub, stampRepo: stamps, questionRepo: questions);
});

final testStreamProvider = StreamProvider<List<TestState>>((ref) async* {
  final TestsRepo? repo = await ref.watch(testProvider.future);

  if (repo == null) {
    yield [];
  } else {
    yield* repo.objects;
  }
});

final testsHolderProvider =
    AsyncNotifierProvider<TestsNotifier, TestsState>(TestsNotifier.new);

class TestsNotifier extends AsyncNotifier<TestsState> {
  @override
  FutureOr<TestsState> build() async {
    final SharedService service = ref.watch(sharedSeviceProvider);
    final TestsRepo? testsRepo = await ref.watch(testProvider.future);

    final List<TestState> testStates =
        ref.watch(testStreamProvider).valueOrNull ?? [];

    if (testsRepo == null || testsRepo.tests.isEmpty) return TestsState.empty();
    final String? currentTestName = await service.getCurrentTest();
    final Test? currentTest = testsRepo.tests
        .firstWhereOrNull((test) => test.testName == currentTestName);
    if (currentTestName == null || currentTest == null) {
      final Test newSelected = testsRepo.tests.first;
      await service.setCurrentTest(name: newSelected.testName);
      return TestsState(
          testsRepo: testsRepo, testStates: testStates, selected: newSelected);
    }
    return TestsState(
        testsRepo: testsRepo, testStates: testStates, selected: currentTest);
  }

  Future<bool> changeCurrent(Test newTest) async {
    final TestsState current = await future;
    final Test? changedTo = current.testsRepo?.tests
        .firstWhereOrNull((test) => test.testName == newTest.testName);
    if (changedTo == null) return false;
    if (changedTo == current.selected) return true;
    final SharedService service = ref.watch(sharedSeviceProvider);

    final bool setTest = await service.setCurrentTest(name: changedTo.testName);

    if (setTest) {
      state = AsyncData(current.copyWith(selected: changedTo));
    }
    return setTest;
  }

  Future<T?> getTest<T extends Test>() async {
    final TestsState current = await future;
    if (current.testsRepo == null) return null;
    return current.testsRepo!.tests.whereType<T>().toList().firstOrNull;
  }

  Future<K?> getTestState<K extends TestState>() async {
    final TestsState current = await future;
    return current.testStates.whereType<K>().toList().firstOrNull;
  }
}

@immutable
class TestsState with EquatableMixin {
  final TestsRepo? testsRepo;
  final List<TestState> testStates;
  final Test? selected;

  TestsState(
      {required this.testsRepo, required this.testStates, this.selected});

  factory TestsState.empty() =>
      TestsState(testsRepo: null, testStates: const []);

  TestsState copyWith(
          {TestsRepo? testsRepo,
          List<TestState>? testStates,
          Test? selected}) =>
      TestsState(
          testStates: testStates ?? this.testStates,
          selected: selected ?? this.selected,
          testsRepo: testsRepo ?? this.testsRepo);

  T? getTest<T extends Test>() {
    if (testsRepo == null) return null;
    return testsRepo!.tests.whereType<T>().toList().firstOrNull;
  }

  K? getTestState<K extends TestState>() {
    return testStates.whereType<K>().toList().firstOrNull;
  }

  @override
  List<Object?> get props => [testsRepo, testStates, selected];
}
