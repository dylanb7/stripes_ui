import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

import 'package:stripes_backend_helper/date_format.dart';

import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:collection/collection.dart';

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
            final EntryBuilder? override =
                questionEntries[question.id]?.entryBuilder;
            if (override != null) return override(questionsListener, question);

            if (question is Check) {
              return CheckBoxWidget(
                  check: question, listener: questionsListener);
            } else if (question is MultipleChoice) {
              return MultiChoiceEntry(
                  question: question, listener: questionsListener);
            } else if (question is Numeric) {
              return SeverityWidget(
                  question: question, questionsListener: questionsListener);
            }
            return Text(question.prompt);
          }).toList(),
        ),
      ],
    );
  }
}

class MultiChoiceEntry extends ConsumerStatefulWidget {
  final MultipleChoice question;

  final QuestionsListener listener;

  const MultiChoiceEntry(
      {required this.question, required this.listener, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MultiChoiceEntryState();
}

class _MultiChoiceEntryState extends ConsumerState<MultiChoiceEntry> {
  @override
  void initState() {
    final bool pending = selected() == null;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (pending) {
        widget.listener.addPending(widget.question);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> answers = widget.question.choices;
    final int? selectedIndex = selected();
    final bool isSelected = selectedIndex != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            side: isSelected
                ? const BorderSide(color: buttonDarkBackground, width: 5.0)
                : const BorderSide(width: 0, color: Colors.transparent),
          ),
          color: darkBackgroundText,
          elevation: 4.0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.question.prompt,
                    style: lightBackgroundStyle,
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: answers.mapIndexed((index, choice) {
                    final bool isSelected = index == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: GestureDetector(
                        onTap: () {
                          _onTap(isSelected, index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                              border: Border.all(
                                  color: isSelected
                                      ? buttonDarkBackground
                                      : Colors.transparent,
                                  width: 2.0),
                              color: darkBackgroundText),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  choice,
                                  style: lightBackgroundStyle,
                                ),
                              ),
                              const SizedBox(
                                width: 6.0,
                              ),
                              IgnorePointer(
                                ignoring: true,
                                child: Checkbox(
                                  value: isSelected,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: null,
                                  fillColor:
                                      MaterialStateProperty.all(darkIconButton),
                                  checkColor: darkBackgroundText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? selected() {
    Response? logged = widget.listener.fromQuestion(widget.question);
    if (logged == null) return null;
    return (logged as MultiResponse).index;
  }

  _onTap(bool isSelected, int index) {
    if (isSelected) {
      widget.listener.addPending(widget.question);
      widget.listener.removeResponse(widget.question);
    } else {
      widget.listener.removePending(widget.question);
      widget.listener.addResponse(MultiResponse(
          question: widget.question,
          stamp: dateToStamp(DateTime.now()),
          index: index));
    }
    setState(() {});
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

  final Numeric question;

  const SeverityWidget(
      {required this.questionsListener, required this.question, Key? key})
      : super(key: key);

  @override
  ConsumerState<SeverityWidget> createState() => _SeverityWidgetState();
}

class _SeverityWidgetState extends ConsumerState<SeverityWidget> {
  late double value;

  final SliderListener _sliderListener = SliderListener();

  late final ExpandibleController _controller;

  @override
  void initState() {
    _controller = ExpandibleController(false);
    final double max = (widget.question.max ?? 5).toDouble();
    final double min = (widget.question.min ?? 1).toDouble();

    value = (((max - min) / 2) + min).roundToDouble();
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
                  widget.question.prompt,
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
            min: widget.question.min?.toInt() ?? 1,
            max: widget.question.max?.toInt() ?? 5,
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

    super.initState();
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
          min: 1,
          max: 10,
          minLabel: AppLocalizations.of(context)!.moodLowLevel,
          maxLabel: AppLocalizations.of(context)!.moodHighLevel,
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
}

class SeverityPainWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;

  final Numeric question;

  const SeverityPainWidget(
      {required this.questionsListener, required this.question, Key? key})
      : super(key: key);

  @override
  ConsumerState<SeverityPainWidget> createState() => _SeverityPainWidgetState();
}

class _SeverityPainWidgetState extends ConsumerState<SeverityPainWidget> {
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
                  widget.question.prompt,
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
          child: PainSlider(
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

class SeverityScreenWidget extends StatefulWidget {
  final QuestionsListener listener;

  final Numeric question;

  const SeverityScreenWidget(
      {required this.listener, required this.question, super.key});
  @override
  State<StatefulWidget> createState() {
    return SeverityScreenWidgetState();
  }
}

class SeverityScreenWidgetState extends State<SeverityScreenWidget> {
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

    super.initState();
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
}

class BMSlider extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  final Numeric question;

  const BMSlider({required this.listener, required this.question, Key? key})
      : super(key: key);

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
          minLabel: AppLocalizations.of(context)!.hardTag,
          maxLabel: AppLocalizations.of(context)!.softTag,
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

final questionEntryOverides = Provider<Map<String, QuestionEntry>>((ref) => {});

typedef EntryBuilder<T extends Question> = Widget Function(
    QuestionsListener, T);

class QuestionEntry {
  final bool isSeparateScreen;

  final EntryBuilder entryBuilder;

  const QuestionEntry(
      {required this.isSeparateScreen, required this.entryBuilder});
}
