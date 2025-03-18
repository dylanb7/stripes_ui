import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
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
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
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
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
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
                height: 6.0,
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
                      if (!cardLayout) ...[
                        transitLabel,
                        const Divider(),
                      ],
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
                      if (clicked == BlueDyeProgression.stepFive)
                        Text(
                          AppLocalizations.of(context)!
                              .studyStepFourExplanationCompletedNotice,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
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
              if (clicked != BlueDyeProgression.stepFive) ...[
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

class WaitingTime extends ConsumerStatefulWidget {
  final Function next;

  const WaitingTime({required this.next, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WaitingTimeState();
  }
}

class _WaitingTimeState extends ConsumerState<WaitingTime> {
  bool isLoading = false;

  Timer? timer;

  final Duration waitTime = const Duration(days: 1);

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.large);
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    final List<TestDate> orderedTests =
        progress.valueOrNull?.orderedTests ?? [];
    if (orderedTests.isEmpty) return Container();
    final DateTime progressDate = orderedTests[0].finishTime.add(waitTime);
    final Duration timePassed =
        DateTime.now().difference(orderedTests[0].finishTime);

    final Widget waitingLabel = Text(
      "Waiting Time",
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );

    final bool canProgress = waitTime.compareTo(timePassed) < 0;
    final Duration timeLeft = canProgress
        ? Duration.zero
        : Duration(
            milliseconds: waitTime.inMilliseconds - timePassed.inMilliseconds);
    final Color cardColor =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);
    if (canProgress) timer?.cancel();
    return Column(
      children: [
        const SizedBox(
          height: 6.0,
        ),
        cardLayout
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [waitingLabel, const BlueMealInfoButton()],
                ),
              )
            : const Center(child: BlueMealInfoButton()),
        const SizedBox(
          height: 6.0,
        ),
        AdaptiveCardLayout(
          cardColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!cardLayout) ...[
                  waitingLabel,
                  const Divider(),
                ],
                Text(
                  AppLocalizations.of(context)!.blueMealWaitTimeTitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 4.0,
                ),
                Text(
                  AppLocalizations.of(context)!.blueMealWaitTimeLineOne,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: 4.0,
                ),
                Text(
                  AppLocalizations.of(context)!.blueMealWaitTimeLineTwo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: 4.0,
                ),
                if (!canProgress && !kIsWeb) ...[
                  Text(
                    AppLocalizations.of(context)!.blueMealWaitTimeLineThree,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await Add2Calendar.addEvent2Cal(
                          Event(
                            title: "Blue Meal Study",
                            description:
                                "You are eligible to start the second Blue Meal today.",
                            startDate: progressDate,
                            endDate: progressDate,
                            allDay: true,
                          ),
                        );
                      },
                      label: const Text("Add to calendar"),
                      icon: const Icon(Icons.edit_calendar),
                      iconAlignment: IconAlignment.end,
                    ),
                  )
                ],
                const SizedBox(
                  height: 8.0,
                ),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.stepTwoCompletedSubText,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(
                  height: 6.0,
                ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          width: 1.0, color: Theme.of(context).primaryColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 4.0),
                      child: canProgress
                          ? const Icon(Icons.check, size: 40.0)
                          : Text(
                              AppLocalizations.of(context)!
                                  .stepTwoCompletedTimeText(
                                _from(timeLeft, context),
                              ),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                    ),
                  ),
                ),

                /*if (cardLayout)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Center(
                        child: RichText(
                            text: TextSpan(
                                text: AppLocalizations.of(context)!
                                    .stepTwoCompletedSubText,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                children: [
                              canProgress
                                  ? const WidgetSpan(
                                      child: Icon(Icons.check, size: 40.0))
                                  : TextSpan(
                                      text:
                                          ' ${AppLocalizations.of(context)!.stepTwoCompletedTimeText(_from(timeLeft, context))}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor))
                            ])),
                      ),
                    ),
                  )*/
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Center(
          child: FilledButton(
            onPressed: isLoading || !canProgress
                ? null
                : () {
                    _next();
                  },
            child: Text(AppLocalizations.of(context)!.nextButton),
          ),
        ),
        const SizedBox(
          height: 25.0,
        ),
      ],
    );
  }

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
    widget.next();
  }

  String _from(Duration duration, BuildContext context) {
    final Locale current = Localizations.localeOf(context);
    return prettyDuration(duration,
        delimiter: ' ',
        locale: DurationLocale.fromLanguageCode(current.languageCode) ??
            const EnglishDurationLocale(),
        abbreviated: false,
        first: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
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

    final bool emptyLogs = blueDyeState.logs.isEmpty;

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
                ? BlueStudyInstructionsPartTwo(initiallyExpanded: emptyLogs)
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
                    emptyLogs
                        ? Center(
                            child: Text(
                              "Please add a bowel movement",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontVariations: [
                                const FontVariation.italic(1.0)
                              ]),
                            ),
                          )
                        : BMDisplay(logs: blueDyeState.logs),
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

class RecordingsInProgress extends ConsumerStatefulWidget {
  const RecordingsInProgress({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _RecordingsInProgressState();
  }
}

class _RecordingsInProgressState extends ConsumerState<RecordingsInProgress> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
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

    final bool emptyLogs = blueDyeState.logs.isEmpty;

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
                ? ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: Breakpoint.medium.value),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [transitLabel, const BlueMealInfoButton()],
                    ),
                  )
                : const Center(
                    child: BlueMealInfoButton(),
                  ),
            const SizedBox(
              height: 12.0,
            ),
            BlueStudyInstructionsBMLogs(
              step: stage,
            ),
            const SizedBox(
              height: 12.0,
            ),
            AdaptiveCardLayout(
              cardColor: Colors.yellow.withValues(alpha: 0.35),
              child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(AppLocalizations.of(context)!
                      .blueMealRecordInstructions)),
            ),
            const SizedBox(
              height: 12.0,
            ),
            AdaptiveCardLayout(
              cardColor: panelColor,
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
                    emptyLogs
                        ? Center(
                            child: Text(
                              "Please add a bowel movement",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          )
                        : BMDisplay(logs: blueDyeState.logs),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: Breakpoint.tiny.value),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pushNamed(
                              'recordType',
                              pathParameters: {'type': Symptoms.BM},
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .lighten(35),
                            ),
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.all(8.0)),
                            side: WidgetStateProperty.all(BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .darken(10),
                                width: 2.0)),
                            shape: WidgetStateProperty.all(
                              const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: Icon(
                            Icons.add,
                            size: 30.0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .darken(10),
                          ),
                          label: Text(
                            "Record a Bowel Movement",
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
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
