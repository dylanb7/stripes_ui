import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// A page title with the short, labelled step segments used in onboarding.
class OnboardingHeader extends StatelessWidget {
  final String title;
  final int totalSteps;
  final int currentStep;
  final String Function(int) labelForStep;
  final VoidCallback? onBack;
  final String? backTooltip;

  const OnboardingHeader({
    required this.title,
    required this.totalSteps,
    required this.currentStep,
    required this.labelForStep,
    this.onBack,
    this.backTooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    tooltip: backTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Theme.of(context).colorScheme.primary,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      if (totalSteps > 1) ...[
                        const SizedBox(height: AppPadding.small),
                        OnboardingProgressBar(
                          totalSteps: totalSteps,
                          currentStep: currentStep,
                          labelForStep: labelForStep,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final String Function(int) labelForStep;

  const OnboardingProgressBar({
    required this.totalSteps,
    required this.currentStep,
    required this.labelForStep,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSteps <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final current = currentStep.clamp(0, totalSteps - 1);
    final style = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.primary,
    );
    final painter = TextPainter(
      text: TextSpan(text: 'Step $totalSteps', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final labelWidth = painter.width;
    painter.dispose();

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Step ${current + 1} of $totalSteps',
      value: labelForStep(current),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showEachLabel =
                (constraints.maxWidth - (totalSteps - 1) * 6) / totalSteps >=
                labelWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    for (var index = 0; index < totalSteps; index++) ...[
                      if (index > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              key: ValueKey('onboarding-step-$index'),
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: index == current
                                    ? colors.secondary
                                    : index < current
                                    ? colors.primary
                                    : colors.primaryContainer,
                              ),
                            ),
                            if (showEachLabel) ...[
                              const SizedBox(height: 5),
                              Text('Step ${index + 1}', style: style),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (!showEachLabel) ...[
                  const SizedBox(height: 5),
                  Text('Step ${current + 1} of $totalSteps', style: style),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
