import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/animated_segmented_progress.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordFlowCreationProgress extends StatelessWidget {
  static const segmentIds = ['details', 'build', 'review'];

  final int currentStep;
  final Set<int> errorSteps;
  final PageController pageController;

  const RecordFlowCreationProgress({
    required this.currentStep,
    required this.errorSteps,
    required this.pageController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = errorSteps.contains(currentStep);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.large,
        AppPadding.medium,
        AppPadding.large,
        AppPadding.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: context.translate.creationStepLabel(
              currentStep + 1,
              segmentIds.length,
              [
                context.translate.questionSetDetailsStep,
                context.translate.buildFlowStep,
                context.translate.reviewStep,
              ][currentStep],
            ),
            child: AnimatedSegmentedProgress(
              segmentIds: segmentIds,
              currentIndex: currentStep,
              currentHasError: hasError,
              pageController: pageController,
              inactiveColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class RecordFlowCreationFooter extends StatelessWidget {
  final int currentStep;
  final bool saving;
  final VoidCallback onPressed;

  const RecordFlowCreationFooter({
    required this.currentStep,
    required this.saving,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep =
        currentStep == RecordFlowCreationProgress.segmentIds.length - 1;
    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onPressed,
          icon: saving
              ? const ButtonLoadingIndicator()
              : Icon(isLastStep ? Icons.check : Icons.arrow_forward),
          label: Text(
            isLastStep
                ? context.translate.createQuestionSet
                : context.translate.continueButton,
          ),
        ),
      ),
    );
  }
}
