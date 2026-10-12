import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/extensions.dart';

import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class DateListener extends ChangeNotifier {
  DateTime _date = DateTime.now();
  DateTime get date => _date.toLocal();
  set date(DateTime value) => _date = value.toLocal();

  void setDate(DateTime dateTime) {
    date = dateTime;
    notifyListeners();
  }
}

class DateWidget extends StatelessWidget {
  final DateTime? earliest, latest;

  final bool hasHeader, hasIcon, enabled;

  final DateListener dateListener;

  const DateWidget({
    required this.dateListener,
    this.earliest,
    this.latest,
    this.hasHeader = true,
    this.enabled = true,
    this.hasIcon = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dateListener,
      builder: (context, child) {
        final DateTime date = dateListener.date;
        final text = Text(
          context.translate.dateChangeEntry(date),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: enabled ? TextDecoration.underline : null,
          ),
        );
        final Widget inner = hasIcon
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [const Icon(Icons.calendar_today), text],
              )
            : text;

        return DateTimeHolder(
          text: context.translate.dateChangeTitle,
          hasHeader: hasHeader,
          onClick: enabled
              ? () {
                  _showDatePicker(context);
                }
              : null,
          child: inner,
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime now = DateTime.now();

    DateTime? res = await showDatePicker(
      context: context,
      initialDate: dateListener.date,
      firstDate: earliest?.toLocal() ?? SigDates.minDate,
      lastDate: latest?.toLocal() ?? now,
    );
    if (res == null) return;
    dateListener.setDate(res);
  }
}

class TimeListener extends ChangeNotifier {
  TimeOfDay time = TimeOfDay.now();
  String? error;

  void setTime(TimeOfDay timeOfDay) {
    time = timeOfDay;
    notifyListeners();
  }

  void setError(String? message) {
    error = message;
    notifyListeners();
  }
}

class TimeWidget extends StatelessWidget {
  final TimeOfDay? earliest, latest;

  final TimeListener timeListener;

  final bool hasHeader, hasIcon, enabled;

  const TimeWidget({
    required this.timeListener,
    this.earliest,
    this.latest,
    this.enabled = true,
    this.hasHeader = true,
    this.hasIcon = true,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timeListener,
      builder: (context, child) {
        final TimeOfDay time = timeListener.time;
        final Widget text = Text(
          time.format(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: enabled ? TextDecoration.underline : null,
          ),
        );
        final Widget inner = hasIcon
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [const Icon(Icons.access_time), text],
              )
            : text;

        return DateTimeHolder(
          text: context.translate.timeChangeTitle,
          hasHeader: hasHeader,
          onClick: enabled
              ? () {
                  _showTimePicker(context);
                }
              : null,
          errorText: timeListener.error,
          child: inner,
        );
      },
    );
  }

  bool _selectionPredicate(TimeOfDay? time) {
    if (time == null) return true;
    bool lateEnough = true;
    bool earlyEnough = true;
    if (earliest != null) {
      lateEnough =
          time.hour > earliest!.hour ||
          time.hour == earliest!.hour && time.minute >= earliest!.minute;
    }
    if (latest != null) {
      earlyEnough =
          time.hour < latest!.hour ||
          time.hour == latest!.hour && time.minute <= latest!.minute;
    }
    return lateEnough && earlyEnough;
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final String? early = earliest?.format(context);
    final String? latestErr = latest?.format(context);
    String selectionError = "";
    if (early != null && latestErr != null) {
      selectionError = context.translate.timePickerErrorBoth(early, latestErr);
    } else if (early != null) {
      selectionError = context.translate.timePickerErrorEarly(early);
    } else if (latestErr != null) {
      selectionError = context.translate.timePickerErrorLate(latestErr);
    }
    TimeOfDay? res = await showTimePicker(
      context: context,
      initialTime: timeListener.time,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (res == null) return;
    if (_selectionPredicate(res)) {
      timeListener.setError(null);
      timeListener.setTime(res);
      return;
    }
    timeListener.setError(selectionError);
  }
}

class DateTimeHolder extends StatelessWidget {
  final String text;

  final String? errorText;

  final Widget child;

  final Function? onClick;

  final bool hasHeader;

  const DateTimeHolder({
    required this.child,
    required this.text,
    required this.hasHeader,
    this.onClick,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) Text(text, textAlign: TextAlign.left),
          child,
          if (errorText != null)
            Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
    if (onClick != null) {
      return OutlinedButton(
        onPressed: () {
          onClick!.call();
        },
        child: inner,
      ).showCursorOnHover;
    }
    return inner;
  }
}

class DateRangePicker extends StatelessWidget {
  final void Function(DateTimeRange?) onSelection;

  final DateTime? initialStart, initialEnd;

  const DateRangePicker({
    required this.onSelection,
    this.initialStart,
    this.initialEnd,
    super.key,
  });

  Route<DateTimeRange?> _dateRangePickerRoute(BuildContext context) {
    return DialogRoute<DateTimeRange?>(
      context: context,
      builder: (BuildContext context) {
        return DateRangePickerDialog(
          initialDateRange: initialStart != null && initialEnd != null
              ? DateTimeRange(
                  start: initialStart!.toLocal(),
                  end: initialEnd!.toLocal(),
                )
              : null,
          firstDate: SigDates.minDate,
          currentDate: DateTime.now(),
          lastDate: DateTime.now(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String toRange() {
      if (initialStart == null || initialEnd == null) {
        return context.translate.dateRangeButton;
      }
      String locale = Localizations.localeOf(context).languageCode;

      final DateFormat yearFormat = DateFormat.yMMMd(locale);
      if (sameDay(initialStart!.toLocal(), initialEnd!.toLocal())) {
        return yearFormat.format(initialStart!.toLocal());
      }

      final bool sameYear =
          initialEnd!.toLocal().year == initialStart!.toLocal().year;
      final bool sameMonth =
          sameYear &&
          initialEnd!.toLocal().month == initialStart!.toLocal().month;
      final String firstPortion = sameYear
          ? DateFormat.MMMd(locale).format(initialStart!.toLocal())
          : yearFormat.format(initialStart!.toLocal());
      final String lastPortion = sameMonth
          ? '${DateFormat.d(locale).format(initialEnd!.toLocal())}, ${DateFormat.y(locale).format(initialEnd!.toLocal())}'
          : yearFormat.format(initialEnd!.toLocal());
      return '$firstPortion - $lastPortion';
    }

    return OutlinedButton.icon(
      onPressed: () async {
        final DateTimeRange? selectedRange = await Navigator.of(context)
            .push<DateTimeRange?>(_dateRangePickerRoute(context));
        onSelection(selectedRange);
      },
      label: Text(toRange()),
      icon: const Icon(Icons.date_range),
      iconAlignment: IconAlignment.end,
    );
  }
}
