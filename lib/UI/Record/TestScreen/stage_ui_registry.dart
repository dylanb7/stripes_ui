import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

typedef StageWidgetBuilder = Widget Function(
  BuildContext context,
  ActiveTestProtocol protocol,
  TestStage stage,
  ModularTestsRepo repo,
);

class StageUiRegistry {
  final Map<String, StageWidgetBuilder> _builders = {};

  void registerStage(String stageId, StageWidgetBuilder builder) {
    _builders[stageId] = builder;
  }

  StageWidgetBuilder? getBuilder(String stageId) => _builders[stageId];

  Widget buildStage({
    required BuildContext context,
    required ActiveTestProtocol protocol,
    required TestStage stage,
    required ModularTestsRepo repo,
  }) {
    final builder = _builders[stage.id];
    if (builder != null) {
      return builder(context, protocol, stage, repo);
    }
    return LocalizedDefaultStageCard(
      protocol: protocol,
      stage: stage,
      repo: repo,
    );
  }
}

/// Default registry populated with BlueDye stage builders.
final stageUiRegistryProvider = Provider<StageUiRegistry>((ref) {
  final registry = StageUiRegistry();

  // ---- Blue Dye Transit Test stage builders ----

  // eat_meal: Pre-study info → meal details form → advance
  registry.registerStage('eat_meal', (context, protocol, stage, repo) {
    return _EatMealStage(protocol: protocol, repo: repo);
  });

  // awaiting_transit: BM recording with blue question injection
  registry.registerStage('awaiting_transit', (context, protocol, stage, repo) {
    return _AwaitingTransitStage(protocol: protocol, repo: repo);
  });

  registry.registerStage('waiting', (context, protocol, stage, repo) {
    return const StudyOngoing();
  });

  registry.registerStage('eat_meal_2', (context, protocol, stage, repo) {
    return _EatMealStage(protocol: protocol, repo: repo);
  });

  registry.registerStage('awaiting_transit_2', (
    context,
    protocol,
    stage,
    repo,
  ) {
    return _AwaitingTransitStage(protocol: protocol, repo: repo);
  });

  // completed: Terminal / completion display
  registry.registerStage('completed', (context, protocol, stage, repo) {
    return _CompletedStage(protocol: protocol, repo: repo);
  });

  return registry;
});

// ============================================================================
// eat_meal stage widget
// ============================================================================

class _EatMealStage extends ConsumerStatefulWidget {
  final ActiveTestProtocol protocol;
  final ModularTestsRepo repo;

  const _EatMealStage({required this.protocol, required this.repo});

  @override
  ConsumerState<_EatMealStage> createState() => _EatMealStageState();
}

class _EatMealStageState extends ConsumerState<_EatMealStage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(blueDyeMealStateProvider)
        .when(
          data: (mealState) {
            switch (mealState.stage) {
              case BlueDyeTestStage.initial:
                return BlueMealPreStudy(
                  onClick: _startTest,
                  isLoading: isLoading,
                );
              case BlueDyeTestStage.started:
              case BlueDyeTestStage.amountConsumed:
              case BlueDyeTestStage.logs:
              case BlueDyeTestStage.logsSubmit:
                return const StudyOngoing();
            }
          },
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Future<void> _startTest() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final newMealState = BlueDyeMealState(startTime: now);
      final updated = widget.protocol.copyWith(
        testContext: newMealState.replaceInContext(widget.protocol.testContext),
      );
      await widget.repo.updateProtocol(updated);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

// ============================================================================
// awaiting_transit stage widget
// ============================================================================

class _AwaitingTransitStage extends ConsumerWidget {
  final ActiveTestProtocol protocol;
  final ModularTestsRepo repo;

  const _AwaitingTransitStage({required this.protocol, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const StudyOngoing();
  }
}

// ============================================================================
// completed stage widget
// ============================================================================

class _CompletedStage extends ConsumerWidget {
  final ActiveTestProtocol protocol;
  final ModularTestsRepo repo;

  const _CompletedStage({required this.protocol, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const StudyOngoing();
  }
}

// ============================================================================
// Fallback default stage card (for unregistered stages)
// ============================================================================

class LocalizedDefaultStageCard extends ConsumerStatefulWidget {
  final ActiveTestProtocol protocol;
  final TestStage stage;
  final ModularTestsRepo repo;

  const LocalizedDefaultStageCard({
    required this.protocol,
    required this.stage,
    required this.repo,
    super.key,
  });

  @override
  ConsumerState<LocalizedDefaultStageCard> createState() =>
      _LocalizedDefaultStageCardState();
}

class _LocalizedDefaultStageCardState
    extends ConsumerState<LocalizedDefaultStageCard> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).primaryColor
        .withValues(alpha: 0.15);
    final Color primaryColor = Theme.of(context).primaryColor;

    return AdaptiveCardLayout(
      cardColor: cardColor,
      borderColor: primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.stage.id.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (widget.stage.isTerminal)
                  Chip(
                    label: const Text('Completed'),
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              "Protocol: ${widget.protocol.testId}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppPadding.medium),
            if (!widget.stage.isTerminal) ...[
              Center(
                child: FilledButton(
                  onPressed: isLoading ? null : _advanceStage,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.translate.nextButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage() async {
    setState(() {
      isLoading = true;
    });
    try {
      await widget.repo.advanceStage(activeTestId: widget.protocol.id);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
