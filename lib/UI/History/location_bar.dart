import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'history_toggle.dart';

class LocationBar extends ConsumerWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<DayChoice, String> eventsMap = {
      DayChoice.day: AppLocalizations.of(context)!.eventViewDayCategoty,
      DayChoice.month: AppLocalizations.of(context)!.eventViewMonthCategory,
      DayChoice.all: AppLocalizations.of(context)!.eventViewAllCategory
    };

    Map<Loc, String> locMap = {Loc.day: "Events", Loc.graph: "Graph"};

    Map<GraphChoice, String> graphMap = {
      GraphChoice.day: "Day",
      GraphChoice.week: "Week",
      GraphChoice.month: "Month",
      GraphChoice.year: "Year"
    };

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
                if (ref.watch(hasGraphingProvider))
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
                LocationToggle(
                    options: (location.loc == Loc.day
                            ? location.selectedValues
                                .map((val) => eventsMap[val]!)
                            : location.selectedValues
                                .map((val) => graphMap[val]!))
                        .toList(),
                    toggled: location.selectedValue is DayChoice
                        ? eventsMap[location.selectedValue]!
                        : graphMap[location.selectedValue]!,
                    fontSize: 14.0,
                    onChange: (value) {
                      if (value == null) return;
                      final HistoryLocation newLoc = location.loc == Loc.day
                          ? location.copyWith(
                              dayChoice: DayChoice.values.firstWhere(
                                  (element) => eventsMap[element] == value),
                            )
                          : location.copyWith(
                              graphChoice: GraphChoice.values.firstWhere(
                                  (element) => graphMap[element] == value),
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
