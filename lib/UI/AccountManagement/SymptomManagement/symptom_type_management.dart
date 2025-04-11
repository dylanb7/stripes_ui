import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:select_field/select_field.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SymptomTypeManagement extends ConsumerWidget {
  final String? category;

  const SymptomTypeManagement({required this.category, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);
    final AsyncValue<Map<String, List<Question>>> questions =
        ref.watch(questionsByType(context));

    Widget loaded(Map<String, List<Question>> questions) {
      final List<Question>? ofCategory =
          category != null ? questions[category] : null;

      return RefreshWidget(
        depth: RefreshDepth.subuser,
        scrollable: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      context.goNamed(Routes.SYMPTOMS);
                    },
                    icon: const Icon(Icons.keyboard_arrow_left)),
                category != null
                    ? Text(
                        category!,
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
              ],
            ),
            const SizedBox(
              height: 6.0,
            ),
            if (ofCategory == null)
              Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Category not created"),
                      const SizedBox(
                        height: 8.0,
                      ),
                      FilledButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                          label: const Text("Create"))
                    ]),
              ),
            if (ofCategory != null) ...[
              const Divider(),
              const AddSymptomWidget(),
              ...ofCategory
                  .map(
                    (question) => ListTile(
                      title: Text(question.prompt),
                    ),
                  )
                  .separated(
                      by: const Divider(
                        endIndent: 8.0,
                        indent: 8.0,
                      ),
                      includeEnds: true),
            ],
          ]),
        ),
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
        child: questions.map(
            data: (data) => loaded(data.value),
            loading: (_) => const LoadingWidget(),
            error: (error) => Center(
                  child: Text("Error: ${error.error.toString()}"),
                )));
  }
}

class AddSymptomWidget extends ConsumerStatefulWidget {
  const AddSymptomWidget({super.key});

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const List<String> options = [
    "Check",
    "Free Response",
    "Slider",
    "Multiple Choice",
    "All That Apply"
  ];

  static const buttonHeight = 60.0;

  String selectedQuestionType = options[0];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
        child: AnimatedSize(
          duration: Durations.medium1,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isAdding) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SelectField<String>(
                          onOptionSelected: (option) {
                            setState(() {
                              selectedQuestionType = option.value;
                            });
                          },
                          menuDecoration: MenuDecoration(
                            animationDuration: Durations.short4,
                            height: min(buttonHeight * options.length,
                                screenHeight / 2),
                            buttonStyle: TextButton.styleFrom(
                              fixedSize:
                                  const Size(double.infinity, buttonHeight),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(16),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                          initialOption: Option<String>(
                            label: selectedQuestionType,
                            value: selectedQuestionType,
                          ),
                          options: options
                              .map((option) =>
                                  Option(label: option, value: option))
                              .toList(),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              isAdding = false;
                            });
                          },
                          icon: const Icon(Icons.close))
                    ],
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  LabeledField(
                    label: "Prompt",
                    child: TextFormField(
                      controller: prompt,
                      decoration: const InputDecoration(hintText: "Prompt"),
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
                  if (selectedQuestionType == "Slider")
                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: LabeledField(
                              label: "Min",
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
                            width: 8.0,
                          ),
                          Expanded(
                            child: LabeledField(
                              label: "Max",
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: maxValue,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a minimum';
                                  }
                                  int? minNum = int.tryParse(value);
                                  int? maxNum = int.tryParse(maxValue.text);
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
                    ),
                  const SizedBox(
                    height: 16.0,
                  ),
                ],
                FilledButton.icon(
                  onPressed: () {
                    if (!isAdding) {
                      setState(() {
                        isAdding = true;
                      });
                    } else {
                      if (_formKey.currentState!.validate()) {}
                    }
                  },
                  label:
                      isAdding ? const Text("Add") : const Text("Add Symptom"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChoicesFormField extends FormField<List<String>> {
  ChoicesFormField({
    super.key,
    required FormFieldSetter<List<String>> onSaved,
    required FormFieldValidator<List<String>> validator,
    List<String> initialValue = const [],
  }) : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            builder: (FormFieldState<List<String>> state) {
              return Column(
                children: [],
              );
            });
}

enum InputType {
  string,
  number;
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
          child
        ],
      ),
    );
  }
}
