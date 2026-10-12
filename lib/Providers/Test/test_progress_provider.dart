import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

/// Derives BlueDye progression from the modular [ActiveTestProtocol] state.
final blueDyeTestProgressProvider = FutureProvider<BlueDyeTestProgress>((
  ref,
) async {
  final ActiveTestProtocol? protocol = await ref.watch(
    activeProtocolProvider.future,
  );
  final BlueDyeMealState mealState = await ref.watch(
    blueDyeMealStateProvider.future,
  );

  if (protocol == null) {
    return const BlueDyeTestProgress(
      stage: BlueDyeTestStage.initial,
      orderedTests: [],
      testIteration: 0,
      isCompleted: false,
      protocolStageId: null,
    );
  }

  final stamps = await ref.watch(
    stampsStreamProvider.selectAsync((stamps) => stamps),
  );
  final orderedTests = <TestDate>[];
  for (final run in blueDyeCompletedRuns(protocol)) {
    final date = _testDateForRun(
      run.mealState,
      blueDyeBmTestLogs(stamps, run.sessionId),
      sessionId: run.sessionId,
      finishTime: run.finishTime,
    );
    if (date != null) orderedTests.add(date);
  }

  final stageId = protocol.currentStageId;
  if (stageId == 'waiting' || stageId == 'completed') {
    final activeSessionId = blueDyeActiveRunSessionId(protocol);
    if (!blueDyeCompletedRuns(protocol)
        .any((run) => run.sessionId == activeSessionId)) {
      final date = _testDateForRun(
        mealState,
        blueDyeBmTestLogs(stamps, activeSessionId),
        sessionId: activeSessionId,
      );
      if (date != null) orderedTests.add(date);
    }
  }
  orderedTests.sort(
    (first, second) => first.finishTime.compareTo(second.finishTime),
  );

  return BlueDyeTestProgress(
    stage: mealState.stage,
    orderedTests: orderedTests,
    testIteration: orderedTests.length,
    isCompleted: protocol.isCompleted,
    protocolStageId: stageId,
  );
});

TestDate? _testDateForRun(
  BlueDyeMealState mealState,
  List<BMTestLog> logs, {
  required String sessionId,
  DateTime? finishTime,
}) {
  final startEating = mealState.startTime;
  if (startEating == null || logs.isEmpty) return null;
  final blueLogs = logs.where((log) => log.isBlue).toList();
  final fallbackBlueTime = startEating;
  final response = BlueDyeResp(
    id: sessionId,
    startEating: startEating,
    eatingDuration: mealState.finishedEating ?? Duration.zero,
    finishedEatingTime: mealState.finishedEatingTime,
    normalBowelMovements: logs.length - blueLogs.length,
    blueBowelMovements: blueLogs.length,
    amountConsumed: mealState.amountConsumed ?? AmountConsumed.undetermined,
    logs: logs,
    firstBlue: blueLogs.isEmpty
        ? fallbackBlueTime
        : dateFromStamp(blueLogs.first.stamp),
    lastBlue: blueLogs.isEmpty
        ? fallbackBlueTime
        : dateFromStamp(blueLogs.last.stamp),
  );
  return TestDate(
    test: response,
    finishTime: finishTime ?? dateFromStamp(logs.last.stamp),
  );
}

@immutable
class BlueDyeTestProgress {
  final BlueDyeTestStage stage;
  final int testIteration;
  final List<TestDate> orderedTests;
  final bool isCompleted;
  final String? protocolStageId;

  BlueDyeProgression? getProgression() {
    switch (protocolStageId) {
      case 'eat_meal':
        return BlueDyeProgression.stepOne;
      case 'awaiting_transit':
        return BlueDyeProgression.stepTwo;
      case 'waiting':
        return BlueDyeProgression.stepThree;
      case 'eat_meal_2':
        return BlueDyeProgression.stepFour;
      case 'awaiting_transit_2':
        return BlueDyeProgression.stepFive;
      case 'completed':
        return BlueDyeProgression.completed;
    }

    if (isCompleted) return BlueDyeProgression.completed;

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
      orderedTests = const [],
      isCompleted = false,
      protocolStageId = null;

  const BlueDyeTestProgress({
    required this.stage,
    required this.orderedTests,
    required this.testIteration,
    this.isCompleted = false,
    this.protocolStageId,
  });

  bool isLoading() => testIteration == -1;

  @override
  String toString() {
    return 'Iteration: $testIteration, Stage: ${stage.name}, Tests: $orderedTests';
  }
}

@immutable
class TestDate {
  final BlueDyeResp test;
  final DateTime finishTime;

  const TestDate({required this.test, required this.finishTime});
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
        return "Eat\nMeal";
      case BlueDyeProgression.stepTwo:
        return "Log\nBMs";
      case BlueDyeProgression.stepThree:
        return "Waiting\nTime";
      case BlueDyeProgression.stepFour:
        return "Eat\nMeal";
      case BlueDyeProgression.stepFive:
        return "Log\nBMs";
      case BlueDyeProgression.completed:
        return "Complete";
    }
  }
}
