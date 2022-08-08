import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class StartedEating extends StatelessWidget {
  final DateTime start;
  final WidgetRef ref;
  const StartedEating({required this.start, required this.ref, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
              text: 'Start Date: ',
              style:
                  lightBackgroundHeaderStyle.copyWith(color: lightIconButton),
              children: [
                TextSpan(
                    text: dateToMDY(start), style: lightBackgroundHeaderStyle)
              ]),
        ),
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
        StripesRoundedButton(
            text: 'Finished Blue Meal',
            light: false,
            onClick: () {
              ref
                  .read(testHolderProvider.notifier)
                  .setDuration(DateTime.now().difference(start));
            }),
      ],
    );
  }
}
