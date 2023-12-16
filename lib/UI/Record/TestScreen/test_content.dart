import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/instructions.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/repos/blue_dye_test_repo.dart';

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
    final BlueDyeObj? blueDyeObj =
        ref.watch(testHolderProvider).getObject<BlueDyeObj>();
    final TestState state =
        blueDyeObj == null ? TestState.initial : stateFromTestOBJ(blueDyeObj);
    final bool isLoading = ref.watch(testLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state.testInProgress
            ? Text(
                AppLocalizations.of(context)!.blueMealStartTime(
                    blueDyeObj!.startTime!, blueDyeObj.startTime!),
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
                          : () async {
                              ref.read(testLoading.notifier).state = true;
                              await ref
                                  .read(testHolderProvider)
                                  .getTest<BlueDyeTest>()
                                  ?.setStart(DateTime.now());
                              ref.read(testLoading.notifier).state = false;
                            },
                      child: isLoading
                          ? const ButtonLoadingIndicator()
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
    final BlueDyeObj? blueDyeObj =
        ref.watch(testHolderProvider).getObject<BlueDyeObj>();
    final bool isStarted = (blueDyeObj == null
            ? TestState.initial
            : stateFromTestOBJ(blueDyeObj)) ==
        TestState.started;
    final DateTime startTime = blueDyeObj!.startTime!;
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
                            .getTest<BlueDyeTest>()
                            ?.finishedEating(
                                DateTime.now().difference(startTime));
                        ref.read(testLoading.notifier).state = false;
                      },
                child: isLoading
                    ? const ButtonLoadingIndicator()
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
                style: lightBackgroundStyle.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              TextSpan(
                text: '\t${from(blueDyeObj.finishedEating!)}',
                style: lightBackgroundStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ])),
      ),
    );
  }
}
