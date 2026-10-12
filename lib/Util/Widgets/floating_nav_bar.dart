import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


/// A single navigation destination within a [FloatingNavBar].
class FloatingNavItem {
  /// Icon shown when this item is not selected.
  final IconData icon;

  /// Icon shown when this item is selected. Falls back to [icon].
  final IconData? activeIcon;

  /// Text label displayed below the icon.
  final String label;

  const FloatingNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Visual styling for a [FloatingNavBar].
///
/// All values have sensible defaults. Override individual properties via
/// [copyWith] to customise without rebuilding the whole object.
class FloatingNavBarDecoration {
  /// Corner radius of the floating capsule.
  final double borderRadius;

  /// Background color. When null, uses `ColorScheme.surface` from the theme.
  final Color? backgroundColor;

  /// Opacity applied to [backgroundColor].
  final double backgroundOpacity;

  /// Blur sigma for the frosted-glass backdrop filter.
  /// Set to 0 to disable the blur entirely.
  final double blurSigma;

  /// Box shadows around the capsule. When null, a subtle default is used.
  final List<BoxShadow>? shadows;

  /// Horizontal margin from screen edges.
  final double horizontalMargin;

  /// Bottom margin above the safe-area inset.
  final double bottomMargin;

  /// Width allocated for the [FloatingNavBar.actionSlot].
  final double actionSlotSize;

  const FloatingNavBarDecoration({
    this.borderRadius = 28.0,
    this.backgroundColor,
    this.backgroundOpacity = 0.65,
    this.blurSigma = 20.0,
    this.shadows,
    this.horizontalMargin = 16.0,
    this.bottomMargin = 12.0,
    this.actionSlotSize = 56.0,
  });

  FloatingNavBarDecoration copyWith({
    double? borderRadius,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? blurSigma,
    List<BoxShadow>? shadows,
    double? horizontalMargin,
    double? bottomMargin,
    double? actionSlotSize,
  }) {
    return FloatingNavBarDecoration(
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      blurSigma: blurSigma ?? this.blurSigma,
      shadows: shadows ?? this.shadows,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      actionSlotSize: actionSlotSize ?? this.actionSlotSize,
    );
  }
}


/// Controls the dynamic state of a [FloatingNavBar].
///
/// Manages two independent axes:
/// - **Collapse**: the bar shrinks to a compact form (labels hidden, padding
///   reduced) driven by scroll direction.
/// - **Secondary expansion**: a content region above the primary row.
///
/// Wire scroll events by calling [onUserScroll] from a
/// [NotificationListener] that receives [UserScrollNotification].
class FloatingNavBarController extends ChangeNotifier {
  bool _collapsed = false;
  bool _secondaryExpanded = false;

  /// Whether the bar is targeting its compact state.
  bool get collapsed => _collapsed;

  /// Whether the secondary content region is showing.
  bool get secondaryExpanded => _secondaryExpanded;

  /// Call when a [UserScrollNotification] is received.
  ///
  /// Scrolling **down** (`ScrollDirection.reverse`) collapses the bar and
  /// closes the secondary region. Scrolling **up** expands the bar.
  void onUserScroll(ScrollDirection direction) {
    if (direction == ScrollDirection.reverse && !_collapsed) {
      _collapsed = true;
      if (_secondaryExpanded) _secondaryExpanded = false;
      notifyListeners();
    } else if (direction == ScrollDirection.forward && _collapsed) {
      _collapsed = false;
      notifyListeners();
    }
  }

  /// Programmatically collapse the bar.
  void collapse() {
    if (!_collapsed) {
      _collapsed = true;
      notifyListeners();
    }
  }

  /// Programmatically expand the bar.
  void expand() {
    if (_collapsed) {
      _collapsed = false;
      notifyListeners();
    }
  }

  /// Toggle the secondary content region.
  void toggleSecondary() {
    _secondaryExpanded = !_secondaryExpanded;
    notifyListeners();
  }

  /// Explicitly set whether the secondary region is expanded.
  void setSecondaryExpanded(bool value) {
    if (_secondaryExpanded != value) {
      _secondaryExpanded = value;
      notifyListeners();
    }
  }
}


/// Provides a [FloatingNavBarController] to the widget subtree.
///
/// Place this above both the [FloatingNavBar] and the scrollable body so
/// that scroll events and the bar share a single controller instance.
class FloatingNavBarScope extends InheritedWidget {
  /// The shared controller instance.
  final FloatingNavBarController controller;

  /// Estimated total height of the bar overlay. Descendants can read this
  /// via [bottomPaddingOf] to add appropriate bottom insets to scrollable
  /// content.
  final double barHeight;

  const FloatingNavBarScope({
    required this.controller,
    this.barHeight = 0.0,
    required super.child,
    super.key,
  });

  /// Returns the nearest [FloatingNavBarController], or `null`.
  static FloatingNavBarController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FloatingNavBarScope>()
        ?.controller;
  }

  /// Returns the estimated bar height from the nearest scope, or `0`.
  static double bottomPaddingOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FloatingNavBarScope>()
        ?.barHeight ??
        0.0;
  }

  @override
  bool updateShouldNotify(FloatingNavBarScope oldWidget) =>
      controller != oldWidget.controller || barHeight != oldWidget.barHeight;
}


/// A floating, self-sizing navigation bar rendered as a translucent capsule.
///
/// ## Composable regions
///
/// 1. **Primary row** — [items] distributed horizontally with animated
///    selection. An optional [actionSlot] renders as a standalone capsule
///    to the right of the nav bar.
/// 2. **Secondary content** — an expandable area above the primary row,
///    driven by [FloatingNavBarController.toggleSecondary].
///
/// ## Self-sizing
///
/// The bar sizes itself to its content. When the controller enters
/// [FloatingNavBarController.collapsed] the labels shrink away and padding
/// tightens, producing a compact capsule. When [secondaryContent] expands
/// the bar grows to accommodate it.
///
/// ## Positioning
///
/// Place this in a [Positioned] overlay at the bottom of a [Stack]. The
/// widget handles its own [SafeArea] and applies [decoration] margins.
class FloatingNavBar extends StatefulWidget {
  /// Navigation destinations.
  final List<FloatingNavItem> items;

  /// Currently active item index. Negative means no selection.
  final int activeIndex;

  /// Called when a navigation item is tapped, with the item index.
  final ValueChanged<int> onTap;

  /// Optional widget rendered as a standalone floating capsule to the right
  /// of the navigation bar (e.g. an "add" button).
  final Widget? actionSlot;

  /// Content for the expandable secondary region.
  final Widget? secondaryContent;

  /// Controls collapse and secondary-expansion animations.
  /// When null the bar stays in its expanded form.
  final FloatingNavBarController? controller;

  /// Visual configuration.
  final FloatingNavBarDecoration decoration;

  const FloatingNavBar({
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.actionSlot,
    this.secondaryContent,
    this.controller,
    this.decoration = const FloatingNavBarDecoration(),
    super.key,
  });

  /// Estimated total height including content, margins, and [safeAreaBottom].
  ///
  /// Use this to compute bottom padding for content behind the bar.
  static double estimatedHeight({
    FloatingNavBarDecoration decoration = const FloatingNavBarDecoration(),
    double safeAreaBottom = 34.0,
  }) {
    return _kExpandedContentHeight + decoration.bottomMargin + safeAreaBottom;
  }

  static const double _kExpandedContentHeight = 72.0;

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _collapseAnim;
  late final AnimationController _secondaryAnim;

  @override
  void initState() {
    super.initState();
    _collapseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.controller?.collapsed == true ? 1.0 : 0.0,
    );
    _secondaryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      value: widget.controller?.secondaryExpanded == true ? 1.0 : 0.0,
    );
    widget.controller?.addListener(_syncAnimations);
  }

  @override
  void didUpdateWidget(covariant FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncAnimations);
      widget.controller?.addListener(_syncAnimations);
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    final c = widget.controller;
    if (c == null) return;
    c.collapsed ? _collapseAnim.forward() : _collapseAnim.reverse();
    c.secondaryExpanded
        ? _secondaryAnim.forward()
        : _secondaryAnim.reverse();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncAnimations);
    _collapseAnim.dispose();
    _secondaryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.decoration;
    final colors = Theme.of(context).colorScheme;
    final bgColor = (d.backgroundColor ?? colors.surface)
        .withValues(alpha: d.backgroundOpacity);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: d.horizontalMargin,
          right: d.horizontalMargin,
          bottom: d.bottomMargin,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_collapseAnim, _secondaryAnim]),
          builder: (context, _) {
            final collapse =
                Curves.easeOutCubic.transform(_collapseAnim.value);
            final secondary =
                Curves.easeOutCubic.transform(_secondaryAnim.value);

            final double screenWidth = MediaQuery.of(context).size.width;
            final double availableWidth = screenWidth - 2 * d.horizontalMargin;
            final double actionSpace = widget.actionSlot != null
                ? d.actionSlotSize + 8.0
                : 0.0;
            final double expandedNavWidth = availableWidth - actionSpace;
            final double collapsedNavWidth =
                (widget.items.length * 80.0 + 24.0).clamp(200.0, expandedNavWidth);
            final double currentNavWidth =
                lerpDouble(expandedNavWidth, collapsedNavWidth, collapse)!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.secondaryContent != null)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: secondary,
                      child: Opacity(
                        opacity: secondary,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _GlassContainer(
                            bgColor: bgColor,
                            decoration: d,
                            colors: colors,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: widget.secondaryContent!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: currentNavWidth,
                          child: _GlassContainer(
                            bgColor: bgColor,
                            decoration: d,
                            colors: colors,
                            child: _PrimaryRow(
                              items: widget.items,
                              activeIndex: widget.activeIndex,
                              onTap: widget.onTap,
                              collapseFraction: collapse,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (widget.actionSlot != null) ...[
                      const SizedBox(width: 8.0),
                      _GlassContainer(
                        bgColor: bgColor,
                        decoration: d.copyWith(borderRadius: d.actionSlotSize / 2),
                        colors: colors,
                        child: SizedBox(
                          width: d.actionSlotSize,
                          height: d.actionSlotSize,
                          child: Center(child: widget.actionSlot!),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class _GlassContainer extends StatelessWidget {
  final Color bgColor;
  final FloatingNavBarDecoration decoration;
  final ColorScheme colors;
  final Widget child;

  const _GlassContainer({
    required this.bgColor,
    required this.decoration,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(decoration.borderRadius);

    Widget container = DecoratedBox(
      decoration: BoxDecoration(
        color: decoration.blurSigma > 0
            ? bgColor
            : bgColor.withValues(alpha: 1.0),
        borderRadius: borderRadius,
        boxShadow: decoration.shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );

    if (decoration.blurSigma > 0) {
      container = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blurSigma,
            sigmaY: decoration.blurSigma,
          ),
          child: container,
        ),
      );
    }

    return container;
  }
}


class _PrimaryRow extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final double collapseFraction;

  const _PrimaryRow({
    required this.items,
    required this.activeIndex,
    required this.onTap,
    required this.collapseFraction,
  });

  @override
  Widget build(BuildContext context) {
    final double vPad = lerpDouble(10.0, 4.0, collapseFraction)!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 4.0),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavItemWidget(
                item: items[i],
                isActive: i == activeIndex,
                collapseFraction: collapseFraction,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}


class _NavItemWidget extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final double collapseFraction;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.collapseFraction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color color = isActive
        ? colors.primary
        : colors.onSurface.withValues(alpha: 0.55);

    final double iconSize = lerpDouble(24.0, 22.0, collapseFraction)!;
    final double labelProgress =
        ((1.0 - collapseFraction) / 0.7).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(
              isActive ? (item.activeIcon ?? item.icon) : item.icon,
              key: ValueKey(
                isActive ? 'active_${item.label}' : 'inactive_${item.label}',
              ),
              color: color,
              size: iconSize,
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: labelProgress,
              child: Opacity(
                opacity: labelProgress,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.0,
                    child: Text(
                      item.label,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
