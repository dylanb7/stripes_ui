/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_content.dart';
import 'package:stripes_ui/Util/helpers/date_helper.dart';
import 'package:stripes_ui/Util/widgets/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BlueRecordings<T extends Test> extends ConsumerWidget {
  const BlueRecordings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BlueDyeObj? blueObj =
        getObject<BlueDyeObj>(ref.watch(testStreamProvider));
    final List<BMTestLog> logs = blueObj?.logs ?? [];
    final BlueDyeTestStage state = blueObj == null
        ? BlueDyeTestStage.initial
        : stageFromTestState(blueObj);
    final bool isLoading = ref.watch(testLoading);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12.0),
        SizedBox(
          width: double.infinity,
          child: Text(
            '${context.translate.blueDyeLogsInstructionOne}${logs.isEmpty ? context.translate.blueDyeLogsInstructionTwo : ''}',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ...logs.map((e) => LogRow(log: e, ref: ref)),
        const SizedBox(height: 12.0),
        Text(
          context.translate.blueDyeInstructionsStepThreeA,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 8.0,
        ),
        Center(
          child: SizedBox(
            width: 250,
            child: GestureDetector(
                onTap: () {
                  if (state != TestState.logsSubmit && !isLoading) {
                    showSnack(
                      context,
                      context.translate.blueDyeLogsSubmitTestError,
                    );
                  }
                },
                child: FilledButton(
                  onPressed: state != BlueDyeTestStage.logsSubmit || isLoading
                      ? null
                      : () async {
                          ref.read(testLoading.notifier).state = true;
                          await getTest(ref.read(testProvider))
                              ?.submit(DateTime.now());

                          ref.read(testLoading.notifier).state = false;
                          if (context.mounted) {
                            showSnack(
                                context,
                                context.translate
                                    .testSubmitSuccess);
                          }
                        },
                  child: isLoading
                      ? const ButtonLoadingIndicator()
                      : Text(
                          context.translate.blueDyeLogsSubmitTest),
                )),
          ),
        ),
      ],
    );
  }
}

class LogRow extends ConsumerWidget {
  final BMTestLog log;
  final WidgetRef ref;
  const LogRow({required this.log, required this.ref, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DetailResponse event = log.response;
    final DateTime date = dateFromStamp(event.stamp);
    List<Widget> vals = [
      Text(
        event.type,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      if (event.description != null && event.description!.isNotEmpty) ...[
        Text(
          context.translate.descriptionLabel,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          event.description!,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: null,
        )
      ],
      Text(
        context.translate.behaviorsLabel,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      ...event.responses.map(
        (res) {
          return ResponseDisplay(res: res);
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
              style: Theme.of(context).textTheme.bodyLarge,
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
*/
