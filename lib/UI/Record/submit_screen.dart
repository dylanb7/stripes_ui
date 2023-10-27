import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final toggleProvider = StateProvider.autoDispose(
  (ref) => [false, false],
);

class SubmitScreen extends ConsumerWidget {
  final String type;

  final QuestionsListener questionsListener;

  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  final DateTime? submitTime;

  final bool isEdit;

  final String? desc;

  SubmitScreen(
      {required this.questionsListener,
      required this.type,
      this.submitTime,
      this.isEdit = false,
      this.desc,
      Key? key})
      : super(key: key) {
    if (submitTime != null) {
      _dateListener.date = submitTime!;
      _timeListener.time = TimeOfDay.fromDateTime(submitTime!);
    }
    if (desc != null) {
      _descriptionController.text = desc!;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestState state = ref.watch(testHolderProvider).state;
    final List<bool> toggles = ref.watch(toggleProvider);
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface =
        Theme.of(context).colorScheme.surface.withOpacity(0.12);
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    Period? period = ref.watch(pageProvider)[type]?.period;
    final isBlueRecord =
        (state == TestState.logs || state == TestState.logsSubmit) &&
            (type == "Poo" || type == Symptoms.BM) &&
            !isEdit;
    final bool canSubmit = !isBlueRecord || toggles.contains(true);
    return Column(
      children: [
        Text(
          isEdit
              ? AppLocalizations.of(context)!.editSubmitHeader(type)
              : AppLocalizations.of(context)!.submitHeader(type),
          style: lightBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 40,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DateWidget(
              dateListener: _dateListener,
              enabled: !isEdit,
            ),
            TimeWidget(
              timeListener: _timeListener,
              enabled: !isEdit,
            ),
          ],
        ),
        if (isBlueRecord) ...[
          const SizedBox(
            height: 18.0,
          ),
          Text(
            AppLocalizations.of(context)!.submitBlueQuestion,
            style: lightBackgroundHeaderStyle,
          ),
          const SizedBox(
            height: 8.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.blueQuestionYes),
                selected: toggles[0],
                selectedColor: primary,
                backgroundColor: surface,
                labelStyle:
                    TextStyle(color: toggles[0] ? onPrimary : onSurface),
                checkmarkColor: toggles[0] ? onPrimary : onSurface,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                onSelected: (value) {
                  if (toggles[0]) return;
                  ref.read(toggleProvider.notifier).state = [true, false];
                },
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.blueQuestionNo),
                selected: toggles[1],
                selectedColor: primary,
                backgroundColor: surface,
                labelStyle:
                    TextStyle(color: toggles[1] ? onPrimary : onSurface),
                checkmarkColor: toggles[1] ? onPrimary : onSurface,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                onSelected: (value) {
                  if (toggles[1]) return;
                  ref.read(toggleProvider.notifier).state = [false, true];
                },
              )
            ],
          ),
        ],
        const SizedBox(
          height: 18.0,
        ),
        LongTextEntry(textController: _descriptionController),
        const SizedBox(
          height: 30.0,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: GestureDetector(
            onTap: () {
              showSnack(AppLocalizations.of(context)!.submitBlueQuestionError,
                  context);
            },
            child: FilledButton(
              onPressed: canSubmit
                  ? () {
                      _submitEntry(context, period, ref, isBlueRecord, toggles);
                    }
                  : null,
              child: Text(isEdit
                  ? AppLocalizations.of(context)!.editSubmitButtonText
                  : AppLocalizations.of(context)!.submitButtonText),
            ),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }

  _submitEntry(BuildContext context, Period? period, WidgetRef ref,
      bool blueRecord, List<bool> toggles) async {
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final DateTime dateOfEntry = isEdit ? submitTime ?? date : date;
    final TimeOfDay timeOfEntry = time;
    final currentTime = DateTime.now();
    final DateTime combinedEntry = DateTime(
        dateOfEntry.year,
        dateOfEntry.month,
        dateOfEntry.day,
        timeOfEntry.hour,
        timeOfEntry.minute,
        currentTime.second,
        currentTime.millisecond);
    final DateTime submissionEntry =
        period?.getValue(combinedEntry) ?? combinedEntry;
    final int entryStamp = dateToStamp(submissionEntry);
    final DetailResponse detailResponse = DetailResponse(
      description: _descriptionController.text,
      responses: questionsListener.questions.values.toList(growable: false),
      stamp: isEdit ? dateToStamp(submitTime!) : entryStamp,
      detailType: type,
    );

    if (isEdit) {
      ref.read(stampProvider)?.updateStamp(detailResponse);
    } else {
      await ref.read(stampProvider)?.addStamp(detailResponse);
      if (blueRecord) {
        ref
            .read(testHolderProvider)
            .addLog(BMTestLog(response: detailResponse, isBlue: toggles.first));
      }
    }
    if (context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    }
  }
}

class LongTextEntry extends StatelessWidget {
  final TextEditingController textController;

  const LongTextEntry({required this.textController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.submitDescriptionTag,
            style: lightBackgroundHeaderStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 5,
          ),
          SizedBox(
            height: 120,
            child: TextField(
              controller: textController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  hintText: AppLocalizations.of(context)!
                      .submitDescriptionPlaceholder,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0)),
            ),
          ),
        ],
      ),
    );
  }
}
