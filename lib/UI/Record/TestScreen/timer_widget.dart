import 'dart:async';

import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class TimerWidget extends ConsumerWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) {
            final BlueDyeProgression stage =
                progress.getProgression() ?? BlueDyeProgression.stepOne;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                stage == BlueDyeProgression.stepOne
                    ? const BlueStudyInstructionsPartOne()
                    : const BlueStudyInstructionsPartThree(),
                const SizedBox(height: AppPadding.medium),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450.0),
                    child: const TimerPortion(),
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
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
  int _timerGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(_startTimer));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<BlueDyeMealState>>(blueDyeMealStateProvider, (
      previous,
      next,
    ) {
      final previousState = previous?.when(
        data: (state) => state,
        loading: () => null,
        error: (error, stackTrace) => null,
      );
      next.when(
        data: (state) {
          if (state.timerStart != previousState?.timerStart ||
              state.pauseTime != previousState?.pauseTime) {
            unawaited(_startTimer(state: TimerState.fromMealState(state)));
          }
        },
        loading: () {},
        error: (error, stackTrace) {},
      );
    });

    return ref
        .watch(blueDyeMealStateProvider)
        .when(
          data: (blueDyeState) {
            final bool paused = timerState?.pauseTime != null;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRounding.medium),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          context.translate.mealTimerTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                        Center(
                          child: Text(
                            from(
                              isLoading
                                  ? timerState?.pauseTime != null &&
                                            timerState?.start != null
                                        ? timerState!.pauseTime!.difference(
                                            timerState!.start,
                                          )
                                        : Duration.zero
                                  : gap,
                              context,
                            ),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(
                                        alpha: isLoading ? 0.75 : 1.0,
                                      ),
                                ),
                          ),
                        ),
                        const SizedBox(height: AppPadding.medium),
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
                              style: Theme.of(context).elevatedButtonTheme.style
                                  ?.copyWith(
                                    backgroundColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                              label: Text(context.translate.studyResetLabel),
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
                              style: Theme.of(context).elevatedButtonTheme.style
                                  ?.copyWith(
                                    backgroundColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                              label: Text(
                                paused
                                    ? context.translate.studyPlayLabel
                                    : context.translate.studyPauseLabel,
                              ),
                              icon: Icon(
                                paused ? Icons.play_arrow : Icons.pause,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                Center(
                  child: FilledButton(
                    onPressed:
                        timerState?.pauseTime != null && gap != Duration.zero
                        ? () {
                            _next(blueDyeState);
                          }
                        : null,
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

  Future<void> _startTimer({TimerState? state}) async {
    final int generation = ++_timerGeneration;
    timer?.cancel();

    if (state == null) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      late final TimerState loadedState;
      try {
        loadedState = await _timerState();
      } catch (_) {
        if (mounted && generation == _timerGeneration) {
          setState(() => isLoading = false);
        }
        return;
      }
      if (!mounted || generation != _timerGeneration) return;
      timerState = loadedState;
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      timerState = state;
    }

    if (!mounted || generation != _timerGeneration) return;
    if (timerState?.pauseTime != null) {
      setState(() {
        gap = timerState!.pauseTime!.difference(timerState!.start);
      });
      return;
    }
    setState(() {
      gap = DateTime.now().difference(timerState!.start);
    });
    timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        gap = DateTime.now().difference(timerState!.start);
      });
    });
  }

  Future<TimerState> _timerState() async {
    final blueDyeState = await ref.read(blueDyeMealStateProvider.future);
    return TimerState.fromMealState(blueDyeState);
  }

  Future<void> _pause(BlueDyeMealState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) showSnack(context, "Unable to pause timer");
      return;
    }
    setState(() => isLoading = true);
    final DateTime setTime = DateTime.now();
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final updatedMeal = blueDyeState.copyWith(pauseTime: setTime);
      await repo.updateProtocol(
        protocol.copyWith(
          testContext: updatedMeal.replaceInContext(protocol.testContext),
        ),
      );
      await _startTimer(
        state: TimerState(start: timerState!.start, pauseTime: setTime),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _resume(BlueDyeMealState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) showSnack(context, "Unable to resume timer");
      return;
    }
    setState(() => isLoading = true);
    final Duration timePaused = DateTime.now().difference(
      timerState!.pauseTime!,
    );
    final DateTime adjustedStart = timerState!.start.add(timePaused);
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final updatedMeal = blueDyeState.copyWith(
        timerStart: adjustedStart,
        clearPauseTime: true,
      );
      await repo.updateProtocol(
        protocol.copyWith(
          testContext: updatedMeal.replaceInContext(protocol.testContext),
        ),
      );
      await _startTimer(
        state: TimerState(start: adjustedStart, pauseTime: null),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _reset(BlueDyeMealState? blueDyeState) async {
    if (blueDyeState == null) {
      if (mounted) showSnack(context, "Unable to reset timer");
      return;
    }
    setState(() => isLoading = true);
    final DateTime newStart = DateTime.now();
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final updatedMeal = blueDyeState.copyWith(
        pauseTime: newStart,
        timerStart: newStart,
      );
      await repo.updateProtocol(
        protocol.copyWith(
          testContext: updatedMeal.replaceInContext(protocol.testContext),
        ),
      );
      await _startTimer(
        state: TimerState(start: newStart, pauseTime: newStart),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _next(BlueDyeMealState? blueDyeState) async {
    if (blueDyeState == null || timerState == null) {
      if (mounted) showSnack(context, "Unable to go next");
      return;
    }
    setState(() => isLoading = true);
    final DateTime mealEnd = DateTime.now();
    final Duration timePaused = mealEnd.difference(timerState!.pauseTime!);
    final DateTime adjustedStart = timerState!.start.add(timePaused);
    final Duration mealDuration = mealEnd.difference(adjustedStart);
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final updatedMeal = blueDyeState.copyWith(
        finishedEating: mealDuration,
        finishedEatingTime: mealEnd,
        clearPauseTime: true,
        clearTimerStart: true,
      );
      await repo.updateProtocol(
        protocol.copyWith(
          testContext: updatedMeal.replaceInContext(protocol.testContext),
        ),
      );
    }
    if (mounted) setState(() => isLoading = false);
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

  factory TimerState.fromMealState(BlueDyeMealState mealState) {
    return TimerState(
      start: mealState.timerStart ?? DateTime.now(),
      pauseTime: mealState.pauseTime,
    );
  }
}

String from(Duration duration, BuildContext context) {
  final Locale current = Localizations.localeOf(context);
  return prettyDuration(
    duration,
    delimiter: ' ',
    locale:
        DurationLocale.fromLanguageCode(current.languageCode) ??
        const EnglishDurationLocale(),
    abbreviated: true,
  );
}
