import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/paddings.dart';

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
    const double spaceBetween = AppPadding.large;
    final bool shouldWrap =
        getBreakpoint(context).isLessThan(Breakpoint.medium);
    final int flooredProgress = progress.floor();
    final double totalWidth = MediaQuery.of(context).size.width;
    final double itemWidth = totalWidth * 0.65;
    final double endPadding = (totalWidth - itemWidth) / 2;
    final int itemsLength = steps.length + 2;
    if (shouldWrap) {
      return ListView.separated(
        itemBuilder: (context, index) => index == 0 || index == itemsLength - 1
            ? const SizedBox(
                width: 0,
              )
            : SizedBox(
                width: itemWidth,
                child: _getWidget(
                    steps[index - 1], index - 1, index - 1 <= flooredProgress),
              ),
        separatorBuilder: (context, index) =>
            index == 0 || index == itemsLength - 1
                ? SizedBox(
                    width: endPadding,
                  )
                : const SizedBox(
                    width: spaceBetween,
                  ),
        controller: ScrollController(
            initialScrollOffset:
                ((flooredProgress - 1) * (itemWidth + spaceBetween)) +
                    endPadding),
        itemCount: itemsLength,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: steps
            .mapIndexed((index, step) =>
                _getWidget(step, index, index <= flooredProgress))
            .toList()
            .spacedBy(space: AppPadding.medium, axis: Axis.horizontal),
      ),
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
