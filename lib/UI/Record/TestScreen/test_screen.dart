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
import 'package:stripes_ui/l10n/app_localizations.dart';
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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .blueDyeHeader,
                                        style: darkBackgroundHeaderStyle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 4.0,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _dialog(context);
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: darkBackgroundText,
                                    ),
                                    iconSize: 30,
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
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      Expanded(
                        child: Card(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          elevation: 8.0,
                          child: Scrollbar(
                            thickness: 10,
                            radius: const Radius.circular(20),
                            thumbVisibility: true,
                            child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SingleChildScrollView(
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
                                )),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12.0,
                      ),
                      if (state.testInProgress)
                        Center(
                          child: StripesTextButton(
                              buttonText:
                                  AppLocalizations.of(context)!.blueDyeCancel,
                              mainTextColor: darkBackgroundText,
                              onClicked: () {
                                _cancelTest(context, ref);
                              }),
                        ),
                      const SizedBox(
                        height: 12.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (query.widget != null) query.widget!,
          ]),
        ),
      ),
    ));
  }

  _name(WidgetRef ref) {
    SubUser current = ref.read(subHolderProvider).current;
    return SubUser.isEmpty(current) ? 'N/A' : current.name;
  }

  _dialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(
                AppLocalizations.of(context)!.blueDyeInfoHeader,
                textAlign: TextAlign.center,
                style: lightBackgroundHeaderStyle,
              ),
              contentPadding: const EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 25.0, top: 10.0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
              children: [
                LabeledList(strings: [
                  AppLocalizations.of(context)!.blueDyeInfoLineOne,
                  AppLocalizations.of(context)!.blueDyeInfoLineTwo,
                  AppLocalizations.of(context)!.blueDyeInfoLineThree,
                  AppLocalizations.of(context)!.blueDyeInfoLineFour
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
                          AppLocalizations.of(context)!.errorPreventionTitle,
                          style: darkBackgroundHeaderStyle.copyWith(
                              color: buttonDarkBackground),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .blueMuffinErrorPreventionLineOne,
                          style: lightBackgroundStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .blueMuffinErrorPreventionLineTwo,
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
                        text:
                            AppLocalizations.of(context)!.errorPreventionLeave),
                    BasicButton(
                        onClick: (context) {
                          _closeOverlay(context, ref);
                        },
                        text:
                            AppLocalizations.of(context)!.errorPreventionStay),
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
