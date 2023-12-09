import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String type;

  final QuestionsListener questionsListener;

  final DateTime? submitTime;

  final bool isEdit;

  final String? desc, editedId;

  const SubmitScreen(
      {required this.questionsListener,
      required this.type,
      this.submitTime,
      this.isEdit = false,
      this.editedId,
      this.desc,
      Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SubmitScreenState();
}

class SubmitScreenState extends ConsumerState<SubmitScreen> {
  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  List<bool> toggleState = [false, false];

  bool isLoading = false;

  @override
  void initState() {
    if (widget.submitTime != null) {
      _dateListener.date = widget.submitTime!;
      _timeListener.time = TimeOfDay.fromDateTime(widget.submitTime!);
    }
    if (widget.desc != null) {
      _descriptionController.text = widget.desc!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TestState state = ref.watch(testHolderProvider).state;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface =
        Theme.of(context).colorScheme.surface.withOpacity(0.12);
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    Period? period = ref.watch(pageProvider)[widget.type]?.period;
    final isBlueRecord =
        (state == TestState.logs || state == TestState.logsSubmit) &&
            (widget.type == "Poo" || widget.type == Symptoms.BM) &&
            !widget.isEdit;
    final bool canSubmit = !isBlueRecord || toggleState.contains(true);
    return Column(
      children: [
        Text(
          widget.isEdit
              ? AppLocalizations.of(context)!.editSubmitHeader(widget.type)
              : AppLocalizations.of(context)!.submitHeader(widget.type),
          style: lightBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 40,
        ),
        if (period != null)
          Text(
            period.getRangeString(DateTime.now(), context),
            style: lightBackgroundStyle,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DateWidget(
                dateListener: _dateListener,
                enabled: !widget.isEdit,
              ),
              TimeWidget(
                timeListener: _timeListener,
                enabled: !widget.isEdit,
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
                label: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    child: Text(AppLocalizations.of(context)!.blueQuestionYes)),
                selected: toggleState[0],
                selectedColor: primary,
                backgroundColor: surface,
                labelStyle: TextStyle(
                    color: toggleState[0] ? onPrimary : onSurface,
                    fontWeight: FontWeight.bold),
                checkmarkColor: toggleState[0] ? onPrimary : onSurface,
                onSelected: (value) {
                  if (toggleState[0]) return;
                  setState(() {
                    toggleState = [true, false];
                  });
                },
              ),
              ChoiceChip(
                label: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    child: Text(AppLocalizations.of(context)!.blueQuestionNo)),
                selected: toggleState[1],
                selectedColor: primary,
                backgroundColor: surface,
                labelStyle: TextStyle(
                    color: toggleState[1] ? onPrimary : onSurface,
                    fontWeight: FontWeight.bold),
                checkmarkColor: toggleState[1] ? onPrimary : onSurface,
                onSelected: (value) {
                  if (toggleState[1]) return;
                  setState(() {
                    toggleState = [false, true];
                  });
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
              if (!canSubmit && !isLoading) {
                showSnack(AppLocalizations.of(context)!.submitBlueQuestionError,
                    context);
              }
            },
            child: FilledButton(
              onPressed: canSubmit && !isLoading
                  ? () {
                      _submitEntry(
                          context, period, ref, isBlueRecord, toggleState);
                    }
                  : null,
              child: isLoading
                  ? const ButtonLoadingIndicator()
                  : Text(widget.isEdit
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
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final DateTime dateOfEntry =
        widget.isEdit ? widget.submitTime ?? date : date;
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
      id: widget.editedId,
      description: _descriptionController.text,
      responses:
          widget.questionsListener.questions.values.toList(growable: false),
      stamp: widget.isEdit ? dateToStamp(widget.submitTime!) : entryStamp,
      detailType: widget.type,
    );

    if (widget.isEdit) {
      await ref.read(stampProvider)?.updateStamp(detailResponse);
    } else {
      await ref.read(stampProvider)?.addStamp(detailResponse);
      if (blueRecord) {
        await ref
            .read(testHolderProvider)
            .addLog(BMTestLog(response: detailResponse, isBlue: toggles.first));
      }
    }
    setState(() {
      isLoading = false;
    });
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
