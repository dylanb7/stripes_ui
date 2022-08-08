import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class QuestionsListener {
  final Map<Question, Response> questions = {};

  addResponse(Response response) {
    questions[response.question] = response;
  }

  Response? fromQuestion(Question question) => questions[question];

  removeResponse(Question question) {
    questions.remove(question);
  }
}

class QuestionScreen extends StatelessWidget {
  final List<Question> questions;

  final String header;

  final QuestionsListener questionsListener;

  const QuestionScreen(
      {required this.header,
      required this.questions,
      required this.questionsListener,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          header,
          style: lightBackgroundHeaderStyle,
        ),
        const SizedBox(
          height: 12.0,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: questions.map((question) {
            if (question.id == q4) {
              return BMSlider(listener: questionsListener);
            }
            if (question is Check) {
              return CheckBoxWidget(
                  check: question, listener: questionsListener);
            } else if (question is Numeric) {
              return SeverityWidget(
                  numeric: question, questionsListener: questionsListener);
            }
            return Text(question.prompt);
          }).toList(),
        ),
      ],
    );
  }
}

class CheckBoxWidget extends StatefulWidget {
  final Check check;

  final QuestionsListener listener;

  const CheckBoxWidget({required this.check, required this.listener, Key? key})
      : super(key: key);

  @override
  State<CheckBoxWidget> createState() => _CheckBoxWidgetState();
}

class _CheckBoxWidgetState extends State<CheckBoxWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () {
          _onTap();
        },
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              side: isSelected
                  ? const BorderSide(color: buttonDarkBackground, width: 5.0)
                  : const BorderSide(width: 0, color: Colors.transparent)),
          color: darkBackgroundText,
          elevation: 7.0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text(
                  widget.check.prompt,
                  style: lightBackgroundStyle,
                )),
                const SizedBox(
                  width: 3.0,
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: null,
                    fillColor: MaterialStateProperty.all(darkIconButton),
                    checkColor: darkBackgroundText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get selected => widget.listener.fromQuestion(widget.check) != null;

  _onTap() {
    setState(() {
      if (selected) {
        widget.listener.removeResponse(widget.check);
      } else {
        widget.listener.addResponse(Selected(
            question: widget.check, stamp: dateToStamp(DateTime.now())));
      }
    });
  }
}

class SeverityWidget extends StatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric numeric;

  const SeverityWidget(
      {required this.numeric, required this.questionsListener, Key? key})
      : super(key: key);

  @override
  State<SeverityWidget> createState() => _SeverityWidgetState();
}

class _SeverityWidgetState extends State<SeverityWidget> {
  double value = 3;

  late final ExpandibleListener _listener;
  @override
  void initState() {
    _listener = ExpandibleListener();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      num? val = response();
      _listener.expanded.value = val != null;
      if (val != null) value = val.toDouble();
    });
    _listener.expanded.addListener(() {
      if (_listener.expanded.value) {
        widget.questionsListener.addResponse(NumericResponse(
            question: widget.numeric,
            stamp: dateToStamp(DateTime.now()),
            response: response() ?? value));
      } else {
        widget.questionsListener.removeResponse(widget.numeric);
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final num? res = response();
    return Expandible(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.numeric.prompt,
                  style: lightBackgroundStyle,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 3.0,
          ),
          IgnorePointer(
            ignoring: true,
            child: Checkbox(
              value: res != null,
              onChanged: null,
              fillColor: MaterialStateProperty.all(darkIconButton),
              checkColor: darkBackgroundText,
            ),
          ),
        ],
      ),
      view: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Slider(
              value: value,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChangeEnd: (value) {
                setState(() {
                  widget.questionsListener.addResponse(NumericResponse(
                      question: widget.numeric,
                      stamp: dateToStamp(DateTime.now()),
                      response: value));
                });
              },
              label: '${value.toInt()}',
              onChanged: (double val) {
                setState(() {
                  value = val;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '1 (Mild)',
                    style: lightBackgroundStyle,
                  ),
                  Text(
                    '(Severe) 5',
                    style: lightBackgroundStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      selected: res != null,
      hasIndicator: false,
      listener: _listener,
    );
  }

  num? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.numeric);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }
}

class BMSlider extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  const BMSlider({required this.listener, Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _BMSliderState();
}

class _BMSliderState extends ConsumerState<BMSlider> {
  late List<Image> images;

  double value = 4;

  @override
  void initState() {
    const List<String> paths = [
      'assets/images/poop1.png',
      'assets/images/poop2.png',
      'assets/images/poop3.png',
      'assets/images/poop4.png',
      'assets/images/poop5.png',
      'assets/images/poop6.png',
      'assets/images/poop7.png'
    ];
    images = paths
        .map((path) => Image.asset(
              path,
              package: 'stripes_ui',
            ))
        .toList();
    final Response? res = widget.listener.fromQuestion(
        ref.read(questionHomeProvider).home?.fromID(q4) ?? Question.empty());
    if (res != null) {
      value = (res as NumericResponse).response.toDouble();
    } else {
      _saveValue();
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    for (Image image in images) {
      precacheImage(image.image, context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: images[value.toInt() - 1],
        ),
        Slider(
          value: value,
          onChanged: (val) {
            setState(
              () {
                value = val;
              },
            );
          },
          min: 1,
          max: 7,
          divisions: 6,
          label: '${value.toInt()}',
          onChangeEnd: (val) {
            _saveValue();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1 (Hard)',
                style: lightBackgroundHeaderStyle,
              ),
              Text(
                'Slide to select',
                style: lightBackgroundHeaderStyle,
              ),
              Text(
                '(Soft) 7',
                style: lightBackgroundHeaderStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  _saveValue() {
    widget.listener.addResponse(NumericResponse(
        question: ref.read(questionHomeProvider).home?.fromID(q4) as Numeric,
        stamp: dateToStamp(DateTime.now()),
        response: value));
  }
}
