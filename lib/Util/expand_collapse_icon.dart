import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExpandCollapseIcon extends StatefulWidget {
  const ExpandCollapseIcon(
      {super.key,
      this.isExpanded = false,
      this.size = 24.0,
      required this.onPressed,
      this.padding = const EdgeInsets.all(8.0),
      this.color,
      this.disabledColor,
      this.highlightColor,
      this.curve = Curves.fastOutSlowIn,
      this.duration = Durations.medium1});

  final Duration duration;

  final Curve curve;

  final bool isExpanded;

  final double size;

  final ValueChanged<bool>? onPressed;

  final EdgeInsetsGeometry padding;

  final Color? color;

  final Color? disabledColor;

  final Color? highlightColor;

  @override
  State<ExpandCollapseIcon> createState() => _ExpandIconState();
}

class _ExpandIconState extends State<ExpandCollapseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  late final Animatable<double> _iconTurnTween;

  @override
  void initState() {
    super.initState();
    _iconTurnTween = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).chain(CurveTween(curve: widget.curve));
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _iconTurns = _controller.drive(_iconTurnTween);

    if (widget.isExpanded) {
      _controller.value = math.pi;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandCollapseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _handlePressed() {
    widget.onPressed?.call(widget.isExpanded);
  }

  Color get _iconColor {
    if (widget.color != null) {
      return widget.color!;
    }

    return switch (Theme.brightnessOf(context)) {
      Brightness.light => Colors.black54,
      Brightness.dark => Colors.white60,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String onTapHint = widget.isExpanded
        ? localizations.expandedIconTapHint
        : localizations.collapsedIconTapHint;

    return Semantics(
      onTapHint: widget.onPressed == null ? null : onTapHint,
      child: IconButton(
        padding: widget.padding,
        iconSize: widget.size,
        highlightColor: widget.highlightColor,
        color: _iconColor,
        disabledColor: widget.disabledColor,
        onPressed: widget.onPressed == null ? null : _handlePressed,
        icon: RotationTransition(
            turns: _iconTurns, child: const Icon(Icons.expand_more)),
      ),
    );
  }
}
