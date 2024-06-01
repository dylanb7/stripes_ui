import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/filter.dart';
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
  final TabOption selected;

  const TabContent({required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selected == TabOption.record) return const RecordScreenContent();
    if (selected == TabOption.tests) return const TestScreenContent();
    return const HistoryScreenContent();
  }
}

class TestScreenContent extends StatelessWidget {
  const TestScreenContent({super.key});
  @override
  Widget build(BuildContext context) {
    return AddIndicator(
      child: SingleChildScrollView(
        key: scrollkey,
        controller: ScrollController(),
        child: const TestScreen(),
      ),
    );
  }
}

class RecordScreenContent extends StatelessWidget {
  const RecordScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return AddIndicator(
      child: ListView(
        key: scrollkey,
        controller: ScrollController(),
        children: const [
          SizedBox(
            height: 20,
          ),
          Header(),
          Options(),
        ],
      ),
    );
  }
}

class HistoryScreenContent extends StatelessWidget {
  const HistoryScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return AddIndicator(
      child: CustomScrollView(
        key: scrollkey,
        controller: ScrollController(),
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
                const SizedBox(
                  height: 20,
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
              ]),
            ),
          ),
          const EventGrid()
        ],
      ),
    );
  }
}

class AddIndicator extends ConsumerWidget {
  final Widget child;
  const AddIndicator({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic>? attributes =
        ref.watch(authStream.select((value) => value.valueOrNull?.attributes));
    final Widget? Function(Map<String, dynamic>)? indicator =
        ref.watch(configProvider).stageIndicator;
    final Widget? addition =
        attributes != null ? indicator?.call(attributes) : null;
    return addition != null
        ? Stack(
            children: [child, addition],
          )
        : child;
  }
}

class SmallLayout extends ConsumerWidget {
  final TabOption? selected;

  final Function(String)? customSelect;

  const SmallLayout({this.selected, this.customSelect, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(authStream).valueOrNull;
    final bool hasTests = user?.attributes["custom:group"] != null;
    const divider = VerticalDivider(
      endIndent: 10.0,
      indent: 10.0,
      thickness: 1.0,
      width: 1.0,
    );
    return Container(
      decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
          color: Theme.of(context).canvasColor),
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: NavTile(
                icon: const Icon(Icons.add),
                label: AppLocalizations.of(context)!.recordTab,
                onTap: () {
                  if (customSelect != null) {
                    customSelect!(Routes.HOME);
                  } else {
                    context.go(Routes.HOME);
                  }
                },
                selected: selected == TabOption.record),
          ),
          divider,
          Expanded(
            child: NavTile(
                icon: const Icon(Icons.checklist_outlined),
                label: AppLocalizations.of(context)!.testTab,
                onTap: () {
                  if (customSelect != null) {
                    customSelect!(Routes.TEST);
                  } else {
                    context.go(Routes.TEST);
                  }
                },
                selected: selected == TabOption.tests),
          ),
          divider,
          Expanded(
            child: NavTile(
                icon: const Icon(Icons.grading),
                label: AppLocalizations.of(context)!.historyTab,
                onTap: () {
                  if (customSelect != null) {
                    customSelect!(Routes.HISTORY);
                  } else {
                    context.go(Routes.HISTORY);
                  }
                },
                selected: selected == TabOption.history),
          ),
        ],
      ),
    );
  }
}

class NavTile extends StatelessWidget {
  final Icon icon;

  final Icon? activeIcon;

  final Function onTap;

  final String label;

  final bool selected;

  const NavTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.selected,
      this.activeIcon,
      super.key});

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor = Theme.of(context).disabledColor;
    return InkResponse(
      containedInkWell: true,
      onTap: () {
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Align(
            alignment: Alignment.topCenter,
            heightFactor: 1.0,
            child: IconTheme(
              data: Theme.of(context).iconTheme.copyWith(
                    color: selected ? selectedColor : unselectedColor,
                  ),
              child: selected ? activeIcon ?? icon : icon,
            ),
          ),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1.0,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? selectedColor : unselectedColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LargeNavButton extends ConsumerWidget {
  final TabOption tab;

  final TabOption? selected;

  final Function(String)? customSelect;

  const LargeNavButton(
      {required this.tab, this.selected, this.customSelect, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<TabOption, String> buttonText = {
      TabOption.record: AppLocalizations.of(context)!.recordTab,
      TabOption.tests: AppLocalizations.of(context)!.testTab,
      TabOption.history: AppLocalizations.of(context)!.historyTab,
    };

    final String text = buttonText[tab]!;

    Widget button() => TextButton(
        onPressed: () {
          String route = Routes.HOME;
          if (tab == TabOption.tests) {
            route = Routes.TEST;
          } else if (tab == TabOption.history) {
            route = Routes.HISTORY;
          }
          if (customSelect != null) {
            customSelect!(route);
          } else {
            context.push(route);
          }
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
