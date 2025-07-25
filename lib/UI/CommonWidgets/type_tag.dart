import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/styled_tooltip.dart';
import 'package:stripes_ui/Util/paddings.dart';

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
    final Widget inner = Chip(
      visualDensity: VisualDensity.compact,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.all(
          Radius.circular(AppRounding.tiny),
        ),
      ),
      label: Text(
        text,
      ),
    );

    if (onHover == null) return inner;

    return StyledTooltip(message: onHover!, title: onHoverTitle, child: inner);
  }
}
