import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StripesTextButton(
              buttonText: 'About',
              onClicked: () {},
              mainTextColor: lightBackgroundText,
            ),
          ],
        ),
        const SizedBox(
          height: 35,
        )
      ],
    ));
  }
}

class Options extends ConsumerWidget {
  const Options({Key? key}) : super(key: key);

  static const symToRoute = <String, String>{
    Symptoms.BM: Routes.BM,
    Symptoms.PAIN: Routes.PAIN,
    Symptoms.REFLUX: Routes.REFLUX,
    Symptoms.NB: Routes.NB,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(questionHomeProvider);
    final TestState state =
        ref.watch(testHolderProvider.select((value) => value.state));
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            const SizedBox(
              height: 20.0,
            ),
            const Text(
              'Select a category to record:',
              style: darkBackgroundHeaderStyle,
            ),
            ...Options.symToRoute.keys.map((key) {
              final String route = Options.symToRoute[key]!;
              if (key != Symptoms.BM || !state.testInProgress) {
                return RecordButton(key, (context) {
                  context.pushNamed(route);
                });
              }
              return RecordButton(
                key,
                (context) {
                  context.pushNamed(route);
                },
                subText: 'Blue Dye Test in Progress',
              );
            }).toList(growable: false),
            const StartTest(),
            const SizedBox(
              height: 20.0,
            ),
            const Divider(
              height: 2,
              indent: 15,
              endIndent: 15,
              color: darkBackgroundText,
              thickness: 2,
            ),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends ConsumerWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isSmall = ref.watch(isSmallProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      sliver: SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const PatientChanger(),
              const Spacer(),
              isSmall
                  ? const UserProileButton()
                  : const SizedBox(
                      width: 35,
                    ),
            ],
          ),
          const SizedBox(
            height: 4.0,
          ),
          const LastEntryText(),
        ]),
      ),
    );
  }
}

class LastEntryText extends ConsumerWidget {
  const LastEntryText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Stamp> vals = ref.watch(stampHolderProvider).stamps;
    final String lastEntry = vals.isEmpty
        ? 'No Patient Entries'
        : 'Last Entry: ${dateToMDY(dateFromStamp(vals.first.stamp))}';
    return Text(
      lastEntry,
      style: darkBackgroundStyle.copyWith(fontSize: 16.0),
    );
  }
}

class StartTest extends ConsumerWidget {
  const StartTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestNotifier testNotifier = ref.watch(testHolderProvider);
    String message = '';
    switch (testNotifier.state) {
      case TestState.started:
        message = 'Test Started';
        break;
      case TestState.logs:
        message = 'Logging BMs - Logged: ${testNotifier.obj?.logs.length ?? 0}';
        break;
      case TestState.logsSubmit:
        message = 'Logging BMs - Test Submittable';
        break;
      default:
        break;
    }

    return RecordButton(
      'Blue Dye Test',
      (context) {
        context.pushNamed(Routes.TEST);
      },
    );
  }
}

class RecordButton extends StatelessWidget {
  final String text;
  final String? subText;
  final Function(BuildContext) onClick;

  const RecordButton(this.text, this.onClick, {this.subText, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT / 1.5),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          onTap: () {
            onClick(context);
          },
          child: Card(
            color: darkBackgroundText,
            elevation: 12,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                side: BorderSide(color: Colors.transparent, width: 0)),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (subText != null && subText!.isNotEmpty)
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: lightBackgroundHeaderStyle,
                          ),
                          Text(
                            subText!,
                            style: lightBackgroundStyle.copyWith(
                                fontSize: 16.0, color: darkIconButton),
                          ),
                        ]),
                  if (subText == null || subText!.isEmpty)
                    Text(
                      text,
                      style: lightBackgroundHeaderStyle,
                    ),
                  const Icon(
                    Icons.add,
                    size: 35,
                    color: darkIconButton,
                  )
                ],
              ),
            ),
          ),
        )).showCursorOnHover;
  }
}
