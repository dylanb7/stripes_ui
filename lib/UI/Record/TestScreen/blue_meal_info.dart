import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BlueMealPreStudy extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  final Function onClick;

  final bool isLoading;

  BlueMealPreStudy({required this.onClick, required this.isLoading, super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAssistedList(
        builder: (context, properties) => SingleChildScrollView(
              key: properties.scrollStateKey,
              controller: properties.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ColoredBox(
                    color: Colors.yellow.withOpacity(0.5),
                    child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.preStudySeeing,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              AppLocalizations.of(context)!.preStudySeeingExp,
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
                    AppLocalizations.of(context)!.preStudyEnrollTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(AppLocalizations.of(context)!.preStudyEnrollDescPartOne),
                  const SizedBox(
                    height: 12.0,
                  ),
                  Text(AppLocalizations.of(context)!.preStudyEnrollDescPartTwo),
                  const SizedBox(
                    height: 25.0,
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              onClick();
                            },
                      child: isLoading
                          ? const ButtonLoadingIndicator()
                          : Text(AppLocalizations.of(context)!
                              .preStudyEnrollButton),
                    ),
                  ),
                  const SizedBox(
                    height: 50.0,
                  ),
                ],
              ),
            ),
        scrollController: _scrollController);
  }
}

class BlueMealInfoSheet extends StatelessWidget {
  final ScrollController scrollController;

  const BlueMealInfoSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
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
                        ColoredBox(
                          color: Colors.yellow.withOpacity(0.5),
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
                                onPressed: () {},
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
            title: Text(AppLocalizations.of(context)!.studyFlowPrepTitle),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
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
              color: Colors.yellow.withOpacity(0.5),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    AppLocalizations.of(context)!
                        .studyStepTwoExplanationPartOneDetailThree
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surfaceTint, 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                AppLocalizations.of(context)!.studyStepFourExplanationPartThree,
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

class LabeledList extends StatelessWidget {
  final List<String> strings;

  final String Function(int)? mark;

  final Widget? title;

  final List<Widget>? additions;

  final bool highlight;

  const LabeledList({
    required this.strings,
    required this.highlight,
    this.additions,
    this.title,
    this.mark,
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
              width: 5,
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
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
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
        padding: const EdgeInsets.all(4.0),
        child: titleWidget);
  }
}
