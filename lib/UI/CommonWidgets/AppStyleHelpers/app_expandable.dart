import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Unified expand/collapse widget.
///
/// Set [decorated] to `true` for a [Card]-wrapped appearance (elevation,
/// optional highlight border) or `false` for a raw, un-styled layout.
///
/// Replaces the legacy `Expandible` and `ExpandibleRaw` widgets.
class AppExpandable extends StatefulWidget {
  /// Content shown regardless of expansion state.
  final Widget header;

  /// Content revealed when expanded.
  final Widget body;

  /// Whether the widget can be toggled. When `false` the body is always
  /// visible and the expand indicator is hidden.
  final bool canExpand;

  /// Show the expand/collapse chevron indicator.
  final bool showIndicator;

  /// Wrap the content in a [Card] with elevation and optional highlight.
  final bool decorated;

  /// Card elevation (only used when [decorated] is `true`).
  final double elevation;

  /// Optional accent border color applied to the card when expanded
  /// (or always, when [highlightOnShrink] is `true`).
  final Color? highlightColor;

  /// Width of the highlight border.
  final double highlightWidth;

  /// Show the highlight border even when collapsed.
  final bool highlightOnShrink;

  /// Size override for the expand/collapse indicator icon.
  final double? iconSize;

  /// External controller. If omitted an internal one is created.
  final AppExpandableController? controller;

  const AppExpandable({
    required this.header,
    required this.body,
    this.canExpand = true,
    this.showIndicator = true,
    this.decorated = true,
    this.elevation = 1.0,
    this.highlightColor,
    this.highlightWidth = 4.0,
    this.highlightOnShrink = false,
    this.iconSize,
    this.controller,
    super.key,
  });

  @override
  State<AppExpandable> createState() => _AppExpandableState();
}

class _AppExpandableState extends State<AppExpandable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _heightFactor;
  late bool _expanded;
  late bool _canExpand;
  late AppExpandableController _controller;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _heightFactor =
        _animController.drive(CurveTween(curve: Curves.easeIn));
    _canExpand = widget.canExpand;
    _expanded = !_canExpand;
    _controller =
        widget.controller ?? AppExpandableController(_expanded);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.set(_expanded);
      if (_expanded) {
        _animController.value = _animController.upperBound;
      }
    });

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!_canExpand || !mounted) return;
    _expanded = _controller.expanded;
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse().then<void>((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppExpandable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canExpand != oldWidget.canExpand) {
      _canExpand = widget.canExpand;
      if (!_canExpand && !_expanded) {
        _expanded = true;
        _controller.set(true);
        _animController.value = _animController.upperBound;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_canExpand || _animController.isAnimating) return;
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse().then<void>((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
      _controller.set(_expanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController.view,
      child: _expanded ? widget.body : null,
      builder: (context, bodyChild) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppPadding.tiny),
            Row(
              children: [
                const SizedBox(width: AppPadding.small),
                Expanded(child: widget.header),
                if (_canExpand && widget.showIndicator) ...[
                  const SizedBox(width: AppPadding.tiny),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: widget.iconSize,
                  ),
                ],
                const SizedBox(width: AppPadding.tiny),
              ],
            ),
            const SizedBox(height: AppPadding.tiny),
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: _heightFactor.value,
                child: bodyChild,
              ),
            ),
          ],
        );

        final innerContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.tiny),
          child: content,
        );

        if (!widget.decorated) {
          return GestureDetector(
            onTap: _toggle,
            child: innerContent,
          );
        }

        final showBorder =
            (_expanded || widget.highlightOnShrink) &&
                widget.highlightColor != null;

        return GestureDetector(
          onTap: _toggle,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(12.0),
              ),
              side: showBorder
                  ? BorderSide(
                      color: widget.highlightColor!,
                      width: widget.highlightWidth,
                    )
                  : const BorderSide(
                      width: 0,
                      color: Colors.transparent,
                    ),
            ),
            elevation: widget.elevation,
            child: innerContent,
          ),
        );
      },
    );
  }
}

/// Controller for [AppExpandable].
///
/// Provides programmatic expand/collapse/toggle and notifies listeners on
/// state change.
class AppExpandableController extends ChangeNotifier {
  bool expanded;

  AppExpandableController([this.expanded = false]);

  /// Set the expansion state directly.
  void set(bool expand) {
    expanded = expand;
    notifyListeners();
  }

  /// Expand the widget.
  void expand() => set(true);

  /// Collapse the widget.
  void collapse() => set(false);

  /// Toggle the current state.
  void toggle() => set(!expanded);

  /// Alias for [expanded].
  bool get isExpanded => expanded;
}
