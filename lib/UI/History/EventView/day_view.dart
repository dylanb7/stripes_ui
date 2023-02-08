import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class DayView extends ConsumerWidget {
  const DayView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  final Widget inner = _inner(vals[1], isToday,
                      selected == null ? false : sameDay(day, selected));
                  final int events = eventMap.getEvents(day).length;
                  if (events == 0) return inner;
                  return Badge(
                      badgeContent: Text(
                        '$events',
                        style: darkBackgroundStyle.copyWith(fontSize: 10.0),
                      ),
                      badgeColor: darkIconButton,
                      position: BadgePosition.topEnd(top: 0, end: 0),
                      child: inner);
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

  Widget _inner(String text, bool isToday, bool selected) {
    final Color background =
        selected ? darkBackgroundText : backgroundLight.withOpacity(0.8);
    final Color textColor =
        selected ? buttonDarkBackground : darkBackgroundText;
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),
        padding: const EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isToday ? darkBackgroundText : Colors.transparent,
                  width: 2.0)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Center(
              child: Text(
                text,
                style: darkBackgroundStyle.copyWith(
                    color: textColor, fontSize: 20),
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
