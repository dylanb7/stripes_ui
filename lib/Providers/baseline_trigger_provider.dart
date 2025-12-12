import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';

/// Manually configure available baseline triggers.
/// The system will only show triggers that haven't been completed.
final allBaselineTriggersProvider = Provider<List<BaselineTrigger>>((ref) {
  // Configure baseline triggers here.
  // These map fromBaseline values to their corresponding record paths.
  return const [
    BaselineTrigger(
      baselineType: 'category.SEIZURE_BASELINE',
      recordPath: 'category.SEIZURE_BASELINE',
      title: 'Seizure Baseline',
      description: 'Please complete the seizure baseline questionnaire.',
    ),
    // Add more baseline triggers as needed:
    // BaselineTrigger(
    //   baselineType: 'your-baseline-type',
    //   recordPath: 'category.YOUR_BASELINE',
    //   title: 'Your Baseline',
    //   description: 'Description here.',
    // ),
  ];
});

/// Provides the list of incomplete baselines.
final incompleteBaselinesProvider =
    FutureProvider<List<BaselineTrigger>>((ref) async {
  final List<BaselineTrigger> allTriggers =
      ref.watch(allBaselineTriggersProvider);
  final List<Stamp> baselines = await ref.watch(baselinesStreamProvider.future);

  return allTriggers
      .where((trigger) => !trigger.isComplete(baselines))
      .toList();
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
