import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:select_field/select_field.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SymptomTypeManagement extends ConsumerStatefulWidget {
  final String? category;

  const SymptomTypeManagement({required this.category, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SymptomTypeManagementState();
  }
}

class _SymptomTypeManagementState extends ConsumerState<SymptomTypeManagement> {
  bool editing = false;

  @override
  Widget build(BuildContext context) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);

    final AsyncValue<PagesData> pagesData =
        ref.watch(pagesByPath(PagesByPathProps(pathName: widget.category)));

    Widget topRow() {
      return Row(
        children: [
          IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(Routes.SYMPTOMS);
                }
              },
              icon: const Icon(Icons.keyboard_arrow_left)),
          widget.category != null
              ? Text(
                  widget.category!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                )
              : Text(
                  "No Category Provided",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
          const Spacer(),
          if (!editing)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  editing = !editing;
                });
              },
              label: const Text("Edit Layout"),
              icon: const Icon(Icons.edit),
            )
        ],
      );
    }

    Widget createNewCategory() {
      return Center(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Text("Category not created"),
          const SizedBox(
            height: 8.0,
          ),
          FilledButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final QuestionRepo repo =
                    await ref.read(questionsProvider.future);
                final bool added = await repo.addRecordPath(
                  RecordPath(
                      pages: const [],
                      period: null,
                      userCreated: true,
                      name: widget.category!),
                );
                if (!added && context.mounted) {
                  showSnack(context, "Failed to add ${widget.category}");
                }
              },
              label: const Text("Create"))
        ]),
      );
    }

    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(tab: tab)),
        const UserProfileButton(
          selected: true,
        )
      ],
      bottomNav: isSmall ? const SmallLayout() : null,
      child: AsyncValueDefaults(
        value: pagesData,
        onData: (loadedPagesData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 20.0,
              ),
              topRow(),
              const Divider(),
              if (loadedPagesData.loadedLayouts == null &&
                  widget.category != null)
                createNewCategory(),
              if (loadedPagesData.loadedLayouts != null &&
                  widget.category != null)
                Expanded(
                  child: editing
                      ? EditingMode(
                          pagesData: loadedPagesData,
                          setNotEditing: () {
                            if (mounted) {
                              setState(() {
                                editing = false;
                              });
                            }
                          },
                        )
                      : ViewingMode(
                          type: widget.category!,
                          pages: loadedPagesData.loadedLayouts!,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class EditingMode extends ConsumerStatefulWidget {
  final PagesData pagesData;

  final Function setNotEditing;

  const EditingMode(
      {required this.pagesData, required this.setNotEditing, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EditingModeState();
  }
}

class _EditingModeState extends ConsumerState<EditingMode>
    with SingleTickerProviderStateMixin {
  late List<LoadedPageLayout> layouts;

  late final ScrollController scrollController;

  bool isDragging = false;

  double? listHeight;

  @override
  void initState() {
    scrollController = ScrollController();
    layouts = widget.pagesData.loadedLayouts!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildList(),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.topCenter,
                child: DragTarget<Question>(
                  builder:
                      (context, List<Question?> candidateData, rejectedData) =>
                          Container(
                    height: 40.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveUp();
                    return false;
                  },
                ),
              ),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.bottomCenter,
                child: DragTarget<Question>(
                  builder:
                      (context, List<Question?> candidateData, rejectedData) =>
                          Container(
                    height: 20.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveDown();
                    return false;
                  },
                ),
              ),
      ],
    );
  }

  _moveUp() {
    final double height = (listHeight ?? 400);
    final double distanceToTravel = max(scrollController.offset - height,
        scrollController.position.minScrollExtent);
    final int travelInMillis =
        ((distanceToTravel / height) * Durations.long1.inMilliseconds).round();
    if (distanceToTravel == 0 || travelInMillis == 0) return;
    scrollController.animateTo(distanceToTravel,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  _moveDown() {
    final double height = (listHeight ?? 400);
    final double distanceToTravel = min(scrollController.offset + height,
        scrollController.position.maxScrollExtent);
    final int travelInMillis =
        ((distanceToTravel / height) * Durations.long1.inMilliseconds).round();
    if (distanceToTravel == 0 || travelInMillis == 0) return;
    scrollController.animateTo(distanceToTravel,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  Widget _buildDropPreview(BuildContext context, Question? value) {
    return SizedBox(
        height: 60,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
        ));
  }

  Widget _buildList() {
    List<Widget> widgets = [];
    for (int i = 0; i < layouts.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
          child: Text(
            "Page ${i + 1}",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );

      const Widget sep = Divider(
        height: 8.0,
        endIndent: 16.0,
        indent: 16.0,
      );

      final List<Question> pageQuestions = layouts[i].questions;
      for (int j = 0; j < pageQuestions.length; j++) {
        final Question question = pageQuestions[j];
        bool isNeighbor(Question candidate) {
          if (candidate == question) return true;
          if (j + 1 < pageQuestions.length &&
              pageQuestions[j + 1] == question) {
            return true;
          }
          return false;
        }

        widgets.add(
          DragTarget<Question>(
            builder: (context, List<Question?> candidates, rejects) {
              if (candidates.isEmpty || candidates[0] == null) return sep;
              final Question candidate = candidates[0]!;
              return !isNeighbor(candidate)
                  ? _buildDropPreview(context, candidates[0])
                  : sep;
            },
          ),
        );
        widgets.add(_buildSymptom(question));
      }
      widgets.add(
        DragTarget<Question>(
          builder: (context, List<Question?> candidates, rejects) {
            if (candidates.isEmpty || candidates[0] == null) return sep;
            final Question candidate = candidates[0]!;
            return pageQuestions.isEmpty || candidate != pageQuestions.last
                ? _buildDropPreview(context, candidates[0])
                : sep;
          },
        ),
      );

      widgets.add(const Divider());
    }

    return LayoutBuilder(builder: (context, constraints) {
      listHeight = constraints.maxHeight;
      return ListView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.setNotEditing();
                  },
                  child: Text(
                    "Cancel",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              VerticalDivider(
                width: 2.0,
                color: Theme.of(context).dividerColor,
                thickness: 1.5,
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    if (await _save()) {
                      widget.setNotEditing();
                    } else if (context.mounted) {
                      showSnack(context, "Failed to edit layouts");
                    }
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
          const Divider(
            height: 1,
            thickness: 1,
          ),
          ...widgets,
          if (isDragging) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(
                "Page ${layouts.length + 1}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
            DragTarget<Question>(
              builder: (context, List<Question?> candidates, rejects) {
                if (candidates.isEmpty || candidates[0] == null) {
                  return const SizedBox();
                }
                final Question candidate = candidates[0]!;
                return _buildDropPreview(context, candidate);
              },
            ),
          ],
          const SizedBox(
            height: 40,
          ),
        ],
      );
    });
  }

  Widget _symptomDisplay({required Question question}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SymptomInfoDisplay(question: question),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.drag_handle)
        ],
      ),
    );
  }

  Widget _buildSymptom(Question question) {
    return Draggable<Question>(
      maxSimultaneousDrags: 1,
      data: question,
      axis: Axis.vertical,
      hitTestBehavior: HitTestBehavior.translucent,
      feedback: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            border: Border.symmetric(
              horizontal:
                  BorderSide(width: 3.0, color: Theme.of(context).primaryColor),
            ),
          ),
          child: _symptomDisplay(question: question),
        ),
      ),
      onDragStarted: () {
        setState(() {
          isDragging = true;
        });
      },
      onDragEnd: (_) {
        setState(() {
          isDragging = false;
        });
      },
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _symptomDisplay(question: question),
      ),
      child: _symptomDisplay(question: question),
    );
  }

  Future<bool> _save() async {
    final RecordPath path = widget.pagesData.path!;
    final List<PageLayout> newPages =
        layouts.map((layout) => layout.toPageLayout()).toList();
    final QuestionRepo repo = await ref.read(questionsProvider.future);
    return await repo.updateRecordPath(path.copyWith(pages: newPages));
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class ViewingMode extends StatelessWidget {
  final String type;

  final List<LoadedPageLayout> pages;

  const ViewingMode({required this.type, required this.pages, super.key});

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> questionDisplays() {
      List<Widget> displays = [];
      for (final LoadedPageLayout page in pages) {
        displays.addAll([
          ...page.questions
              .map((question) => SymptomDisplay(question: question))
              .separated(
                by: Divider(
                  endIndent: 16.0,
                  indent: 16.0,
                  color: Theme.of(context).disabledColor,
                ),
              ),
          const Divider(
            endIndent: 8.0,
            indent: 8.0,
          ),
        ]);
      }
      return displays..removeLast();
    }

    return SingleChildScrollView(
      key: const PageStorageKey("SymptomScreen"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 6.0,
          ),
          AddSymptomWidget(
            type: type,
          ),
          const Divider(),
          ...questionDisplays(),
        ],
      ),
    );
  }
}

class SymptomDisplay extends ConsumerWidget {
  final Question question;

  const SymptomDisplay({required this.question, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionType type = QuestionType.from(question);

    Iterable<Widget>? added;

    if (type == QuestionType.allThatApply ||
        type == QuestionType.multipleChoice) {
      final List<String> choices = type == QuestionType.allThatApply
          ? (question as AllThatApply).choices
          : (question as MultipleChoice).choices;
      added = choices.map((choice) => Text(choice)).separated(
            by: const SizedBox(
              height: 4.0,
            ),
          );
    } else if (type == QuestionType.slider) {
      final Numeric numeric = question as Numeric;
      final num min = numeric.min ?? 1;
      final num max = numeric.max ?? 5;
      added = [Text("$min - $max")];
    }

    Widget editsRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Switch(
            value: question.enabled,
            onChanged: question.locked
                ? null
                : (_) async {
                    if (!await (await ref.read(questionsProvider.future))
                            .setQuestionEnabled(question, !question.enabled) &&
                        context.mounted) {
                      showSnack(context,
                          "Failed to ${!question.enabled ? "enable" : "disable"} ${question.prompt}");
                    }
                  },
            thumbIcon: question.locked
                ? WidgetStateProperty.all(const Icon(Icons.lock))
                : null,
          ),
          IconButton(
              onPressed: question.userCreated
                  ? () async {
                      if (!await (await ref.read(questionsProvider.future))
                              .removeQuestion(question) &&
                          context.mounted) {
                        showSnack(
                            context, "Failed to delete ${question.prompt}");
                      }
                    }
                  : null,
              icon: const Icon(Icons.delete))
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SymptomInfoDisplay(question: question),
          if (added != null) ...added,
          editsRow(),
        ],
      ),
    );
  }
}

class SymptomInfoDisplay extends StatelessWidget {
  final Question question;
  const SymptomInfoDisplay({required this.question, super.key});

  @override
  Widget build(BuildContext context) {
    final QuestionType type = QuestionType.from(question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
              text: question.prompt,
              style: Theme.of(context).textTheme.titleMedium,
              children: [
                if (question.isRequired)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                if (question.userCreated)
                  TextSpan(
                    text: " · custom symptom",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor.darken()),
                  )
              ]),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          type.value,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).disabledColor.darken()),
        ),
      ],
    );
  }
}

class AddSymptomWidget extends ConsumerStatefulWidget {
  final String type;

  const AddSymptomWidget({required this.type, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AddSymptomWidgetState();
  }
}

class _AddSymptomWidgetState extends ConsumerState<AddSymptomWidget> {
  bool isAdding = false;

  final TextEditingController prompt = TextEditingController();

  final TextEditingController minValue = TextEditingController(text: "1");
  final TextEditingController maxValue = TextEditingController(text: "5");
  List<String> choices = [];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  static const buttonHeight = 60.0;

  bool isLoading = false, submitSuccess = false;

  QuestionType selectedQuestionType = QuestionType.check;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
        child: AnimatedSize(
          duration: Durations.medium1,
          child: Form(
            key: formKey,
            child: Opacity(
              opacity: isLoading ? 0.6 : 1.0,
              child: IgnorePointer(
                ignoring: isLoading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAdding) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            isAdding = false;
                          });
                        },
                        label: const Text("Close"),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      LabeledField(
                        label: "type",
                        child: SelectField<QuestionType>(
                          onOptionSelected: (option) {
                            setState(() {
                              selectedQuestionType = option.value;
                            });
                          },
                          menuDecoration: MenuDecoration(
                            animationDuration: Durations.short4,
                            height: min(
                                buttonHeight * QuestionType.ordered.length,
                                screenHeight / 2),
                            buttonStyle: TextButton.styleFrom(
                              fixedSize:
                                  const Size(double.infinity, buttonHeight),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(16),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                          initialOption: Option<QuestionType>(
                            label: selectedQuestionType.value,
                            value: selectedQuestionType,
                          ),
                          options: QuestionType.ordered
                              .map((option) =>
                                  Option(label: option.value, value: option))
                              .toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      LabeledField(
                        label: "prompt",
                        child: TextFormField(
                          controller: prompt,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a prompt';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      if (selectedQuestionType == QuestionType.slider)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: LabeledField(
                                label: "min",
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: minValue,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a minimum';
                                    }
                                    int? minNum = int.tryParse(value);
                                    int? maxNum = int.tryParse(maxValue.text);
                                    if (minNum == null || maxNum == null) {
                                      return "Must have a range";
                                    }
                                    if (minNum >= maxNum) {
                                      return "Invalid range";
                                    }
                                    return null;
                                  },
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20.0,
                            ),
                            Expanded(
                              child: LabeledField(
                                label: "max",
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: maxValue,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a minimum';
                                    }
                                    int? maxNum = int.tryParse(value);
                                    int? minNum = int.tryParse(minValue.text);
                                    if (minNum == null || maxNum == null) {
                                      return "Must have a range";
                                    }
                                    if (maxNum <= minNum) {
                                      return "Invalid range";
                                    }
                                    return null;
                                  },
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (selectedQuestionType == QuestionType.multipleChoice ||
                          selectedQuestionType == QuestionType.allThatApply)
                        ChoicesFormField(
                          validator: (value) => value == null || value.isEmpty
                              ? "Must have at least one option"
                              : null,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              choices = value;
                            });
                          },
                          initialValue: choices,
                        ),
                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                    FilledButton(
                      onPressed: () async {
                        await add();
                      },
                      child: submitSuccess
                          ? const Icon(Icons.check)
                          : isLoading
                              ? const ButtonLoadingIndicator()
                              : const Text("Add Symptom"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> add() async {
    if (isLoading) return;
    if (!isAdding) {
      setState(() {
        isAdding = true;
      });
      return;
    }

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });
    Question question;
    switch (selectedQuestionType) {
      case QuestionType.check:
        question = Check(
            id: "", prompt: prompt.text, type: widget.type, userCreated: true);
      case QuestionType.freeResponse:
        question = FreeResponse(
            id: "", prompt: prompt.text, type: widget.type, userCreated: true);
      case QuestionType.slider:
        question = Numeric(
            id: "", prompt: prompt.text, type: widget.type, userCreated: true);
      case QuestionType.multipleChoice:
        question = MultipleChoice(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            choices: choices,
            userCreated: true);
      case QuestionType.allThatApply:
        question = AllThatApply(
            id: "",
            prompt: prompt.text,
            type: widget.type,
            choices: choices,
            userCreated: true);
    }
    final bool added =
        await (await ref.read(questionsProvider.future)).addQuestion(question);
    if (added) {
      if (mounted) {
        setState(() {
          submitSuccess = true;
        });
      }
      await Future.delayed(Durations.long4);
      prompt.clear();
      minValue.clear();
      maxValue.clear();
      choices.clear();
      formKey.currentState?.reset();
    } else if (mounted) {
      showSnack(context, "Failed to add question");
    }

    if (mounted) {
      setState(() {
        submitSuccess = false;
        isLoading = false;
      });
    }
  }
}

class ChoicesFormField extends FormField<List<String>> {
  ChoicesFormField({
    super.key,
    super.onSaved,
    super.validator,
    ValueChanged<List<String>?>? onChanged,
    List<String> super.initialValue = const [],
  }) : super(
          builder: (FormFieldState<List<String>> state) {
            final TextEditingController controller = TextEditingController();

            void onChangedHandler(List<String>? value) {
              state.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return UnmanagedRestorationScope(
              bucket: state.bucket,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.value != null)
                    LabeledField(
                      label: "Choice",
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                          ),
                        ),
                        const SizedBox(
                          width: 8.0,
                        ),
                        IconButton(
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                if (state.value != null) {
                                  onChangedHandler(
                                      [controller.text, ...state.value!]);
                                } else {
                                  onChangedHandler([controller.text]);
                                }
                                controller.clear();
                              }
                            },
                            icon: const Icon(Icons.add)),
                      ]),
                    ),
                  ...state.value!
                      .mapIndexed(
                        (index, choice) => ListTile(
                          title: Text(choice),
                          trailing: IconButton(
                            onPressed: () {
                              onChangedHandler(state.value!..removeAt(index));
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      )
                      .separated(by: const Divider()),
                  if (state.hasError) ...[
                    const SizedBox(
                      height: 4.0,
                    ),
                    Text(
                      state.errorText!,
                      style: const TextStyle(fontSize: 15, color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          },
        );
}

class LabeledField extends StatelessWidget {
  final Widget child;
  final String label;

  const LabeledField({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).disabledColor),
          ),
          const SizedBox(
            height: 4.0,
          ),
          child
        ],
      ),
    );
  }
}
