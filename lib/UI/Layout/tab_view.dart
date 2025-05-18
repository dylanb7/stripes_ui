import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/filter.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/config.dart';

import 'package:stripes_ui/entry.dart';

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
    return const TestScreen();
  }
}

class RecordScreenContent extends ConsumerWidget {
  const RecordScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AddIndicator(
      builder: (context, hasIndicator) => RefreshWidget(
        depth: RefreshDepth.authuser,
        scrollable: SizedBox.expand(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            key: scrollkey,
            controller: ScrollController(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: Column(children: [
                  const SizedBox(
                    height: 20,
                  ),
                  const Header(),
                  const Options(),
                  if (hasIndicator)
                    const SizedBox(
                      height: 100.0,
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryScreenContent extends ConsumerWidget {
  const HistoryScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);
    if (isSmall) {
      return AddIndicator(builder: (context, hasIndicator) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
            child: RefreshWidget(
              depth: RefreshDepth.authuser,
              scrollable: ListView(
                controller: ScrollController(),
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: PatientChanger(
                                tab: TabOption.history,
                              ),
                            ),
                            if (config.hasGraphing) ...[
                              IconButton(
                                onPressed: () {
                                  context.pushNamed(Routes.TRENDS);
                                },
                                icon: const Icon(Icons.trending_up),
                              ),
                            ]
                          ]),
                      const SizedBox(
                        height: 12.0,
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterView(),
                            SizedBox(
                              height: 8.0,
                            ),
                            EventsCalendar(),
                            SizedBox(
                              height: 16.0,
                            ),
                            ActionRow()
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const EventGrid(),
                ],
              ),
            ),
          ),
        );
      });
    }
    return AddIndicator(builder: (context, hasIndicator) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      PatientChanger(
                        tab: TabOption.history,
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      FilterView(),
                      SizedBox(
                        height: 8.0,
                      ),
                      EventsCalendar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                const SizedBox(
                  height: 8.0,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: ActionRow(),
                ),
                Expanded(
                  child: RefreshWidget(
                    depth: RefreshDepth.authuser,
                    scrollable: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      key: scrollkey,
                      controller: ScrollController(),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: EventGrid(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      );
    });
  }
}

class AddIndicator extends ConsumerWidget {
  final Widget Function(BuildContext context, bool hasAddition) builder;
  const AddIndicator({required this.builder, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user =
        ref.watch(authStream.select((value) => value.valueOrNull));
    final Widget? Function(AuthUser)? indicator =
        ref.watch(configProvider).stageIndicator;
    final Widget? addition = user != null ? indicator?.call(user) : null;
    return addition != null
        ? Stack(
            children: [
              builder(context, true),
              addition,
            ],
          )
        : builder(context, false);
  }
}

enum RefreshDepth { authuser, subuser, stamp }

class RefreshWidget extends ConsumerStatefulWidget {
  final Widget scrollable;
  final RefreshDepth depth;
  const RefreshWidget(
      {required this.scrollable, this.depth = RefreshDepth.subuser, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return RefreshWidgetState();
  }
}

class RefreshWidgetState extends ConsumerState<RefreshWidget> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
        onRefresh: () async {
          const String timeout = "Time Out";
          final Object? completed = await Future.any([
            if (widget.depth == RefreshDepth.authuser) authFuture(),
            if (widget.depth == RefreshDepth.subuser) subFuture(),
            if (widget.depth == RefreshDepth.stamp) stampFuture(),
            Future.delayed(const Duration(seconds: 5), () => timeout),
          ]);
          if (completed == timeout && context.mounted) {
            showSnack(context, "Timed out");
          }
        },
        child: widget.scrollable);
  }

  Future<AuthUser> authFuture() {
    ref.invalidate(authProvider);
    Completer<AuthUser> completer = Completer();
    ref.read(authProvider).user.listen((data) {
      completer.complete(data);
    });
    return completer.future;
  }

  Future<SubUserRepo?> subFuture() async {
    return ref.refresh(subProvider.future);
  }

  Future<StampRepo<Stamp>?> stampFuture() {
    return ref.refresh(stampProvider.future);
  }
}

class SmallLayout extends ConsumerWidget {
  final TabOption? selected;

  final Function(String)? customSelect;

  const SmallLayout({this.selected, this.customSelect, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasTests =
        ref.watch(testsHolderProvider).value?.testsRepo?.tests.isNotEmpty ??
            false;
    const divider = VerticalDivider(
      endIndent: 10.0,
      indent: 10.0,
      thickness: 1.0,
      width: 1.0,
    );

    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: NavTile(
                    icon: const Icon(Icons.add),
                    label: context.translate.recordTab,
                    onTap: () {
                      if (customSelect != null) {
                        customSelect!(Routes.HOME);
                      } else {
                        context.go(Routes.HOME);
                      }
                    },
                    selected: selected == TabOption.record),
              ),
              if (hasTests) ...[
                divider,
                Expanded(
                  child: NavTile(
                      icon: const Icon(Icons.checklist_outlined),
                      label: context.translate.testTab,
                      onTap: () {
                        if (customSelect != null) {
                          customSelect!(Routes.TEST);
                        } else {
                          context.go(Routes.TEST);
                        }
                      },
                      selected: selected == TabOption.tests),
                ),
              ],
              divider,
              Expanded(
                child: NavTile(
                    icon: const Icon(Icons.history),
                    label: context.translate.historyTab,
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
        ),
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
    return InkResponse(
      containedInkWell: true,
      onTap: () {
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: AnimatedContainer(
          duration: Durations.short4,
          decoration: selected
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(6.0),
                  ),
                )
              : const BoxDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Align(
                alignment: Alignment.topCenter,
                heightFactor: 1.0,
                child: IconTheme(
                  data: Theme.of(context).iconTheme.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final bool hasTests =
        ref.watch(testsHolderProvider).value?.testsRepo?.tests.isNotEmpty ??
            false;

    if (tab == TabOption.tests && !hasTests) return Container();

    Map<TabOption, String> buttonText = {
      TabOption.record: context.translate.recordTab,
      TabOption.tests: context.translate.testTab,
      TabOption.history: context.translate.historyTab,
    };

    final String text = buttonText[tab]!;

    Widget button() => TextButton(
        style: ButtonStyle(
            shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6.0))))),
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
          style: Theme.of(context).textTheme.bodyLarge,
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
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.all(
            Radius.circular(6.0),
          ),
        ),
        child: child,
      );
}
