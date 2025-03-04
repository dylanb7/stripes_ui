import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';

import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class DateListener extends ChangeNotifier {
  DateTime date = DateTime.now();

  setDate(DateTime dateTime) {
    date = dateTime;
    notifyListeners();
  }
}

class DateWidget extends ConsumerWidget {
  final DateTime? earliest, latest;

  final bool hasHeader, hasIcon, enabled;

  final DateListener dateListener;

  const DateWidget(
      {required this.dateListener,
      this.earliest,
      this.latest,
      this.hasHeader = true,
      this.enabled = true,
      this.hasIcon = true,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: dateListener,
      builder: (context, child) {
        final DateTime date = dateListener.date;
        final text = Text(
          AppLocalizations.of(context)!.dateChangeEntry(date),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: enabled ? TextDecoration.underline : null,
              ),
        );
        final Widget inner = hasIcon
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                  ),
                  text,
                ],
              )
            : text;

        return DateTimeHolder(
          text: AppLocalizations.of(context)!.dateChangeTitle,
          hasHeader: hasHeader,
          onClick: enabled
              ? () {
                  _showDatePicker(context, ref);
                }
              : null,
          child: inner,
        );
      },
    );
  }

  _showDatePicker(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    DateTime? res = await showDatePicker(
        context: context,
        initialDate: dateListener.date,
        firstDate: earliest ?? SigDates.minDate,
        lastDate: latest ?? now);
    if (res == null) return;
    dateListener.setDate(res);
  }
}

class TimeListener extends ChangeNotifier {
  TimeOfDay time = TimeOfDay.now();

  setTime(TimeOfDay timeOfDay) {
    time = timeOfDay;
    notifyListeners();
  }
}

final timeErrorProvider = StateProvider<String?>((ref) => null);

class TimeWidget extends ConsumerWidget {
  final TimeOfDay? earliest, latest;

  final TimeListener timeListener;

  final bool hasHeader, hasIcon, enabled;

  const TimeWidget(
      {required this.timeListener,
      this.earliest,
      this.latest,
      this.enabled = true,
      this.hasHeader = true,
      this.hasIcon = true,
      super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  children: [
                    const Icon(
                      Icons.access_time,
                    ),
                    text
                  ],
                )
              : text;

          return DateTimeHolder(
            text: AppLocalizations.of(context)!.timeChangeTitle,
            hasHeader: hasHeader,
            onClick: enabled
                ? () {
                    _showTimePicker(context, ref);
                  }
                : null,
            errorText: ref.read(timeErrorProvider),
            child: inner,
          );
        });
  }

  _selectionPredicate(TimeOfDay? time) {
    if (time == null) return true;
    bool lateEnough = true;
    bool earlyEnough = true;
    if (earliest != null) {
      lateEnough = time.hour > earliest!.hour ||
          time.hour == earliest!.hour && time.minute >= earliest!.minute;
    }
    if (latest != null) {
      earlyEnough = time.hour < latest!.hour ||
          time.hour == latest!.hour && time.minute <= latest!.minute;
    }
    return lateEnough && earlyEnough;
  }

  _showTimePicker(BuildContext context, WidgetRef ref) async {
    final String? early = earliest?.format(context);
    final String? latestErr = latest?.format(context);
    String selectionError = "";
    if (early != null && latestErr != null) {
      selectionError =
          AppLocalizations.of(context)!.timePickerErrorBoth(early, latestErr);
    } else if (early != null) {
      selectionError =
          AppLocalizations.of(context)!.timePickerErrorEarly(early);
    } else if (latestErr != null) {
      selectionError =
          AppLocalizations.of(context)!.timePickerErrorLate(latestErr);
    }
    TimeOfDay? res = await showTimePicker(
      context: context,
      initialTime: timeListener.time,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (res == null) return;
    if (_selectionPredicate(res)) {
      ref.read(timeErrorProvider.notifier).state = null;
      timeListener.setTime(res);
      return;
    }
    ref.read(timeErrorProvider.notifier).state = selectionError;
  }
}

class DateTimeHolder extends StatelessWidget {
  final String text;

  final String? errorText;

  final Widget child;

  final Function? onClick;

  final bool hasHeader;

  const DateTimeHolder(
      {required this.child,
      required this.text,
      required this.hasHeader,
      this.onClick,
      this.errorText,
      super.key});

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
            Text(
              text,
              textAlign: TextAlign.left,
            ),
          child,
          if (errorText != null)
            Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
        ],
      ),
    );
    if (onClick != null) {
      return OutlinedButton(
              onPressed: () {
                onClick!.call();
              },
              child: inner)
          .showCursorOnHover;
    }
    return inner;
  }
}

class DateRangePicker extends StatelessWidget {
  final void Function(DateTimeRange?) onSelection;

  final DateTime? initialStart, initialEnd;

  const DateRangePicker(
      {required this.onSelection,
      this.initialStart,
      this.initialEnd,
      super.key});

  Route<DateTimeRange?> _dateRangePickerRoute(
    BuildContext context,
  ) {
    return DialogRoute<DateTimeRange?>(
      context: context,
      builder: (BuildContext context) {
        return DateRangePickerDialog(
          initialDateRange: initialStart != null && initialEnd != null
              ? DateTimeRange(start: initialStart!, end: initialEnd!)
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
        return AppLocalizations.of(context)!.dateRangeButton;
      }
      String locale = Localizations.localeOf(context).languageCode;

      final DateFormat yearFormat = DateFormat.yMMMd(locale);
      if (sameDay(initialStart!, initialEnd!)) {
        return yearFormat.format(initialStart!);
      }

      final bool sameYear = initialEnd!.year == initialStart!.year;
      final bool sameMonth =
          sameYear && initialEnd!.month == initialStart!.month;
      final String firstPortion = sameYear
          ? DateFormat.MMMd(locale).format(initialStart!)
          : yearFormat.format(initialStart!);
      final String lastPortion = sameMonth
          ? '${DateFormat.d(locale).format(initialEnd!)}, ${DateFormat.y(locale).format(initialEnd!)}'
          : yearFormat.format(initialEnd!);
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
