import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class TimerWidget extends StatefulWidget {
  final DateTime start;

  const TimerWidget({required this.start, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TimerWidgetState();
  }
}

class _TimerWidgetState extends State<TimerWidget> {
  Duration gap = Duration.zero;
  late Timer? timer;
  @override
  void initState() {
    gap = DateTime.now().difference(widget.start);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() {
          gap = DateTime.now().difference(widget.start);
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      from(gap),
      style: darkBackgroundScreenHeaderStyle.copyWith(color: lightIconButton),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

String from(Duration duration) {
  final List<String> parts =
      duration.toString().split('.').first.padLeft(8, '0').split(':');
  String hr = _removeZeros(parts[0]);
  String minutes = _removeZeros(parts[1]);
  if (hr.isNotEmpty) {
    hr += 'h ';
  }
  if (minutes.isEmpty) {
    minutes = '0';
  }
  return '$hr$minutes:${parts.last}';
}

String _removeZeros(String val) {
  while (val.startsWith('0')) {
    val = val.substring(1);
  }
  return val;
}
