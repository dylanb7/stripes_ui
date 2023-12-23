import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:collection/collection.dart';

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
          style: lightBackgroundHeaderStyle.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(
          height: 12.0,
        ),
        RenderQuestions(
            questions: questions, questionsListener: questionsListener)
      ],
    );
  }
}

class RenderQuestions extends ConsumerWidget {
  final List<Question> questions;

  final QuestionsListener questionsListener;

  const RenderQuestions(
      {required this.questions, required this.questionsListener, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, QuestionEntry> questionEntries =
        ref.watch(questionsProvider).entryOverrides ?? {};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: questions.map((question) {
        final EntryBuilder? override =
            questionEntries[question.id]?.entryBuilder;
        if (override != null) {
          return override(questionsListener, context, question);
        }
        if (question is Check) {
          return CheckBoxWidget(check: question, listener: questionsListener);
        } else if (question is MultipleChoice) {
          return MultiChoiceEntry(
              question: question, listener: questionsListener);
        } else if (question is Numeric) {
          return SeverityWidget(
              question: question, questionsListener: questionsListener);
        } else if (question is FreeResponse) {
          return FreeResponseEntry(
              question: question, listener: questionsListener);
        }
        return Text(question.prompt);
      }).toList(),
    );
  }
}

class QuestionWrap extends ConsumerStatefulWidget {
  final Question question;

  final QuestionsListener listener;

  final Widget child;

  const QuestionWrap(
      {required this.question,
      required this.listener,
      required this.child,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => QuestionWrapState();
}

class QuestionWrapState extends ConsumerState<QuestionWrap> {
  @override
  void initState() {
    if (widget.question.isRequired && !hasEntry) {
      widget.listener.addPending(widget.question);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.listener.tried &&
        widget.listener.pending.contains(widget.question);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        side: hasEntry
            ? BorderSide(
                width: 3.0, color: Theme.of(context).colorScheme.secondary)
            : hasError
                ? BorderSide(
                    width: 3.0, color: Theme.of(context).colorScheme.error)
                : const BorderSide(width: 0.0, color: Colors.transparent),
      ),
      elevation: 1.0,
      child: widget.child,
    );
  }

  bool get hasEntry => widget.listener.fromQuestion(widget.question) != null;
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: QuestionWrap(
        question: widget.question,
        listener: widget.listener,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
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
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                              width: 2.0),
                        ),
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
                                onChanged: (val) {},
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
        child: QuestionWrap(
          question: widget.check,
          listener: widget.listener,
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
                    onChanged: (val) {},
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

    return QuestionWrap(
      question: widget.question,
      listener: widget.questionsListener,
      child: ExpandibleRaw(
        controller: _controller,
        iconSize: 0.0,
        header: Padding(
          padding: const EdgeInsets.only(left: 6.0, bottom: 6.0, top: 6.0),
          child: Row(
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
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
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

  @override
  void dispose() {
    listener.removeListener(_interactListener);
    super.dispose();
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
    final bool errorHighlight =
        tried && widget.questionsListener.pending.contains(widget.question);
    return Expandible(
      highlightColor: errorHighlight
          ? Theme.of(context).colorScheme.error
          : res != null
              ? Theme.of(context).colorScheme.secondary
              : null,
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
              onChanged: (val) {},
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

class FreeResponseEntry extends StatefulWidget {
  final FreeResponse question;

  final QuestionsListener listener;

  const FreeResponseEntry(
      {required this.question, required this.listener, super.key});

  @override
  State<StatefulWidget> createState() => _FreeResponseEntryState();
}

class _FreeResponseEntryState extends State<FreeResponseEntry> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    final Response? res = widget.listener.fromQuestion(widget.question);
    if (res != null) {
      controller.text = (res as OpenResponse).response;
    }
    controller.addListener(_onEdit);

    super.initState();
  }

  _onEdit() {
    widget.listener.addResponse(OpenResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final InputBorder borderStyle = OutlineInputBorder(
        borderSide: controller.text.isEmpty
            ? const BorderSide(color: Colors.grey, width: 1)
            : BorderSide(
                color: Theme.of(context).colorScheme.secondary, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.question.prompt,
                  textAlign: TextAlign.center,
                  style: lightBackgroundStyle,
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              SizedBox(
                height: 120,
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                      focusedBorder: borderStyle,
                      border: borderStyle,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.listener.removeListener(_onEdit);
    super.dispose();
  }
}

/*class DependentEntry extends StatefulWidget {
  final bool Function(QuestionsListener) showing;

  final QuestionsListener listener;

  const DependentEntry(
      {super.key, required this.listener, required this.showing});

  @override
  State<StatefulWidget> createState() => DependentEntryState();
}

class DependentEntryState extends State<DependentEntry> {
  final TextEditingController controller = TextEditingController();

  bool showing = false;

  @override
  void initState() {
    final Response? res = widget.listener.fromQuestion(widget.question);
    if (res != null) {
      controller.text = (res as OpenResponse).response;
    }
    showing = _showing();
    controller.addListener(_onEdit);
    widget.listener.addListener(_updateShowing);

    super.initState();
  }

  bool _showing() {
    final List<Question> prev = widget.listener.questions.keys
        .where((element) => element.id == s1)
        .toList();

    if (prev.isEmpty) {
      return false;
    }
    final MultiResponse val =
        widget.listener.fromQuestion(prev[0]) as MultiResponse;
    if (val.index == 0) {
      return false;
    }

    return true;
  }

  _updateShowing() {
    final List<Question> prev = widget.listener.questions.keys
        .where((element) => element.id == s1)
        .toList();

    if (prev.isEmpty) {
      showing = false;
      widget.listener.questions.remove(widget.question);
      setState(() {});
      return;
    }
    final MultiResponse res =
        widget.listener.fromQuestion(prev[0]) as MultiResponse;
    if (res.index == 0) {
      showing = false;
      widget.listener.questions.remove(widget.question);
      setState(() {});

      return;
    }

    showing = true;
    widget.listener.questions[widget.question] = OpenResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: controller.text);
    setState(() {});
  }

  _onEdit() {
    widget.listener.addResponse(OpenResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: controller.text));
  }

  @override
  Widget build(BuildContext context) {
    if (!showing) return Container();
  }

  @override
  void dispose() {
    widget.listener.removeListener(_updateShowing);
    super.dispose();
  }
}*/

class BlueDyeEntry extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  final MultipleChoice question;

  const BlueDyeEntry(
      {required this.listener, required this.question, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BlueDyeEntryState();
  }
}

class _BlueDyeEntryState extends ConsumerState<BlueDyeEntry> {
  late int? index;

  List<bool> toggleState = [false, false];

  @override
  void initState() {
    Response? res = widget.listener.questions[widget.question];
    if (res != null) {
      final int index = (res as MultiResponse).index;
      toggleState[index] = true;
    } else {
      widget.listener.addPending(widget.question);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface =
        Theme.of(context).colorScheme.surface.withOpacity(0.12);
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        const SizedBox(
          height: 6.0,
        ),
        Text(
          AppLocalizations.of(context)!.submitBlueQuestion,
          style: lightBackgroundHeaderStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ChoiceChip(
              label: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  child: Text(AppLocalizations.of(context)!.blueQuestionYes)),
              selected: toggleState[0],
              selectedColor: primary,
              backgroundColor: surface,
              labelStyle: TextStyle(
                  color: toggleState[0] ? onPrimary : onSurface,
                  fontWeight: FontWeight.bold),
              checkmarkColor: toggleState[0] ? onPrimary : onSurface,
              onSelected: (value) {
                if (toggleState[0]) return;
                setState(() {
                  toggleState = [true, false];
                  widget.listener.addResponse(MultiResponse(
                      question: widget.question,
                      stamp: DateTime.now().millisecondsSinceEpoch,
                      index: 0));
                  widget.listener.removePending(widget.question);
                });
              },
            ),
            ChoiceChip(
              label: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  child: Text(AppLocalizations.of(context)!.blueQuestionNo)),
              selected: toggleState[1],
              selectedColor: primary,
              backgroundColor: surface,
              labelStyle: TextStyle(
                  color: toggleState[1] ? onPrimary : onSurface,
                  fontWeight: FontWeight.bold),
              checkmarkColor: toggleState[1] ? onPrimary : onSurface,
              onSelected: (value) {
                if (toggleState[1]) return;
                setState(() {
                  toggleState = [false, true];
                  widget.listener.addResponse(MultiResponse(
                      question: widget.question,
                      stamp: DateTime.now().millisecondsSinceEpoch,
                      index: 1));
                  widget.listener.removePending(widget.question);
                });
              },
            )
          ],
        ),
      ],
    );
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
