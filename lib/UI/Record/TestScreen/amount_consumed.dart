import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';

class MealFinishedDisplay extends ConsumerWidget {
  final Function? next;

  final BlueDyeProgression displaying;

  const MealFinishedDisplay({this.next, required this.displaying, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
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
      AmountConsumed.undetermined: context.translate.amountConsumedUnable,
      AmountConsumed.halfOrLess: context.translate.amountConsumedHalfOrLess,
      AmountConsumed.half: context.translate.amountConsumedHalf,
      AmountConsumed.moreThanHalf: context.translate.amountConsumedHalfOrMore,
      AmountConsumed.all: context.translate.amountConsumedAll,
    };

    final Widget transitLabel = Text(
      displaying.value < 2
          ? context.translate.transitOneLabel
          : context.translate.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? AppPadding.xl : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: cardLayout ? Breakpoint.small.value : double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: AppPadding.small,
            ),
            cardLayout
                ? ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: Breakpoint.small.value),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [transitLabel, const BlueMealInfoButton()],
                    ),
                  )
                : const Center(
                    child: BlueMealInfoButton(),
                  ),
            const SizedBox(
              height: AppPadding.small,
            ),
            AdaptiveCardLayout(
              cardColor: cardColor,
              borderColor: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!cardLayout) ...[transitLabel, const Divider()],
                    Text(
                      context.translate.mealCompleteTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (mealStats.start != null) ...[
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.alarm),
                          const SizedBox(
                            width: AppPadding.tiny,
                          ),
                          if (mealStats.start != null)
                            Text(context.translate.mealCompleteStartTime(
                                mealStats.start!, mealStats.start!))
                        ],
                      ),
                    ],
                    if (mealStats.duration != null &&
                        mealStats.duration != Duration.zero) ...[
                      const SizedBox(
                        height: AppPadding.small,
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
                            width: AppPadding.tiny,
                          ),
                          if (mealStats.duration != null)
                            Text(
                                "${context.translate.mealCompleteDuration} ${MealTime.fromDuration(mealStats.duration!)?.value ?? from(mealStats.duration!, context)}")
                        ],
                      ),
                    ],
                    if (mealStats.duration == Duration.zero) ...[
                      const SizedBox(
                        height: AppPadding.small,
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
                            width: AppPadding.tiny,
                          ),
                          const Text("Tube Fed"),
                        ],
                      ),
                    ],
                    if (mealStats.amountConsumed != null &&
                        mealStats.duration != Duration.zero) ...[
                      const SizedBox(
                        height: AppPadding.tiny,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.blur_linear),
                          const SizedBox(
                            width: AppPadding.tiny,
                          ),
                          Flexible(
                            child: Text(
                              "${context.translate.mealCompleteAmountConsumed} ${amountText[mealStats.amountConsumed!]!}",
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    Text(
                      displaying == BlueDyeProgression.stepThree
                          ? context.translate.stepThreeCompletedText
                          : context.translate.stepOneCompletedText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: AppPadding.medium,
            ),
            if (next != null)
              Center(
                child: FilledButton(
                  onPressed: () {
                    next!();
                  },
                  child: Text(context.translate.nextButton),
                ),
              ),
            const SizedBox(
              height: AppPadding.xl,
            ),
          ],
        ),
      ),
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

/// Feeding method options for the blue dye test
enum FeedingMethod {
  oral,
  tubeFed;
  /*Blue Formula (for tube feeding)
 •  • Blue Muffins (for oral feeding) */

  String toDisplayString(BuildContext context) {
    switch (this) {
      case FeedingMethod.oral:
        return "Blue Muffins (for oral feeding)";
      case FeedingMethod.tubeFed:
        return "Blue Formula (for tube feeding)";
    }
  }
}

class _AmountConsumedEntryState extends ConsumerState<AmountConsumedEntry> {
  AmountConsumed? value;
  FeedingMethod? feedingMethod;
  DateTime? tubeFeedEndTime;

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
      AmountConsumed.halfOrLess: context.translate.amountConsumedHalfOrLess,
      AmountConsumed.half: context.translate.amountConsumedHalf,
      AmountConsumed.moreThanHalf: context.translate.amountConsumedHalfOrMore,
      AmountConsumed.all: context.translate.amountConsumedAll,
    };

    final Color cardColor = ElevationOverlay.applySurfaceTint(
        Theme.of(context).cardColor,
        Theme.of(context).colorScheme.surfaceTint,
        3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stage == BlueDyeProgression.stepOne
              ? context.translate.studyStepOneExplanationTitle
              : context.translate.studyStepThreeExplanationTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        // Feeding method selection
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.small),
                color: cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How was the blue dye meal administered?",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: AppPadding.small),
                    RadioGroup<FeedingMethod>(
                      groupValue: feedingMethod,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() {
                          feedingMethod =
                              feedingMethod == newValue ? null : newValue;
                          // Reset other values when switching
                          value = null;
                          tubeFeedEndTime = null;
                        });
                      },
                      child: Column(
                        children: FeedingMethod.values.map((method) {
                          return RadioListTile<FeedingMethod>(
                            title: Text(method.toDisplayString(context)),
                            value: method,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.medium),
        // Show appropriate flow based on feeding method
        if (feedingMethod == FeedingMethod.tubeFed)
          _buildTubeFedFlow(context, testsState, cardColor)
        else if (feedingMethod == FeedingMethod.oral)
          _buildOralFlow(context, testsState, cardColor, amountText),
        const SizedBox(
          height: AppPadding.xl,
        ),
      ],
    );
  }

  /// Simplified tube-fed flow - just capture end time
  Widget _buildTubeFedFlow(
      BuildContext context, BlueDyeState? testsState, Color cardColor) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
        child: Opacity(
          opacity: isLoading ? 0.6 : 1,
          child: IgnorePointer(
            ignoring: isLoading,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.small),
                color: cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tube Feeding Complete",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: AppPadding.small),
                    Text(
                      "Confirm that the feeding with blue dye has finished.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppPadding.medium),
                    // End time picker
                    Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: AppPadding.small),
                        Expanded(
                          child: Text(
                            "Feeding ended at:",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                  tubeFeedEndTime ?? now),
                            );
                            if (picked != null) {
                              setState(() {
                                tubeFeedEndTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(
                            tubeFeedEndTime != null
                                ? TimeOfDay.fromDateTime(tubeFeedEndTime!)
                                    .format(context)
                                : "Select time",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.small),
                    // Use current time button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            tubeFeedEndTime = DateTime.now();
                          });
                        },
                        icon: const Icon(Icons.schedule),
                        label: const Text("Use current time"),
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    // Submit button
                    Center(
                      child: FilledButton(
                        onPressed: tubeFeedEndTime != null && !isLoading
                            ? () => _nextTubeFed(testsState)
                            : null,
                        child: Text(context.translate.nextButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Original oral feeding flow
  Widget _buildOralFlow(BuildContext context, BlueDyeState? testsState,
      Color cardColor, Map<AmountConsumed, String> amountText) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
        child: Opacity(
          opacity: isLoading ? 0.6 : 1,
          child: IgnorePointer(
            ignoring: isLoading,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.small),
                color: cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  children: [
                    Text(
                      context.translate.amountConsumedQuestion,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    RadioGroup<AmountConsumed>(
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
                      },
                      child: Column(
                        children: amountText.keys.map<Widget>((amount) {
                          return RadioListTile<AmountConsumed>(
                            title: Text(amountText[amount]!),
                            value: amount,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(
                      height: AppPadding.small,
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
                        context.translate.amountConsumedUnable,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    FilledButton(
                      onPressed: value != null && !isLoading
                          ? () {
                              _next(testsState);
                            }
                          : null,
                      child: Text(context.translate.nextButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle tube-fed submission - set finishedEating to zero, amountConsumed to all
  Future<void> _nextTubeFed(BlueDyeState? state) async {
    if (state == null || tubeFeedEndTime == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final test = await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>();

    if (test != null) {
      final result = await test.setTestState(state.copyWith(
        amountConsumed: AmountConsumed.all,
        finishedEating: Duration.zero,
        finishedEatingTime: tubeFeedEndTime,
      ));
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        result.handle(context);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Handle oral feeding submission (original flow)
  Future<void> _next(BlueDyeState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
    }
    setState(() {
      isLoading = true;
    });
    final test = await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>();

    if (test != null) {
      final result =
          await test.setTestState(state!.copyWith(amountConsumed: value));
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        result.handle(context);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

class MealStatsEntry extends ConsumerStatefulWidget {
  final BlueDyeProgression clicked;

  const MealStatsEntry({required this.clicked, super.key});

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

  final RestorableEnumN<AmountConsumed> amountConsumed =
      RestorableEnumN(null, values: AmountConsumed.values);

  final RestorableEnumN<MealTime> mealTime =
      RestorableEnumN(null, values: MealTime.mealTimes);

  final RestorableBoolN completedFast = RestorableBoolN(null);

  final RestorableEnumN<FeedingMethod> feedingMethod =
      RestorableEnumN(null, values: FeedingMethod.values);

  // Storing as ISO string because RestorableDateTimeN is not standard
  final RestorableStringN tubeFeedEndTime = RestorableStringN(null);

  @override
  Widget build(BuildContext context) {
    final Widget transitLabel = Text(
      widget.clicked.value < 2
          ? context.translate.transitOneLabel
          : context.translate.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    final BlueDyeState? testsState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));

    if (progress.isLoading) return const LoadingWidget();

    final Color activeCard =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final Color disabledColor = Theme.of(context).disabledColor;

    void onFastTap(bool? state) {
      setState(() {
        completedFast.value = state;
        if (mealTimeQuestionKey.currentContext != null && state != null) {
          Scrollable.ensureVisible(
            mealTimeQuestionKey.currentContext!,
            duration: Durations.medium1,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cardLayout
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [transitLabel, const BlueMealInfoButton()],
                ),
              )
            : const Center(child: BlueMealInfoButton()),
        const SizedBox(
          height: AppPadding.medium,
        ),
        // Feeding Method Selection
        AdaptiveCardLayout(
          cardColor: activeCard,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What type of blue meal is being used?",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppPadding.small),
                RadioGroup<FeedingMethod>(
                  groupValue: feedingMethod.value,
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    setState(() {
                      if (feedingMethod.value != newValue) {
                        feedingMethod.value = newValue;
                        // Reset other values when switching
                        amountConsumed.value = null;
                        mealTime.value = null;
                        completedFast.value = null;
                        tubeFeedEndTime.value = null;
                      } else {
                        feedingMethod.value = null;
                      }
                    });
                  },
                  child: Column(
                    children: FeedingMethod.values.map((method) {
                      return RadioListTile<FeedingMethod>(
                        title: Text(method.toDisplayString(context)),
                        value: method,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppPadding.medium),

        // Tube Fed Flow
        if (feedingMethod.value == FeedingMethod.tubeFed) ...[
          AdaptiveCardLayout(
            cardColor: activeCard,
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tube Feeding Complete",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    "Confirm that the feeding with blue dye has finished.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppPadding.medium),
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: AppPadding.small),
                      Expanded(
                        child: Text(
                          "Feeding ended at:",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          DateTime initial = now;
                          if (tubeFeedEndTime.value != null) {
                            initial = DateTime.parse(tubeFeedEndTime.value!);
                          }
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(initial),
                          );
                          if (picked != null) {
                            setState(() {
                              final newDate = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                picked.hour,
                                picked.minute,
                              );
                              tubeFeedEndTime.value = newDate.toIso8601String();
                            });
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(
                          tubeFeedEndTime.value != null
                              ? TimeOfDay.fromDateTime(
                                      DateTime.parse(tubeFeedEndTime.value!))
                                  .format(context)
                              : "Select time",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          tubeFeedEndTime.value =
                              DateTime.now().toIso8601String();
                        });
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text("Use current time"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          Center(
            child: FilledButton(
              onPressed: tubeFeedEndTime.value != null && !isLoading
                  ? () => _nextTubeFed(testsState)
                  : null,
              child: Text(context.translate.nextButton),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
        ],

        // Oral Flow
        if (feedingMethod.value == FeedingMethod.oral) ...[
          AdaptiveCardLayout(
            key: fastQuestionKey,
            cardColor: activeCard,
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!cardLayout) ...[
                    Center(
                      child: transitLabel,
                    ),
                    const Divider(),
                  ],
                  Text(
                    context.translate.blueMealFastHeader,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  RichText(
                    text: TextSpan(
                      text: '* ',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                      children: [
                        TextSpan(
                            text: context.translate.blueMealFastQuestion,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: AppPadding.small,
                  ),
                  RadioGroup<bool>(
                    groupValue: completedFast.value,
                    onChanged: (selected) {
                      if (selected == null) return;
                      onFastTap(
                          completedFast.value == selected ? null : selected);
                    },
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: Breakpoint.tiny.value),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              onFastTap(
                                  completedFast.value == true ? null : true);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Radio<bool>(
                                  value: true,
                                ),
                                const SizedBox(
                                  width: AppPadding.tiny,
                                ),
                                Text(context.translate.blueQuestionYes),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              onFastTap(
                                  completedFast.value == false ? null : false);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Radio<bool>(
                                  value: false,
                                ),
                                const SizedBox(
                                  width: AppPadding.tiny,
                                ),
                                Text(context.translate.blueQuestionNo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  LabeledList(
                    strings: [
                      context.translate.blueMealFastInstructionLineOne,
                      context.translate.blueMealFastInstructionLineTwo,
                      context.translate.blueMealFastInstructionLineThree
                    ],
                    highlight: false,
                    mark: (index) => '${index + 1}.',
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: AppPadding.medium,
          ),
          IgnorePointer(
            ignoring: completedFast.value == null || !completedFast.value!,
            child: AdaptiveCardLayout(
              key: mealTimeQuestionKey,
              cardColor: completedFast.value == null || !completedFast.value!
                  ? disabledColor
                  : activeCard,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.blueMealDurationTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.translate.blueMealDurationQuestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    RadioGroup<MealTime>(
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        if (newValue == mealTime.value) {
                          setState(() {
                            mealTime.value = null;
                          });
                        } else {
                          setState(() {
                            mealTime.value = newValue;
                          });
                        }
                        if (mealAmountConsumedKey.currentContext != null &&
                            mealTime.value != null) {
                          Scrollable.ensureVisible(
                            mealAmountConsumedKey.currentContext!,
                            duration: Durations.medium1,
                            alignmentPolicy:
                                ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                          );
                        }
                      },
                      groupValue: mealTime.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...MealTime.mealTimes.map<Widget>((amount) {
                            return RadioListTile<MealTime>(
                              title: Text(amount.value),
                              value: amount,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: AppPadding.medium,
          ),
          IgnorePointer(
            ignoring: mealTime.value == null && (completedFast.value ?? false),
            child: AdaptiveCardLayout(
              key: mealAmountConsumedKey,
              cardColor: mealTime.value == null ? disabledColor : activeCard,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.blueMealAmountConsumedTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.translate.amountConsumedQuestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    RadioGroup<AmountConsumed>(
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        if (newValue == amountConsumed.value) {
                          setState(() {
                            amountConsumed.value = null;
                          });
                        } else {
                          setState(() {
                            amountConsumed.value = newValue;
                          });
                        }
                        Scrollable.ensureVisible(context,
                            duration: Durations.medium1,
                            alignmentPolicy:
                                ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
                      },
                      groupValue: amountConsumed.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: AmountConsumed.values.map<Widget>((amount) {
                          return RadioListTile<AmountConsumed>(
                            title: Text(amount.toString()),
                            value: amount,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: AppPadding.small,
          ),
          Center(
            child: FilledButton(
              onPressed: mealTime.value != null &&
                      amountConsumed.value != null &&
                      (completedFast.value ?? false)
                  ? () {
                      _next(testsState);
                    }
                  : null,
              child: Text(context.translate.nextButton),
            ),
          ),
          const SizedBox(
            height: AppPadding.xl,
          ),
        ],
      ],
    );
  }

  Future<void> _nextTubeFed(BlueDyeState? state) async {
    if (state == null || tubeFeedEndTime.value == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final test = await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>();

    if (test != null) {
      final result = await test.setTestState(state.copyWith(
        amountConsumed: AmountConsumed.all,
        finishedEating: Duration.zero,
        finishedEatingTime: DateTime.parse(tubeFeedEndTime.value!),
      ));
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        result.handle(context);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _next(BlueDyeState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
    }
    setState(() {
      isLoading = true;
    });
    final test = await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>();

    if (test != null) {
      final result = await test.setTestState(state!.copyWith(
          amountConsumed: amountConsumed.value,
          finishedEatingTime: DateTime.now(),
          finishedEating: mealTime.value!.toDuration()));

      if (mounted) {
        setState(() {
          isLoading = false;
        });
        result.handle(context);
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
  String? get restorationId => "meal-stats-entry";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(amountConsumed, "amount-consumed-entry");
    registerForRestoration(mealTime, "meal-time-entry");
    registerForRestoration(completedFast, "fasted-entry");
    registerForRestoration(feedingMethod, "feeding-method-entry");
    registerForRestoration(tubeFeedEndTime, "tube-feed-end-time-entry");
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

  static MealTime? fromDuration(Duration duration) {
    if (duration == const Duration(minutes: 15)) {
      return MealTime.fifteenOrLess;
    }
    if (duration == const Duration(minutes: 22, seconds: 30)) {
      return MealTime.fifteenToThrity;
    }
    if (duration == const Duration(minutes: 45)) {
      return MealTime.thirtyToHour;
    }
    if (duration == const Duration(hours: 1)) {
      return MealTime.hourOrMore;
    }
    return null;
  }

  Duration toDuration() {
    switch (this) {
      case MealTime.fifteenOrLess:
        return const Duration(minutes: 15);
      case MealTime.fifteenToThrity:
        return const Duration(minutes: 22, seconds: 30);
      case MealTime.thirtyToHour:
        return const Duration(minutes: 45);
      case MealTime.hourOrMore:
        return const Duration(hours: 1);
    }
  }

  final String value;

  const MealTime(this.value);
}
