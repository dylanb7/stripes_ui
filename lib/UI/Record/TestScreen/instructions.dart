/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';

import 'package:stripes_ui/l10n/app_localizations.dart';

class Instructions extends ConsumerStatefulWidget {
  final ExpandibleController expandController;

  const Instructions({required this.expandController, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _InstructionsState();
}

class _InstructionsState extends ConsumerState<Instructions> {
  @override
  void initState() {
    widget.expandController.addListener(_expandListener);
    super.initState();
  }

  _expandListener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BlueDyeObj? blueDye =
        getObject<BlueDyeObj>(ref.watch(testStreamProvider));
    final BlueDyeTestStage state =
        blueDye == null ? BlueDyeTestStage.initial : stateFromTestOBJ(blueDye);
    final String stage = state == BlueDyeTestStage.started
        ? context.translate.blueDyeInstructionsStepOne
        : state == BlueDyeTestStage.logs
            ? context.translate.blueDyeInstructionsStepTwo
            : context.translate.blueDyeInstructionsStepThree;
    final Widget header = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translate.blueDyeInstructionsHeader,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.left,
          ),
          if (state != BlueDyeTestStage.initial &&
              !widget.expandController.expanded) ...[
            const SizedBox(
              height: 4.0,
            ),
            Text(
              stage,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          ]
        ]);

    final Widget body =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(
        height: 2.0,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledList(
                title: Text(
                  context.translate.blueDyeInstructionsStepOne,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                /*Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        context.translate
                            .blueDyeInstructionsStepOne,
                        textAlign: TextAlign.left,
                        style: lightBackgroundHeaderStyle,
                      ),
                      const SizedBox(
                        width: 4.0,
                      ),
                      SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: IconButton(
                          onPressed: () {
                            _dialog(context);
                          },
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.info_outline,
                            color: lightIconButton,
                          ),
                          iconSize: 18.0,
                        ),
                      ),
                    ]),*/
                strings: [
                  context.translate.blueDyeInstructionsStepOneA,
                  context.translate.blueDyeInstructionsStepOneB
                ],
                mark: (index) => ['a.', 'b.'][index],
                highlight: state == BlueDyeTestStage.started),
            const SizedBox(
              height: 6.0,
            ),
            LabeledList(
                title: Text(
                  context.translate.blueDyeInstructionsStepTwo,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                strings: [
                  context.translate.blueDyeInstructionsStepTwoA,
                  context.translate.blueDyeInstructionsStepTwoB
                ],
                mark: (index) => ['a.', 'b.'][index],
                highlight: state == BlueDyeTestStage.logs),
            const SizedBox(
              height: 6.0,
            ),
            LabeledList(
                title: Text(
                  context.translate.blueDyeInstructionsStepThree,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                strings: [
                  context.translate.blueDyeInstructionsStepThreeA
                ],
                mark: (_) => 'a.',
                highlight: state == BlueDyeTestStage.logsSubmit),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
      )
    ]);
    /*if (state == TestState.initial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(fit: BoxFit.scaleDown, child: header),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: body,
          )
        ],
      );
    }*/
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpandibleRaw(
          header: Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: header,
            ),
          ),
          iconSize: 35,
          view: body,
          controller: widget.expandController,
        ),
      ],
    );
  }

  _dialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(
                context.translate.blueMuffinsInfoHeader,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              contentPadding: const EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 25.0, top: 10.0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
              children: [
                LabeledList(strings: [
                  context.translate.blueMuffinsInfoLineOne,
                  context.translate.blueMuffinsInfoLineTwo,
                  context.translate.blueMuffinsInfoLineThree,
                  context.translate.blueMuffinsInfoLineFour,
                ], highlight: false),
              ],
            ));
  }

  @override
  void dispose() {
    widget.expandController.removeListener(_expandListener);
    super.dispose();
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
}*/
