import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
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
    isEdit = widget.questionsListener.editId != null;
    if (widget.questionsListener.submitTime != null) {
      _dateListener.date = widget.questionsListener.submitTime!;
      _timeListener.time =
          TimeOfDay.fromDateTime(widget.questionsListener.submitTime!);
    }
    if (widget.questionsListener.description != null) {
      _descriptionController.text = widget.questionsListener.description!;
    }
    widget.questionsListener.addListener(_state);
    _dateListener.addListener(_setSubmissionTime);
    _timeListener.addListener(_setSubmissionTime);
    _descriptionController.addListener(_updateDesc);
    super.initState();
  }

  _setSubmissionTime() {
    widget.questionsListener.submitTime = _combinedTime();
  }

  _updateDesc() {
    widget.questionsListener.description = _descriptionController.text;
  }

  DateTime _combinedTime() {
    if (isEdit && widget.questionsListener.submitTime != null) {
      return widget.questionsListener.submitTime!;
    }
    final Period? period = ref.read(pagePaths)[widget.type]?.period;
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final currentTime = DateTime.now();
    final DateTime combinedEntry = DateTime(date.year, date.month, date.day,
        time.hour, time.minute, currentTime.second, currentTime.millisecond);
    return period?.getValue(combinedEntry) ?? combinedEntry;
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.questionsListener.removeListener(_state);
    _dateListener.removeListener(_setSubmissionTime);
    _timeListener.removeListener(_setSubmissionTime);
    _descriptionController.removeListener(_updateDesc);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Period? period = ref.watch(pagePaths)[widget.type]?.period;
    final List<Question> testAdditions = ref
            .watch(testHolderProvider)
            .repo
            ?.getRecordAdditions(context, widget.type) ??
        [];
    return Column(
      children: [
        Text(
          isEdit
              ? AppLocalizations.of(context)!.editSubmitHeader(widget.type)
              : AppLocalizations.of(context)!.submitHeader(widget.type),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 40,
        ),
        if (period != null)
          Text(
            period.getRangeString(DateTime.now(), context),
            style: Theme.of(context).textTheme.bodyMedium,
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
        const SizedBox(
          height: 18.0,
        ),
        LongTextEntry(textController: _descriptionController),
        const SizedBox(
          height: 18.0,
        ),
      ],
    );
  }
}

class LongTextEntry extends StatelessWidget {
  final TextEditingController textController;

  const LongTextEntry({required this.textController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.submitDescriptionTag,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 5,
          ),
          AspectRatio(
            aspectRatio: 1.4,
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
