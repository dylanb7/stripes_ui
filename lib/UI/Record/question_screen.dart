import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/entry.dart';

class QuestionsListener extends ChangeNotifier {
  final Map<Question, Response> questions = {};

  final Set<Question> pending = {};

  addPending(Question question) {
    pending.add(question);
    notifyListeners();
  }

  removePending(Question question) {
    pending.remove(question);
    notifyListeners();
  }

  addResponse(Response response) {
    questions[response.question] = response;
  }

  Response? fromQuestion(Question question) => questions[question];

  removeResponse(Question question) {
    questions.remove(question);
  }
}

class QuestionScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, QuestionEntry> questionEntries =
        ref.watch(questionEntryOverides);
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
            final Widget? override = questionEntries[question.id]?.display;
            if (override != null) return override;
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
          elevation: 4.0,
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

class SeverityWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric numeric;

  const SeverityWidget(
      {required this.numeric, required this.questionsListener, Key? key})
      : super(key: key);

  @override
  ConsumerState<SeverityWidget> createState() => _SeverityWidgetState();
}

class _SeverityWidgetState extends ConsumerState<SeverityWidget> {
  double value = 3;

  final SliderListener _sliderListener = SliderListener();

  late final ExpandibleController _controller;
  @override
  void initState() {
    _controller = ExpandibleController(false);
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
    widget.questionsListener.removePending(widget.numeric);
  }

  _expandListener() {
    if (_controller.expanded) {
      if (_sliderListener.interact) {
        _saveValue();
      } else {
        widget.questionsListener.addPending(widget.numeric);
      }
    } else {
      widget.questionsListener.removeResponse(widget.numeric);
      widget.questionsListener.removePending(widget.numeric);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final num? res = response();
    final bool tried = ref.watch(continueTried);
    final bool errorHighlight = tried && !_sliderListener.interact;
    return Expandible(
      highlightColor: errorHighlight ? error : buttonDarkBackground,
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
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: StripesSlider(
            initial: value.toInt(),
            onChange: (val) {
              setState(() {
                value = val;
                _saveValue();
              });
            },
            listener: _sliderListener,
          )),
      selected: res != null || errorHighlight,
      hasIndicator: false,
      listener: _controller,
    );
  }

  num? response() {
    Response? res = widget.questionsListener.fromQuestion(widget.numeric);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  _saveValue() {
    widget.questionsListener.addResponse(NumericResponse(
        question: widget.numeric,
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

class BMSlider extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  const BMSlider({required this.listener, Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _BMSliderState();
}

class _BMSliderState extends ConsumerState<BMSlider> {
  late List<Image> images;

  late SliderListener listener;

  double value = 4;

  @override
  void initState() {
    const List<String> paths = [
      'packages/stripes_ui/assets/images/poop1.png',
      'packages/stripes_ui/assets/images/poop2.png',
      'packages/stripes_ui/assets/images/poop3.png',
      'packages/stripes_ui/assets/images/poop4.png',
      'packages/stripes_ui/assets/images/poop5.png',
      'packages/stripes_ui/assets/images/poop6.png',
      'packages/stripes_ui/assets/images/poop7.png'
    ];
    images = paths
        .map((path) => Image.asset(
              path,
            ))
        .toList();
    listener = SliderListener();

    final Response? res = widget.listener.fromQuestion(
        ref.read(questionHomeProvider).home?.fromID(q4) ?? Question.empty());
    bool pending = false;
    if (res != null) {
      listener.interact = true;
      value = (res as NumericResponse).response.toDouble();
    } else {
      pending = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (pending) {
        widget.listener.addPending(QuestionHomeInst().fromID(q4));
      }
    });
    listener.addListener(_interactListener);

    super.initState();
  }

  _interactListener() {
    widget.listener.removePending(QuestionHomeInst().fromID(q4));
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
        SizedBox(height: 250, child: images[value.toInt() - 1]),
        StripesSlider(
          onChange: (p0) {},
          onSlide: (val) {
            setState(() {
              value = val;
              _saveValue();
            });
          },
          listener: listener,
          min: 1,
          max: 7,
          minLabel: 'Hard',
          maxLabel: 'Soft',
          initial: value.toInt(),
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

  @override
  void dispose() {
    listener.removeListener(_interactListener);
    super.dispose();
  }
}
