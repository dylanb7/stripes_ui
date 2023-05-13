import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'blue_recordings.dart';

class TestContent extends ConsumerWidget {
  final ExpandibleController expand;

  const TestContent({required this.expand, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestNotifier test = ref.watch(testHolderProvider);
    final TestState state = test.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state.testInProgress
            ? Text(
                AppLocalizations.of(context)!.blueMealStartTime(
                    test.obj!.startTime, test.obj!.startTime),
                textAlign: TextAlign.left,
                style: lightBackgroundHeaderStyle,
              )
            : Center(
                child: SizedBox(
                  width: 250,
                  child: StripesRoundedButton(
                    text: AppLocalizations.of(context)!.blueDyeStart,
                    onClick: () {
                      ref.read(testHolderProvider).setStart(DateTime.now());
                      expand.set(false);
                    },
                    light: true,
                  ),
                ),
              ),
        if (state.testInProgress) const TimerDisplay(),
        if (state == TestState.logs || state == TestState.logsSubmit)
          const BlueRecordings(),
      ],
    );
  }
}

class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestNotifier test = ref.watch(testHolderProvider);
    final bool isStarted = test.state == TestState.started;
    final DateTime startTime = test.obj!.startTime;

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
          TimerWidget(start: startTime),
          Center(
            child: SizedBox(
              width: 250,
              child: StripesRoundedButton(
                  text: AppLocalizations.of(context)!.blueMealFinishedButton,
                  light: true,
                  onClick: () {
                    ref
                        .read(testHolderProvider.notifier)
                        .setDuration(DateTime.now().difference(startTime));
                  }),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.blueMealFinalDurationTag,
            style: lightBackgroundHeaderStyle,
          ),
          const SizedBox(
            width: 8.0,
          ),
          Text(
            from(test.obj!.finishedEating!),
            style: lightBackgroundHeaderStyle.copyWith(color: lightIconButton),
          ),
        ],
      ),
    );
  }
}
