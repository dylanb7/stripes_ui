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
      stampHolderProvider.selectAsync((responses) => responses
          .whereType<BlueDyeResp>()
          .where((test) => test.group == group)
          .toList()));

  final List<TestDate> mostRecent = _getOrderedTests(testResponses);

  final int iterations = testResponses.length;

  return BlueDyeTestProgress(
      stage: stageFromTestState(blueDyeState),
      testIteration: iterations,
      orderedTests: mostRecent);
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

  BlueDyeProgression? getProgression() {
    if (stage == BlueDyeTestStage.initial && testIteration == 0) return null;
    if (testIteration == 0 &&
        (stage == BlueDyeTestStage.started ||
            stage == BlueDyeTestStage.amountConsumed)) {
      return BlueDyeProgression.stepOne;
    }
    if (testIteration == 0) {
      return BlueDyeProgression.stepTwo;
    }
    if (!stage.testInProgress && orderedTests.length == 1) {
      return BlueDyeProgression.stepThree;
    }
    if (stage == BlueDyeTestStage.amountConsumed ||
        stage == BlueDyeTestStage.started) {
      return BlueDyeProgression.stepFour;
    }
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
  stepFive(4);

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
    }
  }
}
