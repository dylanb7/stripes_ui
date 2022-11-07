import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class SubmitScreen extends ConsumerWidget {
  final String type;

  final QuestionsListener questionsListener;

  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  final DateTime? submitTime;

  final bool isEdit, isTest;

  final String? desc;

  SubmitScreen(
      {required this.questionsListener,
      required this.type,
      this.submitTime,
      this.isEdit = false,
      this.isTest = false,
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
    return Column(
      children: [
        Text(
          isEdit
              ? 'Information Entered about $type'
              : 'Enter Information about the $type entry below',
          style: lightBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 40,
        ),
        IgnorePointer(
          ignoring: isEdit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DateWidget(dateListener: _dateListener),
              TimeWidget(timeListener: _timeListener),
            ],
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        LongTextEntry(type: type, textController: _descriptionController),
        const SizedBox(
          height: 30,
        ),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: StripesRoundedButton(
              text: isEdit ? 'Save Changes' : 'Submit Entry',
              onClick: () {
                _submitEntry(context, ref);
              },
              light: false,
              rounding: 25.0,
            )),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }

  _submitEntry(BuildContext context, WidgetRef ref) {
    final DateTime dateOfEntry =
        isEdit ? submitTime ?? _dateListener.date : _dateListener.date;
    final TimeOfDay timeOfEntry = _timeListener.time;
    final currentTime = DateTime.now();
    final int entryStamp = dateToStamp(DateTime(
        dateOfEntry.year,
        dateOfEntry.month,
        dateOfEntry.day,
        timeOfEntry.hour,
        timeOfEntry.minute,
        currentTime.second,
        currentTime.millisecond));
    final DetailResponse detailResponse = DetailResponse(
      description: _descriptionController.text,
      responses: questionsListener.questions.values.toList(growable: false),
      stamp: isEdit ? dateToStamp(submitTime!) : entryStamp,
      detailType: type,
    );
    if (isEdit) {
      ref.read(stampProvider)?.updateStamp(detailResponse);
    } else {
      ref.read(stampProvider)?.addStamp(detailResponse);
    }
    context.pop();
  }
}

class LongTextEntry extends StatelessWidget {
  final TextEditingController textController;

  final String type;

  const LongTextEntry(
      {required this.type, required this.textController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        children: [
          Text(
            'Description of $type',
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
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  hintText: 'Tap to type...',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0)),
            ),
          ),
        ],
      ),
    );
  }
}
