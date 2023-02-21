import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class BlueRecordings extends ConsumerWidget {
  const BlueRecordings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TestNotifier notifier = ref.watch(testHolderProvider);
    List<BMTestLog> logs = notifier.obj!.logs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 25.0),
        Text(
          'Record bowel movements from the record screen. ${logs.isEmpty ? ' Recorded bowel movements will appear below' : ''}',
          textAlign: TextAlign.center,
          style: lightBackgroundHeaderStyle,
        ),
        const SizedBox(
          height: 8.0,
        ),
        ...logs.map((e) => LogRow(log: e, ref: ref)),
        const SizedBox(height: 12.0),
        Center(
          child: SizedBox(
            width: 250,
            child: StripesRoundedButton(
              text: 'Submit Test',
              onClick: () {
                ref.read(testHolderProvider).submit(DateTime.now());
              },
              disabledClick: () {
                showSnack(
                    'Record a normal colored bowel movement before submitting',
                    context);
              },
              disabled: notifier.state != TestState.logsSubmit,
              light: true,
            ),
          ),
        ),
      ],
    );
  }
}

class LogRow extends ConsumerWidget {
  final BMTestLog log;
  final WidgetRef ref;
  const LogRow({required this.log, required this.ref, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DetailResponse event = log.response;
    final DateTime date = dateFromStamp(event.stamp);
    List<Text> vals = [
      Text(
        event.type,
        style: lightBackgroundHeaderStyle,
      ),
      if (event.description.isNotEmpty) ...[
        const Text(
          'Description:',
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          event.description,
          style: lightBackgroundStyle,
          maxLines: null,
        )
      ],
      const Text(
        'Behaviors:',
        style: lightBackgroundHeaderStyle,
      ),
      ...event.responses.map(
        (res) {
          if (res is NumericResponse) {
            return Text('${res.question.prompt} - ${res.response}',
                style: lightBackgroundStyle, maxLines: null);
          }
          return Text(
            res.question.prompt,
            style: lightBackgroundStyle,
            maxLines: null,
          );
        },
      ),
    ];

    return Expandible(
      highlightOnShrink: true,
      highlightColor: lightIconButton,
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${dateToMDY(date)} at ${timeString(TimeOfDay.fromDateTime(date))}',
          style: lightBackgroundHeaderStyle,
        ),
      ]),
      selected: log.isBlue,
      view: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: vals
            .map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: text,
              ),
            )
            .toList(),
      ),
    );
  }
}