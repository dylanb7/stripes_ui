import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/paddings.dart';

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
      if (pending && widget.question.isRequired) {
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
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: QuestionWrap(
        question: widget.question,
        listener: widget.listener,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small, vertical: AppPadding.small),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.question.userCreated) ...[
                const SizedBox(
                  height: AppPadding.tiny,
                ),
                Text(
                  "custom symptom",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor.darken(),
                      ),
                ),
              ],
              const SizedBox(
                height: AppPadding.small,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: answers.mapIndexed((index, choice) {
                  final bool isSelected = index == selectedIndex;
                  return Selection(
                      text: choice,
                      onClick: () {
                        _onTap(isSelected, index);
                      },
                      selected: isSelected);
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
      if (widget.question.isRequired) {
        widget.listener.addPending(widget.question);
      }
      widget.listener.removeResponse(widget.question);
    } else {
      if (widget.question.isRequired) {
        widget.listener.removePending(widget.question);
      }
      widget.listener.addResponse(MultiResponse(
          question: widget.question,
          stamp: dateToStamp(DateTime.now()),
          index: index));
    }
    setState(() {});
  }
}

class AllThatApplyEntry extends StatefulWidget {
  final QuestionsListener listener;

  final AllThatApply question;

  const AllThatApplyEntry(
      {required this.listener, required this.question, super.key});

  @override
  State<AllThatApplyEntry> createState() => _AllThatApplyEntryState();
}

class _AllThatApplyEntryState extends State<AllThatApplyEntry> {
  @override
  void initState() {
    final bool pending = selected() == null;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (pending && widget.question.isRequired) {
        widget.listener.addPending(widget.question);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> answers = widget.question.choices;
    final List<int>? selectedIndices = selected();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: QuestionWrap(
        question: widget.question,
        listener: widget.listener,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small, vertical: AppPadding.small),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.question.userCreated) ...[
                const SizedBox(
                  height: AppPadding.tiny,
                ),
                Text(
                  "custom symptom",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor.darken(),
                      ),
                ),
              ],
              const SizedBox(
                height: AppPadding.small,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: answers.mapIndexed((index, choice) {
                  final bool isSelected =
                      selectedIndices?.contains(index) ?? false;
                  return Selection(
                      text: choice,
                      onClick: () {
                        _onTap(isSelected, index, selectedIndices);
                      },
                      selected: isSelected);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int>? selected() {
    Response? logged = widget.listener.fromQuestion(widget.question);
    if (logged == null) return null;
    return [...(logged as AllResponse).responses];
  }

  _onTap(bool isSelected, int index, List<int>? selectedIndices) {
    if (isSelected) {
      final int currentCount = selectedIndices?.length ?? 0;
      if (currentCount <= 1) {
        if (widget.question.isRequired) {
          widget.listener.addPending(widget.question);
        }
        widget.listener.removeResponse(widget.question);
      } else {
        widget.listener.addResponse(
          AllResponse(
            question: widget.question,
            stamp: dateToStamp(DateTime.now()),
            responses: selectedIndices!..remove(index),
          ),
        );
      }
    } else {
      if (widget.question.isRequired) {
        widget.listener.removePending(widget.question);
      }
      widget.listener.addResponse(
        AllResponse(
          question: widget.question,
          stamp: dateToStamp(DateTime.now()),
          responses: [...(selectedIndices ?? []), index],
        ),
      );
    }
    setState(() {});
  }
}

class CheckBoxWidget extends StatefulWidget {
  final Check check;

  final QuestionsListener listener;

  const CheckBoxWidget(
      {required this.check, required this.listener, super.key});

  @override
  State<CheckBoxWidget> createState() => _CheckBoxWidgetState();
}

class _CheckBoxWidgetState extends State<CheckBoxWidget> {
  @override
  void initState() {
    final bool isNotChecked =
        widget.listener.fromQuestion(widget.check) == null;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isNotChecked && widget.check.isRequired) {
        widget.listener.addPending(widget.check);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _onTap();
      },
      child: QuestionWrap(
        question: widget.check,
        listener: widget.listener,
        styled: false,
        child: Column(
          children: [
            Selection(
                text: widget.check.prompt,
                onClick: () {
                  _onTap();
                },
                selected: selected),
            if (widget.check.userCreated) ...[
              const SizedBox(
                height: AppPadding.tiny,
              ),
              Text(
                "custom symptom",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor.darken(),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get selected => widget.listener.fromQuestion(widget.check) != null;

  _onTap() {
    setState(() {
      if (selected) {
        // Unchecking - add back to pending if required
        if (widget.check.isRequired) {
          widget.listener.addPending(widget.check);
        }
        widget.listener.removeResponse(widget.check);
      } else {
        // Checking - remove from pending if required
        if (widget.check.isRequired) {
          widget.listener.removePending(widget.check);
        }
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
      {required this.questionsListener, required this.question, super.key});

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
        if (mounted) {
          setState(() {});
        }
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
      if (_sliderListener.hasInteracted) {
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppPadding.small,
              right: AppPadding.tiny,
              left: AppPadding.tiny),
          child: QuestionWrap(
            question: widget.question,
            listener: widget.questionsListener,
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question.prompt,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (widget.question.userCreated) ...[
                    const SizedBox(
                      height: AppPadding.tiny,
                    ),
                    Text(
                      "custom symptom",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor.darken(),
                          ),
                    ),
                  ],
                  const SizedBox(
                    height: AppPadding.small,
                  ),
                  StripesSlider(
                    initial: value.toInt(),
                    min: widget.question.min?.toInt() ?? 1,
                    max: widget.question.max?.toInt() ?? 5,
                    hasInstruction: false,
                    onChange: (val) {
                      setState(() {
                        value = val;
                        _saveValue();
                      });
                    },
                    listener: _sliderListener,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_sliderListener.hasInteracted)
          Positioned(
            right: 0.0,
            top: AppPadding.tiny,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                widget.questionsListener.removeResponse(widget.question);
                _sliderListener.hasInteracted = false;
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(),
                    color: Theme.of(context).colorScheme.surface),
                child: const Padding(
                  padding: EdgeInsets.all(AppPadding.tiny),
                  child: Icon(
                    Icons.close,
                    size: 14.0,
                  ),
                ),
              ),
            ),
          ),
      ],
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
            ? const BorderSide(color: Colors.grey, width: 3)
            : BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 3),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppRounding.small)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppRounding.medium),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small, vertical: AppPadding.tiny),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.question.prompt,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.question.userCreated) ...[
                const SizedBox(
                  height: AppPadding.tiny,
                ),
                Text(
                  "custom symptom",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor.darken(),
                      ),
                ),
              ],
              const SizedBox(
                height: AppPadding.tiny,
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
                          horizontal: AppPadding.small,
                          vertical: AppPadding.tiny)),
                ),
              ),
              const SizedBox(
                height: AppPadding.tiny,
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

class DependentEntry extends StatefulWidget {
  final bool Function(QuestionsListener) showing;

  final QuestionsListener listener;

  final Question question;

  const DependentEntry(
      {super.key,
      required this.listener,
      required this.question,
      required this.showing});

  @override
  State<StatefulWidget> createState() => DependentEntryState();
}

class DependentEntryState extends State<DependentEntry> {
  bool showing = false;

  @override
  void initState() {
    showing = widget.showing(widget.listener);
    widget.listener.addListener(_updateShowing);

    super.initState();
  }

  _updateShowing() {
    setState(() {
      showing = widget.showing(widget.listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!showing) return Container();
    return RenderQuestions(
        questions: [widget.question], questionsListener: widget.listener);
  }

  @override
  void dispose() {
    widget.listener.removeListener(_updateShowing);
    super.dispose();
  }
}

class Selection extends StatelessWidget {
  final String text;

  final Function onClick;

  final bool selected;

  const Selection(
      {required this.text,
      required this.onClick,
      required this.selected,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onClick();
      },
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppPadding.small,
              right: AppPadding.tiny,
              left: AppPadding.tiny),
          child: AnimatedContainer(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRounding.small)),
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).dividerColor)),
            duration: const Duration(milliseconds: 150),
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.medium, vertical: AppPadding.small),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface),
                )),
          ),
        ),
        if (selected)
          Positioned(
            right: 0.0,
            top: AppPadding.tiny,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(),
                  color: Theme.of(context).colorScheme.surface),
              child: const Padding(
                padding: EdgeInsets.all(AppPadding.tiny),
                child: Icon(
                  Icons.close,
                  size: 14.0,
                ),
              ),
            ),
          )
      ]),
    );
  }
}
