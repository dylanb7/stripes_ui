import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/paddings.dart';

class PopupStyle extends StatelessWidget {
  final Widget child;

  const PopupStyle({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(
          horizontal: AppPadding.large, vertical: AppPadding.medium),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
        child: Center(
          child: DecoratedBox(
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.surface),
            child: child,
          ),
        ),
      ),
    );
  }
}

showSheetOrPopup(BuildContext context) {
  bool popup = getBreakpoint(context).isGreaterThan(Breakpoint.medium);
}
