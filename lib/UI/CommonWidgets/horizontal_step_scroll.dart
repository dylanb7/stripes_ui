import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';

class HorizontalStepScrollController {}

class HorizontalStepScroll extends StatelessWidget {
  final List<Widget> steps;

  final Function(int index, bool active) onStepPressed;

  final double progress;

  const HorizontalStepScroll(
      {required this.steps,
      required this.progress,
      required this.onStepPressed,
      super.key});

  @override
  Widget build(BuildContext context) {
    const double spaceBetween = 16.0;
    final bool shouldWrap = getBreakpoint(context).isLessThan(Breakpoint.small);
    final int flooredProgress = progress.floor();
    final double totalWidth = MediaQuery.of(context).size.width;
    final double itemWidth = totalWidth * 0.7;
    final double endPadding = (totalWidth - itemWidth) / 2;
    if (shouldWrap) {
      return ListView.separated(
        itemBuilder: (context, index) => index == 0 || index == steps.length + 1
            ? const SizedBox(
                width: 0,
              )
            : SizedBox(
                width: itemWidth,
                child: _getWidget(
                    steps[index - 1], index - 1, index - 1 <= flooredProgress),
              ),
        separatorBuilder: (context, index) =>
            index == 0 || index == steps.length + 1
                ? SizedBox(
                    width: endPadding,
                  )
                : const SizedBox(
                    width: spaceBetween,
                  ),
        controller: ScrollController(
            initialScrollOffset:
                (flooredProgress * (itemWidth + spaceBetween)) + endPadding),
        itemCount: steps.length + 2,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps
          .mapIndexed((index, step) =>
              _getWidget(step, index, index <= flooredProgress))
          .toList()
          .spacedBy(space: 12.0, axis: Axis.horizontal),
    );
  }

  Widget _getWidget(Widget step, int index, bool isActive) {
    return GestureDetector(
        onTap: () {
          onStepPressed(index, isActive);
        },
        child: step);
  }
}

extension on List<Widget> {
  List<Widget> spacedBy({required double space, Axis axis = Axis.vertical}) {
    final Iterable<Widget> expanded = expand((widget) => [
          widget,
          axis == Axis.horizontal
              ? SizedBox(
                  width: space,
                )
              : SizedBox(
                  height: space,
                )
        ]);
    return expanded.toList()..removeLast();
  }
}
