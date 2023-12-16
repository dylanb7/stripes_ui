import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
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

  const SubmitScreen(
      {required this.questionsListener, required this.type, Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SubmitScreenState();
}

class SubmitScreenState extends ConsumerState<SubmitScreen> {
  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  bool isLoading = false;

  late final bool isEdit;

  @override
  void initState() {
    if (widget.questionsListener.submitTime != null) {
      _dateListener.date = widget.questionsListener.submitTime!;
      _timeListener.time =
          TimeOfDay.fromDateTime(widget.questionsListener.submitTime!);
    }
    if (widget.questionsListener.description != null) {
      _descriptionController.text = widget.questionsListener.description!;
    }
    widget.questionsListener.addListener(_state);
    isEdit = widget.questionsListener.editId != null;
    super.initState();
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.questionsListener.removeListener(_state);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface =
        Theme.of(context).colorScheme.surface.withOpacity(0.12);
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    Period? period = ref.watch(pagePaths)[widget.type]?.period;
    final List<Question> testAdditions = ref
            .watch(testHolderProvider)
            .repo
            ?.getRecordAdditions(context, widget.type) ??
        [];

    final bool canSubmit = widget.questionsListener.pending.isEmpty;
    return Column(
      children: [
        Text(
          isEdit
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
                enabled: !isEdit,
              ),
              TimeWidget(
                timeListener: _timeListener,
                enabled: !isEdit,
              ),
            ],
          ),
        RenderQuestions(
            questions: testAdditions,
            questionsListener: widget.questionsListener),
        /*if (isBlueRecord) ...[
          const SizedBox(
            height: 18.0,
          ),
          Text(
            AppLocalizations.of(context)!.submitBlueQuestion,
            style: lightBackgroundHeaderStyle,
            textAlign: TextAlign.center,
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
        ],*/
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
                      _submitEntry(context, period, ref);
                    }
                  : null,
              child: isLoading
                  ? const ButtonLoadingIndicator()
                  : Text(isEdit
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

  _submitEntry(
    BuildContext context,
    Period? period,
    WidgetRef ref,
  ) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final DateTime dateOfEntry =
        isEdit ? widget.questionsListener.submitTime ?? date : date;
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
      id: widget.questionsListener.editId,
      description: _descriptionController.text,
      responses:
          widget.questionsListener.questions.values.toList(growable: false),
      stamp: isEdit
          ? dateToStamp(widget.questionsListener.submitTime!)
          : entryStamp,
      detailType: widget.type,
    );

    if (isEdit) {
      await ref.read(stampProvider)?.updateStamp(detailResponse);
      await ref
          .read(testHolderProvider)
          .repo
          ?.onResponseEdit(detailResponse, widget.type);
    } else {
      await ref.read(stampProvider)?.addStamp(detailResponse);
      await ref
          .read(testHolderProvider)
          .repo
          ?.onResponseSubmit(detailResponse, widget.type);
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
