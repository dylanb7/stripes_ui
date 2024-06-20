import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/repos/blue_dye_test_repo.dart';

class MealFinishedDisplay extends ConsumerWidget {
  final Function next;

  final bool isStepThree;

  const MealFinishedDisplay(
      {required this.next, required this.isStepThree, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    final BlueDyeState? testsState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));
    final BlueDyeProgression progression =
        progress.getProgression() ?? BlueDyeProgression.stepOne;
    final bool displayOld =
        progression == BlueDyeProgression.stepThree && !isStepThree;
    DateTime? blueMealStart = displayOld
        ? progress.lastTestCompleted?.test.startEating
        : testsState?.startTime;
    Duration? blueMealDuration = displayOld
        ? progress.lastTestCompleted?.test.eatingDuration
        : testsState?.finishedEating;
    final double iconSize = Theme.of(context).iconTheme.size ?? 20;
    return Column(
      children: [
        Text(
          isStepThree
              ? AppLocalizations.of(context)!.studyStepThreeExplanationTitle
              : AppLocalizations.of(context)!.studyStepOneExplanationTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: ElevationOverlay.applySurfaceTint(
                  Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surfaceTint,
                  3),
              border: Border.all(
                  color: Theme.of(context).primaryColor, width: 2.0)),
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
                const SizedBox(
                  height: 8.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.alarm),
                    const SizedBox(
                      width: 4.0,
                    ),
                    if (blueMealStart != null)
                      Text(AppLocalizations.of(context)!
                          .mealCompleteStartTime(blueMealStart, blueMealStart))
                  ],
                ),
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
                      width: 4.0,
                    ),
                    if (blueMealDuration != null)
                      Text(
                          "${AppLocalizations.of(context)!.mealCompleteDuration} ${from(blueMealDuration, context)}")
                  ],
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Text(
                  isStepThree
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
          child: ElevatedButton(
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
    final BlueDyeTestProgress progress = ref.watch(blueDyeTestProgressProvider);
    final BlueDyeState? testsState = ref.watch(testsHolderProvider
        .select((holder) => holder.valueOrNull?.getTestState<BlueDyeState>()));
    final BlueDyeProgression stage =
        progress.getProgression() ?? BlueDyeProgression.stepOne;

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
        Opacity(
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
                          .bodyMedium
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                            value: value == AmountConsumed.undetermined,
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              if (newValue) {
                                setState(() {
                                  value = AmountConsumed.undetermined;
                                });
                              } else {
                                setState(() {
                                  value = null;
                                });
                              }
                            }),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          AppLocalizations.of(context)!.amountConsumedUnable,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    Center(
                      child: ElevatedButton(
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
                ),
              ),
            ),
          ),
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
    await ref.read(testsHolderProvider.notifier).getTest<BlueDyeTest>().then(
        (test) => test?.setTestState(state!.copyWith(amountConsumed: value)));
    setState(() {
      isLoading = false;
    });
  }
}
