import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/UI/Record/TestScreen/tube_feeding_start_field.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class MealFinishedDisplay extends ConsumerWidget {
  final Function? next;

  final BlueDyeProgression displaying;

  const MealFinishedDisplay({this.next, required this.displaying, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BlueDyeTestProgress> progressAsync = ref.watch(
      blueDyeTestProgressProvider,
    );
    final AsyncValue<BlueDyeMealState> mealStateAsync = ref.watch(
      blueDyeMealStateProvider,
    );

    return progressAsync.when(
      data: (progress) => mealStateAsync.when(
        data: (mealState) => _buildLoaded(context, progress, mealState),
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => TestAsyncError(error: error),
      ),
      loading: () => const LoadingWidget(),
      error: (error, stackTrace) => TestAsyncError(error: error),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    BlueDyeTestProgress progress,
    BlueDyeMealState mealState,
  ) {
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    final Color cardColor = Theme.of(context).primaryColor
        .withValues(alpha: 0.2);
    final BlueDyeProgression progression =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

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
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );

    BlueMealStats getMealStats() {
      final bool testOngoing =
          (progress.testIteration) < 2 || (progress.stage.testInProgress);
      if (testOngoing &&
          ((displaying == BlueDyeProgression.stepOne &&
                  progression == BlueDyeProgression.stepTwo) ||
              (displaying == BlueDyeProgression.stepFour &&
                  progression == BlueDyeProgression.stepFive))) {
        return BlueMealStats(
          start: mealState.startTime,
          duration: mealState.finishedEating,
          amountConsumed: mealState.amountConsumed,
        );
      }
      final List<TestDate> dates = progress.orderedTests;

      if (dates.isEmpty) {
        return const BlueMealStats(
          start: null,
          duration: null,
          amountConsumed: null,
        );
      }
      if (displaying == BlueDyeProgression.stepOne) {
        return BlueMealStats(
          start: dates[0].test.startEating,
          duration: dates[0].test.eatingDuration,
          amountConsumed: dates[0].test.amountConsumed,
        );
      }
      if (dates.length < 2) {
        return const BlueMealStats(
          start: null,
          duration: null,
          amountConsumed: null,
        );
      }
      return BlueMealStats(
        start: dates[1].test.startEating,
        duration: dates[1].test.eatingDuration,
        amountConsumed: dates[1].test.amountConsumed,
      );
    }

    final BlueMealStats mealStats = getMealStats();
    final double iconSize = Theme.of(context).iconTheme.size ?? 20;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardLayout ? AppPadding.xl : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: cardLayout ? Breakpoint.small.value : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: AppPadding.small),
            cardLayout
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Breakpoint.small.value,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [transitLabel, const BlueMealInfoButton()],
                    ),
                  )
                : const Center(child: BlueMealInfoButton()),
            const SizedBox(height: AppPadding.small),
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
                      mealStats.duration == Duration.zero
                          ? 'Tube feeding'
                          : context.translate.mealCompleteTitle,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (mealStats.start != null) ...[
                      const SizedBox(height: AppPadding.small),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.alarm),
                          const SizedBox(width: AppPadding.tiny),
                          if (mealStats.start != null)
                            Text(
                              context.translate.mealCompleteStartTime(
                                mealStats.start!,
                                mealStats.start!,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (mealStats.duration != null &&
                        mealStats.duration != Duration.zero) ...[
                      const SizedBox(height: AppPadding.small),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'packages/stripes_ui/assets/svg/muffin_icon.svg',
                            width: iconSize,
                            height: iconSize,
                          ),
                          const SizedBox(width: AppPadding.tiny),
                          if (mealStats.duration != null)
                            Text(
                              "${context.translate.mealCompleteDuration} ${MealTime.fromDuration(mealStats.duration!)?.value ?? from(mealStats.duration!, context)}",
                            ),
                        ],
                      ),
                    ],
                    if (mealStats.duration == Duration.zero) ...[
                      const SizedBox(height: AppPadding.small),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'packages/stripes_ui/assets/svg/muffin_icon.svg',
                            width: iconSize,
                            height: iconSize,
                          ),
                          const SizedBox(width: AppPadding.tiny),
                          const Text("Tube Fed"),
                        ],
                      ),
                    ],
                    if (mealStats.amountConsumed != null &&
                        mealStats.duration != Duration.zero) ...[
                      const SizedBox(height: AppPadding.tiny),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.blur_linear),
                          const SizedBox(width: AppPadding.tiny),
                          Flexible(
                            child: Text(
                              "${context.translate.mealCompleteAmountConsumed} ${amountText[mealStats.amountConsumed!]!}",
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppPadding.small),
                    Text(
                      displaying == BlueDyeProgression.stepFour
                          ? context.translate.stepThreeCompletedText
                          : context.translate.stepOneCompletedText,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.small),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            if (next != null)
              Center(
                child: FilledButton(
                  onPressed: () {
                    next!();
                  },
                  child: Text(context.translate.nextButton),
                ),
              ),
            const SizedBox(height: AppPadding.xl),
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

  const BlueMealStats({
    required this.start,
    required this.duration,
    required this.amountConsumed,
  });
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
  DateTime? tubeFeedStartTime;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeTestProgress> progressAsync = ref.watch(
      blueDyeTestProgressProvider,
    );
    final AsyncValue<BlueDyeMealState> mealStateAsync = ref.watch(
      blueDyeMealStateProvider,
    );

    return progressAsync.when(
      data: (progress) => mealStateAsync.when(
        data: (mealState) => _buildLoaded(context, progress, mealState),
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => TestAsyncError(error: error),
      ),
      loading: () => const LoadingWidget(),
      error: (error, stackTrace) => TestAsyncError(error: error),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    BlueDyeTestProgress progress,
    BlueDyeMealState mealState,
  ) {
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.halfOrLess: context.translate.amountConsumedHalfOrLess,
      AmountConsumed.half: context.translate.amountConsumedHalf,
      AmountConsumed.moreThanHalf: context.translate.amountConsumedHalfOrMore,
      AmountConsumed.all: context.translate.amountConsumedAll,
    };

    final Color cardColor = ElevationOverlay.applySurfaceTint(
      Theme.of(context).cardColor,
      Theme.of(context).colorScheme.surfaceTint,
      3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stage == BlueDyeProgression.stepOne
              ? context.translate.studyStepOneExplanationTitle
              : context.translate.studyStepThreeExplanationTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.small),
        // Feeding method selection
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
            child: Material(
              borderRadius: BorderRadius.circular(AppRounding.small),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How was the blue dye meal administered?",
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: AppPadding.small),
                    RadioGroup<FeedingMethod>(
                      groupValue: feedingMethod,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() {
                          feedingMethod = feedingMethod == newValue
                              ? null
                              : newValue;
                          // Reset other values when switching
                          value = null;
                          tubeFeedStartTime = null;
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
          _buildTubeFedFlow(context, mealState, cardColor)
        else if (feedingMethod == FeedingMethod.oral)
          _buildOralFlow(context, mealState, cardColor, amountText),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }

  /// Tube-fed flow records the start without waiting for feeding to finish.
  Widget _buildTubeFedFlow(
    BuildContext context,
    BlueDyeMealState? testsState,
    Color cardColor,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
        child: Opacity(
          opacity: isLoading ? 0.6 : 1,
          child: IgnorePointer(
            ignoring: isLoading,
            child: Material(
              borderRadius: BorderRadius.circular(AppRounding.small),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TubeFeedingStartField(
                      start: tubeFeedStartTime,
                      enabled: !isLoading,
                      onChanged: (start) => setState(() {
                        tubeFeedStartTime = start;
                      }),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    // Submit button
                    Center(
                      child: FilledButton(
                        onPressed: tubeFeedStartTime != null && !isLoading
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
  Widget _buildOralFlow(
    BuildContext context,
    BlueDyeMealState? testsState,
    Color cardColor,
    Map<AmountConsumed, String> amountText,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
        child: Opacity(
          opacity: isLoading ? 0.6 : 1,
          child: IgnorePointer(
            ignoring: isLoading,
            child: Material(
              borderRadius: BorderRadius.circular(AppRounding.small),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  children: [
                    Text(
                      context.translate.amountConsumedQuestion,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: AppPadding.small),
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
                    const SizedBox(height: AppPadding.small),
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
                        style: Theme.of(context).textTheme.titleMedium
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

  /// Start tracking from the recorded feeding start, with no assumed end.
  Future<void> _nextTubeFed(BlueDyeMealState? state) async {
    if (state == null || tubeFeedStartTime == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final newMealState = state.withTubeFeedingStart(tubeFeedStartTime!);
      final updated = protocol.copyWith(
        testContext: newMealState.replaceInContext(protocol.testContext),
      );
      await repo.updateProtocol(updated);
      if (isBlueDyeMealStageId(protocol.currentStageId)) {
        await repo.advanceStage(activeTestId: protocol.id);
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _next(BlueDyeMealState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final newMealState = state.copyWith(amountConsumed: value);
      final updated = protocol.copyWith(
        testContext: newMealState.replaceInContext(protocol.testContext),
      );
      await repo.updateProtocol(updated);
      if (isBlueDyeMealStageId(protocol.currentStageId)) {
        await repo.advanceStage(activeTestId: protocol.id);
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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

  final feedInstructionsKey = GlobalKey();
  final tubeFeedingQuestionKey = GlobalKey();
  final nextActionKey = GlobalKey();

  void _scrollToQuestion(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = key.currentContext;
      if (target == null) return;
      final media = MediaQuery.of(context);
      Scrollable.ensureVisible(
        target,
        alignment: 0.05,
        duration: media.disableAnimations || media.accessibleNavigation
            ? Duration.zero
            : Durations.medium1,
        curve: Curves.easeInOut,
      );
    });
  }

  bool isLoading = false;

  final RestorableEnumN<AmountConsumed> amountConsumed = RestorableEnumN(
    null,
    values: AmountConsumed.values,
  );

  final RestorableEnumN<MealTime> mealTime = RestorableEnumN(
    null,
    values: MealTime.mealTimes,
  );

  final RestorableBoolN completedFast = RestorableBoolN(null);

  final RestorableEnumN<FeedingMethod> feedingMethod = RestorableEnumN(
    null,
    values: FeedingMethod.values,
  );

  // Storing as ISO string because RestorableDateTimeN is not standard
  final RestorableStringN tubeFeedStartTime = RestorableStringN(null);

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(blueDyeMealStateProvider)
        .when(
          data: (mealState) => _buildLoaded(context, mealState),
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Widget _buildLoaded(BuildContext context, BlueDyeMealState mealState) {
    if (ref.watch(configProvider).betaUi.blueDyeTest) {
      return _buildRedesigned(context, mealState);
    }

    final Widget transitLabel = Text(
      widget.clicked.value < 2
          ? context.translate.transitOneLabel
          : context.translate.transitTwoLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    final Color activeCard = Theme.of(context).primaryColor
        .withValues(alpha: 0.2);
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
        const SizedBox(height: AppPadding.medium),
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
                  style: Theme.of(context).textTheme.bodyMedium
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
                        tubeFeedStartTime.value = null;
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
              child: TubeFeedingStartField(
                start: tubeFeedStartTime.value == null
                    ? null
                    : DateTime.parse(tubeFeedStartTime.value!),
                enabled: !isLoading,
                onChanged: (start) => setState(() {
                  tubeFeedStartTime.value = start.toUtc().toIso8601String();
                }),
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          Center(
            child: FilledButton(
              onPressed: tubeFeedStartTime.value != null && !isLoading
                  ? () => _nextTubeFed(mealState)
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
                    Center(child: transitLabel),
                    const Divider(),
                  ],
                  Text(
                    context.translate.blueMealFastHeader,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  RichText(
                    text: TextSpan(
                      text: '* ',
                      style: const TextStyle(color: Colors.red),
                      children: [
                        TextSpan(
                          text: context.translate.blueMealFastQuestion,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.small),
                  RadioGroup<bool>(
                    groupValue: completedFast.value,
                    onChanged: (selected) {
                      if (selected == null) return;
                      onFastTap(
                        completedFast.value == selected ? null : selected,
                      );
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Breakpoint.tiny.value,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              onFastTap(
                                completedFast.value == true ? null : true,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Radio<bool>(value: true),
                                const SizedBox(width: AppPadding.tiny),
                                Text(context.translate.blueQuestionYes),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              onFastTap(
                                completedFast.value == false ? null : false,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Radio<bool>(value: false),
                                const SizedBox(width: AppPadding.tiny),
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
                      context.translate.blueMealFastInstructionLineThree,
                    ],
                    highlight: false,
                    mark: (index) => '${index + 1}.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
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
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.translate.blueMealDurationQuestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppPadding.small),
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
          const SizedBox(height: AppPadding.medium),
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
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.translate.amountConsumedQuestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppPadding.small),
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
                        Scrollable.ensureVisible(
                          context,
                          duration: Durations.medium1,
                          alignmentPolicy:
                              ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                        );
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
          const SizedBox(height: AppPadding.small),
          Center(
            child: FilledButton(
              onPressed:
                  mealTime.value != null &&
                      amountConsumed.value != null &&
                      (completedFast.value ?? false)
                  ? () {
                      _next(mealState);
                    }
                  : null,
              child: Text(context.translate.nextButton),
            ),
          ),
          const SizedBox(height: AppPadding.xl),
        ],
      ],
    );
  }

  Widget _buildRedesigned(BuildContext context, BlueDyeMealState state) {
    final s = context.translate;
    final oral = feedingMethod.value == FeedingMethod.oral;
    final tube = feedingMethod.value == FeedingMethod.tubeFed;
    final canAnswer = oral && completedFast.value == true && !isLoading;
    final valid = tube
        ? tubeFeedStartTime.value != null
        : canAnswer && amountConsumed.value != null && mealTime.value != null;
    final amountLabels = {
      AmountConsumed.halfOrLess: s.amountConsumedHalfOrLess,
      AmountConsumed.half: s.amountConsumedHalf,
      AmountConsumed.moreThanHalf: s.amountConsumedHalfOrMore,
      AmountConsumed.all: s.amountConsumedAll,
      AmountConsumed.undetermined: s.amountConsumedUnable,
    };
    final durationLabels = [
      s.blueMealDurationAnswerOne,
      s.blueMealDurationAnswerTwo,
      s.blueMealDurationAnswerThree,
      s.blueMealDurationAnswerFour,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlueDyeStudyCard(
          title: s.blueMealFeedingMethod,
          child: Column(
            children: [
              for (final method in FeedingMethod.values)
                BlueDyeStudyChoice<FeedingMethod>(
                  value: method,
                  selected: feedingMethod.value,
                  label: method.toDisplayString(context),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (feedingMethod.value == value) return;
                          setState(() {
                            feedingMethod.value = value;
                            amountConsumed.value = null;
                            mealTime.value = null;
                            completedFast.value = null;
                            tubeFeedStartTime.value = null;
                          });
                          _scrollToQuestion(
                            value == FeedingMethod.tubeFed
                                ? tubeFeedingQuestionKey
                                : fastQuestionKey,
                          );
                        },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tube)
          BlueDyeStudyCard(
            key: tubeFeedingQuestionKey,
            child: TubeFeedingStartField(
              start: tubeFeedStartTime.value == null
                  ? null
                  : DateTime.parse(tubeFeedStartTime.value!),
              enabled: !isLoading,
              onChanged: (value) {
                setState(
                  () =>
                      tubeFeedStartTime.value = value.toUtc().toIso8601String(),
                );
                _scrollToQuestion(nextActionKey);
              },
            ),
          )
        else ...[
          BlueDyeStudyCard(
            key: fastQuestionKey,
            title: s.blueMealFastTitle,
            description: s.blueMealFastQuestion,
            enabled: oral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final answer in [true, false])
                      Semantics(
                        selected: completedFast.value == answer,
                        child: OutlinedButton(
                          onPressed: !oral || isLoading
                              ? null
                              : () {
                                  setState(() => completedFast.value = answer);
                                  if (answer) {
                                    _scrollToQuestion(feedInstructionsKey);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(100, 52),
                            foregroundColor: completedFast.value == answer
                                ? BlueDyeStudyStyle.surface(context)
                                : BlueDyeStudyStyle.ink(context),
                            backgroundColor: completedFast.value == answer
                                ? BlueDyeStudyStyle.ink(context)
                                : null,
                            side: BorderSide(
                              color: BlueDyeStudyStyle.outline(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            answer ? s.blueQuestionYes : s.blueQuestionNo,
                          ),
                        ),
                      ),
                  ],
                ),
                if (completedFast.value == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      s.blueMealFastRequired,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlueDyeStudyCard(
            key: feedInstructionsKey,
            title: s.blueMealFeedTitle,
            enabled: canAnswer,
            child: Text(
              '1. ${s.blueMealFastInstructionLineOne}\n2. ${s.blueMealFastInstructionLineTwo}\n3. ${s.blueMealFastInstructionLineThree}',
            ),
          ),
          const SizedBox(height: 16),
          BlueDyeStudyCard(
            key: mealAmountConsumedKey,
            title: s.blueMealAmountTitle,
            description: s.amountConsumedQuestion,
            enabled: canAnswer,
            child: Column(
              children: [
                for (final amount in amountLabels.entries)
                  BlueDyeStudyChoice<AmountConsumed>(
                    value: amount.key,
                    selected: amountConsumed.value,
                    label: amount.value,
                    onChanged: canAnswer
                        ? (value) {
                            setState(() => amountConsumed.value = value);
                            _scrollToQuestion(
                              mealTime.value == null
                                  ? mealTimeQuestionKey
                                  : nextActionKey,
                            );
                          }
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlueDyeStudyCard(
            key: mealTimeQuestionKey,
            title: s.blueMealTimeTitle,
            description: s.blueMealDurationQuestion,
            enabled: canAnswer,
            child: Column(
              children: [
                for (var i = 0; i < MealTime.mealTimes.length; i++)
                  BlueDyeStudyChoice<MealTime>(
                    value: MealTime.mealTimes[i],
                    selected: mealTime.value,
                    label: durationLabels[i],
                    onChanged: canAnswer
                        ? (value) {
                            setState(() => mealTime.value = value);
                            _scrollToQuestion(
                              amountConsumed.value == null
                                  ? mealAmountConsumedKey
                                  : nextActionKey,
                            );
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        BlueDyeStudyAction(
          key: nextActionKey,
          label: s.blueMealNextStep(
            widget.clicked == BlueDyeProgression.stepOne ? 2 : 4,
          ),
          loading: isLoading,
          onPressed: valid ? () => _saveRedesigned(state, tube: tube) : null,
        ),
      ],
    );
  }

  Future<void> _saveRedesigned(
    BlueDyeMealState state, {
    required bool tube,
  }) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final protocol = await ref.read(activeProtocolProvider.future);
      final repo = await ref.read(testProvider.future);
      if (protocol == null || repo == null) {
        throw StateError('Study unavailable');
      }
      final updatedState = tube
          ? state.withTubeFeedingStart(DateTime.parse(tubeFeedStartTime.value!))
          : state.copyWith(
              amountConsumed: amountConsumed.value,
              finishedEatingTime: DateTime.now(),
              finishedEating: mealTime.value!.toDuration(),
            );
      await repo.updateProtocol(
        protocol.copyWith(
          testContext: updatedState.replaceInContext(protocol.testContext),
        ),
      );
      if (isBlueDyeMealStageId(protocol.currentStageId)) {
        await repo.advanceStage(activeTestId: protocol.id);
      }
    } catch (_) {
      if (mounted) showSnack(context, context.translate.blueMealSaveError);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _nextTubeFed(BlueDyeMealState? state) async {
    if (state == null || tubeFeedStartTime.value == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final newMealState = state.withTubeFeedingStart(
        DateTime.parse(tubeFeedStartTime.value!),
      );
      final updated = protocol.copyWith(
        testContext: newMealState.replaceInContext(protocol.testContext),
      );
      await repo.updateProtocol(updated);
      if (isBlueDyeMealStageId(protocol.currentStageId)) {
        await repo.advanceStage(activeTestId: protocol.id);
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _next(BlueDyeMealState? state) async {
    if (state == null) {
      showSnack(context, "Could not go next");
      return;
    }
    setState(() {
      isLoading = true;
    });
    final protocol = await ref.read(activeProtocolProvider.future);
    final repo = await ref.read(testProvider.future);
    if (protocol != null && repo != null) {
      final newMealState = state.copyWith(
        amountConsumed: amountConsumed.value,
        finishedEatingTime: DateTime.now(),
        finishedEating: mealTime.value!.toDuration(),
      );
      final updated = protocol.copyWith(
        testContext: newMealState.replaceInContext(protocol.testContext),
      );
      await repo.updateProtocol(updated);
      if (isBlueDyeMealStageId(protocol.currentStageId)) {
        await repo.advanceStage(activeTestId: protocol.id);
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
    registerForRestoration(tubeFeedStartTime, "tube-feed-start-time-entry");
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
    MealTime.hourOrMore,
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
