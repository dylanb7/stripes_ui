import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/db_keys.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/form_container.dart';
import 'package:stripes_ui/UI/CommonWidgets/obscure_text_field.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Util/async_ui_callback.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/Util/validators.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends ConsumerState<Login> {
  bool isReset = false;

  @override
  Widget build(BuildContext context) {
    return isReset ? ResetScreen(ref: ref) : LoginScreen(ref: ref);
  }

  openReset() {
    setState(() {
      isReset = true;
    });
  }

  closeReset() {
    setState(() {
      isReset = false;
    });
  }
}

class LoginScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController email = TextEditingController(),
      password = TextEditingController();

  final WidgetRef ref;

  LoginScreen({required this.ref, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ref.read(authProvider).logIn({});
    return FormContainer(
      close: () {
        context.go(Routes.LANDING);
      },
      topPortion: Column(children: const [
        Spacer(
          flex: 2,
        ),
        Padding(
          padding: EdgeInsets.only(left: 20.0, right: 15.0),
          child: Text(
            'Login',
            style: darkBackgroundScreenHeaderStyle,
            textAlign: TextAlign.justify,
          ),
        ),
        Spacer(
          flex: 1,
        )
      ]),
      bottomPortion: StripesTextButton(
        prefix: 'Don\'t have an account? ',
        buttonText: 'Create One',
        onClicked: () {
          context.go(Routes.SIGN_UP);
        },
      ),
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 16.0,
                ),
                TextFormField(
                  validator: emailDigest,
                  autofillHints: const [AutofillHints.email],
                  controller: email,
                  decoration: formFieldDecoration(
                      prefix: Icons.email_outlined,
                      hintText: 'Email',
                      controller: email),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                ObscureTextField(
                  hintText: 'Password',
                  controller: password,
                  validator: (value) {
                    return customPassDigest(value) != null
                        ? 'Invalid Password'
                        : null;
                  },
                  shouldValidate: false,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(
                  height: 16.0,
                ),
                StripesRoundedButton(
                    text: 'Login',
                    onClick: () {
                      _login(
                          ref,
                          AsyncUiCallback(onSuccess: () {
                            context.go(Routes.HOME);
                          }, onError: ({err}) {
                            showSnack(err!, context);
                          }));
                    }),
                const SizedBox(
                  height: 8.0,
                ),
                StripesRoundedButton(
                    text: 'Forgot Password',
                    onClick: () {
                      _formKey.currentState?.save();
                      context
                          .findAncestorStateOfType<_LoginState>()!
                          .openReset();
                    }),
                const SizedBox(
                  height: 16.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login(WidgetRef ref, AsyncUiCallback callback) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref
            .read(authProvider)
            .logIn({EMAIL_FIELD: email.text, PASSWORD: password.text});
        callback.onSuccess();
      } catch (e) {
        callback.onError(err: e.toString());
      }
    }
  }
}

class ResetScreen extends StatelessWidget {
  final WidgetRef ref;
  ResetScreen({required this.ref, Key? key}) : super(key: key);

  final TextEditingController email = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FormContainer(
        hasClose: false,
        topPortion: Column(children: const [
          Spacer(
            flex: 2,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.0, right: 15.0),
            child: Text(
              'Reset Password',
              style: darkBackgroundScreenHeaderStyle,
              textAlign: TextAlign.justify,
            ),
          ),
          Spacer(
            flex: 1,
          ),
        ]),
        form: FocusTraversalGroup(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextFormField(
                        validator: (value) => emailDigest(value ?? ''),
                        autofillHints: const [AutofillHints.email],
                        decoration: formFieldDecoration(
                            prefix: Icons.email_outlined,
                            hintText: 'Email',
                            controller: email),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      StripesRoundedButton(
                          text: 'Send Reset Email',
                          onClick: () {
                            _resetPass(
                                ref,
                                AsyncUiCallback(onSuccess: () {
                                  showSnack('Reset email sent', context);
                                  context
                                      .findAncestorStateOfType<_LoginState>()!
                                      .closeReset();
                                }, onError: ({err}) {
                                  showSnack('Email failed to send', context);
                                }));
                          }),
                      const SizedBox(
                        height: 8.0,
                      ),
                      StripesRoundedButton(
                          text: 'Back',
                          onClick: () {
                            _back(context);
                          }),
                      const SizedBox(
                        height: 16.0,
                      ),
                    ]),
              ),
            ),
          ),
        ));
  }

  void _back(BuildContext context) {
    context.findAncestorStateOfType<_LoginState>()!.closeReset();
  }

  void _resetPass(WidgetRef ref, AsyncUiCallback callback) async {
    if (_formKey.currentState?.validate() ?? false) {
      bool success = await ref.read(authProvider).resetPassword(email.text);
      if (success) {
        callback.onSuccess();
      } else {
        email.clear();
        callback.onError();
      }
    }
  }
}
