import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/Util/constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(
          flex: 2,
        ),
        Image.asset('assets/images/StripesLogo.png'),
        const Spacer(
          flex: 1,
        ),
        SizedBox(
            width: 325,
            child: StripesRoundedButton(
                text: 'Sign up with access code',
                rounding: 25.0,
                onClick: () {
                  context.go(Routes.SIGN_UP);
                })),
        const SizedBox(height: 8.0),
        StripesTextButton(
          buttonText: 'Login',
          onClicked: () {
            context.go(Routes.LOGIN);
          },
          prefix: 'Already have an account? ',
        ),
        const Spacer(
          flex: 3,
        ),
      ],
    );
  }
}
