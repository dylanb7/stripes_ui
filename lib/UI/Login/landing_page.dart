import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/entry.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthStrat strat = ref.watch(authStrat);
    return ColoredBox(
      color: darkBackgroundText,
      child: Column(
        children: [
          const Spacer(
            flex: 2,
          ),
          Image.asset(
            'packages/stripes_ui/assets/images/StripesLogo.png',
          ),
          const Spacer(
            flex: 1,
          ),
          if (strat == AuthStrat.accessCodeEmail) const SignUpLogin(),
          if (strat == AuthStrat.accessCode) AccessLogin(),
          const Spacer(
            flex: 3,
          ),
        ],
      ),
    );
  }
}

class SignUpLogin extends StatelessWidget {
  const SignUpLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}

class AccessLogin extends ConsumerWidget {
  AccessLogin({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          decoration: formFieldDecoration(
              hintText: "Access Code", controller: controller),
        ),
        const SizedBox(height: 4.0),
        StripesRoundedButton(
          text: 'Submit',
          disabled: controller.text.isEmpty,
          onClick: () {
            ref.read(authProvider).logIn({});
          },
        ),
        const SizedBox(height: 8.0),
        StripesTextButton(
          buttonText: 'Use without account',
          onClicked: () {
            ref.read(authProvider).logIn({});
          },
        ),
      ],
    );
  }
}
