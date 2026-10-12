import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

void main() {
  group('BlueDyeMealState protocol context', () {
    test('clears nullable timer fields without dropping unrelated context', () {
      final start = DateTime.utc(2026, 8, 8, 12);
      final paused = DateTime.utc(2026, 8, 8, 12, 5);
      final state = BlueDyeMealState(
        startTime: start,
        timerStart: start,
        pauseTime: paused,
      );

      final resumed = state.copyWith(
        timerStart: start.add(const Duration(minutes: 5)),
        clearPauseTime: true,
      );
      final context = resumed.replaceInContext({
        'unrelated': 'preserved',
        BlueDyeContextKeys.pauseTime: paused.toIso8601String(),
      });

      expect(context['unrelated'], 'preserved');
      expect(context, isNot(contains(BlueDyeContextKeys.pauseTime)));
      expect(
        context[BlueDyeContextKeys.timerStart],
        start.add(const Duration(minutes: 5)).toIso8601String(),
      );
    });

    test('replaces stale Blue Dye fields before serializing new state', () {
      final start = DateTime.utc(2026, 8, 8, 12);
      final state = BlueDyeMealState(startTime: start);

      final context = state.replaceInContext({
        BlueDyeContextKeys.finishedEating: 900000,
        BlueDyeContextKeys.amountConsumed: 'AmountConsumed.all',
        BlueDyeContextKeys.logs: [
          {'stamp': 1, 'isBlue': true},
        ],
      });

      expect(context, isNot(contains(BlueDyeContextKeys.finishedEating)));
      expect(context, isNot(contains(BlueDyeContextKeys.amountConsumed)));
      expect(context[BlueDyeContextKeys.logs], isEmpty);
      expect(
        BlueDyeMealState.fromContext(context),
        BlueDyeMealState(startTime: start),
      );
    });
  });

  group('blueDyeBmTestLogs', () {
    test('returns BMs from the requested session in chronological order', () {
      final mealStart = DateTime.utc(2026, 8, 19, 12);
      final dyeQuestion = MultipleChoice(
        id: 'BlueDyeQuestion',
        type: 'category.BM',
        prompt: 'Blue?',
        choices: const ['Yes', 'No'],
      );

      DetailResponse bm(
        DateTime at,
        int selected,
        String id, {
        required String sessionId,
      }) {
        return DetailResponse(
          id: id,
          linkingId: sessionId,
          stamp: dateToStamp(at),
          detailType: 'category.BM',
          responses: [
            MultiResponse(
              question: dyeQuestion,
              stamp: dateToStamp(at),
              index: selected,
            ),
          ],
        );
      }

      final beforeMeal = bm(
        mealStart.subtract(const Duration(minutes: 1)),
        0,
        'before',
        sessionId: 'active-session',
      );
      final brown = bm(
        mealStart.add(const Duration(hours: 2)),
        1,
        'brown',
        sessionId: 'active-session',
      );
      final blue = bm(
        mealStart.add(const Duration(hours: 1)),
        0,
        'blue',
        sessionId: 'active-session',
      );
      final otherSession = bm(
        mealStart.add(const Duration(minutes: 30)),
        0,
        'other',
        sessionId: 'other-session',
      );

      final logs = blueDyeBmTestLogs([
        brown,
        beforeMeal,
        blue,
        otherSession,
      ], 'active-session');

      expect(logs.map((log) => log.id), ['before', 'blue', 'brown']);
      expect(logs.map((log) => log.isBlue), [true, true, false]);
    });

    test('ignores ordinary BMs without the study color response', () {
      final mealStart = DateTime.utc(2026, 8, 19, 12);
      final ordinaryBm = DetailResponse(
        id: 'ordinary',
        linkingId: 'active-session',
        stamp: dateToStamp(mealStart.add(const Duration(minutes: 5))),
        detailType: 'category.BM',
        responses: const [],
      );

      expect(blueDyeBmTestLogs([ordinaryBm], 'active-session'), isEmpty);
    });
  });

  test('starting run two snapshots run one and changes the session id', () {
    final firstStart = DateTime.utc(2026, 8, 1);
    final secondStart = DateTime.utc(2026, 8, 10);
    final completed = BlueDyeMealState(
      startTime: firstStart,
      finishedEating: const Duration(minutes: 10),
      amountConsumed: AmountConsumed.all,
      logs: [
        BlueDyeBmLog(
          stamp: dateToStamp(firstStart.add(const Duration(hours: 5))),
          isBlue: true,
        ),
        BlueDyeBmLog(
          stamp: dateToStamp(firstStart.add(const Duration(hours: 8))),
          isBlue: false,
        ),
      ],
    );
    const protocol = ActiveTestProtocol(
      id: 'protocol',
      testId: 'blue',
      currentStageId: 'waiting',
      testContext: {blueDyeActiveRunSessionKey: 'protocol:1'},
    );

    final context = startSecondBlueDyeRunContext(
      protocol: protocol,
      completedState: completed,
      startTime: secondStart,
    );
    final updated = protocol.copyWith(
      currentStageId: 'eat_meal_2',
      testContext: context,
    );

    expect(blueDyeActiveRunSessionId(updated), 'protocol:2');
    expect(blueDyeCompletedRuns(updated), hasLength(1));
    expect(blueDyeCompletedRuns(updated).single.sessionId, 'protocol:1');
    expect(BlueDyeMealState.fromContext(context).startTime, secondStart);
    expect(BlueDyeMealState.fromContext(context).logs, isEmpty);
  });

  test('protocol stages map directly to the five-step progression', () {
    const expected = {
      'eat_meal': BlueDyeProgression.stepOne,
      'awaiting_transit': BlueDyeProgression.stepTwo,
      'waiting': BlueDyeProgression.stepThree,
      'eat_meal_2': BlueDyeProgression.stepFour,
      'awaiting_transit_2': BlueDyeProgression.stepFive,
      'completed': BlueDyeProgression.completed,
    };

    for (final entry in expected.entries) {
      final progress = BlueDyeTestProgress(
        stage: BlueDyeTestStage.initial,
        orderedTests: const [],
        testIteration: 0,
        isCompleted: entry.key == 'completed',
        protocolStageId: entry.key,
      );
      expect(progress.getProgression(), entry.value);
    }
  });
}
