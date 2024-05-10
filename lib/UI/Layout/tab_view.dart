import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/filter.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';

import 'package:stripes_ui/Util/constants.dart';
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

class TabContent extends ConsumerWidget {
  const TabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final ScrollController scrollController = ScrollController();
    final selected = ref.watch(tabProvider);
    final Map<String, dynamic>? attributes =
        ref.watch(authStream.select((value) => value.valueOrNull?.attributes));
    final Widget? Function(Map<String, dynamic>)? indicator =
        ref.watch(configProvider).stageIndicator;
    final Widget? addition =
        attributes != null ? indicator?.call(attributes) : null;

    Widget scroll;

    if (selected == TabOption.history) {
      scroll = CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            sliver: SliverToBoxAdapter(
              child: Column(children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: PatientChanger(
                          tab: TabOption.history,
                        ),
                      ),
                    ]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: const Column(
                      children: [FilterView(), EventsCalendar(), ActionRow()],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const EventGrid()
        ],
      );
    } else {
      scroll = ListView(
        key: scrollkey,
        controller: scrollController,
        children: [
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: PatientChanger(
                        tab: TabOption.history,
                      ),
                    ),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Column(
                  children: [FilterView(), EventsCalendar(), ActionRow()],
                ),
              ),
            ),
            const EventGrid()
          ],
          if (selected == TabOption.tests) const TestScreen(),
        ],
      );
    }

    return Stack(
      children: [
        scroll,
        if (addition != null) addition,
      ],
    );
  }
}

class SmallLayout extends ConsumerWidget {
  final TabOption selected;

  const SmallLayout({required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: TabOption.values.indexOf(selected),
      onTap: (index) {
        ref.read(tabProvider.notifier).state = TabOption.values[index];
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
    );
  }
}

class LargeNavButton extends ConsumerWidget {
  final TabOption tab;

  const LargeNavButton({required this.tab, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TabOption selected = ref.watch(tabProvider);

    Map<TabOption, String> buttonText = {
      TabOption.record: AppLocalizations.of(context)!.recordTab,
      TabOption.tests: AppLocalizations.of(context)!.testTab,
      TabOption.history: AppLocalizations.of(context)!.historyTab,
    };

    final String text = buttonText[tab]!;

    Widget button() => TextButton(
        onPressed: () {
          ref.read(tabProvider.notifier).state = tab;
        },
        child: Text(
          text,
        ));

    if (tab == selected) {
      return _decorationWrap(child: button(), context: context);
    }
    return button();
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
