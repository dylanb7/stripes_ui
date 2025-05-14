import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';

class MoodScreenWidget extends StatefulWidget {
  final QuestionsListener listener;

  final Numeric question;

  const MoodScreenWidget(
      {required this.listener, required this.question, super.key});
  @override
  State<StatefulWidget> createState() {
    return MoodScreenWidgetState();
  }
}

class MoodScreenWidgetState extends State<MoodScreenWidget> {
  late SliderListener listener;

  late double value;

  @override
  void initState() {
    value = 5;
    listener = SliderListener();

    final Response? res = widget.listener.fromQuestion(widget.question);
    bool pending = false;
    if (res != null) {
      listener.hasInteracted = true;
      value = (res as NumericResponse).response.toDouble();
    } else {
      pending = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (pending) {
        widget.listener.addPending(widget.question);
      }
    });
    listener.addListener(_interactListener);

    super.initState();
  }

  _interactListener() {
    widget.listener.removePending(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 35,
        ),
        StripesSlider(
          onChange: (p0) {},
          onSlide: (val) {
            setState(() {
              value = val;
              _saveValue();
            });
          },
          listener: listener,
          min: 0,
          max: 10,
          minLabel: context.translate.moodLowLevel,
          maxLabel: context.translate.moodHighLevel,
          initial: value.toInt(),
        ),
      ],
    );
  }

  _saveValue() {
    widget.listener.addResponse(NumericResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: value));
  }

  @override
  void dispose() {
    listener.removeListener(_interactListener);
    super.dispose();
  }
}
