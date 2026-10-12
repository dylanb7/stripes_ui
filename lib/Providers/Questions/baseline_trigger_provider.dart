import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

final incompleteBaselinesProvider = FutureProvider<List<BaselineTrigger>>((
  ref,
) async {
  final List<RecordPath> baselinePaths = await ref.watch(
    baselineLayoutProvider.future,
  );
  // Repositories without baseline layouts may not expose a baseline stream.
  if (baselinePaths.isEmpty) return const <BaselineTrigger>[];

  final List<Stamp> existingBaselines = await ref.watch(
    baselinesStreamProvider.future,
  );

  final List<BaselineTrigger> triggers = [];

  for (final path in baselinePaths) {
    final bool hasBaseline = existingBaselines.any(
      (stamp) => stamp.type == path.name,
    );

    if (!hasBaseline) {
      triggers.add(
        BaselineTrigger(
          baselineType: path.name,
          recordPath: path.name,
          title: path.name,
          description: 'Please complete this baseline questionnaire.',
        ),
      );
    }
  }

  return triggers;
});

class BaselineDismissNotifier extends Notifier<Set<String>> {
  BaselineDismissNotifier();

  void dismiss(String baselineType) {
    state = {...state, baselineType};
  }

  void reset() {
    state = {};
  }

  bool isDismissed(String baselineType) => state.contains(baselineType);

  @override
  Set<String> build() {
    state = {};
    return state;
  }
}

final baselineDismissProvider =
    NotifierProvider<BaselineDismissNotifier, Set<String>>(
      BaselineDismissNotifier.new,
    );

final activeBaselineTriggersProvider = FutureProvider<List<BaselineTrigger>>((
  ref,
) async {
  final List<BaselineTrigger> incomplete = await ref.watch(
    incompleteBaselinesProvider.future,
  );
  final Set<String> dismissed = ref.watch(baselineDismissProvider);

  return incomplete
      .where((trigger) => !dismissed.contains(trigger.baselineType))
      .toList();
});
