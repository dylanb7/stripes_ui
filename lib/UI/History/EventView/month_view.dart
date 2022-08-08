import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

import 'day_view.dart';

class MonthView extends ConsumerWidget {
  const MonthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime? selected =
        ref.watch(filtersProvider.select((value) => value.selectedDate));
    final EventList<CalendarEvent> eventMap = ref.watch(eventsMapProvider);
    final bool isSmall = ref.watch(isSmallProvider);
    return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                decoration: const BoxDecoration(
                    color: darkBackgroundText,
                    borderRadius: BorderRadius.all(
                      Radius.circular(15.0),
                    )),
                child: AspectRatio(
                  aspectRatio: 0.95,
                  child: CalendarCarousel<CalendarEvent>(
                    onDayPressed: (date, events) {
                      final Filters current = ref.read(filtersProvider);
                      if (selected != date) {
                        ref.read(filtersProvider.notifier).state =
                            current.copyWith(selectDate: date);
                        _scrollToEvents(context, isSmall);
                      } else {
                        ref.read(filtersProvider.notifier).state =
                            current.copyWith(selectDate: null);
                      }
                    },
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
                      final Widget inner = _inner(
                          '${day.day}',
                          selected == null ? false : sameDay(day, selected),
                          isToday);
                      if (events == 0) return inner;
                      return Badge(
                        badgeContent: Text(
                          '$events',
                          style: darkBackgroundStyle.copyWith(fontSize: 8.0),
                        ),
                        badgeColor: darkIconButton,
                        position: BadgePosition.topEnd(end: 0, top: 0),
                        child: inner,
                      );
                    },
                    onCalendarChanged: (dateTime) {
                      final Filters current = ref.read(filtersProvider);
                      ref.read(filtersProvider.notifier).state = current
                          .copyWith(selectDate: null, selectMonth: dateTime);
                    },
                    headerMargin: const EdgeInsets.symmetric(vertical: 4.0),
                    customGridViewPhysics: const NeverScrollableScrollPhysics(),
                    iconColor: darkIconButton,
                    dayPadding: 0,
                    weekDayMargin: EdgeInsets.zero,
                    selectedDateTime: selected,
                    isScrollable: false,
                    scrollDirection: Axis.horizontal,
                    headerTextStyle: lightBackgroundHeaderStyle,
                    weekendTextStyle:
                        lightBackgroundStyle.copyWith(fontSize: 14),
                    inactiveDaysTextStyle: lightBackgroundStyle.copyWith(
                        fontSize: 14,
                        color: lightBackgroundText.withOpacity(0.5)),
                    maxSelectedDate: DateTime.now(),
                    minSelectedDate: getMinDate(),
                    showOnlyCurrentMonthDate: true,
                    weekdayTextStyle: lightBackgroundStyle.copyWith(
                        color: lightBackgroundText.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  _scrollToEvents(BuildContext context, bool isSmall) {
    context
        .findAncestorWidgetOfExactType<CustomScrollView>()
        ?.controller
        ?.animateTo(isSmall ? 185 : 215,
            duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  _inner(String text, bool selected, bool isToday) {
    final Color background = isToday ? backgroundLight : darkBackgroundText;
    final Color textColor = isToday ? darkBackgroundText : lightBackgroundText;
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: darkBackgroundText),
        child: DecoratedBox(
          child: Center(
            child: Text(
              text,
              style: lightBackgroundStyle.copyWith(
                  color: textColor, fontSize: 14.0),
            ),
          ),
          decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? textColor : Colors.transparent,
                width: 3.0,
              )),
        ),
      ),
    );
  }
}
