import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

const blueMealSupportEmail = 'help@simplifysolutions.com';

class BlueDyeStudyHeader extends ConsumerWidget {
  final String subtitle;
  final bool showInfo;

  const BlueDyeStudyHeader({
    required this.subtitle,
    this.showInfo = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.translate.blueMealStudyTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BlueDyeStudyStyle.ink(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      if (showInfo)
        IconButton(
          tooltip: context.translate.blueMealStudyInformation,
          onPressed: () => showBlueDyeStudyInformation(context, ref),
          icon: Icon(Icons.info_outline, color: BlueDyeStudyStyle.ink(context)),
        ),
    ],
  );
}

Future<void> showBlueDyeStudyInformation(BuildContext context, WidgetRef ref) =>
    ref
        .read(sheetControllerProvider)
        .show<void>(
          context: context,
          scrollControlled: true,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          sheetBuilder: (context, controller) => SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Row(
                    children: [
                      Expanded(
                        child: BlueDyeStudyHeader(
                          subtitle: context.translate.blueMealAboutTitle,
                          showInfo: false,
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    child: const BlueDyeStudyInformation(),
                  ),
                ),
              ],
            ),
          ),
        );

/// Shared by enrollment and the persistent information button.
class BlueDyeStudyInformation extends StatelessWidget {
  const BlueDyeStudyInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.translate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoSection(
          id: 'invitation',
          title: s.blueMealInvitationTitle,
          initiallyExpanded: true,
          children: [
            Text(s.blueMealInvitationBody),
            const SizedBox(height: 16),
            Text(s.blueMealInvitationCorrection),
            const _SupportLink(),
          ],
        ),
        _InfoSection(
          id: 'about',
          title: s.blueMealAboutTitle,
          children: [
            Text(s.blueMealAboutBody),
            const SizedBox(height: 16),
            Text(s.studyExpBodyCont),
            _bullets([
              s.studyBodySymptomOne,
              s.studyBodySymptomTwo,
              s.blueMealGiSymptoms,
              s.blueMealSleepMood,
            ]),
          ],
        ),
        _InfoSection(
          id: 'eligibility',
          title: s.studyEligibilityTitle,
          children: [
            Text(s.studyEligibilityParticipants),
            _bullets([
              s.blueMealEligibilityDisorder,
              s.studyEligibilityTwo,
              s.studyEligibilityThree,
              s.studyEligibilityFour,
            ]),
          ],
        ),
        _InfoSection(
          id: 'flow',
          title: s.studyFlowTitle,
          children: [
            Text(s.studyFlowDesc),
            _FlowPart(
              title: s.studyFlowPreStudy,
              lines: [s.studyFlowPreStudyOne, s.studyFlowPreStudyTwo],
              numbered: true,
            ),
            _FlowPart(
              title: s.studyFlowPrepTitle,
              lines: [s.studyFlowPrepOne, s.studyFlowPrepTwo],
            ),
            _FlowPart(
              title: s.studyFlowStepOneTitle,
              lines: [s.studyFlowStepOnePartOne, s.studyFlowStepOnePartTwo],
              numbered: true,
            ),
            _FlowPart(
              title: s.studyFlowStepTwoTitle,
              lines: [s.studyFlowStepTwoPartOne, s.studyFlowStepTwoPartTwo],
              numbered: true,
            ),
            _FlowPart(
              title: s.studyFlowBetweenStepTwoStepThree,
              lines: [s.blueMealWaitInstruction],
            ),
            _FlowPart(
              title: s.studyFlowStepThreeTitle,
              lines: [s.studyFlowStepThreeDesc],
            ),
            _FlowPart(
              title: s.studyFlowStepFourTitle,
              lines: [s.studyFlowStepFourDesc],
            ),
            const SizedBox(height: 16),
            Text(s.studyFlowComplete),
          ],
        ),
        _InfoSection(
          id: 'terms',
          title: s.blueMealTermsTitle,
          children: [const BlueDyeStudyDefinitions()],
        ),
      ],
    );
  }

  static Widget _bullets(List<String> lines) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(line)),
            ],
          ),
        ),
    ],
  );
}

class _InfoSection extends StatelessWidget {
  final String id;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  const _InfoSection({
    required this.id,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: BlueDyeStudyStyle.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: BlueDyeStudyStyle.outline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('blue-meal-info-$id'),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: BlueDyeStudyStyle.ink(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const Divider(), ...children],
      ),
    ),
  );
}

class _FlowPart extends StatelessWidget {
  final String title;
  final List<String> lines;
  final bool numbered;
  const _FlowPart({
    required this.title,
    required this.lines,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${numbered
                  ? '${i + 1}. '
                  : lines.length > 1
                  ? '• '
                  : ''}${lines[i]}',
            ),
          ),
      ],
    ),
  );
}

class BlueDyeStudyDefinitions extends StatelessWidget {
  const BlueDyeStudyDefinitions({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.translate.blueMealTermsIntro),
      for (final definition in context.translate.blueMealTermsBody.split(
        '\n\n',
      ))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: definition.substring(0, definition.indexOf(':') + 1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: definition.substring(definition.indexOf(':') + 1),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _SupportLink extends StatelessWidget {
  const _SupportLink();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: () async {
        try {
          final opened = await launchUrl(
            Uri(scheme: 'mailto', path: blueMealSupportEmail),
          );
          if (!opened && context.mounted) {
            showSnack(context, blueMealSupportEmail);
          }
        } catch (_) {
          if (context.mounted) showSnack(context, blueMealSupportEmail);
        }
      },
      child: const Text(blueMealSupportEmail),
    ),
  );
}

class BlueDyeStudyIntroduction extends StatefulWidget {
  final VoidCallback onStart;
  final bool isLoading;
  const BlueDyeStudyIntroduction({
    required this.onStart,
    required this.isLoading,
    super.key,
  });
  @override
  State<BlueDyeStudyIntroduction> createState() =>
      _BlueDyeStudyIntroductionState();
}

class _BlueDyeStudyIntroductionState extends State<BlueDyeStudyIntroduction> {
  bool accepted = false;
  bool beforeBegin = false;
  final controller = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.translate;
    final navPadding = FloatingNavBarScope.bottomPaddingOf(context);
    final bottomPadding = navPadding > 0
        ? navPadding
        : MediaQuery.paddingOf(context).bottom;
    return Material(
      color: BlueDyeStudyStyle.surface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep room for reading even on short screens or with enlarged text.
          final footerHeight =
              (constraints.maxHeight - bottomPadding).clamp(
                0.0,
                double.infinity,
              ) *
              0.45;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('blue-meal-introduction-reading'),
                  controller: controller,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BlueDyeStudyHeader(
                              subtitle: beforeBegin
                                  ? s.blueMealGettingStarted
                                  : s.blueMealAboutTitle,
                              showInfo: beforeBegin,
                            ),
                            const SizedBox(height: 24),
                            if (!beforeBegin)
                              const BlueDyeStudyInformation()
                            else ...[
                              BlueDyeStudyCard(
                                title: s.blueMealBeforeBegin,
                                child: Text(s.blueMealBeforeBeginBody),
                              ),
                              const SizedBox(height: 16),
                              BlueDyeStudyCard(
                                title: s.blueMealTermsTitle,
                                child: const BlueDyeStudyDefinitions(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                key: const ValueKey('blue-meal-introduction-footer'),
                color: BlueDyeStudyStyle.canvas(context),
                shape: Border(
                  top: BorderSide(color: BlueDyeStudyStyle.outline(context)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: footerHeight),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!beforeBegin) ...[
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    titleAlignment: ListTileTitleAlignment.top,
                                    value: accepted,
                                    onChanged: widget.isLoading
                                        ? null
                                        : (value) => setState(
                                            () => accepted = value ?? false,
                                          ),
                                    title: Text(s.blueMealConsent),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                BlueDyeStudyAction(
                                  label: beforeBegin
                                      ? s.blueMealContinueStudy
                                      : s.blueMealStartStudy,
                                  loading: widget.isLoading,
                                  onPressed: !accepted
                                      ? null
                                      : beforeBegin
                                      ? widget.onStart
                                      : () {
                                          setState(() => beforeBegin = true);
                                          controller.jumpTo(0);
                                        },
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
            ],
          );
        },
      ),
    );
  }
}
