import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class DateListener extends ChangeNotifier {
  DateTime date = DateTime.now();

  setDate(DateTime dateTime) {
    date = dateTime;
    notifyListeners();
  }
}

class DateWidget extends ConsumerStatefulWidget {
  final DateTime? earliest, latest;

  final bool hasHeader, hasIcon;

  final DateListener dateListener;

  const DateWidget(
      {required this.dateListener,
      this.earliest,
      this.latest,
      this.hasHeader = true,
      this.hasIcon = true,
      Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DateWidgetState();
}

class _DateWidgetState extends ConsumerState<DateWidget> {
  @override
  void initState() {
    print("init");
    widget.dateListener.addListener(() {
      if (mounted) {
        setState(() {});
        print(widget.dateListener.date);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = widget.dateListener.date;
    final text = Text(
      AppLocalizations.of(context)!.dateChangeEntry(date),
      style: lightBackgroundStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
    );
    final Widget inner = GestureDetector(
      onTap: () {
        _showDatePicker(context, ref);
      },
      child: widget.hasIcon
          ? Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: darkIconButton,
                  size: 35,
                ),
                text
              ],
            )
          : text,
    ).showCursorOnHover;
    if (widget.hasHeader) {
      return DateTimeHolder(
        text: AppLocalizations.of(context)!.dateChangeTitle,
        child: inner,
      );
    }
    return inner;
  }

  _showDatePicker(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    DateTime? res = await showDatePicker(
        context: context,
        initialDate: widget.dateListener.date,
        firstDate: widget.earliest ?? now.subtract(const Duration(days: 365)),
        lastDate: widget.latest ?? now);
    if (res == null) return;
    widget.dateListener.setDate(res);
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

class TimeWidget extends ConsumerStatefulWidget {
  final TimeOfDay? earliest, latest;

  final TimeListener timeListener;

  final bool hasHeader, hasIcon;

  const TimeWidget(
      {required this.timeListener,
      this.earliest,
      this.latest,
      this.hasHeader = true,
      this.hasIcon = true,
      Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends ConsumerState<TimeWidget> {
  @override
  void initState() {
    widget.timeListener.addListener(() {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TimeOfDay time = widget.timeListener.time;
    final Widget text = Text(
      time.format(context),
      style: lightBackgroundStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
    );
    final Widget inner = GestureDetector(
      onTap: () {
        _showTimePicker(context, ref);
      },
      child: widget.hasIcon
          ? Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: darkIconButton,
                  size: 35,
                ),
                text
              ],
            )
          : text,
    ).showCursorOnHover;
    if (widget.hasHeader) {
      return DateTimeHolder(
        text: AppLocalizations.of(context)!.timeChangeTitle,
        errorText: ref.read(timeErrorProvider),
        child: inner,
      );
    }
    return inner;
  }

  _selectionPredicate(TimeOfDay? time) {
    if (time == null) return true;
    bool lateEnough = true;
    bool earlyEnough = true;
    if (widget.earliest != null) {
      lateEnough = time.hour > widget.earliest!.hour ||
          time.hour == widget.earliest!.hour &&
              time.minute >= widget.earliest!.minute;
    }
    if (widget.latest != null) {
      earlyEnough = time.hour < widget.latest!.hour ||
          time.hour == widget.latest!.hour &&
              time.minute <= widget.latest!.minute;
    }
    return lateEnough && earlyEnough;
  }

  _showTimePicker(BuildContext context, WidgetRef ref) async {
    final String? early = widget.earliest?.format(context);
    final String? latestErr = widget.latest?.format(context);
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
      initialTime: widget.timeListener.time,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (res == null) return;
    if (_selectionPredicate(res)) {
      ref.read(timeErrorProvider.notifier).state = null;
      widget.timeListener.setTime(res);
      return;
    }
    ref.read(timeErrorProvider.notifier).state = selectionError;
  }
}

class DateTimeHolder extends StatelessWidget {
  final String text;

  final String? errorText;

  final Widget child;

  const DateTimeHolder(
      {required this.child, required this.text, this.errorText, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                text,
                style: lightBackgroundStyle.copyWith(
                    color: lightBackgroundText.withOpacity(0.8)),
              ),
            ),
            child,
            if (errorText != null)
              Text(
                errorText!,
                style: errorStyle,
              )
          ],
        ),
      ),
    );
  }
}
