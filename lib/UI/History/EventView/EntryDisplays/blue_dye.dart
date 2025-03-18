import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BlueDyeVisualDisplay extends StatelessWidget {
  final BlueDyeResp resp;

  const BlueDyeVisualDisplay({required this.resp, super.key});

  @override
  Widget build(BuildContext context) {
    final double iconSize = Theme.of(context).iconTheme.size ?? 20;

    final Map<AmountConsumed, String> amountText = {
      AmountConsumed.undetermined:
          AppLocalizations.of(context)!.amountConsumedUnable,
      AmountConsumed.halfOrLess:
          AppLocalizations.of(context)!.amountConsumedHalfOrLess,
      AmountConsumed.half: AppLocalizations.of(context)!.amountConsumedHalf,
      AmountConsumed.moreThanHalf:
          AppLocalizations.of(context)!.amountConsumedHalfOrMore,
      AmountConsumed.all: AppLocalizations.of(context)!.amountConsumedAll,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.mealCompleteTitle,
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
            Text(AppLocalizations.of(context)!
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
                "${AppLocalizations.of(context)!.mealCompleteDuration} ${MealTime.fromDuration(resp.eatingDuration) ?? from(resp.eatingDuration, context)}")
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
                "${AppLocalizations.of(context)!.mealCompleteAmountConsumed} ${amountText[resp.amountConsumed]!}",
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12.0,
        ),
        Text(
          AppLocalizations.of(context)!.recordingStateTitle,
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
            elevated: false,
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
