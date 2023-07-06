import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/access_provider.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/entry.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthStrat strat = ref.watch(authStrat);
    return Scaffold(
        body: ColoredBox(
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
    ));
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

class AccessLogin extends ConsumerStatefulWidget {
  const AccessLogin({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return AccessLoginState();
  }
}

class AccessLoginState extends ConsumerState<AccessLogin> {
  final TextEditingController controller = TextEditingController();

  bool loading = false;

  String? accessError;

  @override
  void initState() {
    controller.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          children: [
            if (accessError != null && !loading)
              Text(
                accessError!,
                style: errorStyleTitle,
              ),
            if (!loading)
              TextField(
                decoration: formFieldDecoration(
                    hintText: "Access Code", controller: controller),
              ),
            if (loading)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    controller.text,
                    style: lightBackgroundHeaderStyle,
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  const CircularProgressIndicator(
                    color: darkIconButton,
                  ),
                ],
              ),
            const SizedBox(height: 4.0),
            StripesRoundedButton(
              text: 'Submit',
              disabled: controller.text.isEmpty,
              onClick: () {
                _submitCode();
              },
            ),
            const SizedBox(height: 8.0),
            StripesTextButton(
              buttonText: 'Use without code',
              onClicked: () {
                ref.read(authProvider).logIn({});
              },
            ),
          ],
        ));
  }

  _submitCode() async {
    setState(() {
      loading = true;
    });
    final String? res =
        await ref.read(accessProvider).workingCode(controller.text);
    if (res != null) {
      await ref.read(authProvider).logIn({localAccessKey: controller.text});
      await ref.read(accessProvider).removeCode();
    }
    controller.clear();
    setState(() {
      loading = false;
      accessError = "Invalid code";
    });
  }

  @override
  void dispose() {
    controller.removeListener(() => setState(() {}));
    super.dispose();
  }
}
