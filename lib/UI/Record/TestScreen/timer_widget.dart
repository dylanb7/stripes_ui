import 'dart:async';

import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final DateTime start;

  const TimerWidget({required this.start, super.key});

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
    Icons.restore;
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(12.0))),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              from(gap),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [],
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
    return Text(
      from(gap),
      style: Theme.of(context).textTheme.headlineMedium,
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
