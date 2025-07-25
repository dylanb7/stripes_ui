import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/paddings.dart';

class StyledTooltip extends StatelessWidget {
  final String message;
  final String? title;
  final Widget child;

  const StyledTooltip({
    super.key,
    required this.message,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = title != null;
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: hasTitle ? null : message,
      padding: const EdgeInsets.all(AppPadding.small),
      margin: const EdgeInsets.all(AppPadding.tiny),
      preferBelow: true,
      constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRounding.tiny),
        ),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface),
      ),
      textStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      richMessage: hasTitle
          ? TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              text: title,
              children: [
                TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8)),
                    text: "\n$message")
              ],
            )
          : null,
      child: child,
    );
  }
}
