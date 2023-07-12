import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/AccessBase/base_access_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/db_keys.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/form_container.dart';
import 'package:stripes_ui/UI/CommonWidgets/obscure_text_field.dart';
import 'package:stripes_ui/Providers/access_provider.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Util/async_ui_callback.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/Util/validators.dart';

import '../../l10n/app_localizations.dart';
import '../CommonWidgets/loading.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccessCodeRepo repo = ref.watch(accessProvider);
    return repo.validState()
        ? const SignInForm()
        : Verification(
            accessRepo: repo,
          );
  }
}

class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SignInFormState();
  }
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final Map<String, bool Function(String)> points = {
      AppLocalizations.of(context)!.passwordLength: (val) {
        return val.length >= 8;
      },
      AppLocalizations.of(context)!.passwordLowercase: (val) {
        return val.contains(RegExp(r'[a-z]'));
      },
      AppLocalizations.of(context)!.passwordUppercase: (val) {
        return val.contains(RegExp(r'[A-Z]'));
      },
      AppLocalizations.of(context)!.passwordNumber: (val) {
        return val.contains(RegExp(r'[0-9]'));
      }
    };
    return loading
        ? const LoadingWidget()
        : FormContainer(
            close: () {
              context.go(Routes.LANDING);
            },
            topPortion: const Column(children: [
              Spacer(
                flex: 1,
              ),
              Padding(
                padding: EdgeInsets.only(left: 20.0, right: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Info',
                      style: darkBackgroundScreenHeaderStyle,
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(
                      height: 6.0,
                    ),
                    Text(
                      'Set up your email and password for your STRIPES account.',
                      style: darkBackgroundStyle,
                      textAlign: TextAlign.justify,
                    )
                  ],
                ),
              ),
              Spacer(
                flex: 1,
              )
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
                          controller: email,
                          autofillHints: const [AutofillHints.email],
                          validator: emailDigest,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: formFieldDecoration(
                              prefix: Icons.email_outlined,
                              hintText: 'Email',
                              controller: email),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        ObscureTextField(
                          hintText: AppLocalizations.of(context)!.passwordText,
                          controller: password,
                          validator: customPassDigest,
                          shouldValidate: true,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        ObscureTextField(
                          hintText: 'Confirm Password',
                          controller: confirm,
                          shouldValidate: true,
                          validator: (value) {
                            return value?.isEmpty ?? true
                                ? AppLocalizations.of(context)!.emptyFieldText
                                : value != password.text
                                    ? AppLocalizations.of(context)!
                                        .passwordMatchError
                                    : null;
                          },
                          autofillHints: const [AutofillHints.password],
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .passwordRequirementHeader,
                          style: buttonTextStyle.copyWith(
                              color: buttonDarkBackground2),
                        ),
                        ...points.keys.map((point) => Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                StatefulBuilder(builder: (context, setState) {
                                  password.addListener(() {
                                    setState(() {});
                                  });
                                  return BulletPoint(
                                      color: points[point]!(password.text)
                                          ? Colors.green
                                          : buttonDarkBackground2);
                                }),
                                const SizedBox(
                                  width: 5.0,
                                ),
                                Text(
                                  point,
                                  style: lightBackgroundStyle,
                                )
                              ],
                            )),
                        const SizedBox(
                          height: 16.0,
                        ),
                        StripesRoundedButton(
                            text: 'Create Account',
                            onClick: () async {
                              _createAccount(AsyncUiCallback(onSuccess: () {
                                context.go(Routes.HOME);
                              }, onError: ({err}) {
                                if (err != null) {
                                  showSnack(err.toString(), context);
                                } else {
                                  showSnack('Account creation failed', context);
                                }
                              }));
                            }),
                        const SizedBox(
                          height: 16.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  _createAccount(AsyncUiCallback callback) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          loading = true;
        });
        await ref
            .read(authProvider)
            .signUp({EMAIL_FIELD: email.text, PASSWORD: password.text});
        final AuthUser current = ref.read(currentAuthProvider);
        if (!AuthUser.isEmpty(current)) {
          await ref.read(accessProvider).removeCode();
          callback.onSuccess();
        } else {
          callback.onError();
        }
        setState(() {
          loading = false;
        });
      } catch (e) {
        callback.onError(err: e.toString());
      }
    }
  }
}

class Verification extends StatefulWidget {
  final AccessCodeRepo accessRepo;
  const Verification({required this.accessRepo, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VerificationState();
  }
}

class _VerificationState extends State<Verification> {
  bool helpShown = false;

  bool loading = false;

  String? accessError;

  final TextEditingController controller = TextEditingController();

  _VerificationState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.addListener(() {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return helpShown
        ? const Help()
        : FormContainer(
            close: () {
              context.go(Routes.LANDING);
            },
            topPortion: const Column(children: [
              Spacer(
                flex: 2,
              ),
              Padding(
                  padding: EdgeInsets.only(left: 20.0, right: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access Code',
                        style: darkBackgroundScreenHeaderStyle,
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  )),
              Spacer(
                flex: 1,
              )
            ]),
            bottomPortion: StripesTextButton(
              buttonText: 'Can\'t find your access code?',
              onClicked: () {
                setState(() {
                  helpShown = true;
                });
              },
            ),
            form: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: 32.0,
                    ),
                    if (accessError != null && !loading)
                      Text(
                        accessError!,
                        style: errorStyleTitle,
                      ),
                    const SizedBox(height: 6.0),
                    if (!loading)
                      TextField(
                        controller: controller,
                        decoration: formFieldDecoration(
                            hintText: AppLocalizations.of(context)!
                                .accessCodePlaceholder,
                            controller: controller),
                      ),
                    if (loading)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.text,
                            style: lightBackgroundHeaderStyle,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          const CircularProgressIndicator(
                            color: darkIconButton,
                          ),
                        ],
                      ),
                    const SizedBox(height: 6.0),
                    StripesRoundedButton(
                      text: AppLocalizations.of(context)!.submitCode,
                      disabled: controller.text.isEmpty,
                      onClick: () {
                        _checkCode(
                            controller.text,
                            AsyncUiCallback(
                                onError: ({err}) {
                                  accessError = 'Could not find code';
                                },
                                onSuccess: () {}));
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    )
                  ]),
            ),
          );
  }

  _checkCode(String val, AsyncUiCallback callback) async {
    bool working = !(await widget.accessRepo.workingCode(val) == null);
    if (working) {
      callback.onSuccess();
    } else {
      callback.onError();
    }
  }

  closeHelp() {
    setState(() {
      helpShown = false;
    });
  }
}

class Help extends StatelessWidget {
  const Help({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormContainer(
      hasClose: false,
      topPortion: const Column(children: [
        Spacer(
          flex: 2,
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 15.0,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Access Code Help',
              style: darkBackgroundScreenHeaderStyle,
              textAlign: TextAlign.justify,
            ),
            SizedBox(
              height: 6.0,
            ),
            Text(
              'You identified that you need help finding your access code.',
              style: darkBackgroundStyle,
              textAlign: TextAlign.justify,
            )
          ]),
        ),
        Spacer(
          flex: 1,
        )
      ]),
      form: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            const Text(
              'This app is designed for caretakers/patients who are enrolled in STRIPES research.',
              style: lightBackgroundStyle,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(
              height: 6.0,
            ),
            RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  text: 'If you are ',
                  style: lightBackgroundStyle,
                  children: [
                    TextSpan(
                        text: 'not',
                        style: lightBackgroundStyle.copyWith(
                            fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                            ' a part of this research study, the app will not be available to you. If you ',
                        style: lightBackgroundStyle),
                    TextSpan(
                        text: 'are',
                        style: lightBackgroundStyle.copyWith(
                            fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                            ' a part of STRIPES research, an access code should have been delivered to you in your email.',
                        style: lightBackgroundStyle),
                  ],
                )),
            const SizedBox(
              height: 20,
            ),
            const Text('If you need any further help, contact:',
                style: lightBackgroundStyle, textAlign: TextAlign.justify),
            const SizedBox(
              height: 6,
            ),
            const Text('help@stripes.com',
                style: lightBackgroundStyle, textAlign: TextAlign.justify),
            const SizedBox(
              height: 8.0,
            ),
            StripesRoundedButton(
                text: 'Back',
                onClick: () {
                  context
                      .findAncestorStateOfType<_VerificationState>()!
                      .closeHelp();
                }),
            const SizedBox(
              height: 16.0,
            ),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final Color color;

  const BulletPoint({required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
