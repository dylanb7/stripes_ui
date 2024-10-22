import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
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

  bool isHidden = false;

  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOff;

  PageController? _pageController;

  final DateTime firstDate = DateTime(2020);

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final Filters filters = ref.watch(filtersProvider);
    final AsyncValue<Map<DateTime, List<Response>>> eventsValue =
        ref.watch(eventsMapProvider);

    bool hasRange(Filters? filters) {
      if (filters == null) return false;
      return filters.rangeStart != null || filters.rangeEnd != null;
    }

    ref.listen<Filters>(filtersProvider, (oldFilters, newFilters) {
      final bool range = hasRange(newFilters);
      if (hasRange(oldFilters) != range && mounted) {
        setState(() {
          _rangeMode = range
              ? RangeSelectionMode.toggledOn
              : RangeSelectionMode.toggledOff;
        });
      }
    });

    final bool waiting = eventsValue.isLoading || eventsValue.hasError;
    final Map<DateTime, List<Response>> eventMap =
        eventsValue.valueOrNull ?? {};
    final Color background =
        Theme.of(context).colorScheme.primary.withOpacity(0.4);

    final DateTime? selected = filters.selectedDate;
    final DateTime? rangeStart = filters.rangeStart;
    final DateTime? rangeEnd = filters.rangeEnd;
    final DateTime now = DateTime.now();
    const CalendarStyle calendarStyle = CalendarStyle(
      cellMargin: EdgeInsets.all(4.0),
      cellPadding: EdgeInsets.all(0.0),
      outsideDaysVisible: false,
    );

    final Map<CalendarFormat, String> formats = {
      CalendarFormat.week: AppLocalizations.of(context)!.calendarVisibilityWeek,
      CalendarFormat.month:
          AppLocalizations.of(context)!.calendarVisibilityMonth
    };

    final String hidden =
        AppLocalizations.of(context)!.calendarVisibilityHidden;

    Widget builder(BuildContext context, DateTime day, DateTime focus) {
      final int events = eventMap[day]?.length ?? 0;
      return CalendarDay(
        day: day,
        isToday: sameDay(day, now),
        selected: selected == null ? false : sameDay(day, selected),
        disabled: day.isAfter(now),
        events: events,
        rangeStart: rangeStart != null && sameDay(rangeStart, day),
        rangeEnd: rangeEnd != null && sameDay(rangeEnd, day),
        within: rangeStart != null &&
            rangeEnd != null &&
            day.isAfter(rangeStart) &&
            day.isBefore(rangeEnd),
        endSelected: rangeEnd != null,
        style: calendarStyle,
      );
    }

    Widget? rangeHighlight(
        BuildContext context, DateTime day, bool withinRange) {
      if (!withinRange) return null;
      if (rangeStart == null || rangeEnd == null) return null;
      final bool firstDay = sameDay(rangeStart, day);
      final bool lastDay = sameDay(rangeEnd, day);
      return LayoutBuilder(builder: (context, constraints) {
        final double shorterSide = constraints.maxHeight > constraints.maxWidth
            ? constraints.maxWidth
            : constraints.maxHeight;
        return Container(
          margin: EdgeInsetsDirectional.only(
              top: calendarStyle.cellMargin.top,
              start: firstDay ? constraints.maxWidth * 0.5 : 0.0,
              end: lastDay ? constraints.maxWidth * 0.5 : 0.0,
              bottom: calendarStyle.cellMargin.bottom),
          height: shorterSide - calendarStyle.cellMargin.vertical,
          color: background,
        );
      });
    }

    Widget? dowBuilder(BuildContext context, DateTime day) {
      final weekdayString = DateFormat.E(locale.languageCode).format(day);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Center(
          child: ExcludeSemantics(
            child: Text(
              weekdayString,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
        ),
      );
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            maintainState: true,
            visible: !isHidden,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface)),
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Column(
                children: [
                  _CalendarHeader(
                      onYearChange: _onYearChange,
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
                      onRangeToggle: () {
                        setState(() {
                          if (_rangeMode == RangeSelectionMode.toggledOff) {
                            _rangeMode = RangeSelectionMode.toggledOn;

                            ref.read(filtersProvider.notifier).state = Filters(
                                rangeStart: null,
                                rangeEnd: null,
                                selectedDate: null,
                                stampFilters: filters.stampFilters,
                                latestRequired: filters.latestRequired,
                                earliestRequired: filters.earliestRequired);
                          } else {
                            _rangeMode = RangeSelectionMode.toggledOff;
                            ref.read(filtersProvider.notifier).state = Filters(
                                rangeStart: null,
                                rangeEnd: null,
                                selectedDate: rangeEnd ?? rangeStart,
                                stampFilters: filters.stampFilters,
                                latestRequired: filters.latestRequired,
                                earliestRequired: filters.earliestRequired);
                          }
                        });
                      },
                      onFormatChange: _onFormatChange,
                      mode: _rangeMode,
                      selected: _format),
                  Stack(
                    children: [
                      IgnorePointer(
                        ignoring: waiting,
                        child: Opacity(
                          opacity: waiting ? 0.6 : 1.0,
                          child: TableCalendar(
                            locale: locale.languageCode,
                            daysOfWeekHeight: 25.0,
                            focusedDay: focusedDay,
                            firstDay:
                                firstDate /*keys.isEmpty ? DateTime(0) : keys[0]*/,
                            lastDay: DateTime.now(),
                            rangeSelectionMode: _rangeMode,
                            rangeStartDay: rangeStart,
                            rangeEndDay: rangeEnd,
                            headerVisible: false,
                            calendarFormat: _format,
                            availableGestures:
                                AvailableGestures.horizontalSwipe,
                            availableCalendarFormats: formats,
                            onFormatChanged: null,
                            calendarStyle: calendarStyle,
                            onCalendarCreated: (controller) {
                              _pageController = controller;
                              Future(() {
                                ref.read(filtersProvider.notifier).state =
                                    filters.copyWith(
                                        earliestRequired: DateTime(
                                            focusedDay.year,
                                            focusedDay.month,
                                            1),
                                        latestRequired:
                                            _lastDayOfMonth(focusedDay));
                              });
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                focusedDay = focusedDay;
                                _rangeMode = RangeSelectionMode.toggledOff;

                                if (selected != null &&
                                    !sameDay(selectedDay, selected)) {
                                  ref.read(filtersProvider.notifier).state =
                                      Filters(
                                          rangeStart: null,
                                          rangeEnd: null,
                                          selectedDate: selectedDay,
                                          stampFilters: filters.stampFilters,
                                          latestRequired:
                                              filters.latestRequired,
                                          earliestRequired:
                                              filters.earliestRequired);
                                }
                              });
                            },
                            onRangeSelected: (start, end, focusedDay) {
                              setState(() {
                                _rangeMode = RangeSelectionMode.toggledOn;
                                this.focusedDay = focusedDay;
                                ref.read(filtersProvider.notifier).state =
                                    Filters(
                                        rangeStart: start,
                                        rangeEnd: end,
                                        selectedDate: null,
                                        stampFilters: filters.stampFilters,
                                        latestRequired: filters.latestRequired,
                                        earliestRequired:
                                            filters.earliestRequired);
                              });
                            },
                            onPageChanged: (newFocus) {
                              setState(() {
                                focusedDay = newFocus;
                                ref.read(filtersProvider.notifier).state =
                                    filters.copyWith(
                                        earliestRequired: DateTime(
                                            newFocus.year, newFocus.month, 1),
                                        latestRequired:
                                            _lastDayOfMonth(newFocus));
                              });
                            },
                            calendarBuilders: CalendarBuilders(
                                defaultBuilder: builder,
                                todayBuilder: builder,
                                rangeStartBuilder: builder,
                                rangeEndBuilder: builder,
                                withinRangeBuilder: builder,
                                disabledBuilder: builder,
                                dowBuilder: dowBuilder,
                                rangeHighlightBuilder: rangeHighlight),
                          ),
                        ),
                      ),
                      if (waiting)
                        Center(
                          child: eventsValue.isLoading
                              ? const LoadingWidget()
                              : Text(
                                  eventsValue.error.toString(),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]);
  }

  _onYearChange() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            currentDate: focusedDay,
            firstDate: firstDate,
            lastDate: DateTime.now(),
            selectedDate: focusedDay,
            onChanged: (val) {
              setState(() {
                focusedDay =
                    DateTime(val.year, focusedDay.month, focusedDay.day);
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  _onFormatChange(CalendarFormat? newFormat) {
    if (newFormat != null) {
      setState(() {
        if (_format != newFormat) _format = newFormat;
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

  List<DateTime> daysInRange(DateTime first, DateTime last) {
    final dayCount = last.difference(first).inDays + 1;
    return List.generate(
      dayCount,
      (index) => DateTime.utc(first.year, first.month, first.day + index),
    );
  }

  int _getDaysBefore(DateTime firstDay) {
    return (firstDay.weekday + 7 - getWeekdayNumber(widget.startDay)) % 7;
  }
}

class _CalendarHeader extends ConsumerWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;

  final VoidCallback onRangeToggle;
  final VoidCallback onYearChange;

  final RangeSelectionMode mode;

  final CalendarFormat selected;
  final Function(CalendarFormat?) onFormatChange;

  const _CalendarHeader(
      {required this.focusedDay,
      required this.onLeftArrowTap,
      required this.onRightArrowTap,
      required this.selected,
      required this.onRangeToggle,
      required this.onYearChange,
      required this.mode,
      required this.onFormatChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<CalendarFormat, String> formats = {
      CalendarFormat.week: AppLocalizations.of(context)!.calendarVisibilityWeek,
      CalendarFormat.month:
          AppLocalizations.of(context)!.calendarVisibilityMonth
    };
    final String headerText = DateFormat.yMMM().format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          Text(
            headerText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
          /*TextButton.icon(
            onPressed: () {
              onYearChange();
            },
            iconAlignment: IconAlignment.end,
            label: Text(
              headerText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            icon: const Icon(Icons.arrow_drop_down),
          ),*/
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              ref.read(filtersProvider.notifier).state = Filters.reset();
            },
            label: Text(AppLocalizations.of(context)!.eventFilterReset),
            icon: const Icon(Icons.restart_alt),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            clipBehavior: Clip.hardEdge,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                borderRadius: BorderRadius.circular(8.0),
                value: formats[selected],
                iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
                selectedItemBuilder: (context) {
                  return [...formats.values]
                      .map(
                        (value) => Center(
                          child: Text(
                            value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          ),
                        ),
                      )
                      .toList();
                },
                onChanged: (value) {
                  if (value != null) {
                    CalendarFormat? format;
                    formats.forEach(
                      (key, name) {
                        if (value == name) {
                          format = key;
                        }
                      },
                    );
                    onFormatChange(format);
                  }
                },
                items: [...formats.values]
                    .map(
                      (format) => DropdownMenuItem(
                        value: format,
                        child: Text(
                          format,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
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
