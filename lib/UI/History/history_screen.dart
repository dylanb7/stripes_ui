import 'package:flutter/material.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/action_row.dart';
import 'package:stripes_ui/UI/History/EventView/day_view.dart';
import 'package:stripes_ui/UI/History/EventView/event_grid.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/month_view.dart';
import 'package:stripes_ui/UI/History/GraphView/date_control.dart';
import 'package:stripes_ui/UI/History/GraphView/event_display.dart';
import 'package:stripes_ui/UI/History/GraphView/time_span_info.dart';

class SliversConfig {
  final HistoryLocation location;

  SliversConfig(this.location);

  List<Widget> get slivers {
    List<Widget> slivers = [];
    switch (location.loc) {
      case Loc.day:
        /*slivers.add(const ActionRow());
        switch (location.day) {
          case DayChoice.day:
            slivers.add(const DayView());
            break;
          case DayChoice.month:
            slivers.add(const MonthView());
            break;
          case DayChoice.all:
            break;
        }*/
        slivers.add(SliverList(
            delegate: SliverChildListDelegate(
                const [ActionRow(), EventsCalendar(), EventGrid()])));
        break;
      case Loc.graph:
        slivers.add(SliverList(
            delegate: SliverChildListDelegate([
          ActionRow(),
          const DateControl(),
          const TimeSpanInfo(),
          const EventDisplay()
        ])));

        break;
    }
    return slivers;
  }
}
