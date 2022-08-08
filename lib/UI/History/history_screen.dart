import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/day_view.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/month_view.dart';
import 'package:stripes_ui/UI/History/GraphView/event_display.dart';
import 'package:stripes_ui/UI/History/GraphView/time_span_info.dart';
import 'package:stripes_ui/UI/History/location_bar.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stampHolderProvider);
    HistoryLocation loc = ref.watch(historyLocationProvider);
    return CustomScrollView(
      primary: false,
      controller:
          ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 10)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: PatientChanger(
              isRecords: false,
            ),
          ),
        ),
        const LocationBar(),
        ...SliversConfig(loc).slivers,
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }
}

class SliversConfig {
  final HistoryLocation location;

  SliversConfig(this.location);

  List<Widget> get slivers {
    List<Widget> slivers = [];
    switch (location.loc) {
      case Loc.day:
        slivers.add(const ActionRow());
        switch (location.day) {
          case DayChoice.day:
            slivers.add(const DayView());
            break;
          case DayChoice.month:
            slivers.add(const MonthView());
            break;
          case DayChoice.all:
            break;
        }
        slivers.add(const EventGrid());
        break;
      case Loc.graph:
        slivers.add(SliverList(
            delegate: SliverChildListDelegate(
                [const TimeSpanInfo(), const EventDisplay()])));

        break;
    }
    return slivers;
  }
}
