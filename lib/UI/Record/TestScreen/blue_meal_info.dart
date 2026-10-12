import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/UI/Resources/resource_markdown.dart';
import 'package:stripes_ui/UI/Record/TestScreen/card_layout_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class BlueMealPreStudy extends ConsumerStatefulWidget {
  final VoidCallback onClick;

  final bool isLoading;

  const BlueMealPreStudy({
    required this.onClick,
    required this.isLoading,
    super.key,
  });

  @override
  ConsumerState<BlueMealPreStudy> createState() {
    return _BlueMealPreStudyState();
  }
}

class _BlueMealPreStudyState extends ConsumerState<BlueMealPreStudy> {
  bool appTosRead = false;

  @override
  Widget build(BuildContext context) {
    final termsAcceptedDuringOnboarding =
        ref.watch(configProvider).betaUi.onboardingTerms;
    return !termsAcceptedDuringOnboarding && !appTosRead
        ? AppTos(
            onContinue: () {
              setState(() {
                appTosRead = true;
              });
            },
          )
        : PreStudyInfo(
            isLoading: widget.isLoading,
            onClick: () {
              widget.onClick();
            },
          );
  }
}

class PreStudyInfo extends StatefulWidget {
  final VoidCallback onClick;
  final bool isLoading;

  const PreStudyInfo({
    required this.onClick,
    required this.isLoading,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _PreStudyInfoState();
  }
}

class _PreStudyInfoState extends State<PreStudyInfo> {
  bool read = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshWidget(
            depth: RefreshDepth.authuser,
            scrollable: AddIndicator(
              builder: (context, hasIndicator) => ScrollAssistedList(
                scrollController: _scrollController,
                key: const PageStorageKey("PreMealScroll"),
                builder: (context, properties) => SizedBox.expand(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: properties.scrollStateKey,
                    controller: properties.scrollController,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Breakpoint.medium.value,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppPadding.large),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppPadding.large,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TestSwitcher(),
                              ),
                            ),
                            const SizedBox(height: AppPadding.medium),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.large,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(AppPadding.tiny),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppPadding.tiny,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.translate.preStudySeeing,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            context.translate.preStudySeeingExp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.medium),
                                  const BlueMealStudyInstructions(),
                                  const SizedBox(height: AppPadding.medium),
                                  Text(
                                    context.translate.preStudyEnrollTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    context.translate.preStudyEnrollDescPartOne,
                                  ),
                                  const SizedBox(height: AppPadding.medium),
                                  Text(
                                    context.translate.preStudyEnrollDescPartTwo,
                                  ),
                                  const SizedBox(height: AppPadding.large),
                                  ReadConfirmation(
                                    value: read,
                                    onChange: (value) =>
                                        setState(() => read = value),
                                    text: "I have read and understand the Blue Meal study process. I agree to start the test",
                                  ),
                                  const SizedBox(height: AppPadding.xl),
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
        _StudyActionFooter(
          child: FilledButton(
            onPressed: read && !widget.isLoading
                ? () {
                    widget.onClick();
                  }
                : null,
            child: widget.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Start step one"),
          ),
        ),
      ],
    );
  }
}

class BlueMealInfoButton extends ConsumerWidget {
  const BlueMealInfoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () {
        toggleBottomSheet(context, ref);
      },
      child: Text(context.translate.studyInfoButtonLabel),
    );
  }

  void toggleBottomSheet(BuildContext context, WidgetRef ref) {
    ref
        .read(sheetControllerProvider)
        .show(
          context: context,
          scrollControlled: true,
          initialChildSize: 0.95,
          maxChildSize: 1.0,
          sheetBuilder: (context, controller) {
            return BlueMealInfoSheet(scrollController: controller);
          },
        );
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshWidget(
            depth: RefreshDepth.authuser,
            scrollable: AddIndicator(
              builder: (context, hasIndicator) => ScrollAssistedList(
                scrollController: _scrollController,
                key: const PageStorageKey("PreMealTOSScroll"),
                builder: (context, properties) => SizedBox.expand(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: properties.scrollStateKey,
                    controller: properties.scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Breakpoint.medium.value,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ResourceMarkdown(
                                data: stripesTermsOfServiceMarkdown,
                              ),
                              const SizedBox(height: AppPadding.large),
                              ReadConfirmation(
                                value: read,
                                onChange: (value) =>
                                    setState(() => read = value),
                                text:
                                    "I have read the Stripes terms of service.",
                              ),
                              const SizedBox(height: AppPadding.large),
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
        ),
        _StudyActionFooter(
          child: FilledButton(
            onPressed: read
                ? () {
                    widget.onContinue();
                  }
                : null,
            child: const Text("Continue"),
          ),
        ),
      ],
    );
  }
}

/// Kept with the document so large text cannot displace its reading viewport.
class ReadConfirmation extends StatelessWidget {
  final bool value;
  final void Function(bool) onChange;
  final String text;
  const ReadConfirmation({
    required this.value,
    required this.onChange,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: (newValue) {
        if (newValue != null) onChange(newValue);
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StudyActionFooter extends StatelessWidget {
  final Widget child;

  const _StudyActionFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomNavPadding = FloatingNavBarScope.bottomPaddingOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? colors.surfaceContainer.withValues(alpha: 0.8)
        : colors.surface.withValues(alpha: 0.85);

    final hasBottomNav = bottomNavPadding > 0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: !hasBottomNav,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppPadding.medium,
                right: AppPadding.medium,
                top: AppPadding.medium,
                bottom: hasBottomNav
                    ? bottomNavPadding + AppPadding.small
                    : AppPadding.medium,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Breakpoint.medium.value,
                  ),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
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
    return Stack(
      children: [
        ScrollAssistedList(
          builder: (context, properties) => ListView(
            physics: const ScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
            key: properties.scrollStateKey,
            controller: properties.scrollController,
            children: [
              const SizedBox(height: AppPadding.xxxl),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRounding.tiny),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.tiny),
                  child: Text(context.translate.inStudySeeingExp),
                ),
              ),
              const SizedBox(height: AppPadding.medium),
              const BlueMealStudyInstructions(),
              const SizedBox(height: AppPadding.medium),
              Text(
                context.translate.inStudyWithdrawTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(context.translate.inStudyWithdrawDesc),
              const SizedBox(height: AppPadding.medium),
              Center(
                child: FilledButton(
                  onPressed: () async {
                    final AuthUser user = await ref.read(authStream.future);

                    final Email email = Email(
                      subject: "Blue Meal Study withdrawl request",
                      recipients: ["BlueMeal@iu.edu"],
                      body:
                          "${user.attributes["email"] ?? "{insert account email}"}",
                    );

                    if (kIsWeb) {
                      final Uri mailTo = webMailTo(email);
                      bool launched = false;
                      if (await canLaunchUrl(mailTo)) {
                        launched = await launchUrl(mailTo);
                      } else {
                        launched = false;
                      }
                      if (!launched && context.mounted) {
                        showSnack(context, "Failed to generate email");
                      }
                      return;
                    }
                    try {
                      await FlutterEmailSender.send(email);
                    } catch (e) {
                      if (context.mounted) {
                        showSnack(context, "Unable to construct email");
                      }
                    }
                  },
                  child: Text(context.translate.inStudyWithdrawButtonText),
                ),
              ),
              const SizedBox(height: AppPadding.xl),
            ],
          ),
          scrollController: scrollController,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: const [0.0, 0.7, 1.0],
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0),
              ],
              begin: AlignmentGeometry.topCenter,
              end: AlignmentGeometry.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.translate.blueDyeHeader,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton.filled(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    /*return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: AppPadding.large,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.translate.blueDyeHeader,
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
          height: AppPadding.small,
        ),
        Expanded(
            child: ScrollAssistedList(
                builder: (context, properties) => ListView(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.large),
                      key: properties.scrollStateKey,
                      controller: properties.scrollController,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.yellow.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(AppRounding.tiny))),
                          child: Padding(
                            padding: const EdgeInsets.all(AppPadding.tiny),
                            child: Text(
                              context.translate.inStudySeeingExp,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: AppPadding.medium,
                        ),
                        const BlueMealStudyInstructions(),
                        const SizedBox(
                          height: AppPadding.medium,
                        ),
                        Text(
                          context.translate.inStudyWithdrawTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          context.translate.inStudyWithdrawDesc,
                        ),
                        const SizedBox(
                          height: AppPadding.medium,
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
                                child: Text(context
                                    .translate.inStudyWithdrawButtonText))),
                        const SizedBox(
                          height: AppPadding.xl,
                        ),
                      ],
                    ),
                scrollController: scrollController)),
      ],
    );*/
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
      queryParameters: parameterMap,
    );
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
          context.translate.studyExpTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.small),
        Text(context.translate.studyExpBody),
        const SizedBox(height: AppPadding.small),
        Text(context.translate.studyExpBodyCont),
        LabeledList(
          strings: [
            context.translate.studyBodySymptomOne,
            context.translate.studyBodySymptomTwo,
            context.translate.studyBodySymptomThree,
            context.translate.studyBodySymptomFour,
          ],
          highlight: false,
        ),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyEligibilityTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyEligibilityParticipants),
        const SizedBox(height: AppPadding.small),
        LabeledList(
          strings: [
            context.translate.studyEligibilityOne,
            context.translate.studyEligibilityTwo,
            context.translate.studyEligibilityThree,
            context.translate.studyEligibilityFour,
          ],
          highlight: false,
        ),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyFlowTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyFlowDesc),
        const SizedBox(height: AppPadding.medium),
        LabeledList(
          title: Text(context.translate.studyFlowPreStudy),
          strings: [
            context.translate.studyFlowPreStudyOne,
            context.translate.studyFlowPreStudyTwo,
          ],
          mark: (index) => "${index + 1}.",
          highlight: false,
        ),
        const SizedBox(height: AppPadding.medium),
        LabeledList(
          title: Text(
            context.translate.studyFlowPrepTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          strings: [
            context.translate.studyFlowPrepOne,
            context.translate.studyFlowPrepTwo,
          ],
          highlight: false,
        ),
        const SizedBox(height: AppPadding.medium),
        LabeledList(
          title: Text(
            context.translate.studyFlowStepOneTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          strings: [
            context.translate.studyFlowStepOnePartOne,
            context.translate.studyFlowStepOnePartTwo,
          ],
          mark: (index) => "${index + 1}.",
          highlight: false,
        ),
        LabeledList(
          title: Text(
            context.translate.studyFlowStepTwoTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          strings: [
            context.translate.studyFlowStepTwoPartOne,
            context.translate.studyFlowStepTwoPartTwo,
          ],
          mark: (index) => "${index + 1}.",
          highlight: false,
        ),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyFlowBetweenStepTwoStepThree,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyFlowBetweenStepTwoStepThreeDesc),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyFlowStepThreeTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyFlowStepThreeDesc),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyFlowStepFourTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyFlowStepFourDesc),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyFlowComplete,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.medium),
        Text(
          context.translate.studyContactTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(context.translate.studyContactBody),
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
        padding: const EdgeInsets.all(AppPadding.small),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate.studyStepOneExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.small),
            LabeledList(
              strings: [
                context.translate.studyStepOneExplanationPartOne,
                context.translate.studyStepOneExplanationPartTwo,
                context.translate.studyStepOneExplanationPartThree,
                context.translate.studyStepOneExplanationPartFour,
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(context.translate.studyStepOneExplanationPreReq),
              highlight: false,
            ),
            const SizedBox(height: AppPadding.small),
            ColoredBox(
              color: Colors.yellow.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.tiny),
                child: Text(context.translate.studyStepOneExplanationNote),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlueStudyInstructionsPartTwo extends StatefulWidget {
  final bool initiallyExpanded;

  const BlueStudyInstructionsPartTwo({
    required this.initiallyExpanded,
    super.key,
  });

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
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!cardLayout) ...[
                Text(
                  context.translate.transitOneLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
              ],
              Text(
                context.translate.studyStepTwoExplanationTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppPadding.small),
              Text(context.translate.studyStepTwoExplanationDesc),
              const SizedBox(height: AppPadding.small),
              LabeledList(
                title: Text(context.translate.studyStepTwoExplanationPartOne),
                strings: [
                  context.translate.studyStepTwoExplanationPartOneDetailOne,
                  context.translate.studyStepTwoExplanationPartOneDetailTwo,
                ],
                highlight: false,
              ),
              const SizedBox(height: AppPadding.small),
              if (expanded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    LabeledList(
                      title: Text(
                        context.translate.studyStepTwoExplanationPartTwo,
                      ),
                      strings: [
                        context
                            .translate
                            .studyStepTwoExplanationPartTwoDetailOne,
                        context
                            .translate
                            .studyStepTwoExplanationPartTwoDetailTwo,
                      ],
                      highlight: false,
                    ),
                    const SizedBox(height: AppPadding.small),
                    Text(context.translate.studyStepTwoExplanationColorExp),
                    const SizedBox(height: AppPadding.small),
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
                      ? context.translate.viewLessButtonText
                      : context.translate.viewMoreButtonText,
                  style: Theme.of(context).textTheme.bodyMedium
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
        padding: const EdgeInsets.all(AppPadding.small),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate.studyStepThreeExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.small),
            LabeledList(
              strings: [
                context.translate.studyStepThreeExplanationPartOne,
                context.translate.studyStepThreeExplanationPartTwo,
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(context.translate.studyStepThreeExplanationPreReq),
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
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!cardLayout) ...[
              Text(
                context.translate.transitTwoLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
            ],
            Text(
              context.translate.studyStepFourExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.small),
            LabeledList(
              strings: [
                context.translate.studyStepFourExplanationPartOne,
                context.translate.studyStepFourExplanationPartTwo,
              ],
              mark: (i) => "${i + 1}. ",
              title: Text(context.translate.studyStepFourExplanationDesc),
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
    final bool cardLayout = getBreakpoint(context)
        .isGreaterThan(Breakpoint.medium);
    return AdaptiveCardLayout(
      cardColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!cardLayout) ...[
              Text(
                step.value < 2
                    ? context.translate.transitOneLabel
                    : context.translate.transitTwoLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
            ],
            Text(
              step.value < 2
                  ? context.translate.studyStepTwoExplanationTitle
                  : context.translate.studyStepFourExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              context.translate.blueMealRecordDescription(
                step.value < 2 ? "Step 2" : "Step 4",
              ),
            ),
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
    this.padding = AppPadding.tiny,
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
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppPadding.tiny),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marker(index.key),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppPadding.tiny),
              Expanded(
                child: Text(
                  index.value,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
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
                padding: const EdgeInsets.only(
                  left: AppPadding.medium,
                  top: AppPadding.tiny,
                ),
                child: list,
              ),
              ...?additions,
            ],
          )
        : list;

    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRounding.small),
        ),
        border: highlight
            ? Border.all(
                width: 2.0,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )
            : null,
      ),
      padding: padding != null ? EdgeInsets.all(padding!) : null,
      child: titleWidget,
    );
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
    this.padding = AppPadding.tiny,
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
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppPadding.tiny),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marker(index.key),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppPadding.tiny),
              Expanded(child: index.value),
            ],
          ),
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
                padding: const EdgeInsets.only(
                  left: AppPadding.medium,
                  top: AppPadding.tiny,
                ),
                child: list,
              ),
              ...?additions,
            ],
          )
        : list;

    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRounding.tiny)),
        border: highlight
            ? Border.all(
                width: 2.0,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )
            : null,
      ),
      padding: padding != null ? EdgeInsets.all(padding!) : null,
      child: titleWidget,
    );
  }
}
