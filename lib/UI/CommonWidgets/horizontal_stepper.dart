import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class HorizontalStepper extends StatelessWidget {
  final List<HorizontalStep> steps;

  final Function(int index, bool active) onStepPressed;

  final double circleWidth, progress;

  final Color active;

  final Color inactive;

  const HorizontalStepper({
    required this.steps,
    required this.circleWidth,
    required this.onStepPressed,
    required this.progress,
    required this.active,
    required this.inactive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final int progressIndex = progress.floor();
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps
                .mapIndexed((index, step) => InkWell(
                    onTap: () {
                      onStepPressed(index, index <= progressIndex);
                    },
                    child: step.title))
                .toList(),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildSteps(progressIndex),
          )
        ],
      ),
    );
  }

  List<Widget> _buildSteps(int progressIndex) {
    const double lineHeight = 4.0;
    final List<Widget> parts = [];
    steps.asMap().forEach((index, step) {
      final Color circleColor =
          index.toDouble() <= progress ? active : inactive;
      parts.add(
        GestureDetector(
          onTap: () {
            onStepPressed(index, index <= progressIndex);
          },
          child: Container(
            width: circleWidth,
            decoration:
                BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: Center(child: step.dotContents),
          ),
        ),
      );
      if (index != steps.length - 1) {
        if (progressIndex == index && progress != index.toDouble()) {
          final double fractionFilled = progress - index.toDouble();
          parts.add(
            Expanded(
              child: SizedBox(
                height: lineHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Container(
                          height: lineHeight,
                          width: fractionFilled * constraints.maxWidth,
                          color: active,
                        ),
                        Container(
                          height: lineHeight,
                          color: inactive,
                          width: (1.0 - fractionFilled) * constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          parts.add(
            Expanded(
              child: Container(
                height: lineHeight,
                color: index < progressIndex ? active : inactive,
              ),
            ),
          );
        }
      }
    });
    return parts;
  }
}

@immutable
class HorizontalStep {
  final Widget title;
  final Widget dotContents;

  const HorizontalStep({required this.title, required this.dotContents});
}
