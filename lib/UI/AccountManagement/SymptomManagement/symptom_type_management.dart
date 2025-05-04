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

    /*final AsyncValue<List<LoadedPageLayout>?> layouts =
        ref.watch(pagesByPath(PagesByPathProps(pathName: widget.category)));*/
    final AsyncLoading<List<LoadedPageLayout>?> layouts = AsyncLoading();

    print(layouts);

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
          TextButton.icon(
            onPressed: () {
              setState(() {
                editing = true;
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
      child: RefreshWidget(
        depth: RefreshDepth.subuser,
        scrollable: AsyncValueDefaults(
          value: layouts,
          onData: (loadedLayouts) {
            return SingleChildScrollView(
              key: const PageStorageKey("SymptomScreen"),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: 20.0,
                    ),
                    topRow(),
                    const SizedBox(
                      height: 6.0,
                    ),
                    if (loadedLayouts == null && widget.category != null)
                      createNewCategory(),
                    if (loadedLayouts != null) ...[
                      const Divider(),
                      AddSymptomWidget(
                        type: widget.category!,
                      ),
                      ...loadedLayouts.mapIndexed((index, page) {
                        return IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (editing)
                                Text(
                                  "Page ${index + 1}",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ...page.questions.map(
                                (question) => SymptomDisplay(
                                  question: question,
                                  editing: editing,
                                ),
                              )
                            ],
                          ),
                        );
                      }).separated(
                          by: const Divider(
                            endIndent: 8.0,
                            indent: 8.0,
                          ),
                          includeEnds: true),
                    ],
                  ]),
            );
          },
        ),
      ),
    );
  }
}

class SymptomDisplay extends ConsumerStatefulWidget {
  final Question question;

  final bool editing;

  const SymptomDisplay(
      {required this.question, required this.editing, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SymptomDisplayState();
  }
}

class _SymptomDisplayState extends ConsumerState<SymptomDisplay> {
  bool requiredHovered = false;
  @override
  Widget build(BuildContext context) {
    final QuestionType type = QuestionType.from(widget.question);

    Iterable<Widget>? added;

    if (type == QuestionType.allThatApply ||
        type == QuestionType.multipleChoice) {
      final List<String> choices = type == QuestionType.allThatApply
          ? (widget.question as AllThatApply).choices
          : (widget.question as MultipleChoice).choices;
      added = choices.map((choice) => Text(choice)).separated(
            by: const SizedBox(
              height: 4.0,
            ),
          );
    } else if (type == QuestionType.slider) {
      final Numeric numeric = widget.question as Numeric;
      final num min = numeric.min ?? 1;
      final num max = numeric.max ?? 5;
      added = [Text("$min - $max")];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
                text: widget.question.prompt,
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  if (widget.question.isRequired)
                    TextSpan(
                      text: '${requiredHovered ? "required" : ""}*',
                      onEnter: (_) {
                        setState(() {
                          requiredHovered = true;
                        });
                      },
                      onExit: (_) async {
                        Future.delayed(Durations.medium4).then((_) {
                          if (mounted) {
                            setState(() {
                              requiredHovered = false;
                            });
                          }
                        });
                      },
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (widget.question.userCreated)
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
          if (added != null && !widget.editing) ...added,
          if (!widget.editing)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: widget.question.enabled,
                  onChanged: widget.question.isRequired
                      ? null
                      : (_) async {
                          if (!await (await ref.read(questionsProvider.future))
                                  .setQuestionEnabled(widget.question,
                                      !widget.question.enabled) &&
                              context.mounted) {
                            showSnack(context,
                                "Failed to ${!widget.question.enabled ? "enable" : "disable"} ${widget.question.prompt}");
                          }
                        },
                  thumbIcon: widget.question.isRequired
                      ? WidgetStateProperty.all(const Icon(Icons.lock))
                      : null,
                ),
                IconButton(
                    onPressed: widget.question.userCreated
                        ? () async {
                            if (!await (await ref
                                        .read(questionsProvider.future))
                                    .removeQuestion(widget.question) &&
                                context.mounted) {
                              showSnack(context,
                                  "Failed to delete ${widget.question.prompt}");
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete))
              ],
            ),
        ],
      ),
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
