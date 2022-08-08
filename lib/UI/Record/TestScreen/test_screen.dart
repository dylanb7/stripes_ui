import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/Record/TestScreen/initial.dart';
import 'package:stripes_ui/UI/Record/TestScreen/started_eating.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_logs.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestState state =
        ref.watch(testHolderProvider.select((value) => value.state));
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundStrong, backgroundLight])),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 15.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Blue Dye Test',
                          style: darkBackgroundScreenHeaderStyle,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: darkIconButton,
                            size: 35,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Card(
                        elevation: 5.0,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25))),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Builder(
                            builder: (context) {
                              switch (state) {
                                case TestState.initial:
                                  return Initial(
                                    ref: ref,
                                  );
                                case TestState.started:
                                  final DateTime start =
                                      ref.read(testHolderProvider).obj!.start!;
                                  return StartedEating(start: start, ref: ref);
                                default:
                                  return Logs();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    if (state.testInProgress)
                      StripesTextButton(
                          buttonText: 'Cancel Test',
                          mainTextColor: darkBackgroundText,
                          onClicked: () {
                            _cancelTest(context, ref);
                          }),
                    const SizedBox(
                      height: 12.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _cancelTest(BuildContext context, WidgetRef ref) {
    ref.read(testHolderProvider.notifier).cancel();
    Navigator.of(context).pop();
  }
}
