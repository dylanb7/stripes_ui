import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

TooltipThemeData tooltipTheme(BuildContext context) => TooltipThemeData(
      preferBelow: true,
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(AppPadding.tiny),
      constraints: BoxConstraints(
        maxWidth: Breakpoint.tiny.value,
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRounding.tiny),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
