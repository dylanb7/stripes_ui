import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final blueDyeTestProgressProvider = Provider<BlueDyeTestProgress>((ref) {
  final AsyncValue<TestsState> asyncState = ref.watch(testsHolderProvider);
  final AsyncValue<List<Stamp>> stamps = ref.watch(stampHolderProvider);
  if (!stamps.hasValue || !asyncState.hasValue) {
    return const BlueDyeTestProgress(
        stage: BlueDyeTestStage.initial,
        testIteration: 0,
        lastTestCompleted: null);
  }
  final List<BlueDyeResp> testResponses =
      stamps.value!.whereType<BlueDyeResp>().toList();

  final MostRecent? mostRecent = _getMostRecent(testResponses);
  final int iterations = testResponses.length;
  final BlueDyeState? state = asyncState.value!.getTestState<BlueDyeState>();
  return BlueDyeTestProgress(
      stage: stageFromTestState(state),
      testIteration: iterations,
      lastTestCompleted: mostRecent);
});

@immutable
class MostRecent {
  final BlueDyeResp test;
  final DateTime finishTime;

  const MostRecent({required this.test, required this.finishTime});
}

MostRecent? _getMostRecent(List<BlueDyeResp> testResponses) {
  if (testResponses.isEmpty) return null;
  BlueDyeResp? latest;
  DateTime? latestsTime;
  for (final BlueDyeResp testResponse in testResponses) {
    DateTime? lastEntry;
    for (final BMTestLog log in testResponse.logs) {
      DateTime logTime = dateFromStamp(log.stamp);
      lastEntry ??= logTime;
      if (logTime.isAfter(lastEntry)) {
        lastEntry = logTime;
      }
    }
    latestsTime ??= lastEntry;
    latest ??= testResponse;
    if (lastEntry != null && lastEntry.isAfter(latestsTime!)) {
      latest = testResponse;
      latestsTime = lastEntry;
    }
  }
  if (latest != null && latestsTime != null) {
    return MostRecent(test: latest, finishTime: latestsTime);
  }
  return null;
}

@immutable
class BlueDyeTestProgress {
  final BlueDyeTestStage stage;
  final int testIteration;
  final MostRecent? lastTestCompleted;

  BlueDyeProgression? getProgression() {
    if (stage == BlueDyeTestStage.initial && testIteration == 0) return null;
    if (testIteration == 0 && stage == BlueDyeTestStage.started ||
        stage == BlueDyeTestStage.amountConsumed) {
      return BlueDyeProgression.stepOne;
    }
    if (testIteration == 0 ||
        (lastTestCompleted != null &&
            DateTime.now()
                    .difference(lastTestCompleted!.finishTime)
                    .compareTo(const Duration(days: 7)) <
                0)) return BlueDyeProgression.stepTwo;
    if (stage == BlueDyeTestStage.amountConsumed ||
        stage == BlueDyeTestStage.started) return BlueDyeProgression.stepThree;
    return BlueDyeProgression.stepFour;
  }

  const BlueDyeTestProgress(
      {required this.stage,
      required this.lastTestCompleted,
      required this.testIteration});
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
