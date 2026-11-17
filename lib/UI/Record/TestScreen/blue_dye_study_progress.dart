import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_study_records_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_step_records.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

/// A read-only overview: consulting the protocol never changes the active form.
class BlueDyeStudyProgress extends ConsumerWidget {
  final BlueDyeProgression progression;

  const BlueDyeStudyProgress({required this.progression, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.translate;
    final steps = _studySteps(context);
    final complete = progression == BlueDyeProgression.completed;
    final title = Semantics(
      header: true,
      liveRegion: true,
      child: Text(
        complete
            ? strings.blueMealStudyCompleteTitle
            : steps[progression.value].title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: BlueDyeStudyStyle.ink(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final viewSteps = TextButton(
      onPressed: () => showBlueDyeStudySteps(context, ref, progression),
      style: TextButton.styleFrom(
        foregroundColor: BlueDyeStudyStyle.ink(context),
        textStyle: Theme.of(context).textTheme.labelSmall
            ?.copyWith(decoration: TextDecoration.underline),
      ),
      child: Text(strings.viewStudySteps),
    );

    return Material(
      color: BlueDyeStudyStyle.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: BlueDyeStudyStyle.outline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.textScalerOf(context).scale(14) > 20)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, viewSteps],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: title),
                  const SizedBox(width: AppPadding.small),
                  Flexible(child: viewSteps),
                ],
              ),
            const SizedBox(height: AppPadding.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _transit(context, strings.transitOneLabel, [0, 1]),
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Column(
                    children: [
                      Text(' ', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: AppPadding.small),
                      _segment(context, 2),
                    ],
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  flex: 2,
                  child: _transit(context, strings.transitTwoLabel, [3, 4]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _transit(BuildContext context, String label, List<int> indices) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: BlueDyeStudyStyle.ink(context)),
        ),
        const SizedBox(height: AppPadding.small),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _segment(context, indices.first)),
            const SizedBox(width: AppPadding.tiny),
            Expanded(child: _segment(context, indices.last)),
          ],
        ),
      ],
    );
  }

  Widget _segment(BuildContext context, int index) {
    final strings = context.translate;
    final colors = Theme.of(context).colorScheme;
    final done = index < progression.value;
    final current = index == progression.value;
    final label = index == 2
        ? strings.blueMealWaitTimeLabel
        : strings.blueMealStepLabel(index < 2 ? index + 1 : index);
    final status = done
        ? strings.blueMealStepCompleted
        : current
        ? strings.blueMealStepCurrent
        : strings.blueMealStepUpcoming;

    return Semantics(
      label: '$label, $status',
      selected: current,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Container(
              key: ValueKey('blue-meal-progress-$index'),
              height: 4,
              decoration: BoxDecoration(
                color: current
                    ? BlueDyeStudyStyle.orange
                    : done
                    ? BlueDyeStudyStyle.ink(context)
                    : colors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: current ? FontWeight.bold : FontWeight.normal,
                color: current
                    ? BlueDyeStudyStyle.currentLabel(context)
                    : done
                    ? BlueDyeStudyStyle.ink(context)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uses the app's shared presentation and sheet-open lifecycle.
Future<void> showBlueDyeStudySteps(
  BuildContext context,
  WidgetRef ref,
  BlueDyeProgression progression,
) => ref
    .read(sheetControllerProvider)
    .show<void>(
      context: context,
      scrollControlled: true,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      sheetBuilder: (context, controller) => BlueDyeStudyStepsSheet(
        progression: progression,
        scrollController: controller,
      ),
    );

class BlueDyeStudyStepsSheet extends ConsumerWidget {
  final BlueDyeProgression progression;
  final ScrollController scrollController;

  const BlueDyeStudyStepsSheet({
    required this.progression,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.translate;
    final steps = _studySteps(context);
    final savedRecords = ref.watch(blueDyeStudyRecordsProvider);
    final records =
        savedRecords.asData?.value ?? const <int, BlueDyeStudyRunRecords>{};

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      strings.blueMealStudySteps,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BlueDyeStudyStyle.ink(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(AppPadding.large),
              itemCount: steps.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppPadding.small),
              itemBuilder: (context, itemIndex) {
                if (itemIndex == 0) {
                  return Column(
                    children: [
                      if (savedRecords.isLoading)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(strings.blueMealRecordsLoading),
                        ),
                      if (savedRecords.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(strings.blueMealRecordsError),
                              TextButton(
                                onPressed: () {
                                  final protocolState = ref.read(
                                    activeProtocolProvider,
                                  );
                                  if (protocolState.hasError) {
                                    ref.invalidate(activeProtocolProvider);
                                  }
                                  final protocol = protocolState.asData?.value;
                                  if (protocol != null) {
                                    final sessions = {
                                      blueDyeActiveRunSessionId(protocol),
                                      ...blueDyeCompletedRuns(protocol)
                                          .map((run) => run.sessionId),
                                    };
                                    for (final session in sessions) {
                                      final provider = blueDyeRunLogsProvider(
                                        session,
                                      );
                                      if (ref.read(provider).hasError) {
                                        ref.invalidate(provider);
                                      }
                                    }
                                  }
                                  ref.invalidate(blueDyeStudyRecordsProvider);
                                },
                                child: Text(strings.recordRetry),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }
                final index = itemIndex - 1;
                final step = steps[index];
                final stepRecords = recordsForStudyStep(records, index);
                final recordLabel = studyStepRecordLabel(
                  context,
                  stepRecords,
                  index,
                );
                return Material(
                  color: BlueDyeStudyStyle.surface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: BlueDyeStudyStyle.outline(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: PageStorageKey('blue-meal-study-step-$index'),
                    maintainState: true,
                    subtitle: recordLabel == null ? null : Text(recordLabel),
                    minTileHeight: 48,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Semantics(
                      label: index < progression.value
                          ? strings.blueMealStepCompleted
                          : index == progression.value
                          ? strings.blueMealStepCurrent
                          : strings.blueMealStepUpcoming,
                      child: Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: BlueDyeStudyStyle.ink(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppPadding.medium,
                      0,
                      AppPadding.medium,
                      AppPadding.medium,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (recordLabel != null && stepRecords != null)
                        BlueDyeStepRecords(
                          records: stepRecords,
                          stepIndex: index,
                        ),
                      for (final paragraph in step.paragraphs)
                        Padding(
                          padding: const EdgeInsets.only(top: AppPadding.small),
                          child: Text(paragraph),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StudyStep = ({String title, List<String> paragraphs});

List<_StudyStep> _studySteps(BuildContext context) {
  final strings = context.translate;
  final mealInstructions = [
    strings.studyStepOneExplanationPreReq,
    strings.blueMealFastInstructionLineOne,
    strings.blueMealFastInstructionLineTwo,
    strings.blueMealFastInstructionLineThree,
  ];
  return [
    (title: strings.studyStepOneExplanationTitle, paragraphs: mealInstructions),
    (
      title: strings.studyStepTwoExplanationTitle,
      paragraphs: [
        strings.studyFlowStepTwoPartOne,
        strings.studyFlowStepTwoPartTwo,
        strings.studyFlowStepTwoPartThree,
      ],
    ),
    (
      title: strings.blueMealWaitTimeLabel,
      paragraphs: [strings.studyFlowBetweenStepTwoStepThreeDesc],
    ),
    (
      title: strings.studyStepThreeExplanationTitle,
      paragraphs: mealInstructions,
    ),
    (
      title: strings.studyStepFourExplanationTitle,
      paragraphs: [strings.studyFlowStepFourDesc],
    ),
  ];
}
