import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';

import 'history_toggle.dart';

class LocationBar extends ConsumerWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HistoryLocation location = ref.watch(historyLocationProvider);
    final double width = MediaQuery.of(context).size.width;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: SizedBox(
            width: min(500, width - 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LocationToggle(
                    options: Loc.values.map((e) => e.value).toList(),
                    toggled: location.loc.value,
                    fontSize: 18.0,
                    onChange: (value) {
                      if (value == null) return;
                      ref.read(historyLocationProvider.notifier).state =
                          location.copyWith(
                              location: Loc.values.firstWhere(
                                  (element) => element.value == value));
                    }),
                const SizedBox(
                  height: 4.0,
                ),
                LocationToggle(
                    options: location.selectedValues,
                    toggled: location.selectedValue,
                    fontSize: 14.0,
                    onChange: (value) {
                      if (value == null) return;
                      final HistoryLocation newLoc = location.loc == Loc.day
                          ? location.copyWith(
                              dayChoice: DayChoice.values.firstWhere(
                                  (element) => element.value == value),
                            )
                          : location.copyWith(
                              graphChoice: GraphChoice.values.firstWhere(
                                  (element) => element.value == value),
                            );
                      ref.read(actionProvider.notifier).state = null;
                      ref.read(filtersProvider.notifier).state =
                          Filters.reset(location: newLoc);
                      ref.read(historyLocationProvider.notifier).state = newLoc;
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
