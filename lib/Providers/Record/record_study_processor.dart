import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// Processes one saved recording batch without advancing a protocol twice when
/// a later protocol update fails. Keep this instance for the lifetime of a draft.
class RecordStudyProcessor {
  final Map<(String, String), TestEvaluationResult> _evaluations = {};
  final Set<(String, String)> _completed = {};

  Future<void> process({
    required ModularTestsRepo tests,
    required List<Entry> entries,
    required List<Entry> history,
  }) async {
    final exactEntries = entries.where(_isExact).toList(growable: false);
    if (exactEntries.any((entry) => entry.id == null || entry.id!.isEmpty)) {
      throw ArgumentError('Study processing requires persisted entry IDs.');
    }

    for (final entry in exactEntries) {
      final protocols = tests.currentProtocols
          .where((protocol) => !protocol.isCompleted)
          .toList(growable: false);
      final relatedHistory = history
          .where(
            (other) =>
                other.id != entry.id &&
                other.sessionId == entry.sessionId &&
                _isExact(other),
          )
          .toList(growable: false);

      for (final protocol in protocols) {
        final key = (entry.id!, protocol.id);
        if (_completed.contains(key)) continue;

        final evaluation =
            _evaluations[key] ??
            await tests.engine.processEntry(
              activeTest: protocol,
              currentResponse: entry,
              historicalResponses: relatedHistory,
            );
        // Cache before the write. A failed acknowledgement may already have
        // committed; retry the same target state instead of evaluating the next
        // stage with the same entry.
        _evaluations[key] = evaluation;
        if (evaluation.stageChanged) {
          await tests.updateProtocol(evaluation.updatedTest);
        }
        _completed.add(key);
      }
    }
  }

  static bool _isExact(Entry entry) =>
      entry.timeOfDay == null || entry.timeOfDay == TimeOfDayEntry.exact;
}
