import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class BlueMealPreStudy extends StatefulWidget {
  final Function onClick;

  final bool isLoading;

  const BlueMealPreStudy(
      {required this.onClick, required this.isLoading, super.key});

  @override
  State<StatefulWidget> createState() {
    return _BlueMealPreStudyState();
  }
}

class _BlueMealPreStudyState extends State<BlueMealPreStudy> {
  bool appTosRead = false;

  @override
  Widget build(BuildContext context) {
    return appTosRead
        ? AppTos(onContinue: () {
            setState(() {
              appTosRead = true;
            });
          })
        : PreStudyInfo(onClick: () {
            widget.onClick();
          });
  }
}

class PreStudyInfo extends StatefulWidget {
  final void Function() onClick;

  const PreStudyInfo({required this.onClick, super.key});

  @override
  State<StatefulWidget> createState() {
    return _PreStudyInfoState();
  }
}

class _PreStudyInfoState extends State<PreStudyInfo> {
  bool read = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: RefreshWidget(
          depth: RefreshDepth.authuser,
          scrollable: AddIndicator(
            builder: (context, hasIndicator) => ScrollAssistedList(
              scrollController: ScrollController(),
              key: const PageStorageKey("PreMealScroll"),
              builder: (context, properties) => SizedBox.expand(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  key: properties.scrollStateKey,
                  controller: properties.scrollController,
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: Breakpoint.medium.value),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 20.0,
                          ),
                          const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TestSwitcher())),
                          const SizedBox(
                            height: 12.0,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.yellow.withValues(alpha: 0.35),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!
                                                .preStudySeeing,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .preStudySeeingExp,
                                          ),
                                        ],
                                      )),
                                ),
                                const SizedBox(
                                  height: 12.0,
                                ),
                                const BlueMealStudyInstructions(),
                                const SizedBox(
                                  height: 12.0,
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .preStudyEnrollTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(AppLocalizations.of(context)!
                                    .preStudyEnrollDescPartOne),
                                const SizedBox(
                                  height: 12.0,
                                ),
                                Text(AppLocalizations.of(context)!
                                    .preStudyEnrollDescPartTwo),
                                const SizedBox(
                                  height: 25.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ReadConfirmation(
          onChange: (value) {
            setState(() {
              read = value;
            });
          },
          button: FilledButton(
            style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor:
                    Theme.of(context).disabledColor.darken(20),
                disabledForegroundColor:
                    Theme.of(context).colorScheme.onPrimary),
            onPressed: read
                ? () {
                    widget.onClick();
                  }
                : null,
            child: const Text("Start step one"),
          ),
          text:
              "I have read and understand the Blue Meal study process. I agree to start the test"),
    ]);
  }
}

class BlueMealInfoButton extends StatelessWidget {
  const BlueMealInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
        onPressed: () {
          toggleBottomSheet(context);
        },
        child: Text(AppLocalizations.of(context)!.studyInfoButtonLabel));
  }

  toggleBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 1.0,
              builder: (context, controller) {
                return SafeArea(
                  child: BlueMealInfoSheet(
                    scrollController: controller,
                  ),
                );
              });
        });
  }
}

class AppTos extends StatefulWidget {
  final void Function() onContinue;

  const AppTos({required this.onContinue, super.key});

  @override
  State<StatefulWidget> createState() {
    return _AppTosState();
  }
}

class _AppTosState extends State<AppTos> {
  bool read = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshWidget(
            depth: RefreshDepth.authuser,
            scrollable: AddIndicator(
              builder: (context, hasIndicator) => ScrollAssistedList(
                scrollController: ScrollController(),
                key: const PageStorageKey("PreMealTOSScroll"),
                builder: (context, properties) => SizedBox.expand(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: properties.scrollStateKey,
                    controller: properties.scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: Breakpoint.medium.value),
                          child: const MarkdownBlock(
                              data: '''# Terms of Service for Stripes 
**Last Updated:** March 31, 2025

**Welcome to Stripes!** Thanks for using our tool to track rare disease symptoms. By using our app, you agree to these terms. Please read them carefully.

## 1. The App

- **What it is:** Stripes helps you monitor and record symptoms. It's designed for awareness, not diagnosis.
- **Account Needed:** You must create an account to use the app. Keep your login details safe. You're responsible for your account.

## 2. Basic Use

- **Track Your Symptoms:** Use the app's core features anytime. Log your experiences. Stay informed about your health journey.
- **Your Data (Basic Use):** Data you enter in basic mode stays within the app according to our Privacy Policy.

## 3. Study Mode - For Invited Participants

- **Participation via Foundations:** Stripes includes a special \"Study Mode.\" Access is limited to users specifically recruited and invited to participate in research studies by partner foundations. You cannot opt-in directly through the app.
- **Study Protocols:** If you are invited and agree to participate, you'll follow specific study protocols. This may include using materials like a Blue Muffin Kit.
- **Tracking for Research:** During the study period, you will use Stripes to record specific information, including symptoms and potentially bowel movements/transit time, as required by the study.
- **Data Sharing with Indiana University (IU):** This is critical. For users participating in Study Mode, **all symptoms and related data** recorded in the Stripes app **during the official study period** are shared. We securely transmit this data to a dedicated research team at Indiana University.
- **Why Share?** Your participation and data help researchers understand rare diseases better. You contribute directly to important scientific work.
- **IU's Oversight & Consent:** This data sharing follows strict rules. It's governed by an Indiana University Institutional Review Board (IRB) protocol. Before participating, you will receive detailed information and must provide specific informed consent via your recruiting foundation, outlining exactly how your data is collected, used, shared, and protected by IU.

## 4. User Accounts

- To use certain features of the App, you may be required to create a user account.

- You agree to:

  - Provide accurate and complete information when creating your account
  - Maintain the security of your account credentials
  - Promptly notify us of any unauthorized use of your account
  - Take responsibility for all activities that occur under your account

- We reserve the right to:

  - Suspend or terminate accounts that violate these Terms
  - Delete accounts that remain inactive for extended periods
  - Refuse service to anyone for any reason at our discretion

- You may delete your account at any time through the App's settings. Upon deletion, some information may be retained as required by law or for legitimate business purposes.

## 5. Privacy is Key

- We care about your privacy. How we handle _all_ your data is detailed in our **Privacy Policy**: [https://symplifysolutions.com/privacy/stripes](https://symplifysolutions.com/privacy/stripes). Please read it.

## 6. Important Disclaimers

- **Not Medical Advice:** Stripes is an informational tool. It does **not** provide medical advice, diagnosis, or treatment.
- **Consult Professionals:** Always talk to your doctor or qualified health provider about your health concerns. Never ignore professional advice because of something you read or tracked in this app.

## 7. Your Responsibilities

- Use the app lawfully.
- Provide accurate information. This is especially crucial if participating in Study Mode.
- Don't misuse the app or try to break it.

## 8. Our Rights

- **App Ownership:** The Stripes app, its content, and features are owned and operated by **Symplify LLC**.
- **Changes:** We might update the app or these terms. We'll aim to notify you of major changes. Continuing to use the app after changes means you accept them.
- **Termination:** We can suspend or terminate your account if you violate these terms. You can stop using the app anytime.

## 9. Limitation of Liability

- The Stripes app is provided "as is." Symplify LLC isn't liable for any damages arising from your use of the app. Use it at your own risk.

## 10. Governing Law

- These terms are governed by the laws of Delaware

## 11. Contact Us

- **General App Support:** Questions about using Stripes? Reach out at **help@symplifysolutions.com**.
- **Active Study Support:** If you are **currently participating** in an active research study using Study Mode and need study-specific assistance, contact **BlueMeal@iu.edu**.

---'''),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ReadConfirmation(
            onChange: (value) {
              setState(() {
                read = value;
              });
            },
            button: FilledButton(
              style: FilledButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  disabledBackgroundColor:
                      Theme.of(context).disabledColor.darken(20),
                  disabledForegroundColor:
                      Theme.of(context).colorScheme.onPrimary),
              onPressed: read
                  ? () {
                      widget.onContinue();
                    }
                  : null,
              child: const Text("Continue"),
            ),
            text: "I have read the Stripes terms of service.")
      ],
    );
  }
}

class ReadConfirmation extends StatefulWidget {
  final void Function(bool) onChange;
  final String text;
  final Widget button;
  const ReadConfirmation(
      {required this.onChange,
      required this.button,
      required this.text,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _ReadConfirmationState();
  }
}

class _ReadConfirmationState extends State<ReadConfirmation> {
  bool read = false;
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).primaryColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                        checkColor: Theme.of(context).colorScheme.onSurface,
                        fillColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surface),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface),
                        value: read,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              read = newValue;
                              widget.onChange(read);
                            });
                          }
                        }),
                    const SizedBox(
                      width: 4.0,
                    ),
                    Flexible(
                      child: Text(
                        widget.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8.0,
                ),
                widget.button,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlueMealInfoSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const BlueMealInfoSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: 15,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.blueDyeHeader,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              IconButton.filled(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close))
            ],
          ),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Expanded(
            child: ScrollAssistedList(
                builder: (context, properties) => ListView(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      key: properties.scrollStateKey,
                      controller: properties.scrollController,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.yellow.withValues(alpha: 0.35),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0))),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              AppLocalizations.of(context)!.inStudySeeingExp,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        const BlueMealStudyInstructions(),
                        const SizedBox(
                          height: 12.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!.inStudyWithdrawTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppLocalizations.of(context)!.inStudyWithdrawDesc,
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        Center(
                            child: FilledButton(
                                onPressed: () async {
                                  final AuthUser user =
                                      await ref.read(authStream.future);

                                  final Email email = Email(
                                      subject:
                                          "Blue Meal Study withdrawl request",
                                      recipients: ["BlueMeal@iu.edu"],
                                      body:
                                          "${user.attributes["email"] ?? "{insert account email}"}");

                                  print(email.toJson());

                                  if (kIsWeb) {
                                    final Uri mailTo = webMailTo(email);
                                    bool launched = false;
                                    if (await canLaunchUrl(mailTo)) {
                                      launched = await launchUrl(mailTo);
                                    } else {
                                      launched = false;
                                    }
                                    if (!launched && context.mounted) {
                                      showSnack(
                                          context, "Failed to generate email");
                                    }
                                    return;
                                  }
                                  try {
                                    await FlutterEmailSender.send(email);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showSnack(
                                          context, "Unable to construct email");
                                    }
                                  }
                                },
                                child: Text(AppLocalizations.of(context)!
                                    .inStudyWithdrawButtonText))),
                        const SizedBox(
                          height: 25.0,
                        ),
                      ],
                    ),
                scrollController: scrollController)),
      ],
    );
  }

  Uri webMailTo(Email email) {
    final parameterMap = {
      'subject': Uri.encodeQueryComponent(email.subject),
      'body': Uri.encodeQueryComponent(email.body),
      'cc': email.cc.join(','),
      'bcc': email.bcc.join(','),
    };

    return Uri(
        scheme: 'mailto',
        path: "BlueMeal@iu.edu",
        queryParameters: parameterMap);
  }
}

class BlueMealStudyInstructions extends StatelessWidget {
  const BlueMealStudyInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.studyExpTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 6.0,
        ),
        Text(AppLocalizations.of(context)!.studyExpBody),
        const SizedBox(
          height: 6.0,
        ),
        Text(AppLocalizations.of(context)!.studyExpBodyCont),
        LabeledList(strings: [
          AppLocalizations.of(context)!.studyBodySymptomOne,
          AppLocalizations.of(context)!.studyBodySymptomTwo,
          AppLocalizations.of(context)!.studyBodySymptomThree,
          AppLocalizations.of(context)!.studyBodySymptomFour,
        ], highlight: false),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyEligibilityTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(AppLocalizations.of(context)!.studyEligibilityParticipants),
        const SizedBox(
          height: 6.0,
        ),
        LabeledList(strings: [
          AppLocalizations.of(context)!.studyEligibilityOne,
          AppLocalizations.of(context)!.studyEligibilityTwo,
          AppLocalizations.of(context)!.studyEligibilityThree,
          AppLocalizations.of(context)!.studyEligibilityFour,
        ], highlight: false),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(AppLocalizations.of(context)!.studyFlowDesc),
        const SizedBox(
          height: 12.0,
        ),
        LabeledList(
            title: Text(AppLocalizations.of(context)!.studyFlowPreStudy),
            strings: [
              AppLocalizations.of(context)!.studyFlowPreStudyOne,
              AppLocalizations.of(context)!.studyFlowPreStudyTwo
            ],
            mark: (index) => "${index + 1}.",
            highlight: false),
        const SizedBox(
          height: 12.0,
        ),
        LabeledList(
            title: Text(
              AppLocalizations.of(context)!.studyFlowPrepTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            strings: [
              AppLocalizations.of(context)!.studyFlowPrepOne,
              AppLocalizations.of(context)!.studyFlowPrepTwo,
            ],
            highlight: false),
        const SizedBox(
          height: 12.0,
        ),
        LabeledList(
            title: Text(
              AppLocalizations.of(context)!.studyFlowStepOneTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            strings: [
              AppLocalizations.of(context)!.studyFlowStepOnePartOne,
              AppLocalizations.of(context)!.studyFlowStepOnePartTwo
            ],
            mark: (index) => "${index + 1}.",
            highlight: false),
        LabeledList(
            title: Text(
              AppLocalizations.of(context)!.studyFlowStepTwoTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            strings: [
              AppLocalizations.of(context)!.studyFlowStepTwoPartOne,
              AppLocalizations.of(context)!.studyFlowStepTwoPartTwo
            ],
            mark: (index) => "${index + 1}.",
            highlight: false),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowBetweenStepTwoStepThree,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowBetweenStepTwoStepThreeDesc,
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowStepThreeTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowStepThreeDesc,
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowStepFourTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowStepFourDesc,
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyFlowComplete,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.studyContactTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.studyContactBody,
        ),
      ],
    );
  }
}

class BlueStudyInstructionsPartOne extends StatelessWidget {
  const BlueStudyInstructionsPartOne({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.studyStepOneExplanationTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8.0,
            ),
            LabeledList(
              strings: [
                AppLocalizations.of(context)!.studyStepOneExplanationPartOne,
                AppLocalizations.of(context)!.studyStepOneExplanationPartTwo,
                AppLocalizations.of(context)!.studyStepOneExplanationPartThree,
                AppLocalizations.of(context)!.studyStepOneExplanationPartFour
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(
                  AppLocalizations.of(context)!.studyStepOneExplanationPreReq),
              highlight: false,
            ),
            const SizedBox(
              height: 8.0,
            ),
            ColoredBox(
              color: Colors.yellow.withValues(alpha: 0.35),
              child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(AppLocalizations.of(context)!
                      .studyStepOneExplanationNote)),
            ),
          ],
        ),
      ),
    );
  }
}

class BlueStudyInstructionsPartTwo extends StatefulWidget {
  final bool initiallyExpanded;

  const BlueStudyInstructionsPartTwo(
      {required this.initiallyExpanded, super.key});

  @override
  State<StatefulWidget> createState() {
    return _BlueStudyInstructionsPartTwoState();
  }
}

class _BlueStudyInstructionsPartTwoState
    extends State<BlueStudyInstructionsPartTwo> {
  late bool expanded;
  @override
  void initState() {
    expanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!cardLayout) ...[
                Text(
                  AppLocalizations.of(context)!.transitOneLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
                ),
                const Divider(),
              ],
              Text(
                AppLocalizations.of(context)!.studyStepTwoExplanationTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Text(AppLocalizations.of(context)!.studyStepTwoExplanationDesc),
              const SizedBox(
                height: 8.0,
              ),
              LabeledList(
                  title: Text(AppLocalizations.of(context)!
                      .studyStepTwoExplanationPartOne),
                  strings: [
                    AppLocalizations.of(context)!
                        .studyStepTwoExplanationPartOneDetailOne,
                    AppLocalizations.of(context)!
                        .studyStepTwoExplanationPartOneDetailTwo,
                  ],
                  highlight: false),
              const SizedBox(
                height: 8.0,
              ),
              if (expanded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    LabeledList(
                        title: Text(AppLocalizations.of(context)!
                            .studyStepTwoExplanationPartTwo),
                        strings: [
                          AppLocalizations.of(context)!
                              .studyStepTwoExplanationPartTwoDetailOne,
                          AppLocalizations.of(context)!
                              .studyStepTwoExplanationPartTwoDetailTwo,
                        ],
                        highlight: false),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(AppLocalizations.of(context)!
                        .studyStepTwoExplanationColorExp),
                    const SizedBox(
                      height: 8.0,
                    ),
                  ],
                ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                label: Text(
                  expanded
                      ? AppLocalizations.of(context)!.viewLessButtonText
                      : AppLocalizations.of(context)!.viewMoreButtonText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.blue),
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlueStudyInstructionsPartThree extends StatelessWidget {
  const BlueStudyInstructionsPartThree({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.studyStepThreeExplanationTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8.0,
            ),
            LabeledList(
              strings: [
                AppLocalizations.of(context)!.studyStepThreeExplanationPartOne,
                AppLocalizations.of(context)!.studyStepThreeExplanationPartTwo,
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(AppLocalizations.of(context)!
                  .studyStepThreeExplanationPreReq),
              highlight: false,
            ),
          ],
        ),
      ),
    );
  }
}

class BlueStudyInstructionsPartFour extends StatelessWidget {
  const BlueStudyInstructionsPartFour({super.key});

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!cardLayout) ...[
              Text(
                AppLocalizations.of(context)!.transitTwoLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              const Divider(),
            ],
            Text(
              AppLocalizations.of(context)!.studyStepFourExplanationTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8.0,
            ),
            LabeledList(
              strings: [
                AppLocalizations.of(context)!.studyStepFourExplanationPartOne,
                AppLocalizations.of(context)!.studyStepFourExplanationPartTwo,
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(
                  AppLocalizations.of(context)!.studyStepFourExplanationDesc),
              highlight: false,
            ),
          ],
        ),
      ),
    );
  }
}

class BlueStudyInstructionsBMLogs extends StatelessWidget {
  final BlueDyeProgression step;
  const BlueStudyInstructionsBMLogs({required this.step, super.key});

  @override
  Widget build(BuildContext context) {
    final bool cardLayout =
        getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!cardLayout) ...[
              Text(
                step.value < 2
                    ? AppLocalizations.of(context)!.transitOneLabel
                    : AppLocalizations.of(context)!.transitTwoLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              const Divider(),
            ],
            Text(
              step.value < 2
                  ? AppLocalizations.of(context)!.studyStepTwoExplanationTitle
                  : AppLocalizations.of(context)!.studyStepFourExplanationTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(AppLocalizations.of(context)!.blueMealRecordDescription(
                step.value < 2 ? "Step 2" : "Step 4")),
          ],
        ),
      ),
    );
  }
}

class LabeledList extends StatelessWidget {
  final List<String> strings;

  final String Function(int)? mark;

  final Widget? title;

  final List<Widget>? additions;

  final bool highlight;

  final double? padding;

  const LabeledList({
    required this.strings,
    required this.highlight,
    this.additions,
    this.title,
    this.mark,
    this.padding = 4.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String Function(int) marker =
        mark ?? (_) => String.fromCharCode(0x2022);

    final Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: strings.asMap().entries.map((index) {
        final bool isLast = index.key == strings.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 6.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(marker(index.key),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(
              width: 4.0,
            ),
            Expanded(
              child: Text(
                index.value,
                softWrap: true,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ]),
        );
      }).toList(),
    );

    final Widget titleWidget = title != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              title!,
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                child: list,
              ),
              if (additions != null) ...additions!
            ],
          )
        : list;

    return Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6.0)),
            border: highlight
                ? Border.all(
                    width: 2.0,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)
                : null),
        padding: padding != null ? EdgeInsets.all(padding!) : null,
        child: titleWidget);
  }
}

class LabeledWidgets extends StatelessWidget {
  final List<Widget> widgets;

  final String Function(int)? mark;

  final Widget? title;

  final List<Widget>? additions;

  final bool highlight;

  final double? padding;

  const LabeledWidgets({
    required this.widgets,
    required this.highlight,
    this.additions,
    this.title,
    this.mark,
    this.padding = 4.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String Function(int) marker =
        mark ?? (_) => String.fromCharCode(0x2022);

    final Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.asMap().entries.map((index) {
        final bool isLast = index.key == widgets.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 6.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(marker(index.key),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(
              width: 4.0,
            ),
            Expanded(child: index.value),
          ]),
        );
      }).toList(),
    );

    final Widget titleWidget = title != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              title!,
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                child: list,
              ),
              if (additions != null) ...additions!
            ],
          )
        : list;

    return Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6.0)),
            border: highlight
                ? Border.all(
                    width: 2.0,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)
                : null),
        padding: padding != null ? EdgeInsets.all(padding!) : null,
        child: titleWidget);
  }
}
