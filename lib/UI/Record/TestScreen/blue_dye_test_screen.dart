import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/horizontal_stepper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/repos/blue_dye_test_repo.dart';

class BlueDyeTestScreen extends ConsumerWidget {
  const BlueDyeTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const TestSwitcher(),
            progress.stage != BlueDyeTestStage.initial
                ? IconButton(
                    onPressed: () {
                      toggleBottomSheet(context);
                    },
                    icon: const Icon(Icons.info))
                : SizedBox(
                    width: Theme.of(context).iconTheme.size,
                  ),
          ],
        ),
        const SizedBox(
          height: 12.0,
        ),
        Expanded(
          child: progress.stage != BlueDyeTestStage.initial
              ? const StudyOngoing()
              : BlueMealPreStudy(
                  onClick: () {
                    _startTest(ref);
                  },
                  isLoading: false,
                ),
        ),
      ],
    );
  }

  Future<void> _startTest(WidgetRef ref) async {
    final DateTime start = DateTime.now();
    await ref.read(testsHolderProvider.notifier).getTest<BlueDyeTest>().then(
        (test) => test?.setTestState(BlueDyeState(
            startTime: start, timerStart: start, pauseTime: start, logs: [])));
  }

  toggleBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 1.0,
              builder: (context, controller) {
                return SafeArea(
                  child: BlueMealInfoSheet(
                    scrollController: controller,
                  ),
                );
              });
        });
  }
}

class StudyOngoing extends ConsumerStatefulWidget {
  const StudyOngoing({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _StudyOngoingState();
  }
}

class _StudyOngoingState extends ConsumerState<StudyOngoing> {
  late int currentIndex;

  @override
  void initState() {
    currentIndex =
        ref.read(blueDyeTestProgressProvider).getProgression()?.value ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BlueDyeProgression?>(
        blueDyeTestProgressProvider
            .select((progress) => progress.getProgression()), (prev, next) {
      if (mounted &&
          next != null &&
          (prev == null || next.value > prev.value)) {
        setState(() {
          currentIndex = next.index;
        });
      }
    });
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    final BlueDyeProgression? currentProgression = progress.getProgression();
    final int index = currentProgression?.value ?? 0;
    final double detailedProgress =
        progress.stage == BlueDyeTestStage.amountConsumed
            ? index.toDouble() + 0.8
            : progress.stage == BlueDyeTestStage.initial &&
                    progress.testIteration > 0
                ? index.toDouble() + 0.99
                : index.toDouble();
    final BlueDyeProgression activeStage =
        BlueDyeProgression.values[currentIndex];
    final bool isPrevious = currentIndex < index;

    Widget getDisplayedWidget() {
      final bool isStepThree = activeStage == BlueDyeProgression.stepThree;
      if (activeStage == BlueDyeProgression.stepOne || isStepThree) {
        if (isPrevious) {
          return MealFinishedDisplay(
              next: () {
                setState(() {
                  currentIndex++;
                });
              },
              isStepThree: isStepThree);
        }
        return progress.stage == BlueDyeTestStage.amountConsumed
            ? const AmountConsumedEntry()
            : const TimerWidget();
      }
      if (isPrevious) return Container();
      return const RecordingsState();
    }

    return Column(children: [
      HorizontalStepper(
          steps: BlueDyeProgression.values
              .map(
                (step) => HorizontalStep(
                  title: Text(
                    step.getLabel(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: step.value > index
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5)
                              : null,
                          decoration:
                              currentIndex != step.value && step.value <= index
                                  ? TextDecoration.underline
                                  : null,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  dotContents: Text(
                    "${step.value + 1}",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
          circleWidth: 70.0,
          onStepPressed: (index, isActive) {
            if (!isActive) {
              showSnack(
                  context,
                  AppLocalizations.of(context)!
                      .stepClickWarning("${index + 1}"));
              return;
            }
            if (currentIndex == index) return;
            setState(() {
              currentIndex = index;
            });
          },
          progress: detailedProgress,
          active: Theme.of(context).colorScheme.primary,
          inactive: Theme.of(context).dividerColor.darken()),
      const SizedBox(
        height: 12.0,
      ),
      Expanded(
        child: SingleChildScrollView(
          child: getDisplayedWidget(),
        ),
      ),
    ]);
  }
}
