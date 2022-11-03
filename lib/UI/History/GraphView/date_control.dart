import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class DateControl extends ConsumerWidget {
  const DateControl({super.key});

  get lightBackgroundHeaderStyle => null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime end =
        ref.watch(filtersProvider.select((value) => value.end)) ??
            DateTime.now();
    final GraphChoice graphChoice = ref.watch(historyLocationProvider).graph;
    final ShiftAmount shiftAmount = graphToShift[graphChoice]!;
    final DateTime start = end.subtract(shiftAmount.amount);
    final double width = MediaQuery.of(context).size.width;
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
                    icon: const Icon(
                      Icons.keyboard_arrow_left,
                      color: darkIconButton,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 6.0,
                ),
                Expanded(
                  child: Card(
                    color: darkBackgroundText,
                    elevation: 8.0,
                    margin: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    child: Center(
                      child: Text(
                        '${dateToMDYAbr(start)} - ${dateToMDYAbr(end)}',
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
                      _shift(ref, ShiftDirection.future, shiftAmount);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_right,
                      color: darkIconButton,
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
        elevation: 6.0,
        child: child,
      );
}
