import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

@immutable
class BlueDyeStudyRunRecords {
  final BlueDyeMealState meal;
  final List<BMTestLog> bowelMovements;

  const BlueDyeStudyRunRecords({
    required this.meal,
    required this.bowelMovements,
  });

  // Starting the study alone sets startTime; it is not a recorded meal yet.
  bool get hasMeal =>
      meal.finishedEating != null ||
      meal.amountConsumed != null ||
      meal.finishedEatingTime != null;
}

/// Keys are transit run indices (0 or 1), not positions in a filtered log list.
/// A deleted first-run BM must never cause second-run records to move to step 2.
final blueDyeStudyRecordsProvider =
    FutureProvider<Map<int, BlueDyeStudyRunRecords>>((ref) async {
      final protocol = await ref.watch(activeProtocolProvider.future);
      if (protocol == null) return const {};
      final activeSession = blueDyeActiveRunSessionId(protocol);
      final secondRun = const [
        'eat_meal_2',
        'awaiting_transit_2',
        'completed',
      ].contains(protocol.currentStageId);
      final snapshots = blueDyeCompletedRuns(protocol);
      final meals = <int, ({String session, BlueDyeMealState meal})>{};
      if (secondRun) {
        final previousRuns =
            snapshots.where((run) => run.sessionId != activeSession).toList()
              ..sort((a, b) => a.finishTime.compareTo(b.finishTime));
        if (previousRuns.isNotEmpty) {
          meals[0] = (
            session: previousRuns.first.sessionId,
            meal: previousRuns.first.mealState,
          );
        }
      }
      meals[secondRun ? 1 : 0] = (
        session: activeSession,
        meal: BlueDyeMealState.fromContext(protocol.testContext),
      );
      final records = await Future.wait(
        meals.entries.map((entry) async {
          final logs = await ref.watch(
            blueDyeRunLogsProvider(entry.value.session).future,
          );
          return MapEntry(
            entry.key,
            BlueDyeStudyRunRecords(
              meal: entry.value.meal,
              bowelMovements: logs,
            ),
          );
        }),
      );
      return Map.unmodifiable(Map.fromEntries(records));
    }, retry: (_, _) => null);
