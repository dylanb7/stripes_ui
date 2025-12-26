import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';

import 'package:stripes_ui/UI/Record/QuestionEntries/severity_slider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class MultiChoiceEntry extends ConsumerWidget {
  final MultipleChoice question;
  final QuestionsListener listener;

  const MultiChoiceEntry({
    required this.question,
    required this.listener,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuestionEntryScope(
      question: question,
      listener: listener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final List<String> answers = question.choices;
            final int? selectedIndex = _getSelectedIndex(controller);

            return QuestionEntryCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.small,
                vertical: AppPadding.small,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      question.prompt,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (question.userCreated) ...[
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      "custom symptom",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor.darken(),
                          ),
                    ),
                  ],
                  const SizedBox(height: AppPadding.small),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: answers.mapIndexed((index, choice) {
                      final bool isSelected = index == selectedIndex;
                      return Selection(
                        text: choice,
                        onClick: () => _onTap(controller, isSelected, index),
                        selected: isSelected,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  int? _getSelectedIndex(QuestionEntryController controller) {
    final Response? response = controller.response;
    if (response == null) return null;
    return (response as MultiResponse).index;
  }

  void _onTap(QuestionEntryController controller, bool isSelected, int index) {
    controller.toggleResponse(() => MultiResponse(
          question: question,
          stamp: controller.stamp,
          index: index,
        ));
  }
}

class AllThatApplyEntry extends StatelessWidget {
  final QuestionsListener listener;
  final AllThatApply question;

  const AllThatApplyEntry({
    required this.listener,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: question,
      listener: listener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final List<String> answers = question.choices;
            final List<int>? selectedIndices = _getSelectedIndices(controller);

            return QuestionEntryCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.small,
                vertical: AppPadding.small,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      question.prompt,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (question.userCreated) ...[
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      "custom symptom",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor.darken(),
                          ),
                    ),
                  ],
                  const SizedBox(height: AppPadding.small),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: answers.mapIndexed((index, choice) {
                      final bool isSelected =
                          selectedIndices?.contains(index) ?? false;
                      return Selection(
                        text: choice,
                        onClick: () => _onTap(
                            controller, isSelected, index, selectedIndices),
                        selected: isSelected,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  List<int>? _getSelectedIndices(QuestionEntryController controller) {
    final Response? response = controller.response;
    if (response == null) return null;
    return [...(response as AllResponse).responses];
  }

  void _onTap(
    QuestionEntryController controller,
    bool isSelected,
    int index,
    List<int>? selectedIndices,
  ) {
    final List<int> current = [...(selectedIndices ?? [])];
    if (isSelected) {
      current.remove(index);
      if (current.isEmpty) {
        controller.removeResponse();
      } else {
        controller.addResponse(
          AllResponse(
            question: question,
            stamp: controller.stamp,
            responses: current,
          ),
        );
      }
    } else {
      controller.addResponse(
        AllResponse(
          question: question,
          stamp: controller.stamp,
          responses: [...current, index],
        ),
      );
    }
  }
}

class CheckBoxWidget extends StatelessWidget {
  final Check check;
  final QuestionsListener listener;

  const CheckBoxWidget({
    required this.check,
    required this.listener,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: check,
      listener: listener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final bool isSelected = controller.hasResponse;

            return QuestionEntryCard(
              styled: false,
              child: Column(
                children: [
                  Selection(
                    text: check.prompt,
                    onClick: () => _onTap(controller),
                    selected: isSelected,
                  ),
                  if (check.userCreated) ...[
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      "custom symptom",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor.darken(),
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _onTap(QuestionEntryController controller) {
    controller.toggleResponse(() => Selected(
          question: check,
          stamp: controller.stamp,
        ));
  }
}

class SeverityWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;
  final Numeric question;

  const SeverityWidget({
    required this.questionsListener,
    required this.question,
    super.key,
  });

  @override
  ConsumerState<SeverityWidget> createState() => _SeverityWidgetState();
}

class _SeverityWidgetState extends ConsumerState<SeverityWidget> {
  late double value;
  final SliderListener _sliderListener = SliderListener();

  @override
  void initState() {
    super.initState();
    final double max = (widget.question.max ?? 5).toDouble();
    final double min = (widget.question.min ?? 1).toDouble();
    value = (((max - min) / 2) + min).roundToDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final num? val = _getResponseStatic();
      if (val != null) {
        value = val.toDouble();
        _sliderListener.interacted();
        if (mounted) setState(() {});
      }
    });

    _sliderListener.addListener(_onSliderInteract);
  }

  @override
  void dispose() {
    _sliderListener.removeListener(_onSliderInteract);
    super.dispose();
  }

  void _onSliderInteract() {
    // This is historically used to remove pending, but controller handles it.
    // Keeping it for the listener interface if needed.
  }

  num? _getResponseStatic() {
    final Response? res =
        widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  void _saveValue(QuestionEntryController controller) {
    controller.addResponse(NumericResponse(
      question: widget.question,
      stamp: controller.stamp,
      response: value,
    ));
  }

  void _clearValue(QuestionEntryController controller) {
    controller.removeResponse();
    _sliderListener.hasInteracted = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.questionsListener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppPadding.small,
                right: AppPadding.tiny,
                left: AppPadding.tiny,
              ),
              child: QuestionEntryCard(
                padding: const EdgeInsets.all(AppPadding.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.prompt,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.question.userCreated) ...[
                      const SizedBox(height: AppPadding.tiny),
                      Text(
                        "custom symptom",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).disabledColor.darken(),
                            ),
                      ),
                    ],
                    const SizedBox(height: AppPadding.small),
                    StripesSlider(
                      initial: value.toInt(),
                      min: widget.question.min?.toInt() ?? 1,
                      max: widget.question.max?.toInt() ?? 5,
                      hasInstruction: false,
                      onChange: (val) {
                        setState(() {
                          value = val;
                          _saveValue(controller);
                        });
                      },
                      listener: _sliderListener,
                    ),
                  ],
                ),
              ),
            ),
            if (_sliderListener.hasInteracted)
              Positioned(
                right: 0.0,
                top: AppPadding.tiny,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _clearValue(controller),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AppPadding.tiny),
                      child: Icon(Icons.close, size: 14.0),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class FreeResponseEntry extends StatefulWidget {
  final FreeResponse question;
  final QuestionsListener listener;

  const FreeResponseEntry({
    required this.question,
    required this.listener,
    super.key,
  });

  @override
  State<FreeResponseEntry> createState() => _FreeResponseEntryState();
}

class _FreeResponseEntryState extends State<FreeResponseEntry> {
  final TextEditingController controller = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onEdit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final Response? res = widget.listener.fromQuestion(widget.question);
      if (res != null) {
        controller.text = (res as OpenResponse).response;
      }
      _initialized = true;
    }
  }

  void _onEdit() {
    // We don't update state immediately on every keystroke to avoid spamming
    // the listener, but we could debouce if needed.
    // For now, mirroring original behavior but using local state
    // The actual update happens via the controller in the build method scope
    // or we need access to the scope controller here.
    // Since we are in State, we can't easily access the scope controller
    // unless we look it up. But the look up requires context.

    final entryController = QuestionEntryScope.maybeOf(context);
    if (entryController == null) return;

    final String text = controller.text;
    if (text.isEmpty) {
      entryController.removeResponse();
    } else {
      entryController.addResponse(OpenResponse(
        question: widget.question,
        stamp: entryController.stamp,
        response: text,
      ));
    }
  }

  // Note: The previous implementation logic for adding/removing pending
  // is now handled by QuestionEntryController automatically.

  @override
  Widget build(BuildContext context) {
    final InputBorder borderStyle = OutlineInputBorder(
        borderSide: controller.text.isEmpty
            ? const BorderSide(color: Colors.grey, width: 3)
            : BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 3),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppRounding.small)));

    return QuestionEntryScope(
      question: widget.question,
      listener: widget.listener,
      child: Builder(builder: (context) {
        // We need to make sure the controller logic in _onEdit has access to this scope
        // The _onEdit listener is called when text changes.
        // context in _onEdit is this widget's context.
        // BUT QuestionEntryScope is a child of this widget.
        // So QuestionEntryScope.of(context) will NOT work in _onEdit if we use 'context' of _FreeResponseEntryState.
        // We need to modify the structure or how we access the controller.

        // Better approach: Pass the controller to the methods or use a wrapper.
        // Actually, since this is a StatefulWidget, we can just use the listener directly
        // for the text editing part, OR we can put the TextEditingController
        // inside a child widget that is under the Scope.

        // Let's refactor to put content in a separate widget or use a builder pattern that works.
        // Or simpler: The QuestionEntryController wraps the listener.
        // We can just use the listener directly for logic as before,
        // BUT we want to use the consistency of the Scope.

        // Let's try to grab the controller in the builder and pass it to a callback wrapper.
        // Or cleaner: make _FreeResponseEntryContent widget.

        return QuestionEntryContent(
          question: widget.question,
          controller: controller, // TextEditingController
          borderStyle: borderStyle,
        );
      }),
    );
  }

  @override
  void dispose() {
    controller.removeListener(_onEdit);
    controller.dispose();
    super.dispose();
  }
}

class QuestionEntryContent extends StatelessWidget {
  final FreeResponse question;
  final TextEditingController controller;
  final InputBorder borderStyle;

  const QuestionEntryContent({
    super.key,
    required this.question,
    required this.controller,
    required this.borderStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scopeController = QuestionEntryScope.of(context);

    // We need to hook up the listener here or in the parent?
    // If we hook in parent, we can't access scopeController.
    // So we should add listener here? But TextEditingController is passed in.
    // Use ValueListenableBuilder on text controller?

    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          // This ensures we have the latest text, but we need to trigger updates to scopeController
          // We can do that in onChange of TextField?
          // TextField has onChanged.

          return QuestionEntryCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.small, vertical: AppPadding.tiny),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (question.userCreated) ...[
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    "custom symptom",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor.darken(),
                        ),
                  ),
                ],
                const SizedBox(height: AppPadding.tiny),
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
                    onChanged: (text) {
                      if (text.isEmpty) {
                        scopeController.removeResponse();
                      } else {
                        scopeController.addResponse(OpenResponse(
                          question: question,
                          stamp: scopeController.stamp,
                          response: text,
                        ));
                      }
                    },
                    decoration: InputDecoration(
                        focusedBorder: borderStyle,
                        border: borderStyle,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: AppPadding.tiny)),
                  ),
                ),
                const SizedBox(height: AppPadding.tiny),
              ],
            ),
          );
        });
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
