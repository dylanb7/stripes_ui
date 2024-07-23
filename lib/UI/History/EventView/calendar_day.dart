import 'package:badges/badges.dart' as b;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarDay extends StatelessWidget {
  final bool isToday,
      selected,
      disabled,
      rangeStart,
      rangeEnd,
      within,
      endSelected;

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
            ? onSurface.withOpacity(0.4)
            : onSurface;
    final Widget dayView = Padding(
      padding: EdgeInsets.only(
          top: 2.0,
          bottom: 2.0,
          left: rangeEnd || within ? 0 : 2.0,
          right: (rangeStart && endSelected) || within ? 0 : 2.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
                topRight: within || rangeStart
                    ? Radius.zero
                    : const Radius.circular(10.0),
                topLeft: within || rangeEnd
                    ? Radius.zero
                    : const Radius.circular(10.0),
                bottomRight: within || rangeStart
                    ? Radius.zero
                    : const Radius.circular(10.0),
                bottomLeft: within || rangeEnd
                    ? Radius.zero
                    : const Radius.circular(10.0)),
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
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textColor, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (events == 0) return dayView;
    return b.Badge(
      badgeContent: Text(
        '$events',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 8.0, color: Theme.of(context).colorScheme.onPrimary),
      ),
      badgeStyle: b.BadgeStyle(
        badgeColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      position: b.BadgePosition.topEnd(end: 0, top: 0),
      child: dayView,
    );
  }
}
