import 'dart:async';

import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class TimerWidget extends ConsumerStatefulWidget {
  final DateTime start;

  const TimerWidget({required this.start, super.key});

  @override
  ConsumerState createState() {
    return _TimerWidgetState();
  }
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.mealTimerTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            Center(
              child: Text(
                from(gap, context),
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
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
  }

  _pause() {}

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

String from(Duration duration, BuildContext context) {
  final Locale current = Localizations.localeOf(context);
  return prettyDuration(duration,
      delimiter: ' ',
      locale: DurationLocale.fromLanguageCode(current.languageCode) ??
          const EnglishDurationLocale(),
      abbreviated: true);
}
