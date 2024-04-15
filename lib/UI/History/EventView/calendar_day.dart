import 'package:badges/badges.dart' as b;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarDay extends StatelessWidget {
  final bool isToday, selected, after;

  final int events;

  final DateTime day;

  const CalendarDay(
      {required this.day,
      required this.isToday,
      required this.selected,
      required this.after,
      required this.events,
      super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color background = selected
        ? Theme.of(context).colorScheme.secondary
        : after
            ? primary.withOpacity(0.4)
            : primary.withOpacity(0.8);
    final text = DateFormat.d().format(day);
    final Color textColor =
        selected ? Theme.of(context).colorScheme.onSecondary : onPrimary;
    final Widget dayView = Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isToday ? onPrimary : Colors.transparent,
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
        ));
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
