import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';

import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/record_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';

enum TabOption {
  record('Record'),
  tests('Tests'),
  history('History');

  const TabOption(this.value);
  final String value;
}

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
            controller: ScrollController(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: Column(children: [
                  const SizedBox(
                    height: AppPadding.xl,
                  ),
                  const Header(),
                  const Options(),
                  if (hasIndicator)
                    const SizedBox(
                      height: AppPadding.xxxl,
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
    return const EventsView();
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
          navBarHeaderKey.currentState?.setLoading(isLoading: true);
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
          navBarHeaderKey.currentState?.setLoading(isLoading: false);
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
      endIndent: AppPadding.small,
      indent: AppPadding.small,
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
                        ref
                            .read(navigationControllerProvider)
                            .navigate(context, Routes.HOME);
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
                          ref
                              .read(navigationControllerProvider)
                              .navigate(context, Routes.TEST);
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
                      if (selected == TabOption.history) {
                        if (ref
                            .read(historyScrollControllerProvider)
                            .hasClients) {
                          ref.read(historyScrollControllerProvider).animateTo(0,
                              duration: Durations.medium2,
                              curve: Curves.easeInOut);
                        }
                      }
                      if (customSelect != null) {
                        customSelect!(Routes.HISTORY);
                      } else {
                        ref
                            .read(navigationControllerProvider)
                            .navigate(context, Routes.HISTORY);
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.small, vertical: AppPadding.tiny),
        child: AnimatedContainer(
          duration: Durations.short4,
          decoration: selected
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRounding.tiny),
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
                borderRadius:
                    BorderRadius.all(Radius.circular(AppRounding.tiny))))),
        onPressed: () {
          if (tab == TabOption.history && selected == TabOption.history) {
            if (ref.read(historyScrollControllerProvider).hasClients) {
              ref.read(historyScrollControllerProvider).animateTo(0,
                  duration: Durations.medium2, curve: Curves.easeInOut);
            }
          }
          String route = Routes.HOME;
          if (tab == TabOption.tests) {
            route = Routes.TEST;
          } else if (tab == TabOption.history) {
            route = Routes.HISTORY;
          }
          if (customSelect != null) {
            customSelect!(route);
          } else {
            ref.read(navigationControllerProvider).navigate(context, route);
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
            Radius.circular(AppRounding.tiny),
          ),
        ),
        child: child,
      );
}
