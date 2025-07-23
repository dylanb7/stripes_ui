import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/styled_tooltip.dart';

class FrequencyRow extends StatelessWidget {
  final double percent;

  final int amount;

  final String prompt;

  final Color fillColor;

  final bool hasTooltip;

  const FrequencyRow(
      {required this.percent,
      required this.amount,
      required this.fillColor,
      required this.prompt,
      this.hasTooltip = true,
      super.key});

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      prompt,
      style: Theme.of(context).textTheme.bodyMedium,
      softWrap: false,
      overflow: TextOverflow.fade,
      maxLines: 1,
    );

    return Card(
        clipBehavior: Clip.hardEdge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15.0),
          ),
        ),
        elevation: 6.0,
        child: Stack(
          children: [
            if (amount != 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: hasTooltip
                        ? StyledTooltip(message: prompt, child: text)
                        : text,
                  ),
                  const SizedBox(
                    width: 12.0,
                  ),
                  Text(
                    '$amount',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
