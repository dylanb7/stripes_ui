import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

import 'package:stripes_ui/Util/Helpers/date_helper.dart';

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

    final Color dividerColor =
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25);

    Widget buildRow(String label, String value, {Widget? icon}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: AppPadding.tiny),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppPadding.small),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.translate.mealCompleteTitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        buildRow(
          "Start Time", // Using generic label as localized one isn't split
          "${dateToMDY(resp.startEating, context)} ${timeString(resp.startEating, context)}",
          icon: const Icon(Icons.alarm, size: 20),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        Divider(height: 1, color: dividerColor),
        const SizedBox(
          height: AppPadding.small,
        ),
        buildRow(
          "Eating Duration",
          resp.eatingDuration == Duration.zero
              ? "Tube Fed"
              : MealTime.fromDuration(resp.eatingDuration)?.value ??
                  from(resp.eatingDuration, context),
          icon: SvgPicture.asset(
            'packages/stripes_ui/assets/svg/muffin_icon.svg',
            width: iconSize,
            height: iconSize,
          ),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        Divider(height: 1, color: dividerColor),
        const SizedBox(
          height: AppPadding.small,
        ),
        if (resp.eatingDuration != Duration.zero)
          buildRow(
            "Amount Eaten",
            amountText[resp.amountConsumed]!,
            icon: const Icon(Icons.blur_linear, size: 20),
          ),
        const SizedBox(
          height: AppPadding.medium,
        ),
        Text(
          context.translate.recordingStateTitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        ...resp.logs
            .map(
              (log) => EntryDisplay(
                event: log.response,
                hasConstraints: false,
                hasControls: false,
                isNested: true,
              ),
            )
            .separated(
              by: const SizedBox(
                height: AppPadding.small,
              ),
            ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        const Divider(),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        buildRow(
          "Transit time",
          from(
              resp.firstBlue.difference(resp.finishedEatingTime ??
                  resp.startEating.add(resp.eatingDuration)),
              context),
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        buildRow(
          "Lag phase",
          from(resp.lastBlue.difference(resp.firstBlue), context),
        ),
      ],
    );
  }
}
