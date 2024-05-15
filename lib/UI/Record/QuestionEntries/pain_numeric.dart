import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class PainFacesWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric question;

  const PainFacesWidget(
      {required this.questionsListener, required this.question, super.key});

  @override
  ConsumerState<PainFacesWidget> createState() => _PainFacesWidgetState();
}

class _PainFacesWidgetState extends ConsumerState<PainFacesWidget> {
  late double value;

  final SliderListener _sliderListener = SliderListener();

  late final ExpandibleController _controller;

  @override
  void initState() {
    _controller = ExpandibleController(false);
    value = 5;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      num? val = response();
      if (val != null) {
        value = val.toDouble();
        _controller.set(true);
        _sliderListener.interacted();
      }
    });

    _controller.addListener(_expandListener);
    _sliderListener.addListener(_interactListener);
    super.initState();
  }

  _interactListener() {
    widget.questionsListener.removePending(widget.question);
  }

  _expandListener() {
    if (_controller.expanded) {
      if (_sliderListener.interact) {
        _saveValue();
      } else {
        widget.questionsListener.addPending(widget.question);
      }
    } else {
      widget.questionsListener.removeResponse(widget.question);
      widget.questionsListener.removePending(widget.question);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return QuestionWrap(
      question: widget.question,
      listener: widget.questionsListener,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: PainSlider(
          initial: value.toInt(),
          onChange: (val) {
            setState(() {
              value = val;
              _saveValue();
            });
          },
          listener: _sliderListener,
        ),
      ),
    );
  }

  num? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  _saveValue() {
    widget.questionsListener.addResponse(NumericResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: value));
  }

  @override
  void dispose() {
    _controller.removeListener(_expandListener);
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
      listener.interact = true;
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
          minLabel: AppLocalizations.of(context)!.painLevelZero,
          maxLabel: AppLocalizations.of(context)!.painLevelFive,
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
