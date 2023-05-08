import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/History/button_style.dart';
import 'package:stripes_ui/UI/Record/RecordPaths/question_splitter.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

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
            message: dateToMDY(selected),
            child: ElevatedButton(
              style: historyButtonStyle,
              child: Text(
                'Add Event',
                style: buttonText,
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
        child: Container(
          decoration: BoxDecoration(
              color: darkBackgroundText,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              boxShadow: [
                BoxShadow(
                    color: lightBackgroundText.withOpacity(0.4),
                    offset: Offset.zero,
                    blurRadius: 3.0,
                    spreadRadius: 3.0)
              ]),
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
                      const Text(
                        'Select a type to record',
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
                            color: darkIconButton,
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
                              params: {'type': type},
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
