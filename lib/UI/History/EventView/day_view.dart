import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

import 'calendar_day.dart';

class DayView extends ConsumerWidget {
  const DayView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final DateTime? selected =
        ref.watch(filtersProvider.select((value) => value.selectedDate));
    final EventList<CalendarEvent> eventMap = ref.watch(eventsMapProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: IconTheme(
              data: IconTheme.of(context).copyWith(size: 30.0),
              child: CalendarCarousel<CalendarEvent>(
                onDayPressed: (date, events) {
                  if (selected != date) {
                    final Filters current = ref.read(filtersProvider);
                    ref.read(filtersProvider.notifier).state =
                        current.copyWith(selectDate: date);
                  }
                },
                locale: Localizations.localeOf(context).countryCode ?? 'en',
                weekdayTextStyle: darkBackgroundStyle,
                showWeekDays: true,
                customDayBuilder: (isSelectable,
                    index,
                    isSelectedDay,
                    isToday,
                    isPrevMonthDay,
                    textStyle,
                    isNextMonthDay,
                    isThisMonthDay,
                    day) {
                  List<String> vals = dateToShortMDY(day).split(' ');

                  final int events = eventMap.getEvents(day).length;
                  return CalendarDay(
                      text: vals[1],
                      isToday: isToday,
                      selected:
                          selected == null ? false : sameDay(day, selected),
                      after: day.isAfter(now),
                      events: events);
                },
                todayButtonColor: Colors.transparent,
                todayBorderColor: Colors.transparent,
                selectedDayBorderColor: Colors.transparent,
                selectedDayButtonColor: Colors.transparent,
                iconColor: darkIconButton,
                headerMargin: const EdgeInsets.symmetric(vertical: 5.0),
                weekFormat: true,
                isScrollable: false,
                scrollDirection: Axis.horizontal,
                showHeader: true,
                headerTextStyle: darkBackgroundHeaderStyle,
                pageSnapping: true,
                inactiveDaysTextStyle: lightBackgroundStyle.copyWith(
                    fontSize: 14, color: lightBackgroundText.withOpacity(0.5)),
                maxSelectedDate: DateTime.now(),
                minSelectedDate: getMinDate(),
                height: 150,
                width: 380,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool sameDay(DateTime day, DateTime testDate) {
  return day.year == testDate.year &&
      day.month == testDate.month &&
      day.day == testDate.day;
}
