import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/extensions.dart';

class BlueDyeVisualDisplay extends StatelessWidget {
  final BlueDyeResp resp;

  const BlueDyeVisualDisplay({required this.resp, super.key});

  @override
  Widget build(BuildContext context) {
    final double iconSize = Theme.of(context).iconTheme.size ?? 20;

    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.undetermined: context.translate.amountConsumedUnable,
      AmountConsumed.halfOrLess: context.translate.amountConsumedHalfOrLess,
      AmountConsumed.half: context.translate.amountConsumedHalf,
      AmountConsumed.moreThanHalf: context.translate.amountConsumedHalfOrMore,
      AmountConsumed.all: context.translate.amountConsumedAll,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate.mealCompleteTitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.alarm),
            const SizedBox(
              width: 6.0,
            ),
            Text(context.translate
                .mealCompleteStartTime(resp.startEating, resp.startEating))
          ],
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'packages/stripes_ui/assets/svg/muffin_icon.svg',
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(
              width: 6.0,
            ),
            Text(
                "${context.translate.mealCompleteDuration} ${MealTime.fromDuration(resp.eatingDuration) ?? from(resp.eatingDuration, context)}")
          ],
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.blur_linear),
            const SizedBox(
              width: 6.0,
            ),
            Flexible(
              child: Text(
                "${context.translate.mealCompleteAmountConsumed} ${amountText[resp.amountConsumed]!}",
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          context.translate.recordingStateTitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 8.0,
        ),
        ...resp.logs.map(
          (log) => EntryDisplay(
            event: log.response,
            hasConstraints: false,
            hasControls: false,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Text(
          "Transit time: ${from(resp.firstBlue.difference(resp.finishedEatingTime ?? resp.startEating.add(resp.eatingDuration)), context)}",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Text(
          "Lag phase: ${from(resp.lastBlue.difference(resp.firstBlue), context)}",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
