import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';

class HorizontalStepScroll extends StatelessWidget {
  final List<HorizontalScrollStep> steps;

  final Function(int index, bool active) onStepPressed;

  final double progress;

  const HorizontalStepScroll(
      {required this.steps,
      required this.progress,
      required this.onStepPressed,
      super.key});

  @override
  Widget build(BuildContext context) {
    final bool shouldWrap =
        getBreakpoint(context).isLessThan(Breakpoint.medium);
    final int flooredProgress = progress.floor();
    if (shouldWrap) {
      return ListView.separated(
        itemBuilder: (context, index) =>
            _getWidget(steps[index], index, index <= flooredProgress),
        separatorBuilder: (context, index) => const SizedBox(
          width: 12.0,
        ),
        itemCount: steps.length,
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

  Widget _getWidget(HorizontalScrollStep step, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        onStepPressed(index, isActive);
      },
      child: DecoratedBox(
        decoration: step.decoration,
        child: step.bottomRow != null
            ? Column(
                children: [step.content, const Divider(), step.bottomRow!],
              )
            : step.content,
      ),
    );
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

@immutable
class HorizontalScrollStep {
  final Widget content;
  final Widget? bottomRow;
  final BoxDecoration decoration;

  const HorizontalScrollStep(
      {required this.content, required this.decoration, this.bottomRow});
}
