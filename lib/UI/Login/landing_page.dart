import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/access_provider.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthStrat strat = ref.watch(authStrat);
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
          if (strat == AuthStrat.accessCodeEmail) const SignUpLogin(),
          if (strat == AuthStrat.accessCode) const AccessLogin(),
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
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 325,
              child: FilledButton(
                  onPressed: () {
                    context.go(Routes.SIGN_UP);
                  },
                  child: Text(
                      AppLocalizations.of(context)!.signupWithAccessCode))),
          const SizedBox(height: 8.0),
          TextButton(
            child: RichText(
                text: TextSpan(children: [
              TextSpan(text: AppLocalizations.of(context)!.loginButtonPrefix),
              TextSpan(
                  text: AppLocalizations.of(context)!.loginButtonText,
                  style: const TextStyle(decoration: TextDecoration.underline))
            ])),
            onPressed: () {
              context.go(Routes.LOGIN);
            },
          ),
          const SizedBox(
            height: 4.0,
          ),
          const Divider(
            height: 1,
            color: Colors.grey,
            endIndent: 8.0,
            indent: 8.0,
          ),
          const SizedBox(
            height: 4.0,
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.useWithoutAccount),
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
                    hintText:
                        AppLocalizations.of(context)!.accessCodePlaceholder,
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
                    width: 12.0,
                  ),
                  const CircularProgressIndicator(),
                ],
              ),
            const SizedBox(height: 6.0),
            FilledButton(
              child: Text(AppLocalizations.of(context)!.submitCode),
              onPressed: () {
                if (!controller.text.isNotEmpty) _submitCode(context);
              },
            ),
            const SizedBox(height: 8.0),
            TextButton(
              child: Text(AppLocalizations.of(context)!.withoutCode),
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
        accessError = AppLocalizations.of(context)!.codeError;
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(() => setState(() {}));
    super.dispose();
  }
}
