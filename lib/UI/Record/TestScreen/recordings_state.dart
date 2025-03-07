import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class RecordingsView extends ConsumerWidget {
  final Function next;

  final BlueDyeProgression clicked;

  const RecordingsView({required this.next, required this.clicked, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.small);
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    if (progress.isLoading) return const LoadingWidget();
    final Color panelColor =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final List<BMTestLog> logs = clicked == BlueDyeProgression.stepFour &&
            (progress.valueOrNull?.orderedTests.length ?? 0) >= 2
        ? progress.valueOrNull?.orderedTests[1].test.logs ?? []
        : progress.valueOrNull?.orderedTests[0].test.logs ?? [];
    final Widget transitLabel = Text(
      clicked.value < 2
          ? AppLocalizations.of(context)!.transitOneLabel
          : AppLocalizations.of(context)!.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? 20.0 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: cardLayout ? Breakpoint.small.value : double.infinity),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 6,
              ),
              cardLayout
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [transitLabel, const BlueMealInfoButton()],
                    )
                  : const Center(child: BlueMealInfoButton()),
              const SizedBox(
                height: 6.0,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: cardLayout
                      ? BorderRadius.circular(12.0)
                      : const BorderRadius.all(Radius.circular(0)),
                  color: panelColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.recordingStateTitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      BMDisplay(logs: logs),
                      const SizedBox(
                        height: 8.0,
                      ),
                      Center(
                          child: Text(
                        clicked == BlueDyeProgression.stepTwo
                            ? AppLocalizations.of(context)!.stepTwoCompletedText
                            : AppLocalizations.of(context)!
                                .stepFourCompletedText,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      )),
                      if (clicked == BlueDyeProgression.stepFour)
                        Center(
                            child: Text(
                          AppLocalizations.of(context)!
                              .studyStepFourExplanationCompletedNotice,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )),
                      const SizedBox(
                        height: 12.0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 12.0,
              ),
              if (clicked != BlueDyeProgression.stepFour) ...[
                Center(
                  child: FilledButton(
                    onPressed: () {
                      next();
                    },
                    child: Text(AppLocalizations.of(context)!.nextButton),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
              ],
            ]),
      ),
    );
  }
}

class RecordingsWaiting extends ConsumerStatefulWidget {
  const RecordingsWaiting({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _RecordingsWaitingState();
  }
}

class _RecordingsWaitingState extends ConsumerState<RecordingsWaiting> {
  bool isLoading = false;

  Timer? timer;

  final Duration waitTime = const Duration(seconds: 30);

  @override
  void didChangeDependencies() {
    _onDependencyChange();
    super.didChangeDependencies();
  }

  void _onDependencyChange() async {
    final DateTime testFinished =
        (await ref.read(blueDyeTestProgressProvider.future))
            .orderedTests[0]
            .finishTime;
    final Duration timePassed = DateTime.now().difference(testFinished);
    final bool canProgress = waitTime.compareTo(timePassed) < 0;
    if (!canProgress) {
      timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    final List<TestDate> orderedTests =
        progress.valueOrNull?.orderedTests ?? [];
    if (orderedTests.isEmpty) return Container();
    final DateTime progressDate = orderedTests[0].finishTime.add(waitTime);
    final Duration timePassed =
        DateTime.now().difference(orderedTests[0].finishTime);

    final bool canProgress = waitTime.compareTo(timePassed) < 0;
    final Duration timeLeft = canProgress
        ? Duration.zero
        : Duration(
            milliseconds: waitTime.inMilliseconds - timePassed.inMilliseconds);
    if (canProgress) timer?.cancel();
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BlueStudyInstructionsPartTwo(initiallyExpanded: false),
          const SizedBox(
            height: 12.0,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: ElevationOverlay.applySurfaceTint(
                  Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surfaceTint,
                  3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.recordingStateTitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  BMDisplay(logs: orderedTests[0].test.logs),
                  const SizedBox(
                    height: 8.0,
                  ),
                  Center(
                      child: Text(
                    AppLocalizations.of(context)!.stepTwoCompletedText,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )),
                  if (!canProgress) ...[
                    Center(
                        child: Text(
                      "${AppLocalizations.of(context)!.stepTwoCompletedSubText}${from(timeLeft, context)}",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                      textAlign: TextAlign.center,
                    )),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Center(
                      child: TextButton(
                          onPressed: () {
                            Add2Calendar.addEvent2Cal(
                              Event(
                                title: "Blue Meal Test",
                                description:
                                    "The second Blue Meal Test is available today.",
                                startDate: progressDate,
                                endDate: progressDate,
                                allDay: true,
                              ),
                            );
                          },
                          child: const Text("Add to Calendar")),
                    )
                  ],
                  const SizedBox(
                    height: 12.0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12.0,
          ),
          if (canProgress) ...[
            Center(
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _next();
                      },
                child: Text(AppLocalizations.of(context)!.nextButton),
              ),
            ),
            const SizedBox(
              height: 25.0,
            )
          ]
        ]);
  }

  _next() async {
    setState(() {
      isLoading = true;
    });
    final DateTime start = DateTime.now();
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) {
      test?.setTestState(BlueDyeState(
          startTime: start, timerStart: start, pauseTime: start, logs: []));
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class RecordingsState extends ConsumerStatefulWidget {
  const RecordingsState({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _RecordingsState();
  }
}

class _RecordingsState extends ConsumerState<RecordingsState> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.small);
    final Color panelColor =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final BlueDyeState? blueDyeState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);

    if (progress.isLoading) return const LoadingWidget();

    final BlueDyeProgression stage =
        progress.valueOrNull?.getProgression() ?? BlueDyeProgression.stepOne;

    if (blueDyeState == null) {
      return const LoadingWidget();
    }

    final Widget transitLabel = Text(
      stage.value < 2
          ? AppLocalizations.of(context)!.transitOneLabel
          : AppLocalizations.of(context)!.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? 20.0 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: cardLayout ? Breakpoint.small.value : double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 6,
            ),
            cardLayout
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [transitLabel, const BlueMealInfoButton()],
                  )
                : const Center(child: BlueMealInfoButton()),
            const SizedBox(
              height: 6,
            ),
            stage == BlueDyeProgression.stepTwo
                ? BlueStudyInstructionsPartTwo(
                    initiallyExpanded: blueDyeState.logs.isEmpty)
                : const BlueStudyInstructionsPartFour(),
            const SizedBox(
              height: 12.0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: cardLayout
                    ? BorderRadius.circular(12.0)
                    : BorderRadius.circular(0),
                color: panelColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.recordingStateTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    BMDisplay(logs: blueDyeState.logs),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Center(
                      child: FilledButton(
                        onPressed: () {
                          context.pushNamed(
                            'recordType',
                            pathParameters: {'type': Symptoms.BM},
                          );
                        },
                        child: Text(
                            AppLocalizations.of(context)!.studyRecordBMButton),
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 35.0,
            ),
          ],
        ),
      ),
    );
  }
}

class BMDisplay extends StatelessWidget {
  final List<BMTestLog> logs;
  const BMDisplay({required this.logs, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: logs.map((log) {
        return EntryDisplay(
          elevated: false,
          event: log.response,
          hasControls: false,
          hasConstraints: false,
        );
        /*Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 35.0,
                  height: 35.0,
                  child: log.isBlue
                      ? Image.asset(
                          'packages/stripes_ui/assets/images/Blue_Poop.png')
                      : Image.asset(
                          'packages/stripes_ui/assets/images/Brown_Poop.png')),
              const SizedBox(
                width: 6.0,
              ),
              Text(
                '${DateFormat.yMMMd().format(logTime)} - ${DateFormat.jm().format(logTime)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ]);*/
      }).toList(),
    );
  }
}
