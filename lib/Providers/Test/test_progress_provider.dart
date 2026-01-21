import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';

final blueDyeTestProgressProvider =
    FutureProvider<BlueDyeTestProgress>((ref) async {
  final AuthUser user = await ref.watch(authStream.future);
  final BlueDyeState? blueDyeState = await ref.watch(testsHolderProvider
      .selectAsync((value) => value.getTestState<BlueDyeState>()));

  final String? group = user.attributes["custom:group"];
  final List<BlueDyeResp> testResponses = await ref.watch(
      stampsStreamProvider.selectAsync((responses) => responses
          .whereType<BlueDyeResp>()
          .where((test) => test.group == group)
          .toList()));

  final List<TestDate> mostRecent = _getOrderedTests(testResponses);

  final int iterations = testResponses.length;
  final stage = stageFromTestState(blueDyeState);

  final progress = BlueDyeTestProgress(
      stage: stage, testIteration: iterations, orderedTests: mostRecent);

  return progress;
});

@immutable
class TestDate {
  final BlueDyeResp test;
  final DateTime finishTime;

  const TestDate({required this.test, required this.finishTime});
}

List<TestDate> _getOrderedTests(List<BlueDyeResp> testResponses) {
  if (testResponses.isEmpty) return [];

  DateTime end(BlueDyeResp resp) {
    DateTime? lastEntry;
    for (final BMTestLog log in resp.logs) {
      DateTime logTime = dateFromStamp(log.stamp);
      lastEntry ??= logTime;
      if (logTime.isAfter(lastEntry)) {
        lastEntry = logTime;
      }
    }
    return lastEntry ?? DateTime.now();
  }

  final List<TestDate> testDates = testResponses
      .map<TestDate>((res) => TestDate(test: res, finishTime: end(res)))
      .toList()
    ..sort((first, second) => first.finishTime.compareTo(second.finishTime));

  return testDates;
}

@immutable
class BlueDyeTestProgress {
  final BlueDyeTestStage stage;
  final int testIteration;
  final List<TestDate> orderedTests;

  /// Returns the current progression step based on test state and iterations.
  ///
  /// Progression flow:
  /// - null: No tests started (initial state, 0 iterations)
  /// - stepOne: Test 1 meal in progress (started/amountConsumed, 0 iterations)
  /// - stepTwo: Test 1 logging BMs (logs/logsSubmit stages, 0 iterations)
  /// - stepThree: Waiting period between tests (1 completed test, no test in progress)
  /// - stepFour: Test 2 meal in progress (started/amountConsumed, 1 iteration)
  /// - stepFive: Test 2 logging BMs (logs/logsSubmit stages, 1 iteration)
  /// - completed: Study complete (2+ tests, no test in progress)
  BlueDyeProgression? getProgression() {
    // No tests started, no submissions
    if (stage == BlueDyeTestStage.initial && testIteration == 0) return null;

    // Test 1: Started or entering amount (iteration 0, test in progress)
    if (testIteration == 0 && stage.testInProgress) {
      if (stage == BlueDyeTestStage.started ||
          stage == BlueDyeTestStage.amountConsumed) {
        return BlueDyeProgression.stepOne;
      }
      // Logging BMs for test 1
      return BlueDyeProgression.stepTwo;
    }

    // Test 1 complete, waiting for test 2 (1 test submitted, no test in progress)
    if (testIteration == 1 && !stage.testInProgress) {
      return BlueDyeProgression.stepThree;
    }

    // Test 2: Started or entering amount (1 test submitted, test in progress)
    if (testIteration == 1 && stage.testInProgress) {
      if (stage == BlueDyeTestStage.started ||
          stage == BlueDyeTestStage.amountConsumed) {
        return BlueDyeProgression.stepFour;
      }
      // Logging BMs for test 2
      return BlueDyeProgression.stepFive;
    }

    // Study complete: 2+ tests submitted, no test in progress
    if (testIteration >= 2 && !stage.testInProgress) {
      return BlueDyeProgression.completed;
    }

    // Fallback: in-progress test (shouldn't normally reach here)
    return BlueDyeProgression.stepFive;
  }

  const BlueDyeTestProgress.loading()
      : stage = BlueDyeTestStage.initial,
        testIteration = -1,
        orderedTests = const [];

  const BlueDyeTestProgress(
      {required this.stage,
      required this.orderedTests,
      required this.testIteration});

  bool isLoading() => testIteration == -1;

  @override
  String toString() {
    return 'Iteration: $testIteration, Stage: ${stage.name}, Tests: $orderedTests';
  }
}

enum BlueDyeProgression {
  stepOne(0),
  stepTwo(1),
  stepThree(2),
  stepFour(3),
  stepFive(4),
  completed(5);

  final int value;

  const BlueDyeProgression(this.value);

  String getLabel(BuildContext context) {
    switch (this) {
      case BlueDyeProgression.stepOne:
        return context.translate.studyProgessionOne;
      case BlueDyeProgression.stepTwo:
        return context.translate.studyProgessionTwo;
      case BlueDyeProgression.stepThree:
        return "Waiting\nTime";
      case BlueDyeProgression.stepFour:
        return context.translate.studyProgessionThree;
      case BlueDyeProgression.stepFive:
        return context.translate.studyProgessionFour;
      case BlueDyeProgression.completed:
        return "Complete";
    }
  }
}
