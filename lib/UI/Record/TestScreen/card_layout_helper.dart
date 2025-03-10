import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';

class AdaptiveCardLayout extends StatelessWidget {
  final Color cardColor;

  final Color? borderColor;

  final Widget child;

  const AdaptiveCardLayout(
      {required this.cardColor,
      required this.child,
      this.borderColor,
      super.key});

  @override
  Widget build(BuildContext context) {
    final bool isCard = getBreakpoint(context).isGreaterThan(Breakpoint.medium);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: isCard ? Breakpoint.medium.value : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isCard ? 20.0 : 0.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(20.0),
              ),
              border: Border.all(
                  width: 1,
                  color: isCard ? borderColor ?? cardColor : cardColor),
              color: cardColor,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
