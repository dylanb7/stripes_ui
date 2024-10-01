import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final blueDyeTestProgressProvider = Provider<BlueDyeTestProgress>((ref) {
  final AsyncValue<TestsState> asyncState = ref.watch(testsHolderProvider);
  final AsyncValue<List<Stamp>> stamps = ref.watch(stampHolderProvider);
  final AsyncValue<AuthUser> userStream = ref.watch(authStream);

  if (asyncState.isLoading || stamps.isLoading || userStream.isLoading) {
    return const BlueDyeTestProgress.loading();
  }

  final AuthUser? user = userStream.valueOrNull;
  final String? group = user?.attributes["custom:group"];
  if (!stamps.hasValue || !asyncState.hasValue || group == null) {
    return const BlueDyeTestProgress(
        stage: BlueDyeTestStage.initial, testIteration: 0, orderedTests: []);
  }
  final List<BlueDyeResp> testResponses = stamps.value!
      .whereType<BlueDyeResp>()
      .where((test) => test.group == group)
      .toList();

  final List<TestDate> mostRecent = _getOrderedTests(testResponses);
  final int iterations = testResponses.length;
  final BlueDyeState? state = asyncState.value!.getTestState<BlueDyeState>();
  return BlueDyeTestProgress(
      stage: stageFromTestState(state),
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
    if (testIteration == 0 ||
        (orderedTests.length == 1 && !stage.testInProgress)) {
      return BlueDyeProgression.stepTwo;
    }
    if (stage == BlueDyeTestStage.amountConsumed ||
        stage == BlueDyeTestStage.started) return BlueDyeProgression.stepThree;
    return BlueDyeProgression.stepFour;
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
  stepFour(3);

  final int value;

  const BlueDyeProgression(this.value);

  String getLabel(BuildContext context) {
    switch (this) {
      case BlueDyeProgression.stepOne:
        return AppLocalizations.of(context)!.studyProgessionOne;
      case BlueDyeProgression.stepTwo:
        return AppLocalizations.of(context)!.studyProgessionTwo;
      case BlueDyeProgression.stepThree:
        return AppLocalizations.of(context)!.studyProgessionThree;
      case BlueDyeProgression.stepFour:
        return AppLocalizations.of(context)!.studyProgessionFour;
    }
  }
}
