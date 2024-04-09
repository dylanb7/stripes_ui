import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsCalendar extends ConsumerStatefulWidget {
  const EventsCalendar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return EventsCalendarState();
  }
}

class EventsCalendarState extends ConsumerState<EventsCalendar> {
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final Filters filters = ref.watch(filtersProvider);
    final Map<DateTime, List<Response>> eventMap =
        ref.watch(eventsMapProvider).valueOrNull ?? {};
    final List<DateTime> keys = eventMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: TableCalendar(
            focusedDay: filters.selectedDate ?? DateTime.now(),
            firstDay: keys.isEmpty ? DateTime.now() : keys[0],
            lastDay: keys.isEmpty ? DateTime.now() : keys[keys.length - 1],
            onPageChanged: (focusedDay) {},
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(filtersProvider.notifier).state =
                  filters.copyWith(selectDate: null, selectMonth: focusedDay);
            },
            eventLoader: (day) => eventMap[day] ?? [],
          ),
        ),
      ),
    );
  }
}
