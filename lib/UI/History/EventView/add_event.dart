import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';

import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class AddEvent extends ConsumerWidget {
  const AddEvent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    openEventOverlay(WidgetRef ref, DateTime addTime) {
      ref.read(overlayProvider.notifier).state =
          OverlayQuery(widget: _QuestionTypeOverlay(date: addTime));
    }

    final DateTime? selected =
        ref.watch(filtersProvider.select((value) => value.selectedDate));
    return selected == null
        ? Container()
        : Tooltip(
            message: dateToMDY(selected, context),
            child: FilledButton(
              child: Text(
                AppLocalizations.of(context)!.addEventButton,
              ),
              onPressed: () {
                openEventOverlay(ref, selected);
              },
            ),
          );
  }
}

class _QuestionTypeOverlay extends ConsumerWidget {
  final DateTime date;

  const _QuestionTypeOverlay({required this.date, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> questionTypes =
        ref.watch(questionSplitProvider).keys.toList();
    return OverlayBackdrop(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 30),
                      Text(
                        AppLocalizations.of(context)!.addEventHeader,
                        style: lightBackgroundHeaderStyle,
                      ),
                      IconButton(
                          onPressed: () {
                            ref.read(overlayProvider.notifier).state =
                                closedQuery;
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 30,
                          )),
                    ]),
                ...questionTypes.map((type) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: StripesRoundedButton(
                        shadow: false,
                        light: true,
                        text: type,
                        onClick: () {
                          ref.read(overlayProvider.notifier).state =
                              closedQuery;
                          context.pushNamed('recordType',
                              pathParameters: {'type': type},
                              extra: SymptomRecordData(submitTime: date));
                        },
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
