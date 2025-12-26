import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';

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
    super.initState();
    value = 5;
    listener = SliderListener();

    final Response? res = widget.listener.fromQuestion(widget.question);
    if (res != null) {
      listener.hasInteracted = true;
      value = (res as NumericResponse).response.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.listener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);

        return Column(
          children: [
            const SizedBox(
              height: AppPadding.xxl,
            ),
            QuestionEntryCard(
              styled: false,
              child: StripesSlider(
                onChange: (p0) {},
                onSlide: (val) {
                  setState(() {
                    value = val;
                    _saveValue(controller);
                  });
                },
                listener: listener,
                min: 0,
                max: 10,
                minLabel: context.translate.moodLowLevel,
                maxLabel: context.translate.moodHighLevel,
                initial: value.toInt(),
              ),
            ),
          ],
        );
      }),
    );
  }

  _saveValue(QuestionEntryController controller) {
    controller.addResponse(NumericResponse(
        question: widget.question, stamp: controller.stamp, response: value));
  }

  @override
  void dispose() {
    listener.dispose(); // Ensure listener is disposed
    super.dispose();
  }
}
