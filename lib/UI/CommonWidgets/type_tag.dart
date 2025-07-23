import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/styled_tooltip.dart';

class TypeTag extends StatelessWidget {
  final String text;

  final String? onHover, onHoverTitle;

  final Color? tagColor, textColor;

  const TypeTag(
      {super.key,
      required this.text,
      this.onHover,
      this.tagColor,
      this.textColor,
      this.onHoverTitle});

  @override
  Widget build(BuildContext context) {
    final Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: tagColor ?? Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor ?? Theme.of(context).colorScheme.onSecondary),
      ),
    );

    if (onHover == null) return inner;

    return StyledTooltip(message: onHover!, title: onHoverTitle, child: inner);
  }
}
