import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/filter.dart';
import 'package:stripes_ui/UI/History/history_screen.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

import 'package:stripes_ui/l10n/app_localizations.dart';

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

  const StripesTabView({required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final ScrollController scrollController = ScrollController();
    final Map<String, dynamic>? attributes =
        ref.watch(authStream.select((value) => value.valueOrNull?.attributes));
    final Widget Function(Map<String, dynamic>)? indicator =
        ref.watch(configProvider).stageIndicator;
    final Widget? addition =
        attributes != null ? indicator?.call(attributes) : null;

    Widget scroll = ListView(
      key: scrollkey,
      controller: scrollController,
      children: [
        if (!isSmall) LargeLayout(selected: selected),
        if (selected == TabOption.record) ...const [
          SizedBox(
            height: 20,
          ),
          Header(),
          Options(),
        ],
        if (selected == TabOption.history) ...[
          const SizedBox(
            height: 20,
          ),
          Padding(
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
          const Column(
            children: [FilterView(), EventsCalendar(), ActionRow()],
          )
        ],
        if (selected == TabOption.tests) const TestScreen(),
      ],
    );

    final Widget stack = Stack(
      children: [
        scroll,
        if (addition != null)
          Positioned(
            bottom: 5.0,
            left: 5.0,
            right: 5.0,
            child: addition,
          )
      ],
    );
    return isSmall
        ? SmallLayout(
            selected: selected,
            child: stack,
          )
        : stack;
  }

  handleTap(BuildContext context, TabOption tapped, WidgetRef ref) {
    if (tapped == selected) return;

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

  const SmallLayout({required this.child, required this.selected, super.key});

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
        type: BottomNavigationBarType.shifting,
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

  const LargeLayout({required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget getButton(TabOption option, String text) => TextButton(
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
            child: getButton(
                TabOption.record, AppLocalizations.of(context)!.recordTab),
            context: context)
        : getButton(TabOption.record, AppLocalizations.of(context)!.recordTab);
    Widget testButton = selected == TabOption.tests
        ? _decorationWrap(
            child: getButton(
                TabOption.tests, AppLocalizations.of(context)!.testTab),
            context: context)
        : getButton(TabOption.tests, AppLocalizations.of(context)!.testTab);
    Widget historyButton = selected == TabOption.history
        ? _decorationWrap(
            child: getButton(
                TabOption.history, AppLocalizations.of(context)!.historyTab),
            context: context)
        : getButton(
            TabOption.history, AppLocalizations.of(context)!.historyTab);
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
              Image.asset(
                'packages/stripes_ui/assets/images/StripesLogo.png',
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

  Widget _decorationWrap(
          {required Widget child, required BuildContext context}) =>
      DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
                color: Theme.of(context).colorScheme.secondary, width: 2.0)),
        child: child,
      );
}
