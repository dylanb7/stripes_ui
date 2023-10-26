import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/history_screen.dart';
import 'package:stripes_ui/UI/History/location_bar.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'home_screen.dart';

enum TabOption {
  record('Record'),
  tests('Tests'),
  history('History');

  const TabOption(this.value);
  final String value;
}

final GlobalKey scrollkey = GlobalKey();

class StripesTabView extends ConsumerWidget {
  final TabOption selected;

  const StripesTabView({required this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    HistoryLocation loc = ref.watch(historyLocationProvider);
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final ScrollController scrollController = ScrollController();

    Widget scroll = CustomScrollView(
      key: scrollkey,
      controller: scrollController,
      slivers: [
        if (!isSmall) LargeLayout(selected: selected),
        if (selected == TabOption.record) ...const [
          SliverPadding(padding: EdgeInsets.only(top: 20.0)),
          Header(),
          Options(),
        ],
        if (selected == TabOption.history) ...[
          const SliverPadding(padding: EdgeInsets.only(top: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: PatientChanger(
                        tab: TabOption.history,
                      ),
                    ),
                    isSmall
                        ? const UserProfileButton()
                        : const SizedBox(
                            width: 35,
                          )
                  ]),
            ),
          ),
          const LocationBar(),
          ...SliversConfig(loc).slivers,
        ],
        if (selected == TabOption.tests) const TestScreen()
      ],
    );
    return isSmall
        ? SmallLayout(
            selected: selected,
            child: scroll,
          )
        : scroll;
  }

  handleTap(BuildContext context, TabOption tapped, WidgetRef ref) {
    if (tapped == selected) return;
    ref.read(actionProvider.notifier).state = null;
    if (tapped == TabOption.record) {
      context.go(Routes.HOME);
    } else if (tapped == TabOption.history) {
      context.go(Routes.HISTORY);
    } else if (tapped == TabOption.tests) {
      context.goNamed(Routes.TEST);
    }
  }
}

class SmallLayout extends ConsumerWidget {
  final TabOption selected;

  final Widget child;

  const SmallLayout({required this.child, required this.selected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      Expanded(
        child: SafeArea(
          bottom: false,
          child: child,
        ),
      ),
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: TabOption.values.indexOf(selected),
        onTap: (index) {
          context
              .findAncestorWidgetOfExactType<StripesTabView>()!
              .handleTap(context, TabOption.values[index], ref);
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(
                Icons.add,
              ),
              label: AppLocalizations.of(context)!.recordTab),
          BottomNavigationBarItem(
              icon: const Icon(
                Icons.checklist_outlined,
              ),
              label: AppLocalizations.of(context)!.testTab),
          BottomNavigationBarItem(
              icon: const Icon(
                Icons.grading,
              ),
              label: AppLocalizations.of(context)!.historyTab),
        ],
      )
    ]);
  }
}

class LargeLayout extends ConsumerWidget {
  final TabOption selected;

  const LargeLayout({required this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget getButton(TextStyle style, TabOption option, String text) =>
        TextButton(
            onPressed: () {
              context
                  .findAncestorWidgetOfExactType<StripesTabView>()!
                  .handleTap(context, option, ref);
            },
            child: Text(
              text,
            ));

    Widget recordButton = selected == TabOption.record
        ? _decorationWrap(
            child: getButton(darkBackgroundHeaderStyle, TabOption.record,
                AppLocalizations.of(context)!.recordTab))
        : getButton(darkBackgroundHeaderStyle, TabOption.record,
            AppLocalizations.of(context)!.recordTab);
    Widget testButton = selected == TabOption.tests
        ? _decorationWrap(
            child: getButton(darkBackgroundHeaderStyle, TabOption.tests,
                AppLocalizations.of(context)!.testTab))
        : getButton(darkBackgroundHeaderStyle, TabOption.tests,
            AppLocalizations.of(context)!.testTab);
    Widget historyButton = selected == TabOption.history
        ? _decorationWrap(
            child: getButton(darkBackgroundHeaderStyle, TabOption.history,
                AppLocalizations.of(context)!.historyTab))
        : getButton(darkBackgroundHeaderStyle, TabOption.history,
            AppLocalizations.of(context)!.historyTab);
    return SliverAppBar(
      snap: true,
      floating: true,
      expandedHeight: 70,
      collapsedHeight: 70,
      centerTitle: true,
      flexibleSpace: Center(
        child: SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 6.0,
              ),
              _decorationWrap(
                child: Image.asset(
                  'packages/stripes_ui/assets/images/StripesLogo.png',
                ),
              ),
              const Spacer(),
              recordButton,
              const SizedBox(
                width: 12.0,
              ),
              testButton,
              const SizedBox(
                width: 12.0,
              ),
              historyButton,
              const SizedBox(
                width: 25.0,
              ),
              const UserProfileButton(),
              const SizedBox(
                width: 12.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decorationWrap({required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: child,
      );
}
