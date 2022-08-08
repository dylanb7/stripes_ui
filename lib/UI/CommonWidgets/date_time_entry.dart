import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class DateListener extends ChangeNotifier {
  DateTime date = DateTime.now();

  quietSet(DateTime dateTime) {
    date = dateTime;
  }

  setDate(DateTime dateTime) {
    date = dateTime;
    notifyListeners();
  }
}

class DateWidget extends StatefulWidget {
  final DateListener dateListener;

  final DateTime? earliest, latest;

  final bool hasHeader, hasIcon;

  const DateWidget(
      {required this.dateListener,
      this.earliest,
      this.latest,
      this.hasHeader = true,
      this.hasIcon = true,
      Key? key})
      : super(key: key);

  @override
  State<DateWidget> createState() => _DateWidgetState();
}

class _DateWidgetState extends State<DateWidget> {
  @override
  void initState() {
    widget.dateListener.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      dateToShortMDY(widget.dateListener.date),
      style: lightBackgroundStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
    );
    final Widget inner = GestureDetector(
      onTap: () {
        _showDatePicker(context);
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
        text: 'Date',
        child: inner,
      );
    }
    return inner;
  }

  _showDatePicker(BuildContext context) async {
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

  quietSet(TimeOfDay dateTime) {
    time = dateTime;
  }

  setTime(TimeOfDay timeOfDay) {
    time = timeOfDay;
    notifyListeners();
  }
}

class TimeWidget extends StatefulWidget {
  final TimeListener timeListener;

  final TimeOfDay? earliest, latest;

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
  State<StatefulWidget> createState() {
    return _TimeWidgetState();
  }
}

class _TimeWidgetState extends State<TimeWidget> {
  @override
  void initState() {
    widget.timeListener.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      timeString(widget.timeListener.time),
      style: lightBackgroundStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
    );
    final Widget inner = GestureDetector(
      onTap: () {
        _showTimePicker(context);
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
        text: 'Time',
        child: inner,
      );
    }
    return inner;
  }

  _showTimePicker(BuildContext context) async {
    /*TimeOfDay? res = await picker.showCustomTimePicker(
        context: context,
        initialTime: widget.timeListener.time,
        onFailValidation: (context) {},
        initialEntryMode: picker.TimePickerEntryMode.input,
        selectableTimePredicate: (time) {
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
        });
    if (res == null) return;
    widget.timeListener.setTime(res);*/
  }
}

class DateTimeHolder extends StatelessWidget {
  final String text;

  final Widget child;

  const DateTimeHolder({required this.child, required this.text, Key? key})
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
          ],
        ),
      ),
    );
  }
}
