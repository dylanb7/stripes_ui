import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class DateControl extends ConsumerWidget {
  const DateControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime end =
        ref.watch(filtersProvider.select((value) => value.end)) ??
            DateTime.now();
    final GraphChoice graphChoice = ref.watch(historyLocationProvider).graph;
    final ShiftAmount shiftAmount = graphToShift[graphChoice]!;
    final DateTime start = end.subtract(shiftAmount.amount);
    final double width = MediaQuery.of(context).size.width;
    final bool forwardDisabled =
        end.add(shiftAmount.amount).isAfter(DateTime.now());
    return Padding(
        padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: 8.0),
        child: Center(
            child: SizedBox(
          height: 30,
          width: min(450, width),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buttonWrap(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Back',
                    onPressed: () {
                      _shift(ref, ShiftDirection.past, shiftAmount);
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_right,
                      color: forwardDisabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 6.0,
                ),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    child: Center(
                      child: Text(
                        '${dateToMDY(start, context)} - ${dateToMDY(end, context)}',
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                        style: lightBackgroundStyle.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 6.0,
                ),
                _buttonWrap(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Forward',
                    onPressed: () {
                      if (forwardDisabled) return;
                      _shift(ref, ShiftDirection.future, shiftAmount);
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_right,
                      color: forwardDisabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ]),
        )));
  }

  _shift(WidgetRef ref, ShiftDirection direction, ShiftAmount shiftAmount) {
    final Filters currentFilters = ref.read(filtersProvider);

    final Filters newFilters = currentFilters.shift(shiftAmount, direction);
    if ((newFilters.end?.isAfter(DateTime.now()) ?? false) &&
        direction == ShiftDirection.future) return;
    ref.read(filtersProvider.notifier).state = newFilters;
  }

  Widget _buttonWrap({required Widget child}) => Card(
        margin: EdgeInsets.zero,
        shape: const CircleBorder(),
        child: child,
      );
}
