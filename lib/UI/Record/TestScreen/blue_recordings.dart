import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

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
          '${AppLocalizations.of(context)!.blueDyeLogsInstructionOne}${logs.isEmpty ? AppLocalizations.of(context)!.blueDyeLogsInstructionTwo : ''}',
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
              text: AppLocalizations.of(context)!.blueDyeLogsSubmitTest,
              onClick: () {
                ref.read(testHolderProvider).submit(DateTime.now());
                showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                          contentPadding: const EdgeInsets.all(8.0),
                          children: [
                            Text(
                              AppLocalizations.of(context)!.testSubmitSuccess,
                              style: lightBackgroundHeaderStyle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ));
              },
              disabledClick: () {
                showSnack(
                    AppLocalizations.of(context)!.blueDyeLogsSubmitTestError,
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
        Text(
          AppLocalizations.of(context)!.descriptionLabel,
          style: lightBackgroundHeaderStyle,
        ),
        Text(
          event.description,
          style: lightBackgroundStyle,
          maxLines: null,
        )
      ],
      Text(
        AppLocalizations.of(context)!.behaviorsLabel,
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
      header: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 35.0,
                height: 35.0,
                child: log.isBlue
                    ? Image.asset(
                        'packages/stripes_ui/assets/images/Blue_Poop.png')
                    : Image.asset(
                        'packages/stripes_ui/assets/images/Brown_Poop.png')),
            const SizedBox(
              width: 6.0,
            ),
            Text(
              '${dateToMDY(date, context)} - ${timeString(date, context)}',
              style: lightBackgroundHeaderStyle,
            ),
          ]),
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
