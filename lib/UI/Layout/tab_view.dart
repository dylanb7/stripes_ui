import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/History/DashboardView/dashboard_home.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';

import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/record_screen.dart';

import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/reading_size.dart';

import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

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
    final bool dashboard = ref.watch(configProvider).betaUi.dashboard;
    return IndexedStack(
      index: selected.index,
      children: [
        if (dashboard)
          const DashboardHomeContent()
        else
          const RecordScreenContent(),
        const TestScreenContent(),
        const HistoryScreenContent(),
      ],
    );
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
                child: Column(
                  children: [
                    const SizedBox(height: AppPadding.xl),
                    const Header(),
                    const Options(),
                    SizedBox(
                      height:
                          FloatingNavBarScope.bottomPaddingOf(context) +
                          (hasIndicator ? AppPadding.xxxl : AppPadding.large),
                    ),
                  ],
                ),
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
    final AuthUser? user = ref
        .watch(authStream)
        .when(
          data: (user) => user,
          loading: () => null,
          error: (error, stackTrace) => null,
        );
    final Widget? Function(AuthUser)? indicator = ref
        .watch(configProvider)
        .stageIndicator;
    final Widget? addition = user != null ? indicator?.call(user) : null;
    return addition != null
        ? Stack(children: [builder(context, true), addition])
        : builder(context, false);
  }
}

enum RefreshDepth { authuser, subuser, stamp }

class RefreshWidget extends ConsumerStatefulWidget {
  final Widget scrollable;
  final RefreshDepth depth;
  const RefreshWidget({
    required this.scrollable,
    this.depth = RefreshDepth.subuser,
    super.key,
  });

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
          _refresh(),
          Future.delayed(const Duration(seconds: 5), () => timeout),
        ]);
        if (completed == timeout && context.mounted) {
          showSnack(context, "Timed out");
        }
        navBarHeaderKey.currentState?.setLoading(isLoading: false);
      },
      child: widget.scrollable,
    );
  }

  Future<void> _refresh() async {
    switch (widget.depth) {
      case RefreshDepth.authuser:
        await Future.wait([
          authFuture(),
          subFuture(),
          stampFuture(),
          testFuture(),
        ]);
        break;
      case RefreshDepth.subuser:
        await Future.wait([subFuture(), stampFuture(), testFuture()]);
        break;
      case RefreshDepth.stamp:
        await stampFuture();
        break;
    }
  }

  Future<AuthUser> authFuture() {
    ref.invalidate(authProvider);
    Completer<AuthUser> completer = Completer();
    ref.read(authProvider).user.listen((data) {
      if (completer.isCompleted) return;
      completer.complete(data);
    });
    return completer.future;
  }

  Future<SubUserRepo?> subFuture() async {
    final SubUserRepo? repo = await ref.read(subProvider.future);
    await repo?.refresh();
    return repo;
  }

  Future<StampRepo<Stamp>?> stampFuture() async {
    final StampRepo<Stamp>? repo = await ref.read(stampProvider.future);
    await repo?.refresh();
    return repo;
  }

  Future<void> testFuture() async {
    // Modular test system handles state reactively; no explicit refresh needed.
  }
}

// ---------------------------------------------------------------------------
// Mobile bottom navigation
// ---------------------------------------------------------------------------

class SmallLayout extends ConsumerWidget {
  final TabOption? selected;

  final Function(String)? customSelect;

  /// Optional content for the expandable secondary row.
  final Widget? secondaryContent;

  const SmallLayout({
    this.selected,
    this.customSelect,
    this.secondaryContent,
    super.key,
  });

  static const Map<TabOption, String> _tabRoutes = {
    TabOption.record: Routes.HOME,
    TabOption.tests: Routes.TEST,
    TabOption.history: Routes.HISTORY,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final betaUi = ref.watch(configProvider).betaUi;
    final bool dashboard = betaUi.dashboard;
    final bool hasTests = ref
        .watch(hasTestsProvider)
        .when(
          data: (hasTests) => hasTests,
          loading: () => false,
          error: (error, stackTrace) => false,
        );

    final List<FloatingNavItem> items = [
      FloatingNavItem(
        icon: dashboard ? Icons.dashboard_outlined : Icons.add,
        activeIcon: dashboard ? Icons.dashboard : Icons.add_circle,
        label: dashboard ? 'Home' : context.translate.recordTab,
      ),
      if (hasTests)
        FloatingNavItem(
          icon: Icons.checklist_outlined,
          activeIcon: Icons.checklist,
          label: context.translate.testTab,
        ),
      FloatingNavItem(
        icon: Icons.history,
        activeIcon: Icons.history_rounded,
        label: context.translate.historyTab,
      ),
    ];

    // Parallel list mapping item indices back to TabOptions.
    final List<TabOption> tabOptions = [
      TabOption.record,
      if (hasTests) TabOption.tests,
      TabOption.history,
    ];

    final int activeIndex = tabOptions.indexOf(selected ?? TabOption.record);

    void onTap(int index) {
      final option = tabOptions[index];
      if (option == TabOption.history && selected == TabOption.history) {
        if (ref.read(historyScrollControllerProvider).hasClients) {
          ref
              .read(historyScrollControllerProvider)
              .animateTo(
                0,
                duration: Durations.medium2,
                curve: Curves.easeInOut,
              );
        }
      }
      final route = _tabRoutes[option]!;
      if (customSelect != null) {
        customSelect!(route);
      } else {
        ref.read(navigationControllerProvider).navigate(context, route);
      }
    }

    if (ref.watch(configProvider).display.useLegacyNavigation) {
      return _LegacyBottomNavigation(
        items: items,
        activeIndex: activeIndex,
        onTap: onTap,
        secondaryContent: secondaryContent,
      );
    }
    return _StandardBottomNavigation(
      items: items,
      activeIndex: activeIndex,
      onTap: onTap,
      secondaryContent: secondaryContent,
    );
  }
}

class _LegacyBottomNavigation extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final Widget? secondaryContent;

  const _LegacyBottomNavigation({
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.secondaryContent,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).canvasColor,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?secondaryContent,
        SafeArea(
          top: false,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0)
                    const VerticalDivider(
                      indent: AppPadding.small,
                      endIndent: AppPadding.small,
                      width: 1,
                    ),
                  Expanded(
                    child: _LegacyNavTile(
                      item: items[index],
                      selected: index == activeIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _LegacyNavTile extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _LegacyNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkResponse(
    key: ValueKey('legacy-bottom-nav-${item.label}'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.tiny,
      ),
      child: AnimatedContainer(
        duration: Durations.short4,
        decoration: selected
            ? BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRounding.tiny),
              )
            : const BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(selected ? item.activeIcon ?? item.icon : item.icon),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1,
              child: Text(item.label),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A fixed, scaffold-owned navigation bar. Keeping it in the scaffold's
/// bottomNavigationBar slot ensures modal sheets and body insets understand
/// its bounds instead of rendering beneath a floating overlay.
class _StandardBottomNavigation extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final Widget? secondaryContent;

  const _StandardBottomNavigation({
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.secondaryContent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            reverseDuration: const Duration(milliseconds: 200),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: [...previousChildren, ?currentChild],
            ),
            transitionBuilder: (child, animation) {
              final movement = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: movement,
                child: SizeTransition(
                  sizeFactor: movement,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
            child: secondaryContent == null
                ? const SizedBox.shrink(key: ValueKey('calendar-hidden'))
                : DecoratedBox(
                    key: const ValueKey('calendar-visible'),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: secondaryContent,
                  ),
          ),
          SafeArea(
            top: false,
            child: _SlidingNavigationBar(
              items: items,
              selectedIndex: activeIndex,
              onSelected: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingNavigationBar extends StatefulWidget {
  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SlidingNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_SlidingNavigationBar> createState() => _SlidingNavigationBarState();
}

class _SlidingNavigationBarState extends State<_SlidingNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _positionAnimation;
  late double _position;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.selectedIndex.toDouble();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 360),
        )..addListener(() {
          final animation = _positionAnimation;
          if (animation != null && mounted) {
            setState(() => _position = animation.value);
          }
        });
  }

  @override
  void didUpdateWidget(covariant _SlidingNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.selectedIndex != oldWidget.selectedIndex) {
      _animateTo(widget.selectedIndex.toDouble());
    }
  }

  void _animateTo(double target) {
    _controller.stop();
    _positionAnimation = Tween<double>(
      begin: _position,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  void _select(int index) {
    _animateTo(index.toDouble());
    if (index != widget.selectedIndex) widget.onSelected(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / widget.items.length;
        final iconSize = readingIconSize(context, 25);
        final labelStyle = Theme.of(context).textTheme.labelMedium!
            .copyWith(fontWeight: FontWeight.w700);
        var showLabels = true;
        var labelHeight = 0.0;
        for (final item in widget.items) {
          final label = TextPainter(
            text: TextSpan(text: item.label, style: labelStyle),
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
            locale: Localizations.localeOf(context),
          )..layout();
          showLabels = showLabels && label.width <= itemWidth - 16;
          labelHeight = math.max(labelHeight, label.height);
          label.dispose();
        }
        // When labels cannot fit, retain their accessible names and tooltips
        // and use the available space for larger, recognizable icons.
        final height = math.max(
          76.0,
          iconSize * 1.1 + (showLabels ? labelHeight + 4 : 0) + 20,
        );
        final basePillWidth = math.min(112.0, itemWidth - 18);
        final fraction = (_position - _position.round()).abs();
        final stretch = math.sin(fraction * math.pi) * 18;
        final pillWidth = basePillWidth + stretch;
        final pillLeft = (_position + 0.5) * itemWidth - (pillWidth / 2);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            _controller.stop();
            _dragging = true;
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _position = (_position + details.delta.dx / itemWidth)
                  .clamp(0.0, widget.items.length - 1.0)
                  .toDouble();
            });
          },
          onHorizontalDragEnd: (_) {
            _dragging = false;
            _select(_position.round());
          },
          onHorizontalDragCancel: () {
            _dragging = false;
            _animateTo(widget.selectedIndex.toDouble());
          },
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned(
                  key: const Key('bottom-nav-pill'),
                  left: pillLeft,
                  top: 7,
                  width: pillWidth,
                  height: height - 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRounding.small),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < widget.items.length; index++)
                      Expanded(
                        child: _SlidingNavDestination(
                          item: widget.items[index],
                          proximity: (1 - (_position - index).abs())
                              .clamp(0.0, 1.0)
                              .toDouble(),
                          selected: index == widget.selectedIndex,
                          iconSize: iconSize,
                          showLabel: showLabels,
                          onTap: () => _select(index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlidingNavDestination extends StatelessWidget {
  final FloatingNavItem item;
  final double proximity;
  final bool selected;
  final double iconSize;
  final bool showLabel;
  final VoidCallback onTap;

  const _SlidingNavDestination({
    required this.item,
    required this.proximity,
    required this.selected,
    required this.iconSize,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = Color.lerp(
      colors.onSurfaceVariant,
      colors.primary,
      proximity,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: InkWell(
          key: ValueKey('bottom-nav-${item.label}'),
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1 + proximity * 0.10,
                child: Icon(
                  proximity > 0.5 ? (item.activeIcon ?? item.icon) : item.icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: proximity > 0.5
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop top navigation
// ---------------------------------------------------------------------------

class LargeNavButton extends ConsumerWidget {
  final TabOption tab;

  final TabOption? selected;

  final Function(String)? customSelect;

  const LargeNavButton({
    required this.tab,
    this.selected,
    this.customSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasTests = ref
        .watch(hasTestsProvider)
        .when(
          data: (hasTests) => hasTests,
          loading: () => false,
          error: (error, stackTrace) => false,
        );

    if (tab == TabOption.tests && !hasTests) return Container();

    final betaUi = ref.watch(configProvider).betaUi;
    final bool dashboard = betaUi.dashboard;
    final bool isSelected = tab == selected;
    final ColorScheme colors = Theme.of(context).colorScheme;

    Map<TabOption, String> buttonText = {
      TabOption.record: dashboard ? 'Home' : context.translate.recordTab,
      TabOption.tests: context.translate.testTab,
      TabOption.history: context.translate.historyTab,
    };

    final String text = buttonText[tab]!;

    if (ref.watch(configProvider).display.useLegacyNavigation) {
      return TextButton(
        onPressed: () {
          if (tab == TabOption.history && selected == TabOption.history) {
            final scroll = ref.read(historyScrollControllerProvider);
            if (scroll.hasClients) {
              scroll.animateTo(
                0,
                duration: Durations.medium2,
                curve: Curves.easeInOut,
              );
            }
          }
          final route = switch (tab) {
            TabOption.record => Routes.HOME,
            TabOption.tests => Routes.TEST,
            TabOption.history => Routes.HISTORY,
          };
          if (customSelect != null) {
            customSelect!(route);
          } else {
            ref.read(navigationControllerProvider).navigate(context, route);
          }
        },
        child: Text(text),
      );
    }

    return _AnimatedDesktopTab(
      label: text,
      isSelected: isSelected,
      accentColor: colors.primary,
      surfaceTextColor: colors.onSurface,
      onTap: () {
        if (tab == TabOption.history && selected == TabOption.history) {
          if (ref.read(historyScrollControllerProvider).hasClients) {
            ref
                .read(historyScrollControllerProvider)
                .animateTo(
                  0,
                  duration: Durations.medium2,
                  curve: Curves.easeInOut,
                );
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
    );
  }
}

class _AnimatedDesktopTab extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color surfaceTextColor;
  final VoidCallback onTap;

  const _AnimatedDesktopTab({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.surfaceTextColor,
    required this.onTap,
  });

  @override
  State<_AnimatedDesktopTab> createState() => _AnimatedDesktopTabState();
}

class _AnimatedDesktopTabState extends State<_AnimatedDesktopTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorWidth;
  late Animation<double> _bgOpacity;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _indicatorWidth = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _bgOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedDesktopTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double bgAlpha =
                (_bgOpacity.value * 0.10) + (_hovering ? 0.06 : 0.0);

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
                vertical: AppPadding.small,
              ),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(
                  alpha: bgAlpha.clamp(0, 1),
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRounding.small),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Color.lerp(
                            widget.surfaceTextColor,
                            widget.accentColor,
                            _bgOpacity.value,
                          ),
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      widthFactor: _indicatorWidth.value,
                      alignment: Alignment.center,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
