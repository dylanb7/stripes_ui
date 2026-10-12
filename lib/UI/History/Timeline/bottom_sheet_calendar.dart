import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';

import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:table_calendar/table_calendar.dart';

class BottomSheetCalendar extends ConsumerStatefulWidget {
  final DateTimeRange? initialRange;
  final void Function(DateTimeRange)? onRangeSelected;
  final bool ignoreFilters;

  const BottomSheetCalendar({
    super.key,
    this.initialRange,
    this.onRangeSelected,
    this.ignoreFilters = false,
  });

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
    if (widget.initialRange != null) {
      _rangeStart = widget.initialRange!.start;
      _rangeEnd = widget.initialRange!.end;
    } else {
      final settings = ref.read(displayDataProvider);
      _rangeStart = settings.range.start;
      _rangeEnd = settings.range.end;

      if (_rangeEnd != null && !_dateAltered(_rangeEnd)) {
        _rangeEnd = DateRangeUtils.inclusiveEndOfDay(_rangeEnd!);
      }
    }
    focusedDay = _rangeEnd ?? DateTime.now();
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    // TableCalendar supplies civil dates. Preserve the selected date components.
    start = start == null ? null : DateTime(start.year, start.month, start.day);
    end = end == null ? null : DateTime(end.year, end.month, end.day);
    focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
    // A pending range start is also a complete single-day selection. Keep
    // end null so the calendar can still extend it on the next date tap.
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      this.focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.ignoreFilters
        ? ref.watch(unfilteredEventsMapProvider)
        : ref.watch(eventsMapProvider);
    final paths = ref.watch(
      recordPaths(
        const RecordPathProps(
          filterEnabled: true,
          type: PathProviderType.review,
        ),
      ),
    );

    return events.when(
      loading: () =>
          const _CalendarStateMessage(child: CircularProgressIndicator()),
      error: (error, stack) => _CalendarStateMessage(
        child: Text('Unable to load calendar events: $error'),
      ),
      data: (eventMap) => paths.when(
        loading: () =>
            const _CalendarStateMessage(child: CircularProgressIndicator()),
        error: (error, stack) => _CalendarStateMessage(
          child: Text('Unable to load review paths: $error'),
        ),
        data: (checkinPaths) => _buildCalendar(
          context,
          eventMap: eventMap,
          checkinPaths: checkinPaths,
        ),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context, {
    required Map<DateTime, List<Response>> eventMap,
    required List<RecordPath> checkinPaths,
  }) {
    final Locale locale = Localizations.localeOf(context);
    final TextStyle weekdayStyle = Theme.of(context).textTheme.bodyMedium!;
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double weekdayFontSize = textScaler.scale(weekdayStyle.fontSize!);
    final double weekdayHeight =
        weekdayFontSize * (weekdayStyle.height ?? 1.2) + AppPadding.small;

    final DateTime now = DateTime.now();

    final Set<DateTime> checkInCoverage = {};
    if (eventMap.isNotEmpty) {
      final Map<String, dynamic> typeToPeriod = {
        for (var p in checkinPaths) p.name: p.period!,
      };

      for (final events in eventMap.values) {
        for (final event in events) {
          final period = typeToPeriod[event.type];
          if (period != null) {
            final DateTime date = dateFromStamp(event.stamp);
            final DateTimeRange range = period.getRange(date);

            DateTime iterator = DateTime(
              range.start.year,
              range.start.month,
              range.start.day,
            );
            final DateTime end = DateTime(
              range.end.year,
              range.end.month,
              range.end.day,
            );

            if (DateUtils.isSameDay(range.start, range.end)) {
              checkInCoverage.add(iterator);
            } else {
              while (!iterator.isAfter(end) && !iterator.isAfter(now)) {
                checkInCoverage.add(iterator);
                iterator = DateRangeUtils.shiftCalendarDays(iterator, 1);
              }
            }
          }
        }
      }
    }

    const CalendarStyle calendarStyle = CalendarStyle(
      cellMargin: EdgeInsets.all(AppPadding.tiny),
      cellPadding: EdgeInsets.zero,
      outsideDaysVisible: false,
      rangeHighlightColor: Colors.transparent,
      withinRangeDecoration: BoxDecoration(),
      rangeStartDecoration: BoxDecoration(),
      rangeEndDecoration: BoxDecoration(),
    );

    final DateTime lastDay = (_rangeEnd != null && _rangeEnd!.isAfter(now))
        ? _rangeEnd!
        : now;

    Widget builder(BuildContext context, DateTime day, DateTime focus) {
      final DateTime normalizedDay = DateTime(day.year, day.month, day.day);
      final DateTime? normalizedStart = _rangeStart != null
          ? DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day)
          : null;
      final DateTime? normalizedEnd = _rangeEnd != null
          ? DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day)
          : normalizedStart;

      final bool isStart =
          normalizedStart != null && isSameDay(normalizedDay, normalizedStart);
      final bool isEnd =
          normalizedEnd != null && isSameDay(normalizedDay, normalizedEnd);
      final bool isWithin =
          normalizedStart != null &&
          normalizedEnd != null &&
          normalizedDay.isAfter(normalizedStart) &&
          normalizedDay.isBefore(normalizedEnd) &&
          !isStart &&
          !isEnd;

      int displayEvents = 0;
      final List<Response>? dayEvents = eventMap[day];

      if (dayEvents != null && dayEvents.isNotEmpty) {
        final Set<String> checkinTypes = checkinPaths
            .map((p) => p.name)
            .toSet();
        displayEvents = dayEvents
            .where((e) => !checkinTypes.contains(e.type))
            .length;
      }

      final bool hasCheckIn = checkInCoverage.contains(normalizedDay);

      return CalendarDay(
        day: day,
        isToday: isSameDay(day, now),
        selected: false,
        disabled: day.isAfter(now),
        events: displayEvents,
        rangeStart: isStart,
        rangeEnd: isEnd,
        within: isWithin,
        endSelected: normalizedEnd != null,
        style: calendarStyle,
        hasCheckIn: hasCheckIn,
      );
    }

    Widget? dowBuilder(BuildContext context, DateTime day) {
      final weekdayString = DateFormat(
        weekdayFontSize > 18 ? 'EEEEE' : 'EEE',
        locale.languageCode,
      ).format(day);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppPadding.small),
        child: Center(
          child: ExcludeSemantics(
            child: Text(
              weekdayString,
              style: weekdayStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      "Select dates",
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.small,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            !_showYearPicker &&
                                DateTime(
                                  focusedDay.year,
                                  focusedDay.month,
                                ).isAfter(
                                  DateTime(
                                    SigDates.minDate.year,
                                    SigDates.minDate.month,
                                  ),
                                )
                            ? () => _pageController?.previousPage(
                                duration: Durations.medium1,
                                curve: Curves.easeOut,
                              )
                            : null,
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _onYearChange,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _monthLabel(
                                    focusedDay,
                                    locale,
                                    abbreviated: weekdayFontSize > 18,
                                  ),
                                  semanticsLabel: _monthLabel(
                                    focusedDay,
                                    locale,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              const SizedBox(width: AppPadding.tiny),
                              AnimatedRotation(
                                turns: _showYearPicker ? 0.5 : 0,
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 360),
                                curve: Curves.easeOutBack,
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            !_showYearPicker &&
                                DateTime(
                                  focusedDay.year,
                                  focusedDay.month,
                                ).isBefore(
                                  DateTime(lastDay.year, lastDay.month),
                                )
                            ? () => _pageController?.nextPage(
                                duration: Durations.medium1,
                                curve: Curves.easeOut,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 6 * 52 + weekdayHeight,
                  ),
                  // Both views keep their layout and identity while moving between
                  // the day and year levels, including when a toggle is interrupted.
                  child: Stack(
                    children: [
                      _CalendarModeTransition(
                        visible: !_showYearPicker,
                        yearLayer: false,
                        child: IgnorePointer(
                          ignoring: _showYearPicker,
                          child: ExcludeSemantics(
                            excluding: _showYearPicker,
                            child: TableCalendar(
                              locale: locale.languageCode,
                              onCalendarCreated: (controller) {
                                _pageController = controller;
                              },
                              daysOfWeekHeight: weekdayHeight,
                              focusedDay: focusedDay.isAfter(lastDay)
                                  ? lastDay
                                  : focusedDay,
                              firstDay: SigDates.minDate,
                              lastDay: lastDay,
                              rangeSelectionMode: RangeSelectionMode.toggledOn,
                              rangeStartDay: _rangeStart,
                              rangeEndDay: _rangeEnd,
                              headerVisible: false,
                              availableGestures:
                                  AvailableGestures.horizontalSwipe,
                              calendarStyle: calendarStyle,
                              onRangeSelected: _onRangeSelected,
                              onPageChanged: (newFocus) {
                                // Update earliest date when navigating to earlier months
                                ref
                                    .read(displayDataProvider.notifier)
                                    .ensureDate(
                                      DateTime(
                                        newFocus.year,
                                        newFocus.month,
                                        1,
                                      ),
                                    );
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
                      ),
                      Positioned.fill(
                        child: _CalendarModeTransition(
                          visible: _showYearPicker,
                          yearLayer: true,
                          child: IgnorePointer(
                            ignoring: !_showYearPicker,
                            child: ExcludeSemantics(
                              excluding: !_showYearPicker,
                              child: YearPicker(
                                currentDate: now,
                                firstDate: SigDates.minDate,
                                lastDate: DateTime.now(),
                                selectedDate: focusedDay,
                                onChanged: (val) {
                                  setState(() {
                                    final day = focusedDay.day.clamp(
                                      1,
                                      DateUtils.getDaysInMonth(
                                        val.year,
                                        focusedDay.month,
                                      ),
                                    );
                                    final selected = DateTime(
                                      val.year,
                                      focusedDay.month,
                                      day,
                                    );
                                    focusedDay = selected.isAfter(lastDay)
                                        ? lastDay
                                        : selected;
                                    ref
                                        .read(displayDataProvider.notifier)
                                        .ensureDate(
                                          DateTime(
                                            focusedDay.year,
                                            focusedDay.month,
                                            1,
                                          ),
                                        );
                                    _showYearPicker = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.small,
            ),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: AppPadding.small,
              overflowSpacing: AppPadding.small,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: _rangeStart != null ? _apply : null,
                  child: const Text("Apply"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _apply() {
    final range = DateRangeUtils.rangeFromSelection(
      _rangeStart!,
      _rangeEnd ?? _rangeStart!,
    );

    if (widget.onRangeSelected != null) {
      widget.onRangeSelected!(range);
    } else {
      ref
          .read(displayDataProvider.notifier)
          .setRange(
            range,
            cycle: isSameDay(_rangeStart, _rangeEnd ?? _rangeStart)
                ? TimeCycle.day
                : TimeCycle.custom,
          );
    }
    Navigator.of(context).pop();
  }

  bool _dateAltered(DateTime? date) {
    if (date == null) return false;
    return date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0;
  }

  void _onYearChange() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
  }
}

/// A small change in depth makes switching granularity feel spatial: days
/// retreat toward the header while years rise forward with a gentle overshoot.
/// The child stays mounted, so reversing mid-animation never duplicates it.
class _CalendarModeTransition extends StatelessWidget {
  final bool visible;
  final bool yearLayer;
  final Widget child;

  const _CalendarModeTransition({
    required this.visible,
    required this.yearLayer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: visible ? 1 : 0, end: visible ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: visible ? 360 : 240),
      curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
      child: child,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0);
        final distance = 1 - value;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (yearLayer ? 28 : -16) * distance),
            child: Transform.scale(
              scale: 1 - (yearLayer ? 0.08 : 0.06) * distance,
              alignment: yearLayer ? Alignment.center : Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

String _monthLabel(DateTime day, Locale locale, {bool abbreviated = false}) {
  return day.year == DateTime.now().year
      ? DateFormat(
          abbreviated ? 'MMM' : 'MMMM',
          locale.languageCode,
        ).format(day)
      : (abbreviated
                ? DateFormat.yMMM(locale.languageCode)
                : DateFormat.yMMMM(locale.languageCode))
            .format(day);
}

class _CalendarStateMessage extends StatelessWidget {
  final Widget child;

  const _CalendarStateMessage({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 260, child: Center(child: child));
  }
}
