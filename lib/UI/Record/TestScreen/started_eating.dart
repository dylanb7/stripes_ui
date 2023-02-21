import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class StartedEating extends ConsumerWidget {
  const StartedEating({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime start =
        ref.read(testHolderProvider).obj?.start ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 8.0,
        ),
        const Text(
          'Time since Blue Meal started:',
          style: lightBackgroundHeaderStyle,
        ),
        const SizedBox(
          height: 8.0,
        ),
        TimerWidget(start: start),
        const SizedBox(
          height: 8.0,
        ),
        Center(
          child: SizedBox(
            width: 250,
            child: StripesRoundedButton(
                text: 'Finished Blue Meal',
                light: true,
                onClick: () {
                  ref
                      .read(testHolderProvider.notifier)
                      .setDuration(DateTime.now().difference(start));
                }),
          ),
        ),
      ],
    );
  }
}
