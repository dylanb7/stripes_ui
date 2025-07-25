import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/access_provider.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthStrategy? strat = ref.watch(configProvider).authStrategy;
    return Scaffold(
      body: Column(
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
          if (strat == AuthStrategy.accessCodeEmail) const SignUpLogin(),
          if (strat == AuthStrategy.accessCode) const AccessLogin(),
          const Spacer(
            flex: 3,
          ),
        ],
      ),
    );
  }
}

class SignUpLogin extends ConsumerWidget {
  const SignUpLogin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 325,
              child: FilledButton(
                  onPressed: () {
                    context.go(Routes.SIGN_UP);
                  },
                  child: Text(context.translate.signupWithAccessCode))),
          const SizedBox(height: AppPadding.small),
          TextButton(
            child: RichText(
                text: TextSpan(children: [
              TextSpan(text: context.translate.loginButtonPrefix),
              TextSpan(
                  text: context.translate.loginButtonText,
                  style: const TextStyle(decoration: TextDecoration.underline))
            ])),
            onPressed: () {
              context.go(Routes.LOGIN);
            },
          ),
          const SizedBox(
            height: AppPadding.tiny,
          ),
          const Divider(
            endIndent: AppPadding.small,
            indent: AppPadding.small,
          ),
          const SizedBox(
            height: AppPadding.tiny,
          ),
          TextButton(
            child: Text(context.translate.useWithoutAccount),
            onPressed: () {
              ref.read(authProvider).logIn({});
            },
          ),
        ],
      ),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 6.0),
            if (!loading)
              TextField(
                controller: controller,
                decoration: formFieldDecoration(
                    hintText: context.translate.accessCodePlaceholder,
                    controller: controller),
              ),
            if (loading)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(
                    width: AppPadding.medium,
                  ),
                  const CircularProgressIndicator(),
                ],
              ),
            const SizedBox(height: AppPadding.tiny),
            FilledButton(
              child: Text(context.translate.submitCode),
              onPressed: () {
                if (!controller.text.isNotEmpty) _submitCode(context);
              },
            ),
            const SizedBox(height: AppPadding.small),
            TextButton(
              child: Text(context.translate.withoutCode),
              onPressed: () {
                ref.read(authProvider).logIn({localAccessKey: 'temp'});
              },
            ),
          ],
        ));
  }

  _submitCode(BuildContext context) async {
    setState(() {
      loading = true;
    });
    final String? res =
        await ref.read(accessProvider).workingCode(controller.text);
    if (res != null) {
      await ref.read(authProvider).logIn({localAccessKey: controller.text});
      await ref.read(accessProvider).removeCode();
    }
    if (mounted) {
      controller.clear();
      setState(() {
        loading = false;
        accessError = context.translate.codeError;
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(() => setState(() {}));
    super.dispose();
  }
}
