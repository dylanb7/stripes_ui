/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'blue_recordings.dart';

final testLoading = StateProvider<bool>((ref) => false);

class TestContent<T extends Test> extends ConsumerStatefulWidget {
  final ExpandibleController expand;

  const TestContent({required this.expand, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => TestContentState<T>();
}

class TestContentState<T extends Test> extends ConsumerState<TestContent> {
  @override
  Widget build(BuildContext context) {
    final BlueDyeObj? blueDyeObj =
        getObject<BlueDyeObj>(ref.watch(testStreamProvider));
    final TestState state =
        blueDyeObj == null ? TestState.initial : stateFromTestOBJ(blueDyeObj);
    final bool isLoading = ref.watch(testLoading);

    return state.testInProgress
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.testInProgress)
                Text(
                  context.translate.blueMealStartTime(
                      blueDyeObj!.startTime!, blueDyeObj.startTime!),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (state.testInProgress) TimerDisplay<T>(),
              if (state == TestState.logs || state == TestState.logsSubmit) ...[
                BlueRecordings<T>(),
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
                      child: Text(context.translate.blueDyeCancel),
                    ),
                  ),
                ),
            ],
          )
        : BlueMealPreStudy(
            onClick: () {
              _startTest(blueDyeObj);
            },
            isLoading: isLoading);
  }

  Future<void> _startTest(BlueDyeObj? blueDyeObj) async {
    ref.read(testLoading.notifier).state = true;
    final DateTime start = DateTime.now();
    final BlueDyeObj newVal = blueDyeObj?.copyWith(
            startTime: start, timerStart: DateTime.now(), pauseTime: null) ??
        BlueDyeObj(
          logs: [],
          startTime: DateTime.now(),
          timerStart: DateTime.now(),
        );
    await getTest(ref.read(testProvider))?.setValue(newVal);
    ref.read(testLoading.notifier).state = false;
  }

  _cancelTest(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const CurrentOverlay(widget: TestErrorPrevention());
  }
}

class TimerDisplay<T extends Test> extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeObj? blueDyeObj =
        getObject<BlueDyeObj>(ref.watch(testStreamProvider));
    final bool isStarted = (blueDyeObj == null
            ? TestState.initial
            : stateFromTestOBJ(blueDyeObj)) ==
        TestState.started;

    final bool isLoading = ref.watch(testLoading);

    if (isStarted) {
      return FutureBuilder<DateTime?>(
          future: startTime,
          builder: (context, start) {
            if (!start.hasData) return const CircularProgressIndicator();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 8.0,
                ),
                Text(
                  context.translate.blueMealDurationTag,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Visibility(
                    visible: !isLoading,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TimerWidget(start: start.data!)),
                Center(
                  child: SizedBox(
                    width: 250,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              ref.read(testLoading.notifier).state = true;
                              final BlueDyeObj newValue = blueDyeObj!.copyWith(
                                  finishedEating:
                                      DateTime.now().difference(start.data!));
                              await getTest<T>(ref.read(testProvider))
                                  ?.setValue(newValue);

                              ref.read(testLoading.notifier).state = false;
                            },
                      child: isLoading
                          ? const ButtonLoadingIndicator()
                          : Text(context.translate
                              .blueMealFinishedButton),
                    ),
                  ),
                ),
              ],
            );
          });
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(children: [
              TextSpan(
                text: context.translate.blueMealFinalDurationTag,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              TextSpan(
                text: '\t${from(blueDyeObj!.finishedEating!, context)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ])),
      ),
    );
  }
}
*/
