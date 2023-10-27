import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/TestScreen/instructions.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_content.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
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
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final TestNotifier notifier = ref.watch(testHolderProvider);
    final TestState state = notifier.state;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: PatientChanger(
                      tab: TabOption.tests,
                    ),
                  ),
                  isSmall
                      ? const UserProfileButton()
                      : const SizedBox(
                          width: 35,
                        )
                ]),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.blueDyeHeader,
                style: darkBackgroundHeaderStyle,
                textAlign: TextAlign.left,
              ),
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Instructions(
                expandController: expandListener,
              ),
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
          if (state == TestState.initial) ...[
            const Info(),
            const SizedBox(
              height: 4.0,
            ),
          ],
          Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TestContent(
                  expand: expandListener,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
          const SizedBox(
            height: 4.0,
          ),
          if (state.testInProgress)
            Center(
              child: TextButton(
                onPressed: () {
                  _cancelTest(context, ref);
                },
                child: Text(AppLocalizations.of(context)!.blueDyeCancel),
              ),
            ),
          const SizedBox(
            height: 12.0,
          ),
        ]),
      ),
    );
  }

  _name(WidgetRef ref) {
    SubUser current = ref.read(subHolderProvider).current;
    return SubUser.isEmpty(current) ? 'N/A' : current.name;
  }

  _cancelTest(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const OverlayQuery(widget: TestErrorPrevention());
  }
}

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpandibleRaw(
        header: Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.blueDyeInfoHeader,
              textAlign: TextAlign.center,
              style: lightBackgroundHeaderStyle,
            ),
          ),
        ),
        iconSize: 35,
        view: LabeledList(strings: [
          AppLocalizations.of(context)!.blueDyeInfoLineOne,
          AppLocalizations.of(context)!.blueDyeInfoLineTwo,
          AppLocalizations.of(context)!.blueDyeInfoLineThree,
          AppLocalizations.of(context)!.blueDyeInfoLineFour
        ], highlight: false),
      ),
    );
  }
}

class TestErrorPrevention extends ConsumerWidget {
  const TestErrorPrevention({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        title: Text(
          AppLocalizations.of(context)!.errorPreventionTitle,
          style: darkBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.blueMuffinErrorPreventionLineOne,
              style: lightBackgroundStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              AppLocalizations.of(context)!.blueMuffinErrorPreventionLineTwo,
              style: lightBackgroundStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        onConfirm: () {
          ref.read(testHolderProvider.notifier).cancel();
        },
        cancel: AppLocalizations.of(context)!.errorPreventionStay,
        confirm: AppLocalizations.of(context)!.errorPreventionLeave);
    /*return Stack(
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
                        color: buttonDarkBackground,
                        onClick: (context) {
                          _dismiss(context, ref);
                        },
                        text:
                            AppLocalizations.of(context)!.errorPreventionLeave),
                    BasicButton(
                        color: buttonLightBackground,
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
    );*/
  }
}
