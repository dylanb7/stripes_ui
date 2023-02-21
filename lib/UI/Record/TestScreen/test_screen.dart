import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/TestScreen/instructions.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_content.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import '../../../Providers/sub_provider.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  late final ExpandibleController expandListener;

  @override
  void initState() {
    expandListener = ExpandibleController(true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final TestState state =
        ref.watch(testHolderProvider.select((value) => value.state));
    final OverlayQuery query = ref.watch(overlayProvider);
    return SafeArea(
      child: Scaffold(
        body: SizedBox.expand(
          child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [backgroundStrong, backgroundLight])),
            child: Stack(children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 15.0 : 40.0, vertical: 15.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Blue Dye Test',
                                              style:
                                                  darkBackgroundScreenHeaderStyle,
                                            ),
                                            const SizedBox(
                                              width: 4.0,
                                            ),
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: IconButton(
                                                onPressed: () {
                                                  _dialog(context);
                                                },
                                                icon: const Icon(
                                                  Icons.info_outline,
                                                  color: darkBackgroundText,
                                                ),
                                                iconSize: 30,
                                              ),
                                            )
                                          ]),
                                      Text(
                                        _name(ref),
                                        style: darkBackgroundStyle,
                                      ),
                                    ]),
                                IconButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go(Routes.HOME);
                                    }
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
                                  child: Column(
                                    children: [
                                      Instructions(
                                        expandController: expandListener,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16.0),
                                        child: TestContent(
                                          expand: expandListener,
                                        ),
                                      ),
                                    ],
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
              if (query.widget != null) query.widget!,
            ]),
          ),
        ),
      ),
    );
  }

  _name(WidgetRef ref) {
    SubUser current = ref.read(subHolderProvider).current;
    return SubUser.isEmpty(current) ? 'N/A' : current.name;
  }

  _dialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => const SimpleDialog(
              title: Text(
                'Blue Dye Test Info',
                textAlign: TextAlign.center,
                style: lightBackgroundHeaderStyle,
              ),
              contentPadding: EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 25.0, top: 10.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
              children: [
                LabeledList(strings: [
                  'The Blue Dye Test measures the time it takes for food to transit through the gut.',
                  'To start the test, your participant(s) should eat two blue muffins in the morning after a minimum of a six hour fasting period.',
                  'Record bowel movements, noting whether there is a blue blue-green color.',
                  'Submit test after recording the first BM that lacks any blue or blue green color.'
                ], highlight: false),
              ],
            ));
  }

  _cancelTest(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const OverlayQuery(widget: TestErrorPrevention());
  }
}

class TestErrorPrevention extends ConsumerWidget {
  const TestErrorPrevention({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: lightBackgroundText.withOpacity(0.9),
          ),
        ),
        Center(
          child: SizedBox(
            width: SMALL_LAYOUT / 1.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Wait!',
                          style: darkBackgroundHeaderStyle.copyWith(
                              color: buttonDarkBackground),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'Are you sure you want to cancel your blue dye test?',
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'You will lose all progress',
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BasicButton(
                        onClick: (context) {
                          _dismiss(context, ref);
                        },
                        text: 'Leave'),
                    BasicButton(
                        onClick: (context) {
                          _closeOverlay(context, ref);
                        },
                        text: 'Stay'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _dismiss(BuildContext context, WidgetRef ref) {
    ref.read(testHolderProvider.notifier).cancel();
    _closeOverlay(context, ref);
    if (context.canPop()) {
      context.pop();
    } else {
      context.push(Routes.HOME);
    }
  }

  _closeOverlay(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}
