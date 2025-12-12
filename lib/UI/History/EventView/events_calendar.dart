import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../Util/paddings.dart';

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

  CalendarFormat _format = CalendarFormat.week;

  bool isHidden = false;

  PageController? _pageController;

  final GlobalKey calendarHeaderKey = GlobalKey();

  final DateTime firstDate = DateTime(2020);

  late final CustomSegmentedController<RangeSelection> rangeSelection;

  late final DateRangeSelectionListener dateRangeSelectionListener;

  @override
  void initState() {
    _initializeRangeSelection();
    _initializeFormat();
    dateRangeSelectionListener.addListener(_handleDateRangeChange);
    super.initState();
  }

  @override
  void dispose() {
    dateRangeSelectionListener.removeListener(_handleDateRangeChange);
    super.dispose();
  }

  _initializeFormat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _format = getBreakpoint(context).isGreaterThan(Breakpoint.small)
            ? CalendarFormat.month
            : CalendarFormat.week;
      });
    });
  }

  _initializeRangeSelection() {
    final DisplayDataSettings filters = ref.read(displayDataProvider);
    rangeSelection = CustomSegmentedController(value: RangeSelection.end);
    dateRangeSelectionListener = DateRangeSelectionListener(
        filters.cycle == DisplayTimeCycle.day
            ? RangeStatus.disabled
            : RangeStatus.enabled);
  }

  _handleDateRangeChange() {
    if (!mounted) return;
    if (dateRangeSelectionListener.selectingRange) {
      rangeSelection.value = RangeSelection.end;
      ref.read(displayDataProvider.notifier).setCycle(DisplayTimeCycle.custom);
    } else {
      ref.read(displayDataProvider.notifier).setCycle(DisplayTimeCycle.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final DisplayDataSettings calendarSelection =
        ref.watch(displayDataProvider);
    final AsyncValue<Map<DateTime, List<Response>>> eventsValue =
        ref.watch(eventsMapProvider);

    final bool waiting = eventsValue.isLoading || eventsValue.hasError;
    final Map<DateTime, List<Response>> eventMap =
        eventsValue.valueOrNull ?? {};
    final DateTime? selected = calendarSelection.cycle == DisplayTimeCycle.day
        ? calendarSelection.range.start
        : null;
    final DateTime? rangeStart = calendarSelection.cycle != DisplayTimeCycle.day
        ? calendarSelection.range.start
        : null;
    final DateTime? rangeEnd = calendarSelection.cycle != DisplayTimeCycle.day
        ? calendarSelection.range.end.subtract(const Duration(days: 1))
        : null;
    final DateTime now = DateTime.now();
    const CalendarStyle calendarStyle = CalendarStyle(
      cellMargin: EdgeInsets.all(AppPadding.tiny),
      cellPadding: EdgeInsets.zero,
      outsideDaysVisible: false,
    );

    final Map<CalendarFormat, String> formats = {
      CalendarFormat.week: context.translate.calendarVisibilityWeek,
      CalendarFormat.month: context.translate.calendarVisibilityMonth
    };

    final bool canClear = rangeStart != null && rangeEnd != null;

    reset() {
      setState(() {
        dateRangeSelectionListener.setMode(selectingRange: false);
        focusedDay = DateTime.now();
        ref.read(displayDataProvider.notifier).setCycle(DisplayTimeCycle.day);
        ref.read(displayDataProvider.notifier).setRange(DateTimeRange(
            start: focusedDay, end: focusedDay.add(const Duration(days: 1))));
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

    /*Widget? rangeHighlight(
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
    }*/

    Widget? dowBuilder(BuildContext context, DateTime day) {
      final weekdayString = DateFormat.E(locale.languageCode).format(day);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppPadding.small),
        child: Center(
          child: ExcludeSemantics(
            child: Text(
              weekdayString,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
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
            onStartClear: null,
            onEndClear: canClear
                ? () {
                    final DisplayDataSettings filters =
                        ref.read(displayDataProvider);
                    ref.read(displayDataProvider.notifier).setRange(
                        DateTimeRange(
                            start: filters.range.start,
                            end: filters.range.start
                                .add(const Duration(days: 1))));
                    rangeSelection.value = RangeSelection.end;
                  }
                : null,
            selectedDay: selected,
            start: rangeStart,
            end: rangeEnd,
            rangeSelectionController: rangeSelection),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        Visibility(
          maintainState: true,
          visible: !isHidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRounding.small)),
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface)),
            padding: const EdgeInsets.only(bottom: AppPadding.tiny),
            child: Column(
              children: [
                _CalendarHeader(
                    key: calendarHeaderKey,
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
                          rangeSelectionMode: RangeSelectionMode.disabled,
                          headerVisible: false,
                          calendarFormat: _format,
                          availableGestures: AvailableGestures.horizontalSwipe,
                          availableCalendarFormats: formats,
                          onFormatChanged: null,
                          calendarStyle: calendarStyle,
                          onCalendarCreated: (controller) {
                            _onCalendarCreated(controller);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _onDaySelected(selectedDay, focusedDay);
                            });
                          },
                          onRangeSelected: null,
                          onPageChanged: (newFocus) {
                            _onPageChange(newFocus);
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: builder,
                            todayBuilder: builder,
                            rangeStartBuilder: builder,
                            rangeEndBuilder: builder,
                            withinRangeBuilder: builder,
                            disabledBuilder: builder,
                            dowBuilder: dowBuilder,
                          ),
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
      ],
    );
  }

  void _onPageChange(DateTime newFocus) {
    focusedDay = newFocus;
    setState(() {});
  }

  void _onCalendarCreated(PageController controller) {
    _pageController = controller;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.focusedDay = focusedDay;

    final DisplayDataSettings settings = ref.read(displayDataProvider);

    if (settings.cycle == DisplayTimeCycle.day) {
      if (!sameDay(selectedDay, settings.range.start)) {
        ref.read(displayDataProvider.notifier).setRange(DateTimeRange(
            start: selectedDay, end: selectedDay.add(const Duration(days: 1))));
      }
      return;
    }

    final RangeSelection? selection = rangeSelection.value;
    final DateTimeRange currentRange = settings.range;

    if (selection == RangeSelection.start) {
      if (currentRange.end.isBefore(selectedDay)) {
        ref.read(displayDataProvider.notifier).setRange(
            DateTimeRange(
                start: selectedDay,
                end: selectedDay.add(const Duration(days: 1))),
            cycle: DisplayTimeCycle.custom);
        rangeSelection.value = RangeSelection.end;
      } else {
        ref.read(displayDataProvider.notifier).setRange(
            DateTimeRange(start: selectedDay, end: currentRange.end),
            cycle: DisplayTimeCycle.custom);
      }
    } else if (selection == RangeSelection.end) {
      if (selectedDay.isBefore(currentRange.start)) {
        ref.read(displayDataProvider.notifier).setRange(
            DateTimeRange(
                start: selectedDay,
                end: selectedDay.add(const Duration(days: 1))),
            cycle: DisplayTimeCycle.custom);
      } else {
        // Add 1 day to include the selected end day
        ref.read(displayDataProvider.notifier).setRange(
            DateTimeRange(
                start: currentRange.start,
                end: selectedDay.add(const Duration(days: 1))),
            cycle: DisplayTimeCycle.custom);
      }
    }
  }

  void _onYearChange() {
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

  void _onFormatChange(CalendarFormat? newFormat) {
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

class _CalendarHeader extends StatelessWidget {
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
      required this.onFormatChange,
      super.key});

  @override
  Widget build(BuildContext context) {
    final bool isTiny = getBreakpoint(context).isLessThan(Breakpoint.tiny);

    final Map<CalendarFormat, String> formats = {
      CalendarFormat.week: context.translate.calendarVisibilityWeek,
      CalendarFormat.month: context.translate.calendarVisibilityMonth
    };
    final String headerText = DateFormat.yMMM().format(focusedDay);

    final Widget calendarFormatIcon = selected == CalendarFormat.month
        ? Icon(
            Icons.calendar_month,
            color: Theme.of(context).colorScheme.onPrimary,
          )
        : Icon(
            Icons.calendar_view_week,
            color: Theme.of(context).colorScheme.onPrimary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          TextButton(
            child: Text(
              headerText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onPressed: () {
              onYearChange();
            },
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
          isTiny
              ? IconButton.filled(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(AppRounding.small)))),
                  ),
                  onPressed: () {
                    reset();
                  },
                  icon: const Icon(Icons.restart_alt))
              : FilledButton.icon(
                  onPressed: () {
                    reset();
                  },
                  label: Text(context.translate.eventFilterReset),
                  icon: const Icon(Icons.restart_alt),
                ),
          const SizedBox(width: AppPadding.tiny),
          PopupMenuButton<CalendarFormat>(
            initialValue: selected,
            onSelected: (format) {
              onFormatChange(format);
            },
            icon: isTiny
                ? DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRounding.small),
                        color: Theme.of(context).primaryColor),
                    child: Padding(
                        padding: const EdgeInsets.all(AppPadding.small),
                        child: calendarFormatIcon),
                  )
                : IgnorePointer(
                    child: FilledButton.icon(
                      style: const ButtonStyle(
                          splashFactory: NoSplash.splashFactory),
                      onPressed: () {},
                      label: Text(formats[selected]!),
                      icon: calendarFormatIcon,
                    ),
                  ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarFormat.month,
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_month,
                  ),
                  title: Text(formats[CalendarFormat.month]!),
                ),
              ),
              PopupMenuItem(
                value: CalendarFormat.week,
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_view_week,
                  ),
                  title: Text(formats[CalendarFormat.week]!),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppPadding.small),
        ],
      ),
    );
  }
}

enum RangeSelection {
  start,
  end;
}

enum RangeStatus {
  enabled,
  disabled;
}

class DateRangeSelectionListener extends ChangeNotifier {
  RangeStatus mode;

  DateRangeSelectionListener(this.mode);

  setMode({required bool selectingRange}) {
    final RangeStatus newMode =
        selectingRange ? RangeStatus.enabled : RangeStatus.disabled;
    if (newMode != mode) {
      mode = newMode;
      notifyListeners();
    }
  }

  bool get selectingRange => mode == RangeStatus.enabled;
}

class DateSelectionDisplay extends StatefulWidget {
  final DateRangeSelectionListener listener;

  final CustomSegmentedController<RangeSelection> rangeSelectionController;

  final void Function()? onStartClear, onEndClear;

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
    final bool singleDate = widget.listener.mode == RangeStatus.disabled;

    final bool isTiny = getBreakpoint(context).isLessThan(Breakpoint.tiny);

    final Widget rangeSelectionIcon = singleDate
        ? Icon(
            Icons.event,
            color: Theme.of(context).colorScheme.onPrimary,
          )
        : Icon(
            Icons.date_range,
            color: Theme.of(context).colorScheme.onPrimary,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PopupMenuButton<RangeStatus>(
            padding: EdgeInsets.zero,
            icon: isTiny
                ? DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRounding.small),
                        color: Theme.of(context).primaryColor),
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.small),
                      child: rangeSelectionIcon,
                    ),
                  )
                : IgnorePointer(
                    child: FilledButton.icon(
                      style: const ButtonStyle(
                          splashFactory: NoSplash.splashFactory),
                      onPressed: () {},
                      label: Text(singleDate ? "Day" : "Range"),
                      icon: rangeSelectionIcon,
                    ),
                  ),
            onSelected: (status) {
              widget.listener
                  .setMode(selectingRange: status == RangeStatus.enabled);
              setState(() {});
            },
            itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: RangeStatus.enabled,
                    child: ListTile(
                      leading: Icon(Icons.date_range),
                      title: Text("Range"),
                    ),
                  ),
                  const PopupMenuItem(
                    value: RangeStatus.disabled,
                    child: ListTile(
                      leading: Icon(Icons.event),
                      title: Text("Day"),
                    ),
                  ),
                ]),
        const SizedBox(
          width: AppPadding.tiny,
        ),
        if (singleDate)
          SizedBox(
            height: Theme.of(context).buttonTheme.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.small),
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: DateDispay(
                title: "Selected",
                clear: null,
                hovered: true,
                selected: widget.selectedDay,
              ),
            ),
          )
        else
          SizedBox(
            height: Theme.of(context).buttonTheme.height,
            child: CustomSlidingSegmentedControl<RangeSelection>(
              initialValue: widget.rangeSelectionController.value,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRounding.small),
                  color: Colors.transparent,
                  border: Border.all(color: Theme.of(context).disabledColor)),
              thumbDecoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(7.0)),
              innerPadding: EdgeInsets.zero,
              padding: 2,
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
                  hovered: widget.rangeSelectionController.value ==
                      RangeSelection.end,
                  selected: widget.end,
                )
              },
              onValueChanged: (_) {
                setState(() {});
              },
              controller: widget.rangeSelectionController,
            ),
          ),
      ],
    );
  }
}

class DateDispay extends StatelessWidget {
  final bool hovered;

  final String? title;

  final DateTime? selected;

  final void Function()? clear;

  const DateDispay({
    super.key,
    required this.hovered,
    this.title,
    this.selected,
    this.clear,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDate = selected != null;
    return SizedBox(
        width: 120.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              hasDate ? DateFormat.yMd().format(selected!) : "select",
              textAlign: TextAlign.center,
              style: hovered
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasDate
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor)
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: !hasDate ? Theme.of(context).disabledColor : null),
            ),
            if (clear != null) ...[
              const SizedBox(
                width: 2.0,
              ),
              IconButton(
                onPressed: () {
                  clear!();
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18.0,
                icon: const Icon(
                  Icons.clear,
                ),
              )
            ],
          ],
        ));
  }
}

bool sameDay(DateTime day, DateTime testDate) {
  return day.year == testDate.year &&
      day.month == testDate.month &&
      day.day == testDate.day;
}
