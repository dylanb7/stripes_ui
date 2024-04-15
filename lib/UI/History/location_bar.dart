import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/entry.dart';

import 'history_toggle.dart';

class LocationBar extends ConsumerWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<Loc, String> locMap = {Loc.day: "Events", Loc.graph: "Graph"};

    Map<GraphChoice, String> graphMap = {
      GraphChoice.day: "Day",
      GraphChoice.week: "Week",
      GraphChoice.month: "Month",
      GraphChoice.year: "Year"
    };

    final HistoryLocation location = ref.watch(historyLocationProvider);
    final double width = MediaQuery.of(context).size.width;
    if (!ref.watch(configProvider).hasGraphing) {
      return const SliverToBoxAdapter();
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: SizedBox(
            width: min(500, width - 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ref.watch(configProvider).hasGraphing)
                  LocationToggle(
                      options: Loc.values.map((e) => locMap[e]!).toList(),
                      toggled: locMap[location.loc]!,
                      fontSize: 18.0,
                      onChange: (value) {
                        if (value == null) return;
                        ref.read(historyLocationProvider.notifier).state =
                            location.copyWith(
                                location: Loc.values.firstWhere(
                                    (element) => locMap[element] == value));
                      }),
                const SizedBox(
                  height: 4.0,
                ),
                if (location.loc == Loc.graph)
                  LocationToggle(
                      options: location.selectedValues
                          .map((val) => graphMap[val]!)
                          .toList(),
                      toggled: graphMap[location.selectedValue]!,
                      fontSize: 14.0,
                      onChange: (value) {
                        if (value == null) return;
                        final HistoryLocation newLoc = location.copyWith(
                          graphChoice: GraphChoice.values.firstWhere(
                              (element) => graphMap[element] == value),
                        );
                        ref.read(filtersProvider.notifier).state =
                            Filters.reset(location: newLoc);
                        ref.read(historyLocationProvider.notifier).state =
                            newLoc;
                      }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
