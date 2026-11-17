import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_meal_state.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

export 'package:stripes_ui/Providers/Test/blue_dye_meal_state.dart';

const String blueDyeActiveRunSessionKey = 'active_run_session_id';
const String blueDyeCompletedRunsKey = 'completed_runs';

String blueDyeActiveRunSessionId(ActiveTestProtocol protocol) {
  final stored = protocol.testContext[blueDyeActiveRunSessionKey];
  if (stored is String && stored.isNotEmpty) return stored;
  final secondRun =
      protocol.currentStageId == 'eat_meal_2' ||
      protocol.currentStageId == 'awaiting_transit_2' ||
      protocol.currentStageId == 'completed';
  return '${protocol.id}:${secondRun ? 2 : 1}';
}

bool isBlueDyeMealStageId(String stageId) =>
    stageId == 'eat_meal' || stageId == 'eat_meal_2';

@immutable
class BlueDyeRunSnapshot {
  final String sessionId;
  final BlueDyeMealState mealState;
  final DateTime finishTime;

  const BlueDyeRunSnapshot({
    required this.sessionId,
    required this.mealState,
    required this.finishTime,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'mealState': mealState.toContext(),
    'finishTime': finishTime.toUtc().toIso8601String(),
  };

  factory BlueDyeRunSnapshot.fromJson(Map<String, dynamic> json) {
    return BlueDyeRunSnapshot(
      sessionId: json['sessionId'] as String,
      mealState: BlueDyeMealState.fromContext(
        Map<String, dynamic>.from(json['mealState'] as Map),
      ),
      finishTime: DateTime.parse(json['finishTime'] as String).toUtc(),
    );
  }
}

List<BlueDyeRunSnapshot> blueDyeCompletedRuns(ActiveTestProtocol protocol) {
  final raw = protocol.testContext[blueDyeCompletedRunsKey];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (value) =>
            BlueDyeRunSnapshot.fromJson(Map<String, dynamic>.from(value)),
      )
      .toList(growable: false);
}

Map<String, dynamic> startSecondBlueDyeRunContext({
  required ActiveTestProtocol protocol,
  required BlueDyeMealState completedState,
  required DateTime startTime,
}) {
  final completed = blueDyeCompletedRuns(protocol).toList();
  final sessionId = blueDyeActiveRunSessionId(protocol);
  if (!completed.any((run) => run.sessionId == sessionId)) {
    final finishTime = completedState.logs.isEmpty
        ? DateTime.now()
        : dateFromStamp(completedState.logs.last.stamp);
    completed.add(
      BlueDyeRunSnapshot(
        sessionId: sessionId,
        mealState: completedState,
        finishTime: finishTime,
      ),
    );
  }

  final context = Map<String, dynamic>.from(protocol.testContext)
    ..[blueDyeCompletedRunsKey] = completed
        .map((run) => run.toJson())
        .toList(growable: false)
    ..[blueDyeActiveRunSessionKey] = '${protocol.id}:2';
  return BlueDyeMealState(
    startTime: startTime,
    timerStart: startTime,
    pauseTime: startTime,
  ).replaceInContext(context);
}

final testProvider = FutureProvider<ModularTestsRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final SubUser? sub = await ref.watch(
    subHolderProvider.selectAsync((value) => value.selected),
  );
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (subEmpty) return null;
  final repo = ref.watch(reposProvider).test(user: auth, subUser: sub);
  await repo?.ensureReady();
  return repo;
}, retry: (_, _) => null);

final testStreamProvider = StreamProvider<List<ActiveTestProtocol>>((
  ref,
) async* {
  final ModularTestsRepo? repo = await ref.watch(testProvider.future);
  if (repo == null) {
    yield [];
  } else {
    yield* repo.activeProtocols;
  }
});

final activeTestProtocolsProvider = StreamProvider<List<ActiveTestProtocol>>((
  ref,
) async* {
  final ModularTestsRepo? repo = await ref.watch(testProvider.future);

  if (repo == null) {
    yield [];
  } else {
    yield* repo.activeProtocols;
  }
});

final activeProtocolProvider = FutureProvider<ActiveTestProtocol?>((ref) async {
  final protocols = await ref.watch(
    activeTestProtocolsProvider.selectAsync((protocols) => protocols),
  );
  if (protocols.isEmpty) return null;
  final nonCompleted = protocols.where((p) => !p.isCompleted);
  if (nonCompleted.isEmpty) return protocols.first;
  return nonCompleted.first;
});

final _protocolBlueDyeMealStateProvider = FutureProvider<BlueDyeMealState>((
  ref,
) async {
  final protocol = await ref.watch(activeProtocolProvider.future);
  if (protocol == null) return const BlueDyeMealState.empty();
  return BlueDyeMealState.fromContext(protocol.testContext);
});

// Protocol history is independent of the timeline's selected date range. Keep
// one subtype subscription so local changes update logs without reopening a
// remote lookup whenever the timeline emits.
final _blueDyeBmEntriesProvider = StreamProvider<List<Entry>>((ref) async* {
  final repository = await ref.watch(entryRepoProvider.future);
  if (repository == null) {
    yield const [];
    return;
  }
  yield* repository.entriesBySubtype('category.BM');
});

/// Bowel movements explicitly linked to the active test session, across dates.
final blueDyeBmTestLogsProvider = FutureProvider<List<BMTestLog>>((ref) async {
  final protocol = await ref.watch(activeProtocolProvider.future);
  if (protocol == null) return const [];
  return ref.watch(
    blueDyeRunLogsProvider(blueDyeActiveRunSessionId(protocol)).future,
  );
});

/// Saved entries for one transit run, independent of History's visible range.
final blueDyeRunLogsProvider = FutureProvider.family<List<BMTestLog>, String>((
  ref,
  sessionId,
) async {
  final homeFuture = ref.watch(questionHomeProvider.future);
  final entriesFuture = ref.watch(_blueDyeBmEntriesProvider.future);
  final home = await homeFuture;
  final entries = await entriesFuture;
  return blueDyeBmTestLogs(
    entries
        .where((entry) => entry.sessionId == sessionId)
        .map((entry) => entry.toDetailResponse(home)),
    sessionId,
  );
});

final blueDyeMealStateProvider = FutureProvider<BlueDyeMealState>((ref) async {
  final mealState = await ref.watch(_protocolBlueDyeMealStateProvider.future);
  final logs = await ref.watch(blueDyeBmTestLogsProvider.future);
  return mealState.copyWith(
    logs: logs
        .map(
          (log) => BlueDyeBmLog(
            stamp: log.stamp,
            isBlue: log.isBlue,
            description: log.response.description,
          ),
        )
        .toList(growable: false),
  );
});

List<BMTestLog> blueDyeBmTestLogs(Iterable<Stamp> stamps, String sessionId) {
  if (sessionId.isEmpty) return const [];
  final logs = <BMTestLog>[];

  for (final stamp in stamps) {
    if (stamp is! DetailResponse ||
        stamp.type != 'category.BM' ||
        stamp.linkingId != sessionId) {
      continue;
    }

    final dyeResponse = stamp.responses
        .whereType<MultiResponse>()
        .where((response) => response.question.id == 'BlueDyeQuestion')
        .firstOrNull;
    if (dyeResponse == null) continue;

    logs.add(
      BMTestLog(
        response: stamp,
        isBlue: dyeResponse.index == 0,
        id: stamp.id,
        group: stamp.group,
      ),
    );
  }

  logs.sort((first, second) => first.stamp.compareTo(second.stamp));
  return logs;
}

final hasTestsProvider = FutureProvider<bool>((ref) async {
  final repo = await ref.watch(testProvider.future);
  return repo != null && repo.definitions.isNotEmpty;
});
