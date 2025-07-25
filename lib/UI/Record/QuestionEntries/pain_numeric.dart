import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

class PainFacesWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric question;

  const PainFacesWidget(
      {required this.questionsListener, required this.question, super.key});

  @override
  ConsumerState<PainFacesWidget> createState() => _PainFacesWidgetState();
}

class _PainFacesWidgetState extends ConsumerState<PainFacesWidget> {
  final SliderListener _sliderListener = SliderListener();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      num? val = response();
      if (val != null) {
        _sliderListener.interacted();
      }
    });
    _sliderListener.addListener(_interactListener);
    super.initState();
  }

  _interactListener() {
    widget.questionsListener.removePending(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionWrap(
      question: widget.question,
      listener: widget.questionsListener,
      styled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
        child: Column(children: [
          PainSlider(
            initial: response()?.toInt() ?? 0,
            onChange: (val) {
              setState(() {
                _saveValue(val);
              });
            },
            onSlide: (val) {
              setState(() {
                widget.questionsListener.removePending(widget.question);
                _saveValue(val);
              });
            },
            listener: _sliderListener,
          ),
          const SizedBox(
            height: AppPadding.small,
          ),
          Selection(
              text: "Unable to determine pain level",
              onClick: () {
                setState(() {
                  if (response() == -1) {
                    widget.questionsListener.removeResponse(widget.question);
                    widget.questionsListener.addPending(widget.question);
                  } else {
                    _sliderListener.hasInteracted = false;
                    widget.questionsListener.removePending(widget.question);
                    _saveValue(-1);
                  }
                });
              },
              selected: response() == -1)
        ]),
      ),
    );
  }

  num? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  _saveValue(double newValue) {
    widget.questionsListener.addResponse(NumericResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: newValue));
  }

  @override
  void dispose() {
    _sliderListener.removeListener(_interactListener);
    super.dispose();
  }
}

class PainNumericWidget extends StatefulWidget {
  final QuestionsListener listener;

  final Numeric question;

  const PainNumericWidget(
      {required this.listener, required this.question, super.key});
  @override
  State<StatefulWidget> createState() {
    return PainNumericWidgetState();
  }
}

class PainNumericWidgetState extends State<PainNumericWidget> {
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
          height: AppPadding.xxl,
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
          minLabel: context.translate.painLevelZero,
          maxLabel: context.translate.painLevelFive,
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
