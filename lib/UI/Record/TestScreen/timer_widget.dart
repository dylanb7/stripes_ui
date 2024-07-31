import 'dart:async';

import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/base_test_repo.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class TimerWidget extends ConsumerWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          stage == BlueDyeProgression.stepOne
              ? const BlueStudyInstructionsPartOne()
              : const BlueStudyInstructionsPartThree(),
          const SizedBox(
            height: 12,
          ),
          const TimerPortion(),
        ]);
  }
}

class TimerPortion extends ConsumerStatefulWidget {
  const TimerPortion({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _TimerPortionState();
  }
}

class _TimerPortionState extends ConsumerState<TimerPortion> {
  Duration gap = Duration.zero;
  bool isLoading = false;
  TimerState? timerState;
  Timer? timer;
  @override
  Widget build(BuildContext context) {
    final BlueDyeState? blueDyeState = ref.watch(testsHolderProvider
        .select((value) => value.valueOrNull?.getTestState<BlueDyeState>()));

    final bool paused = timerState?.pauseTime != null;
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(12.0))),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mealTimerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          from(gap, context),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                        ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isLoading || gap == Duration.zero
                          ? null
                          : () {
                              _reset(blueDyeState);
                            },
                      style:
                          Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.surface),
                              ),
                      label:
                          Text(AppLocalizations.of(context)!.studyResetLabel),
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                    ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (paused) {
                                _resume(blueDyeState);
                              } else {
                                _pause(blueDyeState);
                              }
                            },
                      style:
                          Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.surface),
                              ),
                      label: Text(paused
                          ? AppLocalizations.of(context)!.studyPlayLabel
                          : AppLocalizations.of(context)!.studyPauseLabel),
                      icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Center(
          child: FilledButton(
            onPressed: timerState?.pauseTime != null && gap != Duration.zero
                ? () {
                    _next(blueDyeState);
                  }
                : null,
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
    _startTimer();
    super.didChangeDependencies();
  }

  Future<void> _startTimer({TimerState? state}) async {
    if (state == null) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      timerState = await _timerState();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      timerState = state;
    }

    if (timerState?.pauseTime != null) {
      gap = timerState!.pauseTime!.difference(timerState!.start);
      timer?.cancel();
      if (mounted) setState(() {});
      return;
    }
    timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        gap = DateTime.now().difference(timerState!.start);
      });
    });
  }

  Future<TimerState> _timerState() async {
    final BlueDyeState? blueDyeState = await ref
        .read(testsHolderProvider.notifier)
        .getTestState<BlueDyeState>();

    final DateTime? startTime = blueDyeState?.timerStart;
    final DateTime? pauseTime = blueDyeState?.pauseTime;
    return TimerState(start: startTime ?? DateTime.now(), pauseTime: pauseTime);
  }

  Future<void> _pause(BlueDyeState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) {
        showSnack(context, "Unable to pause timer");
      }
      return;
    }
    setState(() {
      isLoading = true;
    });
    final DateTime setTime = DateTime.now();
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) =>
            test?.setTestState(blueDyeState.copyWith(pauseTime: setTime)));
    setState(() {
      isLoading = false;
    });
    await _startTimer(
        state: TimerState(start: timerState!.start, pauseTime: setTime));
  }

  Future<void> _resume(BlueDyeState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) {
        showSnack(context, "Unable to resume timer");
      }
      return;
    }
    setState(() {
      isLoading = true;
    });
    final Duration timePaused =
        DateTime.now().difference(timerState!.pauseTime!);
    final DateTime adjustedStart = timerState!.start.add(timePaused);
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) => test?.setTestState(BlueDyeState(
            id: blueDyeState.id,
            startTime: blueDyeState.startTime,
            timerStart: adjustedStart,
            pauseTime: null,
            logs: blueDyeState.logs)));

    setState(() {
      isLoading = false;
    });

    await _startTimer(state: TimerState(start: adjustedStart, pauseTime: null));
  }

  Future<void> _reset(BlueDyeState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) {
        showSnack(context, "Unable to reset timer");
      }
      return;
    }
    setState(() {
      isLoading = true;
    });
    final DateTime newStart = DateTime.now();
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) => test?.setTestState(
            blueDyeState.copyWith(pauseTime: newStart, timerStart: newStart)));
    setState(() {
      isLoading = false;
    });
    await _startTimer(state: TimerState(start: newStart, pauseTime: newStart));
  }

  Future<void> _next(BlueDyeState? blueDyeState) async {
    if (blueDyeState == null || timerState == null) {
      if (mounted) {
        showSnack(context, "Unable to go next");
      }
      return;
    }
    setState(() {
      isLoading = true;
    });
    final DateTime mealEnd = DateTime.now();
    final Duration timePaused = mealEnd.difference(timerState!.pauseTime!);
    final DateTime adjustedStart = timerState!.start.add(timePaused);
    final Duration mealDuration = mealEnd.difference(adjustedStart);
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then(
          (test) => test?.setTestState(
            blueDyeState.copyWith(
                finishedEating: mealDuration,
                finishedEatingTime: mealEnd,
                pauseTime: null,
                timerStart: null),
          ),
        );
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

@immutable
class TimerState {
  final DateTime start;
  final DateTime? pauseTime;
  const TimerState({required this.start, this.pauseTime});
}

String from(Duration duration, BuildContext context) {
  final Locale current = Localizations.localeOf(context);
  return prettyDuration(duration,
      delimiter: ' ',
      locale: DurationLocale.fromLanguageCode(current.languageCode) ??
          const EnglishDurationLocale(),
      abbreviated: true);
}
