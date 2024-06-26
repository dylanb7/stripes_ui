import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsCalendar extends ConsumerStatefulWidget {
  final bool sixWeeks;

  final StartingDayOfWeek startDay;
  const EventsCalendar(
      {this.sixWeeks = false,
      this.startDay = StartingDayOfWeek.monday,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return EventsCalendarState();
  }
}

class EventsCalendarState extends ConsumerState<EventsCalendar> {
  DateTime focusedDay = DateTime.now();

  CalendarFormat _format = CalendarFormat.month;

  PageController? _pageController;

  @override
  Widget build(BuildContext context) {
    final Filters filters = ref.watch(filtersProvider);
    final Map<DateTime, List<Response>> eventMap =
        ref.watch(eventsMapProvider).valueOrNull ?? {};
    final DateTime? selected =
        ref.watch(filtersProvider.select((value) => value.selectedDate));
    final now = DateTime.now();

    builder(BuildContext context, DateTime day, DateTime focus) {
      final int events = eventMap[day]?.length ?? 0;
      return CalendarDay(
          day: day,
          isToday: sameDay(day, now),
          selected: selected == null ? false : sameDay(day, selected),
          after: day.isAfter(now),
          events: events);
    }

    return Center(
      child: Column(
        children: [
          Center(
            child: _CalendarHeader(
                focusedDay: focusedDay,
                onLeftArrowTap: () {
                  _pageController?.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                onRightArrowTap: () {
                  _pageController?.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                onFormatChange: _onFormatChange,
                selected: _format),
          ),
          TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime(0) /*keys.isEmpty ? DateTime(0) : keys[0]*/,
            lastDay: DateTime.now(),
            onFormatChanged: _onFormatChange,
            headerVisible: false,
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            calendarStyle: const CalendarStyle(
                cellPadding: EdgeInsets.all(2.0), outsideDaysVisible: false),
            onCalendarCreated: (controller) {
              _pageController = controller;
              Future(() {
                ref.read(filtersProvider.notifier).state =
                    filters.copyWith(range: _getVisibleRange());
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                this.focusedDay = focusedDay;
              });
              if (selected != null && sameDay(selectedDay, selected)) {
                ref.read(filtersProvider.notifier).state =
                    filters.copyWith(selectDate: null);
              } else {
                ref.read(filtersProvider.notifier).state = filters.copyWith(
                  selectDate: selectedDay,
                );
              }
            },
            onPageChanged: (newFocus) {
              setState(() {
                focusedDay = newFocus;
                ref.read(filtersProvider.notifier).state = filters.copyWith(
                    selectDate: null, range: _getVisibleRange());
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: builder,
              todayBuilder: builder,
            ),
          ),
        ],
      ),
    );
  }

  _onFormatChange(CalendarFormat newFormat) {
    Filters filters = ref.read(filtersProvider);
    if (_format != newFormat) {
      setState(() {
        _format = newFormat;
        ref.read(filtersProvider.notifier).state =
            filters.copyWith(range: _getVisibleRange());
      });
    }
  }

  DateTimeRange _getVisibleRange() {
    switch (_format) {
      case CalendarFormat.month:
        return _daysInMonth(focusedDay);
      case CalendarFormat.twoWeeks:
        return _daysInTwoWeeks(focusedDay);
      case CalendarFormat.week:
        return _daysInWeek(focusedDay);
      default:
        return _daysInMonth(focusedDay);
    }
  }

  DateTimeRange _daysInWeek(DateTime focusedDay) {
    final daysBefore = _getDaysBefore(focusedDay);
    final firstToDisplay = focusedDay.subtract(Duration(days: daysBefore));
    final lastToDisplay = firstToDisplay.add(const Duration(days: 7));
    return DateTimeRange(start: firstToDisplay, end: lastToDisplay);
  }

  DateTimeRange _daysInTwoWeeks(DateTime focusedDay) {
    final daysBefore = _getDaysBefore(focusedDay);
    final firstToDisplay = focusedDay.subtract(Duration(days: daysBefore));
    final lastToDisplay = firstToDisplay.add(const Duration(days: 14));
    return DateTimeRange(start: firstToDisplay, end: lastToDisplay);
  }

  DateTime _firstDayOfMonth(DateTime month) {
    return DateTime.utc(month.year, month.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime month) {
    final date = month.month < 12
        ? DateTime.utc(month.year, month.month + 1, 1)
        : DateTime.utc(month.year + 1, 1, 1);
    return date.subtract(const Duration(days: 1));
  }

  DateTimeRange _daysInMonth(DateTime focusedDay) {
    final first = _firstDayOfMonth(focusedDay);
    final last = _lastDayOfMonth(focusedDay);
    return DateTimeRange(start: first, end: last);
  }

  int _getDaysBefore(DateTime firstDay) {
    return (firstDay.weekday + 7 - getWeekdayNumber(widget.startDay)) % 7;
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final void Function(CalendarFormat format) onFormatChange;
  final List<CalendarFormat> formats = const [
    CalendarFormat.month,
    CalendarFormat.week
  ];
  final CalendarFormat selected;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onFormatChange,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final String headerText = DateFormat.yMMM().format(focusedDay);
    final Map<CalendarFormat, String> formatName = {
      CalendarFormat.week: "Week",
      CalendarFormat.month: "Month"
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          Flexible(
            child: Text(
              headerText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          DropdownButton<CalendarFormat>(
            items: formats
                .map((format) => DropdownMenuItem(
                    value: format, child: Text(formatName[format] ?? '')))
                .toList(),
            value: selected,
            underline: Container(),
            onChanged: (value) {
              if (value != null) onFormatChange(value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}

bool sameDay(DateTime day, DateTime testDate) {
  return day.year == testDate.year &&
      day.month == testDate.month &&
      day.day == testDate.day;
}
