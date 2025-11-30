import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:table_calendar/table_calendar.dart';

class BottomSheetCalendar extends ConsumerStatefulWidget {
  const BottomSheetCalendar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BottomSheetCalendarState();
  }
}

class _BottomSheetCalendarState extends ConsumerState<BottomSheetCalendar> {
  DateTime focusedDay = DateTime.now();

  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  PageController? _pageController;

  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(displayDataProvider);
    _rangeStart = settings.range.start;
    _rangeEnd = settings.range.end;

    if (settings.cycle != DisplayTimeCycle.month &&
        _rangeEnd != null &&
        _rangeEnd!.hour == 0 &&
        _rangeEnd!.minute == 0 &&
        _rangeEnd!.second == 0 &&
        _rangeEnd!.millisecond == 0) {
      _rangeEnd = _rangeEnd!.subtract(const Duration(milliseconds: 1));
    }
    focusedDay = _rangeEnd ?? DateTime.now();
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    if (start != null && end == null && _rangeStart != null) {
      if (isSameDay(start, _rangeStart)) {
        end = start;
      }
    }
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      this.focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final AsyncValue<Map<DateTime, List<Response>>> eventsValue =
        ref.watch(eventsMapProvider);

    final bool waiting = eventsValue.isLoading || eventsValue.hasError;
    final Map<DateTime, List<Response>> eventMap =
        eventsValue.valueOrNull ?? {};

    final bool validRange = _rangeStart != null && _rangeEnd != null;

    final DateTime now = DateTime.now();
    const CalendarStyle calendarStyle = CalendarStyle(
      cellMargin: EdgeInsets.all(AppPadding.tiny),
      cellPadding: EdgeInsets.zero,
      outsideDaysVisible: false,
      rangeHighlightColor: Colors.transparent,
      withinRangeDecoration: BoxDecoration(),
      rangeStartDecoration: BoxDecoration(),
      rangeEndDecoration: BoxDecoration(),
    );

    Widget builder(BuildContext context, DateTime day, DateTime focus) {
      final int events = eventMap[day]?.length ?? 0;
      final DateTime normalizedDay = DateTime(day.year, day.month, day.day);
      final DateTime? normalizedStart = _rangeStart != null
          ? DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day)
          : null;
      final DateTime? normalizedEnd = _rangeEnd != null
          ? DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day)
          : null;

      final bool isStart =
          normalizedStart != null && isSameDay(normalizedDay, normalizedStart);
      final bool isEnd =
          normalizedEnd != null && isSameDay(normalizedDay, normalizedEnd);
      final bool isWithin = normalizedStart != null &&
          normalizedEnd != null &&
          normalizedDay.isAfter(normalizedStart) &&
          normalizedDay.isBefore(normalizedEnd) &&
          !isStart &&
          !isEnd;

      return CalendarDay(
        day: day,
        isToday: isSameDay(day, now),
        selected: false,
        disabled: day.isAfter(now),
        events: events,
        rangeStart: isStart,
        rangeEnd: isEnd,
        within: isWithin,
        endSelected: normalizedEnd != null,
        style: calendarStyle,
      );
    }

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
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium, vertical: AppPadding.small),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Select Range",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: AppPadding.small),
                  FilledButton(
                    onPressed: validRange
                        ? () {
                            DateTime end = _rangeEnd!;
                            if (end.hour == 0 &&
                                end.minute == 0 &&
                                end.second == 0 &&
                                end.millisecond == 0) {
                              end = end
                                  .add(const Duration(days: 1))
                                  .subtract(const Duration(milliseconds: 1));
                            }
                            ref.read(displayDataProvider.notifier).setRange(
                                DateTimeRange(start: _rangeStart!, end: end));
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text("Apply"),
                  ),
                ],
              )
            ],
          ),
        ),
        const Divider(height: 1),
        _CalendarHeader(
          onYearChange: _onYearChange,
          focusedDay: focusedDay,
          showingYearPicker: _showYearPicker,
          onLeftArrowTap: () {
            _pageController?.previousPage(
              duration: Durations.medium1,
              curve: Curves.easeOut,
            );
          },
          onRightArrowTap: () {
            _pageController?.nextPage(
              duration: Durations.medium1,
              curve: Curves.easeOut,
            );
          },
        ),
        Flexible(
          child: Stack(
            children: [
              Visibility(
                visible: !_showYearPicker,
                maintainState: true,
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: waiting,
                      child: Opacity(
                        opacity: waiting ? 0.6 : 1.0,
                        child: TableCalendar(
                          locale: locale.languageCode,
                          onCalendarCreated: (controller) {
                            _pageController = controller;
                          },
                          daysOfWeekHeight: 25.0,
                          focusedDay: focusedDay,
                          firstDay: DateTime(2020),
                          lastDay:
                              (_rangeEnd != null && _rangeEnd!.isAfter(now))
                                  ? _rangeEnd!
                                  : now,
                          rangeSelectionMode: RangeSelectionMode.toggledOn,
                          rangeStartDay: _rangeStart,
                          rangeEndDay: _rangeEnd,
                          headerVisible: false,
                          availableGestures: AvailableGestures.horizontalSwipe,
                          calendarStyle: calendarStyle,
                          onRangeSelected: _onRangeSelected,
                          onPageChanged: (newFocus) {
                            setState(() {
                              focusedDay = newFocus;
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
              ),
              if (_showYearPicker)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: YearPicker(
                    currentDate: focusedDay,
                    firstDate: SigDates.minDate,
                    lastDate: DateTime.now(),
                    selectedDate: focusedDay,
                    onChanged: (val) {
                      setState(() {
                        focusedDay = DateTime(
                            val.year, focusedDay.month, focusedDay.day);
                        _showYearPicker = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onYearChange() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final bool showingYearPicker;

  final VoidCallback onYearChange;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onYearChange,
    required this.showingYearPicker,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentYear = DateTime.now().year == focusedDay.year;
    final String headerText = isCurrentYear
        ? DateFormat.MMMM().format(focusedDay)
        : DateFormat.yMMMM().format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          const SizedBox(width: AppPadding.tiny),
          Expanded(
            child: TextButton.icon(
              iconAlignment: IconAlignment.end,
              icon: showingYearPicker
                  ? const Icon(Icons.keyboard_arrow_up)
                  : const Icon(Icons.keyboard_arrow_down),
              label: Text(
                headerText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: () {
                onYearChange();
              },
            ),
          ),
          const SizedBox(width: AppPadding.tiny),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}
