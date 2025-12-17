import 'package:badges/badges.dart' as b;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarDay extends StatelessWidget {
  final bool isToday,
      selected,
      disabled,
      rangeStart,
      rangeEnd,
      within,
      endSelected,
      hasCheckIn;

  final CalendarStyle style;

  final int events;

  final DateTime day;

  const CalendarDay(
      {required this.day,
      required this.isToday,
      required this.selected,
      required this.disabled,
      required this.events,
      required this.rangeStart,
      required this.rangeEnd,
      required this.within,
      required this.endSelected,
      required this.style,
      this.hasCheckIn = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool highlighted = selected || rangeStart || rangeEnd;
    final Color background = highlighted ? primary : Colors.transparent;
    final text = DateFormat.d().format(day);
    final Color textColor = highlighted
        ? onPrimary
        : disabled
            ? onSurface.withValues(alpha: 0.4)
            : onSurface;
    final Widget dayView = Padding(
      padding: EdgeInsets.only(
          top: style.cellPadding.top,
          bottom: style.cellPadding.bottom,
          left: rangeEnd || within ? 0 : style.cellPadding.left,
          right: (rangeStart && endSelected) || within
              ? 0
              : style.cellPadding.right),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: AnimatedContainer(
          margin: style.cellMargin,
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
                topRight: within || (rangeStart && !rangeEnd)
                    ? Radius.zero
                    : const Radius.circular(AppRounding.small),
                topLeft: within || (rangeEnd && !rangeStart)
                    ? Radius.zero
                    : const Radius.circular(AppRounding.small),
                bottomRight: within || (rangeStart && !rangeEnd)
                    ? Radius.zero
                    : const Radius.circular(AppRounding.small),
                bottomLeft: within || (rangeEnd && !rangeStart)
                    ? Radius.zero
                    : const Radius.circular(AppRounding.small)),
          ),
          child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isToday
                        ? highlighted
                            ? onPrimary
                            : onSurface
                        : Colors.transparent,
                    width: 2.0)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor, fontSize: 20),
                    ),
                    if (hasCheckIn)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: highlighted ? onPrimary : primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final Widget addedEvents = events == 0
        ? dayView
        : b.Badge(
            badgeContent: Text(
              '$events',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 8.0,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
            badgeStyle: b.BadgeStyle(
              badgeColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            position: b.BadgePosition.topEnd(end: 0, top: 0),
            child: dayView,
          );
    if (endSelected && (within || rangeStart || rangeEnd)) {
      return Stack(children: [
        LayoutBuilder(builder: (context, constraints) {
          final double shorterSide =
              constraints.maxHeight > constraints.maxWidth
                  ? constraints.maxWidth
                  : constraints.maxHeight;
          return Center(
            child: Container(
              margin: EdgeInsetsDirectional.only(
                  top: style.cellMargin.top,
                  start: rangeStart ? constraints.maxWidth * 0.5 : 0.0,
                  end: rangeEnd ? constraints.maxWidth * 0.5 : 0.0,
                  bottom: style.cellMargin.bottom),
              height: shorterSide - style.cellMargin.vertical,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
          );
        }),
        Align(
          alignment: Alignment.center,
          child: addedEvents,
        ),
      ]);
    }
    return addedEvents;
  }
}
