import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';

import 'calendar_day.dart';

class DayView extends ConsumerWidget {
  const DayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final DateTime? selected =
        ref.watch(filtersProvider.select((value) => value.selectedDate));
    final AsyncValue<Map<DateTime, List<Response>>> eventMap =
        ref.watch(eventsMapProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: IconTheme(
              data: IconTheme.of(context).copyWith(size: 35.0),
              child: CalendarCarousel<CalendarEvent>(
                onDayPressed: (date, events) {
                  if (selected != date) {
                    final Filters current = ref.read(filtersProvider);
                    ref.read(filtersProvider.notifier).state =
                        current.copyWith(selectDate: date);
                  }
                },
                locale: Localizations.localeOf(context).languageCode,
                weekdayTextStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground),
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
                  final int events = eventMap.valueOrNull?[day]?.length ?? 0;
                  return CalendarDay(
                      text: '${day.day}',
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
                iconColor: Theme.of(context).colorScheme.secondary,
                headerMargin: const EdgeInsets.only(bottom: 5.0),
                weekFormat: true,
                isScrollable: true,
                scrollDirection: Axis.horizontal,
                showHeader: true,
                headerTextStyle: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground),
                pageSnapping: true,
                inactiveDaysTextStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
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
