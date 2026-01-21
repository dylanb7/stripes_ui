import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/history/stamps_provider.dart';
import 'package:stripes_ui/Providers/questions/questions_provider.dart';

/// Provides the list of incomplete baselines, dynamically generated
/// from the question repo's baseline layout paths.
final incompleteBaselinesProvider =
    FutureProvider<List<BaselineTrigger>>((ref) async {
  // Get baseline record paths from the question provider
  final List<RecordPath> baselinePaths =
      await ref.watch(baselineLayoutProvider.future);

  // Get existing baseline stamps
  final List<Stamp> existingBaselines =
      await ref.watch(baselinesStreamProvider.future);

  final List<BaselineTrigger> triggers = [];

  for (final path in baselinePaths) {
    // Check if a baseline stamp exists for this path
    final bool hasBaseline =
        existingBaselines.any((stamp) => stamp.type == path.name);

    // Only add trigger if baseline is incomplete
    if (!hasBaseline) {
      triggers.add(BaselineTrigger(
        baselineType: path.name,
        recordPath: path.name,
        title: path.name,
        description: 'Please complete this baseline questionnaire.',
      ));
    }
  }

  return triggers;
});

class BaselineDismissNotifier extends StateNotifier<Set<String>> {
  BaselineDismissNotifier() : super({});

  void dismiss(String baselineType) {
    state = {...state, baselineType};
  }

  void reset() {
    state = {};
  }

  bool isDismissed(String baselineType) => state.contains(baselineType);
}

final baselineDismissProvider =
    StateNotifierProvider<BaselineDismissNotifier, Set<String>>(
  (ref) => BaselineDismissNotifier(),
);

/// Provides baselines that are incomplete AND not dismissed.
final activeBaselineTriggersProvider =
    FutureProvider<List<BaselineTrigger>>((ref) async {
  final List<BaselineTrigger> incomplete =
      await ref.watch(incompleteBaselinesProvider.future);
  final Set<String> dismissed = ref.watch(baselineDismissProvider);

  return incomplete
      .where((trigger) => !dismissed.contains(trigger.baselineType))
      .toList();
});
