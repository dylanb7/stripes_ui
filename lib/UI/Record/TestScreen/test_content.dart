import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/instructions.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'blue_recordings.dart';

final testLoading = StateProvider<bool>((ref) => false);

class TestContent extends ConsumerStatefulWidget {
  final ExpandibleController expand;

  const TestContent({required this.expand, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => TestContentState();
}

class TestContentState extends ConsumerState<TestContent> {
  @override
  Widget build(BuildContext context) {
    final TestNotifier test = ref.watch(testHolderProvider);
    final TestState state = test.state;
    final bool isLoading = ref.watch(testLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state.testInProgress
            ? Text(
                AppLocalizations.of(context)!.blueMealStartTime(
                    test.obj!.startTime, test.obj!.startTime),
                textAlign: TextAlign.left,
                style: lightBackgroundStyle,
              )
            : Column(children: [
                LabeledList(strings: [
                  AppLocalizations.of(context)!.blueDyeInfoLineOne,
                  AppLocalizations.of(context)!.blueDyeInfoLineTwo,
                  AppLocalizations.of(context)!.blueDyeInfoLineThree,
                  AppLocalizations.of(context)!.blueDyeInfoLineFour
                ], highlight: false),
                const SizedBox(
                  height: 8.0,
                ),
                Center(
                  child: SizedBox(
                    width: 250,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              ref.read(testLoading.notifier).state = true;
                              ref
                                  .read(testHolderProvider)
                                  .setStart(DateTime.now());
                              ref.read(testLoading.notifier).state = false;
                            },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)!.blueDyeStart),
                    ),
                  ),
                )
              ]),
        if (state.testInProgress) const TimerDisplay(),
        if (state == TestState.logs || state == TestState.logsSubmit) ...[
          const BlueRecordings(),
        ],
        if (state.testInProgress)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _cancelTest(context, ref);
                      },
                child: Text(AppLocalizations.of(context)!.blueDyeCancel),
              ),
            ),
          ),
      ],
    );
  }

  _cancelTest(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const OverlayQuery(widget: TestErrorPrevention());
  }
}

class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestNotifier test = ref.watch(testHolderProvider);
    final bool isStarted = test.state == TestState.started;
    final DateTime startTime = test.obj!.startTime;
    final bool isLoading = ref.watch(testLoading);

    if (isStarted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 8.0,
          ),
          Text(
            AppLocalizations.of(context)!.blueMealDurationTag,
            style: lightBackgroundHeaderStyle,
          ),
          Visibility(
              visible: !isLoading,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: TimerWidget(start: startTime)),
          Center(
            child: SizedBox(
              width: 250,
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        ref.read(testLoading.notifier).state = true;
                        await ref
                            .read(testHolderProvider.notifier)
                            .setDuration(DateTime.now().difference(startTime));
                        ref.read(testLoading.notifier).state = false;
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        AppLocalizations.of(context)!.blueMealFinishedButton),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(children: [
              TextSpan(
                text: AppLocalizations.of(context)!.blueMealFinalDurationTag,
                style: lightBackgroundStyle,
              ),
              TextSpan(
                text: '\t${from(test.obj!.finishedEating!)}',
                style: lightBackgroundStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ])),
      ),
    );
  }
}
