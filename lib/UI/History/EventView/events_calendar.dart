import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
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

  late final CustomSegmentedController<RangeSelection> rangeSelection;

  late final DateRangeSelectionListener dateRangeSelectionListener;

  @override
  void initState() {
    rangeSelection = CustomSegmentedController(value: RangeSelection.start);
    dateRangeSelectionListener =
        DateRangeSelectionListener(RangeSelectionMode.disabled);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final Filters filters = ref.watch(filtersProvider);
    final AsyncValue<Map<DateTime, List<Response>>> eventsValue =
        ref.watch(eventsMapProvider);

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

    reset() {
      setState(() {
        focusedDay = DateTime.now();
        _rangeMode = RangeSelectionMode.toggledOff;
        ref.read(filtersProvider.notifier).state = Filters(
            rangeStart: null,
            rangeEnd: null,
            stampFilters: null,
            latestRequired: filters.latestRequired,
            earliestRequired: filters.earliestRequired,
            selectedDate: focusedDay,
            groupSymptoms: filters.groupSymptoms);
      });
    }

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
          DateSelectionDisplay(
              listener: dateRangeSelectionListener,
              onStartClear: () {},
              onEndClear: () {},
              selectedDay: selected,
              start: rangeStart,
              end: rangeEnd,
              rangeSelectionController: rangeSelection),
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
                      reset: () {
                        reset();
                      },
                      onFormatChange: _onFormatChange,
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
                            rangeSelectionMode: dateRangeSelectionListener.mode,
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
                                              filters.earliestRequired,
                                          groupSymptoms: filters.groupSymptoms);
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
                                            filters.earliestRequired,
                                        groupSymptoms: filters.groupSymptoms);
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

  final VoidCallback onYearChange;

  final VoidCallback reset;

  final CalendarFormat selected;
  final Function(CalendarFormat?) onFormatChange;

  const _CalendarHeader(
      {required this.focusedDay,
      required this.onLeftArrowTap,
      required this.onRightArrowTap,
      required this.selected,
      required this.onYearChange,
      required this.reset,
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
          const SizedBox(
            width: 6.0,
          ),
          TextButton(
            child: Text(
              headerText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onPressed: () {},
          ),
          const SizedBox(
            width: 6.0,
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
              reset();
            },
            label: Text(AppLocalizations.of(context)!.eventFilterReset),
            icon: const Icon(Icons.restart_alt),
          ),
          const SizedBox(width: 6.0),
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
          const SizedBox(width: 6.0),
        ],
      ),
    );
  }
}

enum RangeSelection {
  start,
  end;
}

class DateRangeSelectionListener extends ChangeNotifier {
  RangeSelectionMode mode;

  DateRangeSelectionListener(this.mode);

  setMode({required bool selectingRange}) {
    final RangeSelectionMode newMode = selectingRange
        ? RangeSelectionMode.enforced
        : RangeSelectionMode.disabled;
    if (newMode != mode) {
      mode = newMode;
      notifyListeners();
    }
  }
}

class DateSelectionDisplay extends StatefulWidget {
  final DateRangeSelectionListener listener;

  final CustomSegmentedController<RangeSelection> rangeSelectionController;

  final void Function() onStartClear, onEndClear;

  final DateTime? selectedDay, start, end;

  const DateSelectionDisplay({
    required this.listener,
    required this.onStartClear,
    required this.onEndClear,
    required this.rangeSelectionController,
    this.selectedDay,
    this.start,
    this.end,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _DateSelectionDisplayState();
  }
}

class _DateSelectionDisplayState extends State<DateSelectionDisplay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool singleDate = widget.listener.mode == RangeSelectionMode.disabled;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (singleDate)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: ElevationOverlay.applySurfaceTint(
                  Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surfaceTint,
                  3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DateDispay(
                    title: "Selected",
                    clear: null,
                    hovered: true,
                    selected: widget.selectedDay,
                  )),
            ),
          )
        else
          CustomSlidingSegmentedControl<RangeSelection>(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: ElevationOverlay.applySurfaceTint(
                  Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surfaceTint,
                  3),
            ),
            thumbDecoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.circular(8.0)),
            padding: 0,
            height: 60,
            children: {
              RangeSelection.start: DateDispay(
                title: "Start",
                clear: widget.onStartClear,
                hovered: widget.rangeSelectionController.value ==
                    RangeSelection.start,
                selected: widget.start,
              ),
              RangeSelection.end: DateDispay(
                title: "End",
                clear: widget.onEndClear,
                hovered:
                    widget.rangeSelectionController.value == RangeSelection.end,
                selected: widget.end,
              )
            },
            onValueChanged: (_) {},
            controller: CustomSegmentedController(value: RangeSelection.start),
          ),
        const SizedBox(
          width: 6.0,
        ),
        TextButton(
            onPressed: () {
              widget.listener.setMode(selectingRange: singleDate);
              setState(() {});
            },
            child: Text(singleDate ? "Select Range" : "Select Day"))
      ],
    );
  }
}

class DateDispay extends StatelessWidget {
  final bool hovered;

  final String title;

  final DateTime? selected;

  final void Function()? clear;

  const DateDispay({
    super.key,
    required this.title,
    required this.hovered,
    this.selected,
    this.clear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: hovered ? FontWeight.bold : null),
              ),
              const SizedBox(
                height: 4.0,
              ),
              if (selected != null)
                Text(
                  DateFormat.yMd().format(selected!),
                  style: hovered
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)
                      : Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  "Make selction",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.surfaceDim,
                      fontWeight: hovered ? FontWeight.bold : null),
                )
            ],
          ),
          const SizedBox(
            width: 6.0,
          ),
          if (clear != null)
            IconButton.filled(
              onPressed: () {
                clear!();
              },
              icon: const Icon(Icons.clear),
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
