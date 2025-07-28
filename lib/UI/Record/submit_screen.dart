import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String type;

  final QuestionsListener questionsListener;

  const SubmitScreen(
      {required this.questionsListener, required this.type, super.key});

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
    final Period? period = ref
        .read(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .valueOrNull
        ?.path
        ?.period;
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
    final Period? period = ref
        .watch(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .valueOrNull
        ?.path
        ?.period;
    final List<Question> testAdditions = ref
            .watch(testProvider)
            .valueOrNull
            ?.getRecordAdditions(context, widget.type) ??
        [];
    return Column(
      children: [
        const SizedBox(
          height: AppPadding.small,
        ),
        Text(
          isEdit
              ? context.translate.editSubmitHeader(widget.type)
              : context.translate.submitHeader(widget.type),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: AppPadding.xl,
        ),
        if (period != null)
          Text(
            period.getRangeString(DateTime.now(), context),
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else ...[
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
        ],
        const SizedBox(
          height: AppPadding.small,
        ),
        RenderQuestions(
            questions: testAdditions,
            questionsListener: widget.questionsListener),
        const SizedBox(
          height: AppPadding.small,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
          child: Center(
            child: LongTextEntry(textController: _descriptionController),
          ),
        ),
        const SizedBox(
          height: AppPadding.large,
        ),
      ],
    );
  }
}

class LongTextEntry extends StatelessWidget {
  final TextEditingController textController;

  const LongTextEntry({required this.textController, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate.submitDescriptionTag,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: AppPadding.tiny,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
          child: AspectRatio(
            aspectRatio: 2.5,
            child: TextFormField(
              scrollPadding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 20) *
                          4),
              controller: textController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppRounding.tiny))),
                  hintText: context.translate.submitDescriptionPlaceholder,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.small, vertical: AppPadding.tiny)),
            ),
          ),
        ),
      ],
    );
  }
}
