import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/calendar_day.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/text_styles.dart';

import 'day_view.dart';

class MonthView extends ConsumerWidget {
  const MonthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final Filters filters = ref.watch(filtersProvider);
    final EventList<CalendarEvent> eventMap = ref.watch(eventsMapProvider);
    final DateTime? selected = filters.selectedDate;
    final int rows = _numRows(filters.selectedMonth);
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: IconTheme(
              data: IconTheme.of(context).copyWith(size: 35.0),
              child: LayoutBuilder(builder: (context, constraints) {
                (constraints.maxWidth - 80) / rows.toDouble();
                final double height =
                    ((constraints.maxWidth / 7.0) * rows) + 90;
                return CalendarCarousel<CalendarEvent>(
                    locale: Localizations.localeOf(context).languageCode,
                    onDayPressed: (date, events) {
                      if (selected != date) {
                        ref.read(filtersProvider.notifier).state =
                            filters.copyWith(selectDate: date);
                        _scrollToEvents(context, isSmall);
                      } else {
                        ref.read(filtersProvider.notifier).state =
                            filters.copyWith(selectDate: null);
                      }
                    },
                    height: height,
                    customDayBuilder: (isSelectable,
                        index,
                        isSelectedDay,
                        isToday,
                        isPrevMonthDay,
                        textStyle,
                        isNextMonthDay,
                        isThisMonthDay,
                        day) {
                      final int events = eventMap.getEvents(day).length;
                      return CalendarDay(
                          text: '${day.day}',
                          isToday: isToday,
                          selected:
                              selected == null ? false : sameDay(day, selected),
                          after: day.isAfter(now),
                          events: events);
                    },
                    onCalendarChanged: (dateTime) {
                      ref.read(filtersProvider.notifier).state = filters
                          .copyWith(selectDate: null, selectMonth: dateTime);
                    },
                    headerMargin: const EdgeInsets.only(bottom: 5.0),
                    customGridViewPhysics: const NeverScrollableScrollPhysics(),
                    iconColor: Theme.of(context).colorScheme.secondary,
                    dayPadding: 2.0,
                    weekDayMargin: EdgeInsets.zero,
                    selectedDateTime: selected,
                    isScrollable: false,
                    todayButtonColor: Colors.transparent,
                    todayBorderColor: Colors.transparent,
                    selectedDayBorderColor: Colors.transparent,
                    selectedDayButtonColor: Colors.transparent,
                    daysTextStyle: Theme.of(context).textTheme.bodyMedium,
                    headerTextStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground),
                    weekendTextStyle: Theme.of(context).textTheme.bodyMedium,
                    inactiveDaysTextStyle:
                        Theme.of(context).textTheme.bodyMedium,
                    maxSelectedDate: DateTime.now(),
                    minSelectedDate: getMinDate(),
                    showOnlyCurrentMonthDate: true,
                    weekdayTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground));
              }),
            ),
          ),
        ),
      ),
    );
  }

  int _numRows(DateTime date) {
    const shiftMap = {
      DateTime.sunday: 0,
      DateTime.monday: 1,
      DateTime.tuesday: 2,
      DateTime.wednesday: 3,
      DateTime.thursday: 4,
      DateTime.friday: 5,
      DateTime.saturday: 6
    };
    final int shift = shiftMap[DateTime(date.year, date.month, 1).weekday]!;
    final int monthLength = DateTime(date.year, date.month + 1, 0).day;
    return ((monthLength + shift).toDouble() / 7.0).ceil();
  }

  _scrollToEvents(BuildContext context, bool isSmall) {
    final ScrollController? controller =
        context.findAncestorWidgetOfExactType<CustomScrollView>()?.controller;
    if (controller != null && controller.position.pixels > 1200) {
      controller.animateTo(isSmall ? 185 : 215,
          duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
    }
  }
}
