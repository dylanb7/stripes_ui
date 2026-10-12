import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class RecordingsView extends ConsumerWidget {
  final Function? next;

  final BlueDyeProgression clicked;

  const RecordingsView({required this.next, required this.clicked, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLogs = ref.watch(blueDyeBmTestLogsProvider).value ?? const [];
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) {
            final Color panelColor = Theme.of(context).primaryColor
                .withValues(alpha: 0.2);
            final List<BMTestLog> savedLogs =
                (clicked == BlueDyeProgression.stepFour ||
                        clicked == BlueDyeProgression.stepFive) &&
                    (progress.orderedTests.length) >= 2
                ? progress.orderedTests[1].test.logs
                : (progress.orderedTests.isNotEmpty
                      ? progress.orderedTests[0].test.logs
                      : []);
            final List<BMTestLog> logs = savedLogs.isNotEmpty
                ? savedLogs
                : currentLogs;
            final Widget transitLabel = Text(
              clicked.value < 2
                  ? context.translate.transitOneLabel
                  : context.translate.transitTwoLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            );
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: cardLayout ? AppPadding.xl : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: cardLayout
                      ? Breakpoint.small.value
                      : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppPadding.tiny),
                    cardLayout
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              transitLabel,
                              const BlueMealInfoButton(),
                            ],
                          )
                        : const Center(child: BlueMealInfoButton()),
                    const SizedBox(height: AppPadding.tiny),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: cardLayout
                            ? BorderRadius.circular(AppRounding.medium)
                            : const BorderRadius.all(Radius.circular(0)),
                        color: panelColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.medium),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!cardLayout) ...[transitLabel, const Divider()],
                            Text(
                              context.translate.recordingStateTitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppPadding.small),
                            BMDisplay(logs: logs),
                            const SizedBox(height: AppPadding.small),
                            Text(
                              clicked == BlueDyeProgression.stepTwo
                                  ? context.translate.stepTwoCompletedText
                                  : context.translate.stepFourCompletedText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (clicked == BlueDyeProgression.stepFive)
                              Text(
                                context
                                    .translate
                                    .studyStepFourExplanationCompletedNotice,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: AppPadding.medium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    if (clicked != BlueDyeProgression.stepFive) ...[
                      Center(
                        child: FilledButton(
                          onPressed: next == null
                              ? null
                              : () {
                                  next!();
                                },
                          child: Text(context.translate.nextButton),
                        ),
                      ),
                      const SizedBox(height: AppPadding.xl),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
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

  final Duration waitTime = const Duration(days: 7);

  @override
  Widget build(BuildContext context) {
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.large);
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) {
            final List<TestDate> orderedTests = progress.orderedTests;
            if (orderedTests.isEmpty) return Container();
            final DateTime progressDate = orderedTests[0].finishTime.add(
              waitTime,
            );
            final Duration timePassed = DateTime.now().difference(
              orderedTests[0].finishTime,
            );

            final Widget waitingLabel = Text(
              "Waiting Time",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            );

            final bool canProgress = waitTime.compareTo(timePassed) < 0;
            final Duration timeLeft = canProgress
                ? Duration.zero
                : Duration(
                    milliseconds:
                        waitTime.inMilliseconds - timePassed.inMilliseconds,
                  );
            final Color cardColor = Theme.of(context).primaryColor
                .withValues(alpha: 0.2);
            if (canProgress) timer?.cancel();
            return Column(
              children: [
                const SizedBox(height: AppPadding.small),
                cardLayout
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Breakpoint.medium.value,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [waitingLabel, const BlueMealInfoButton()],
                        ),
                      )
                    : const Center(child: BlueMealInfoButton()),
                const SizedBox(height: AppPadding.tiny),
                AdaptiveCardLayout(
                  cardColor: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (!cardLayout) ...[waitingLabel, const Divider()],
                        Text(
                          context.translate.blueMealWaitTimeTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppPadding.tiny),
                        Text(
                          context.translate.blueMealWaitTimeLineOne,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppPadding.tiny),
                        Text(
                          context.translate.blueMealWaitTimeLineTwo,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppPadding.tiny),
                        if (!canProgress && !kIsWeb) ...[
                          Text(
                            context.translate.blueMealWaitTimeLineThree,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppPadding.tiny),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                await Add2Calendar.addEvent2Cal(
                                  Event(
                                    title: "Blue Meal Study",
                                    description: "You are eligible to start the second Blue Meal today.",
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
                          ),
                        ],
                        const SizedBox(height: AppPadding.small),
                        Center(
                          child: Text(
                            context.translate.stepTwoCompletedSubText,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppPadding.tiny),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRounding.small,
                              ),
                              border: Border.all(
                                width: 1.0,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.small,
                                vertical: AppPadding.tiny,
                              ),
                              child: canProgress
                                  ? const Icon(Icons.check, size: 40.0)
                                  : Text(
                                      context.translate
                                          .stepTwoCompletedTimeText(
                                            _from(timeLeft, context),
                                          ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
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
                                text: context.translate
                                    .stepTwoCompletedSubText,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                children: [
                              canProgress
                                  ? const WidgetSpan(
                                      child: Icon(Icons.check, size: 40.0))
                                  : TextSpan(
                                      text:
                                          ' ${context.translate.stepTwoCompletedTimeText(_from(timeLeft, context))}',
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
                const SizedBox(height: AppPadding.medium),
                Center(
                  child: FilledButton(
                    onPressed: isLoading || !canProgress
                        ? null
                        : () {
                            _next();
                          },
                    child: Text(context.translate.nextButton),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),
              ],
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  @override
  void didChangeDependencies() {
    _onDependencyChange();
    super.didChangeDependencies();
  }

  Future<void> _onDependencyChange() async {
    try {
      final BlueDyeTestProgress progress = await ref.read(
        blueDyeTestProgressProvider.future,
      );
      if (!mounted) return;

      final List<TestDate> dates = progress.orderedTests;
      final DateTime testFinished = dates.isNotEmpty
          ? dates[0].finishTime
          : DateTime.now();
      final Duration timePassed = DateTime.now().difference(testFinished);
      final bool canProgress = waitTime.compareTo(timePassed) < 0;

      timer?.cancel();
      if (!canProgress) {
        timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (mounted) setState(() {});
        });
      }
    } catch (_) {
      // The provider's error state is rendered by build().
    }
  }

  Future<void> _next() async {
    setState(() {
      isLoading = true;
    });
    final DateTime start = DateTime.now();
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);

    if (protocol != null && repo != null) {
      final completedState = await ref.read(blueDyeMealStateProvider.future);
      final updated = protocol.copyWith(
        testContext: startSecondBlueDyeRunContext(
          protocol: protocol,
          completedState: completedState,
          startTime: start,
        ),
      );
      await repo.updateProtocol(updated);
      await repo.advanceStage(
        activeTestId: protocol.id,
        targetStageId: 'eat_meal_2',
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
        widget.next();
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _from(Duration duration, BuildContext context) {
    final Locale current = Localizations.localeOf(context);
    return prettyDuration(
      duration,
      delimiter: ' ',
      locale:
          DurationLocale.fromLanguageCode(current.languageCode) ??
          const EnglishDurationLocale(),
      abbreviated: false,
      first: true,
    );
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

  final Duration waitTime = const Duration(days: 7);

  @override
  void didChangeDependencies() {
    _onDependencyChange();
    super.didChangeDependencies();
  }

  Future<void> _onDependencyChange() async {
    try {
      final BlueDyeTestProgress progress = await ref.read(
        blueDyeTestProgressProvider.future,
      );
      if (!mounted) return;

      final List<TestDate> dates = progress.orderedTests;
      final DateTime testFinished = dates.isNotEmpty
          ? dates[0].finishTime
          : DateTime.now();
      final Duration timePassed = DateTime.now().difference(testFinished);
      final bool canProgress = waitTime.compareTo(timePassed) < 0;

      timer?.cancel();
      if (!canProgress) {
        timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (mounted) setState(() {});
        });
      }
    } catch (_) {
      // The provider's error state is rendered by build().
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) => _buildLoadedContent(context, progress),
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    BlueDyeTestProgress progress,
  ) {
    final List<TestDate> orderedTests = progress.orderedTests;
    if (orderedTests.isEmpty) return const SizedBox.shrink();

    final DateTime progressDate = orderedTests[0].finishTime.add(waitTime);
    final Duration timePassed = DateTime.now().difference(
      orderedTests[0].finishTime,
    );

    final bool canProgress = waitTime.compareTo(timePassed) < 0;
    final Duration timeLeft = canProgress
        ? Duration.zero
        : Duration(
            milliseconds: waitTime.inMilliseconds - timePassed.inMilliseconds,
          );
    if (canProgress) timer?.cancel();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BlueStudyInstructionsPartTwo(initiallyExpanded: false),
        const SizedBox(height: AppPadding.medium),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRounding.medium),
            color: ElevationOverlay.applySurfaceTint(
              Theme.of(context).cardColor,
              Theme.of(context).colorScheme.surfaceTint,
              3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate.recordingStateTitle,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppPadding.small),
                BMDisplay(logs: orderedTests[0].test.logs),
                const SizedBox(height: AppPadding.small),
                Center(
                  child: Text(
                    context.translate.stepTwoCompletedText,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!canProgress) ...[
                  Center(
                    child: Text(
                      "${context.translate.stepTwoCompletedSubText}${from(timeLeft, context)}",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppPadding.small),
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
                      child: const Text("Add to Calendar"),
                    ),
                  ),
                ],
                const SizedBox(height: AppPadding.medium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppPadding.medium),
        if (canProgress)
          Center(
            child: FilledButton(
              onPressed: isLoading ? null : _next,
              child: Text(context.translate.nextButton),
            ),
          ),
      ],
    );
  }

  Future<void> _next() async {
    setState(() {
      isLoading = true;
    });
    final DateTime start = DateTime.now();
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);

    if (protocol != null && repo != null) {
      final completedState = await ref.read(blueDyeMealStateProvider.future);
      final updated = protocol.copyWith(
        testContext: startSecondBlueDyeRunContext(
          protocol: protocol,
          completedState: completedState,
          startTime: start,
        ),
      );
      await repo.updateProtocol(updated);
      await repo.advanceStage(
        activeTestId: protocol.id,
        targetStageId: 'eat_meal_2',
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeMealState> mealState = ref.watch(
      blueDyeMealStateProvider,
    );

    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) => mealState.when(
            data: (mealState) =>
                _buildLoadedContent(context, progress, mealState),
            loading: () => const LoadingWidget(),
            error: (error, stackTrace) => TestAsyncError(error: error),
          ),
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    BlueDyeTestProgress progress,
    BlueDyeMealState blueDyeState,
  ) {
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    final Color panelColor = Theme.of(context).primaryColor
        .withValues(alpha: 0.2);
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

    final detailedLogs = ref.watch(blueDyeBmTestLogsProvider).value ?? const [];
    final displayLogs = detailedLogs.isNotEmpty
        ? detailedLogs
        : blueDyeState.logs;
    final bool emptyLogs = displayLogs.isEmpty;

    final Widget transitLabel = Text(
      stage.value < 2
          ? context.translate.transitOneLabel
          : context.translate.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? AppPadding.xl : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: cardLayout ? Breakpoint.small.value : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppPadding.tiny),
            cardLayout
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [transitLabel, const BlueMealInfoButton()],
                  )
                : const Center(child: BlueMealInfoButton()),
            const SizedBox(height: AppPadding.tiny),
            stage == BlueDyeProgression.stepTwo
                ? BlueStudyInstructionsPartTwo(initiallyExpanded: emptyLogs)
                : const BlueStudyInstructionsPartFour(),
            const SizedBox(height: AppPadding.medium),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: cardLayout
                    ? BorderRadius.circular(AppRounding.medium)
                    : BorderRadius.circular(0),
                color: panelColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppRounding.medium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.recordingStateTitle,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.small),
                    emptyLogs
                        ? Center(
                            child: Text(
                              "Please add a bowel movement",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontVariations: [
                                      const FontVariation.italic(1.0),
                                    ],
                                  ),
                            ),
                          )
                        : BMDisplay(logs: displayLogs),
                    const SizedBox(height: AppPadding.small),
                    Center(
                      child: FilledButton(
                        onPressed: () {
                          context.pushNamed(
                            'recordType',
                            pathParameters: {'type': 'category.BM'},
                          );
                        },
                        child: Text(context.translate.studyRecordBMButton),
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.xxl),
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
  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeMealState> mealState = ref.watch(
      blueDyeMealStateProvider,
    );

    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) => mealState.when(
            data: (mealState) =>
                _buildLoadedContent(context, progress, mealState),
            loading: () => const LoadingWidget(),
            error: (error, stackTrace) => TestAsyncError(error: error),
          ),
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    BlueDyeTestProgress progress,
    BlueDyeMealState blueDyeState,
  ) {
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    final Color panelColor = Theme.of(context).primaryColor
        .withValues(alpha: 0.2);
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

    final detailedLogs = ref.watch(blueDyeBmTestLogsProvider).value ?? const [];
    final displayLogs = detailedLogs.isNotEmpty
        ? detailedLogs
        : blueDyeState.logs;
    final bool emptyLogs = displayLogs.isEmpty;

    final Widget transitLabel = Text(
      stage.value < 2
          ? context.translate.transitOneLabel
          : context.translate.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? AppPadding.xl : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: cardLayout ? Breakpoint.small.value : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppPadding.small),
            cardLayout
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Breakpoint.medium.value,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [transitLabel, const BlueMealInfoButton()],
                    ),
                  )
                : const Center(child: BlueMealInfoButton()),
            const SizedBox(height: AppPadding.medium),
            BlueStudyInstructionsBMLogs(step: stage),
            const SizedBox(height: AppPadding.medium),
            AdaptiveCardLayout(
              cardColor: Colors.yellow.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Text(context.translate.blueMealRecordInstructions),
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            AdaptiveCardLayout(
              cardColor: panelColor,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.recordingStateTitle,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.small),
                    emptyLogs
                        ? Center(
                            child: Text(
                              "Please add a bowel movement",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          )
                        : BMDisplay(logs: displayLogs),
                    const SizedBox(height: AppPadding.small),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Breakpoint.tiny.value,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pushNamed(
                              'recordType',
                              pathParameters: {'type': 'category.BM'},
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.secondary
                                  .lighten(35),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.all(AppPadding.small),
                            ),
                            side: WidgetStateProperty.all(
                              BorderSide(
                                color: Theme.of(context).colorScheme.secondary
                                    .darken(10),
                                width: 2.0,
                              ),
                            ),
                            shape: WidgetStateProperty.all(
                              const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppRounding.tiny),
                                ),
                              ),
                            ),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: Icon(
                            Icons.add,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.secondary
                                .darken(10),
                          ),
                          label: Text(
                            "Record a Bowel Movement",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.xxl),
          ],
        ),
      ),
    );
  }
}

class BMDisplay extends StatelessWidget {
  final List<dynamic> logs;
  const BMDisplay({required this.logs, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: logs.map((log) {
        if (log is BMTestLog) {
          return EntryDisplay(
            event: log.response,
            hasControls: false,
            hasConstraints: false,
            includeFullDate: true,
          );
        }
        if (log is BlueDyeBmLog) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: log.isBlue ? Colors.blue : Colors.brown,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFromStamp(log.stamp).toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).separated(by: const SizedBox(height: AppPadding.small)),
    );
  }
}
