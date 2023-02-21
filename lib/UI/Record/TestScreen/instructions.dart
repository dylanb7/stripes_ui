import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/test_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

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
    final TestState state =
        ref.watch(testHolderProvider.select((value) => value.state));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExpandibleRaw(
          header: Text(
            widget.expandController.expanded
                ? 'Instructions'
                : state == TestState.started
                    ? '1) Eat Muffins'
                    : state == TestState.logs
                        ? '2) Record the Bowel Movements (BMs)'
                        : state == TestState.logsSubmit
                            ? '3) Submit the Test'
                            : 'Instructions',
            style: lightBackgroundHeaderStyle.copyWith(
                fontSize: 20.0, decoration: TextDecoration.underline),
          ),
          view: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 2.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledList(
                        title: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '1) Eat Muffins',
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
                            ]),
                        strings: const [
                          'When your participant starts eating muffins, select “Start Blue Meal',
                          'When your participant is done eating select “Finished Blue Meal”'
                        ],
                        mark: (index) => ['a.', 'b.'][index],
                        highlight: state == TestState.started),
                    const SizedBox(
                      height: 6.0,
                    ),
                    LabeledList(
                        title: const Text(
                          '2) Record the Bowel Movements (BMs)',
                          style: lightBackgroundHeaderStyle,
                        ),
                        strings: const [
                          'Log BMs from the Record page and indicate whether or not the BM has any (even partial) blue or blue green color.',
                          'It is common for the first couple of BMs after eating the muffin to not show blue yet.'
                        ],
                        mark: (index) => ['a.', 'b.'][index],
                        highlight: state == TestState.logs),
                    const SizedBox(
                      height: 6.0,
                    ),
                    LabeledList(
                        title: const Text(
                          '3) Submit the Test',
                          style: lightBackgroundHeaderStyle,
                        ),
                        strings: const [
                          'Submit test after recording the first BM that lacks any blue or blue green color.'
                        ],
                        mark: (_) => 'a.',
                        highlight: state == TestState.logsSubmit),
                    const SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          controller: widget.expandController,
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }

  _dialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => const SimpleDialog(
              title: Text(
                'Blue Muffins Info',
                textAlign: TextAlign.center,
                style: lightBackgroundHeaderStyle,
              ),
              contentPadding: EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 25.0, top: 10.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
              children: [
                LabeledList(strings: [
                  'Blue muffins will come in the mail.',
                  'They can be stored in the refrigerator.',
                  'To get ready for the test, remove the muffins from their packaging and heat them briefly, 20-30 seconds in the microwave or a few minutes in the oven.',
                  'Muffins should be the first thing the participant eats in the morning after an overnight fast of at least 6 hours.',
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

  final bool highlight;

  const LabeledList({
    required this.strings,
    required this.highlight,
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
            Text(
              marker(index.key),
              style: lightBackgroundStyle.copyWith(
                fontSize: 16.0,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: Text(
                index.value,
                softWrap: true,
                textAlign: TextAlign.left,
                style: lightBackgroundStyle,
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
            ],
          )
        : list;

    return Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6.0)),
            border: highlight ? Border.all(width: 2.0) : null),
        padding: const EdgeInsets.all(4.0),
        child: titleWidget);
  }
}
