import 'package:badges/badges.dart' as b;
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class CalendarDay extends StatelessWidget {
  final bool isToday, selected, after;

  final int events;

  final String text;

  const CalendarDay(
      {required this.text,
      required this.isToday,
      required this.selected,
      required this.after,
      required this.events,
      super.key});

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? darkBackgroundText
        : after
            ? backgroundLight.withOpacity(0.4)
            : backgroundLight.withOpacity(0.8);
    final Color textColor =
        selected ? buttonDarkBackground : darkBackgroundText;
    final Widget day = AspectRatio(
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
    if (events == 0) return day;
    return b.Badge(
      badgeContent: Text(
        '$events',
        style: darkBackgroundStyle.copyWith(fontSize: 8.0),
      ),
      badgeColor: darkIconButton,
      position: b.BadgePosition.topEnd(end: 0, top: 0),
      child: day,
    );
  }
}
