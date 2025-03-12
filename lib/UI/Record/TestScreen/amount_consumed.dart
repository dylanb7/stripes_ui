import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class MealFinishedDisplay extends ConsumerWidget {
  final Function next;

  final BlueDyeProgression displaying;

  const MealFinishedDisplay(
      {required this.next, required this.displaying, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);

    final BlueDyeState? testsState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));

    final Color cardColor =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);

    if (progress.isLoading) return const LoadingWidget();

    final BlueDyeProgression progression =
        progress.valueOrNull?.getProgression() ?? BlueDyeProgression.stepOne;

    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.undetermined:
          AppLocalizations.of(context)!.amountConsumedUnable,
      AmountConsumed.halfOrLess:
          AppLocalizations.of(context)!.amountConsumedHalfOrLess,
      AmountConsumed.half: AppLocalizations.of(context)!.amountConsumedHalf,
      AmountConsumed.moreThanHalf:
          AppLocalizations.of(context)!.amountConsumedHalfOrMore,
      AmountConsumed.all: AppLocalizations.of(context)!.amountConsumedAll,
    };

    BlueMealStats getMealStats() {
      final bool testOngoing = (progress.valueOrNull?.testIteration ?? 0) < 2 ||
          (progress.valueOrNull?.stage.testInProgress ?? false);
      if (testOngoing &&
          ((displaying == BlueDyeProgression.stepOne &&
                  progression == BlueDyeProgression.stepTwo) ||
              (displaying == BlueDyeProgression.stepFour &&
                  progression == BlueDyeProgression.stepFive))) {
        return BlueMealStats(
            start: testsState?.startTime,
            duration: testsState?.finishedEating,
            amountConsumed: testsState?.amountConsumed);
      }
      final List<TestDate> dates = progress.valueOrNull?.orderedTests ?? [];

      if (dates.isEmpty) {
        return const BlueMealStats(
            start: null, duration: null, amountConsumed: null);
      }
      if (displaying == BlueDyeProgression.stepOne) {
        return BlueMealStats(
            start: dates[0].test.startEating,
            duration: dates[0].test.eatingDuration,
            amountConsumed: dates[0].test.amountConsumed);
      }
      if (dates.length < 2) {
        return const BlueMealStats(
            start: null, duration: null, amountConsumed: null);
      }
      return BlueMealStats(
          start: dates[1].test.startEating,
          duration: dates[1].test.eatingDuration,
          amountConsumed: dates[1].test.amountConsumed);
    }

    final BlueMealStats mealStats = getMealStats();
    final double iconSize = Theme.of(context).iconTheme.size ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(
          height: 6.0,
        ),
        const Center(child: BlueMealInfoButton()),
        const SizedBox(
          height: 6.0,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            displaying == BlueDyeProgression.stepThree
                ? AppLocalizations.of(context)!.studyStepThreeExplanationTitle
                : AppLocalizations.of(context)!.studyStepOneExplanationTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        AdaptiveCardLayout(
          cardColor: cardColor,
          borderColor: Theme.of(context).primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.mealCompleteTitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (mealStats.start != null) ...[
                  const SizedBox(
                    height: 8.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.alarm),
                      const SizedBox(
                        width: 6.0,
                      ),
                      if (mealStats.start != null)
                        Text(AppLocalizations.of(context)!
                            .mealCompleteStartTime(
                                mealStats.start!, mealStats.start!))
                    ],
                  ),
                ],
                if (mealStats.duration != null) ...[
                  const SizedBox(
                    height: 8.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'packages/stripes_ui/assets/svg/muffin_icon.svg',
                        width: iconSize,
                        height: iconSize,
                      ),
                      const SizedBox(
                        width: 6.0,
                      ),
                      if (mealStats.duration != null)
                        Text(
                            "${AppLocalizations.of(context)!.mealCompleteDuration} ${from(mealStats.duration!, context)}")
                    ],
                  ),
                ],
                if (mealStats.amountConsumed != null) ...[
                  const SizedBox(
                    height: 8.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.blur_linear),
                      const SizedBox(
                        width: 6.0,
                      ),
                      Flexible(
                        child: Text(
                          "${AppLocalizations.of(context)!.mealCompleteAmountConsumed} ${amountText[mealStats.amountConsumed!]!}",
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(
                  height: 8.0,
                ),
                Text(
                  displaying == BlueDyeProgression.stepThree
                      ? AppLocalizations.of(context)!.stepThreeCompletedText
                      : AppLocalizations.of(context)!.stepOneCompletedText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 8.0,
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
    );
  }
}

@immutable
class BlueMealStats {
  final DateTime? start;
  final Duration? duration;
  final AmountConsumed? amountConsumed;

  const BlueMealStats(
      {required this.start,
      required this.duration,
      required this.amountConsumed});
}

class AmountConsumedEntry extends ConsumerStatefulWidget {
  const AmountConsumedEntry({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AmountConsumedEntryState();
  }
}

class _AmountConsumedEntryState extends ConsumerState<AmountConsumedEntry> {
  AmountConsumed? value;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    final BlueDyeState? testsState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));

    if (progress.isLoading) return const LoadingWidget();

    final BlueDyeProgression stage =
        progress.valueOrNull?.getProgression() ?? BlueDyeProgression.stepOne;

    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.halfOrLess:
          AppLocalizations.of(context)!.amountConsumedHalfOrLess,
      AmountConsumed.half: AppLocalizations.of(context)!.amountConsumedHalf,
      AmountConsumed.moreThanHalf:
          AppLocalizations.of(context)!.amountConsumedHalfOrMore,
      AmountConsumed.all: AppLocalizations.of(context)!.amountConsumedAll,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stage == BlueDyeProgression.stepOne
              ? AppLocalizations.of(context)!.studyStepOneExplanationTitle
              : AppLocalizations.of(context)!.studyStepThreeExplanationTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450.0),
            child: Opacity(
              opacity: isLoading ? 0.6 : 1,
              child: IgnorePointer(
                ignoring: isLoading,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: ElevationOverlay.applySurfaceTint(
                        Theme.of(context).cardColor,
                        Theme.of(context).colorScheme.surfaceTint,
                        3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.amountConsumedQuestion,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        ...amountText.keys.map<Widget>((amount) {
                          return RadioListTile<AmountConsumed>(
                              title: Text(amountText[amount]!),
                              value: amount,
                              groupValue: value,
                              onChanged: (newValue) {
                                if (newValue == null) return;
                                if (newValue == value) {
                                  setState(() {
                                    value = null;
                                  });
                                } else {
                                  setState(() {
                                    value = newValue;
                                  });
                                }
                              });
                        }),
                        const SizedBox(
                          height: 8.0,
                        ),
                        CheckboxListTile(
                          value: value == AmountConsumed.undetermined,
                          onChanged: (val) {
                            if (val == null) return;
                            if (value != AmountConsumed.undetermined) {
                              setState(() {
                                value = AmountConsumed.undetermined;
                              });
                            } else {
                              setState(() {
                                value = null;
                              });
                            }
                          },
                          title: Text(
                            AppLocalizations.of(context)!.amountConsumedUnable,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Center(
          child: FilledButton(
            onPressed: value != null && !isLoading
                ? () {
                    _next(testsState);
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

  Future<void> _next(BlueDyeState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
    }
    setState(() {
      isLoading = true;
    });
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) {
      test?.setTestState(state!.copyWith(amountConsumed: value));
    });
    setState(() {
      isLoading = false;
    });
  }
}

class MealStatsEntry extends ConsumerStatefulWidget {
  const MealStatsEntry({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _MealStatsEntryState();
  }
}

class _MealStatsEntryState extends ConsumerState<MealStatsEntry>
    with RestorationMixin {
  final fastQuestionKey = GlobalKey();
  final mealTimeQuestionKey = GlobalKey();
  final mealAmountConsumedKey = GlobalKey();

  bool isLoading = false;

  RestorableEnum<AmountConsumed>? amountConsumed;

  RestorableEnum<MealTime>? mealTime;

  RestorableBool? completedFast;

  @override
  Widget build(BuildContext context) {
    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.halfOrLess:
          AppLocalizations.of(context)!.amountConsumedHalfOrLess,
      AmountConsumed.half: AppLocalizations.of(context)!.amountConsumedHalf,
      AmountConsumed.moreThanHalf:
          AppLocalizations.of(context)!.amountConsumedHalfOrMore,
      AmountConsumed.all: AppLocalizations.of(context)!.amountConsumedAll,
    };

    final Color activeCard =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final Color disabledColor = Theme.of(context).disabledColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveCardLayout(
          key: fastQuestionKey,
          cardColor: activeCard,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.amountConsumedQuestion,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).primaryColor),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                ...amountText.keys.map<Widget>((amount) {
                  return RadioListTile<AmountConsumed>(
                      title: Text(amountText[amount]!),
                      value: amount,
                      groupValue: amountConsumed!.value,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        if (newValue == amountConsumed?.value) {
                          setState(() {
                            amountConsumed = null;
                          });
                        } else {
                          setState(() {
                            amountConsumed ??= RestorableEnum(
                                AmountConsumed.undetermined,
                                values: AmountConsumed.values);
                            amountConsumed!.value = newValue;
                          });
                        }
                        if (mealTimeQuestionKey.currentContext != null) {
                          Scrollable.ensureVisible(
                              mealTimeQuestionKey.currentContext!,
                              duration: Durations.medium1,
                              alignmentPolicy:
                                  ScrollPositionAlignmentPolicy.explicit,
                              alignment: 30.0);
                        }
                      });
                }),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        IgnorePointer(
          ignoring: false,
          child: AdaptiveCardLayout(
            key: mealTimeQuestionKey,
            cardColor: activeCard,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.amountConsumedQuestion,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  ...MealTime.mealTimes.map<Widget>((amount) {
                    return RadioListTile<MealTime>(
                        title: Text(amount.value),
                        value: amount,
                        groupValue: mealTime?.value,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          if (newValue == mealTime?.value) {
                            setState(() {
                              mealTime = null;
                            });
                          } else {
                            setState(() {
                              mealTime ??= RestorableEnum(
                                  MealTime.fifteenOrLess,
                                  values: MealTime.mealTimes);
                              mealTime!.value = newValue;
                            });
                          }
                          if (mealAmountConsumedKey.currentContext != null) {
                            Scrollable.ensureVisible(
                                mealAmountConsumedKey.currentContext!,
                                duration: Durations.medium1,
                                alignmentPolicy:
                                    ScrollPositionAlignmentPolicy.explicit,
                                alignment: 30.0);
                          }
                        });
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        IgnorePointer(
          ignoring: mealTime == null,
          child: AdaptiveCardLayout(
            key: mealAmountConsumedKey,
            cardColor: mealTime == null ? disabledColor : activeCard,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.amountConsumedQuestion,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  ...amountText.keys.map<Widget>((amount) {
                    return RadioListTile<AmountConsumed>(
                        title: Text(amountText[amount]!),
                        value: amount,
                        groupValue: amountConsumed?.value,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          if (newValue == amountConsumed?.value) {
                            setState(() {
                              amountConsumed = null;
                            });
                          } else {
                            setState(() {
                              amountConsumed ??= RestorableEnum(
                                  AmountConsumed.undetermined,
                                  values: AmountConsumed.values);
                              amountConsumed!.value = newValue;
                            });
                          }
                        });
                  }),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: FilledButton(
            onPressed: () {},
            child: Text(AppLocalizations.of(context)!.nextButton),
          ),
        ),
        const SizedBox(
          height: 25.0,
        ),
      ],
    );
  }

  Future<void> _next(BlueDyeState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
    }
    setState(() {
      isLoading = true;
    });
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) {
      test?.setTestState(
          state!.copyWith(amountConsumed: amountConsumed!.value));
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  String? get restorationId => "meal-stats-entry";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (amountConsumed != null) {
      registerForRestoration(amountConsumed!, "amount-consumed");
    }
  }
}

enum MealTime {
  fifteenOrLess("15 minutes or less"),
  fifteenToThrity("15 to 30 minutes"),
  thirtyToHour("30 minutes to 1 hour"),
  hourOrMore("Over 1 hour");

  static List<MealTime> mealTimes = [
    MealTime.fifteenOrLess,
    MealTime.fifteenToThrity,
    MealTime.thirtyToHour,
    MealTime.hourOrMore
  ];

  final String value;

  const MealTime(this.value);
}
