import 'package:flutter/material.dart';

/// Keep each chart at its measured layout during flight. Axes and marks travel
/// together without asking a detailed chart to reflow into a thumbnail.
Widget graphHeroShuttle(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext from,
  BuildContext to,
) {
  Widget surface(BuildContext context) {
    final size = (context.findRenderObject()! as RenderBox).size;
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: (context.widget as Hero).child,
        ),
      ),
    );
  }

  return ClipRect(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = direction == HeroFlightDirection.push
            ? animation.value
            : 1 - animation.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 1 - progress, child: surface(from)),
            Opacity(opacity: progress, child: surface(to)),
          ],
        );
      },
    ),
  );
}
