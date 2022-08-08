import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class Initial extends StatelessWidget {
  final WidgetRef ref;
  const Initial({required this.ref, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StripesRoundedButton(
          text: 'Begin Blue Dye Test',
          onClick: () {
            ref.read(testHolderProvider).setStart(DateTime.now());
          },
          light: false,
        ),
        const SizedBox(
          height: 12.0,
        ),
        const Text(
          'After starting the test begin eating the Blue Meal',
          style: lightBackgroundStyle,
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          'About Blue Dye Test',
          style: lightBackgroundHeaderStyle.copyWith(color: lightIconButton),
        ),
        const SizedBox(
          height: 12.0,
        ),
        const Text(
          'The blue dye test measures the time it takes for food to transit through the gut. To measure transit time in your child, when your participant is ready to eat in the morning after a minimum 6-hour fasting period:\n\n 1. Select the Begin Blue Dye Test Button. \n\n 2. Feed them two blue muffins and when they are done eating select the Finished Blue Meal button. \n\n 3. Log BMs and note blue/blue-green color. \n\n 4. Keep logging BMs until they are no longer blue. \n\n 5. Select the Submit Test Button. \n\n 6. The APP will calculate transit time.\n',
          style: lightBackgroundStyle,
        ),
      ],
    );
  }
}
