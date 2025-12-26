import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

enum ConditionType {
  exists('Has Response'),
  equals('Equals'),
  containsIndex('Contains Selection'),
  containsText('Contains Text');

  final String label;
  const ConditionType(this.label);
}

class ConditionEditor extends StatefulWidget {
  final Condition? initialCondition;
  final List<Question> availableQuestions;
  final Function(Condition?) onChanged;
  final QuestionsLocalizations? localizations;

  const ConditionEditor({
    required this.initialCondition,
    required this.availableQuestions,
    required this.onChanged,
    this.localizations,
    super.key,
  });

  @override
  State<ConditionEditor> createState() => _ConditionEditorState();
}

class _ConditionEditorState extends State<ConditionEditor> {
  _EditableNode? _root;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.initialCondition == null) {
      _root = null;
      return;
    }
    _root = _EditableNode.fromCondition(
      widget.initialCondition!,
      widget.availableQuestions,
    );
  }

  void _notifyChanged() {
    if (_root == null) {
      widget.onChanged(null);
      return;
    }
    if (_root!.isValid) {
      widget.onChanged(_root!.toCondition());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_root == null)
          _buildEmptyState(context)
        else
          _NodeWidget(
            node: _root!,
            availableQuestions: widget.availableQuestions,
            localizations: widget.localizations,
            isRoot: true,
            onRemove: () {
              setState(() => _root = null);
              _notifyChanged();
            },
            onUpdate: () {
              setState(() {});
              _notifyChanged();
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRounding.small),
          ),
          child: Row(
            children: [
              Icon(Icons.rule_folder_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Text(
                  "No rules defined.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.medium),
        Text(
          "Add a rule:",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppPadding.small),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _root = _EditableNode.condition();
                });
                _notifyChanged();
              },
              icon: const Icon(Icons.rule),
              label: const Text("Single Condition"),
            ),
            const SizedBox(width: AppPadding.small),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _root = _EditableNode.group();
                });
                _notifyChanged();
              },
              icon: const Icon(Icons.folder_open),
              label: const Text("Condition Group"),
            ),
          ],
        ),
      ],
    );
  }
}

/// A node in the editable tree - either a leaf condition or a nested group
class _EditableNode {
  bool isGroup;
  GroupOp groupOp;
  List<_EditableNode> children;

  // For leaf conditions
  Question? question;
  ConditionType type;
  dynamic value;

  _EditableNode({
    this.isGroup = false,
    this.groupOp = GroupOp.all,
    List<_EditableNode>? children,
    this.question,
    this.type = ConditionType.exists,
    this.value,
  }) : children = children ?? [];

  factory _EditableNode.condition() => _EditableNode(isGroup: false);

  factory _EditableNode.group() =>
      _EditableNode(isGroup: true, groupOp: GroupOp.all, children: []);

  static _EditableNode fromCondition(
    Condition condition,
    List<Question> availableQuestions,
  ) {
    Question? findQuestion(String? qid) {
      if (qid == null) return null;
      try {
        return availableQuestions.firstWhere((q) => q.id == qid);
      } catch (e) {
        return null;
      }
    }

    if (condition is ConditionGroup) {
      return _EditableNode(
        isGroup: true,
        groupOp: condition.op,
        children: condition.conditions
            .map((c) => fromCondition(c, availableQuestions))
            .toList(),
      );
    }

    return switch (condition) {
      ExistsCondition c => _EditableNode(
          question: findQuestion(c.questionId),
          type: ConditionType.exists,
        ),
      EqualsExact c => _EditableNode(
          question: findQuestion(c.questionId),
          type: ConditionType.equals,
          value: c.expected,
        ),
      ContainsIndex c => _EditableNode(
          question: findQuestion(c.questionId),
          type: ConditionType.containsIndex,
          value: c.index,
        ),
      ContainsText c => _EditableNode(
          question: findQuestion(c.questionId),
          type: ConditionType.containsText,
          value: c.text,
        ),
      ConditionGroup c => _EditableNode(
          isGroup: true,
          groupOp: c.op,
          children: c.conditions
              .map((cc) => fromCondition(cc, availableQuestions))
              .toList(),
        ),
      MatchesRegex() => throw UnimplementedError(),
    };
  }

  bool get isValid {
    if (isGroup) {
      return children.isNotEmpty && children.every((c) => c.isValid);
    }
    if (question == null) return false;
    return switch (type) {
      ConditionType.exists => true,
      ConditionType.equals => value != null,
      ConditionType.containsIndex => value is int,
      ConditionType.containsText => value is String && value.isNotEmpty,
    };
  }

  Condition toCondition() {
    if (isGroup) {
      return ConditionGroup(
        conditions: children.map((c) => c.toCondition()).toList(),
        op: groupOp,
      );
    }

    final qid = question!.id;
    return switch (type) {
      ConditionType.exists => ExistsCondition(qid),
      ConditionType.equals => EqualsExact(qid, value),
      ConditionType.containsIndex => ContainsIndex(qid, value as int),
      ConditionType.containsText => ContainsText(qid, value as String),
    };
  }

  List<ConditionType> getValidTypes() {
    if (question == null) return [ConditionType.exists];

    final questionType = QuestionType.from(question!);
    final validTypes = <ConditionType>[ConditionType.exists];

    if (EqualsExact.validFor.contains(questionType)) {
      validTypes.add(ConditionType.equals);
    }
    if (ContainsIndex.validFor.contains(questionType)) {
      validTypes.add(ConditionType.containsIndex);
    }
    if (ContainsText.validFor.contains(questionType)) {
      validTypes.add(ConditionType.containsText);
    }

    return validTypes;
  }
}

class _NodeWidget extends StatefulWidget {
  final _EditableNode node;
  final List<Question> availableQuestions;
  final QuestionsLocalizations? localizations;
  final bool isRoot;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const _NodeWidget({
    required this.node,
    required this.availableQuestions,
    required this.localizations,
    required this.isRoot,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  String _getLocalizedPrompt(Question q) {
    if (widget.localizations == null) return q.prompt;
    return widget.localizations!.translateQuestion(q).prompt;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.isGroup) {
      return _buildGroupWidget(context);
    }
    return _buildConditionWidget(context);
  }

  Widget _buildGroupWidget(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRounding.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRounding.small - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: borderColor, size: 20),
                const SizedBox(width: AppPadding.small),
                Text("Match ", style: Theme.of(context).textTheme.bodyMedium),
                DropdownButton<GroupOp>(
                  value: widget.node.groupOp,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: GroupOp.all,
                      child: Text("ALL",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: GroupOp.one,
                      child: Text("ANY",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => widget.node.groupOp = value);
                      widget.onUpdate();
                    }
                  },
                ),
                Text(" of:", style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                  tooltip: "Remove group",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppPadding.small),
            child: Column(
              children: [
                ...widget.node.children.asMap().entries.map((entry) {
                  return Column(
                    children: [
                      if (entry.key > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppPadding.tiny),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.tiny,
                                vertical: AppPadding.tiny),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRounding.tiny),
                            ),
                            child: Text(
                              widget.node.groupOp == GroupOp.all ? "AND" : "OR",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: borderColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      _NodeWidget(
                        node: entry.value,
                        availableQuestions: widget.availableQuestions,
                        localizations: widget.localizations,
                        isRoot: false,
                        onRemove: () {
                          setState(() {
                            widget.node.children.removeAt(entry.key);
                          });
                          widget.onUpdate();
                        },
                        onUpdate: () {
                          setState(() {});
                          widget.onUpdate();
                        },
                      ),
                    ],
                  );
                }),
                const SizedBox(height: AppPadding.small),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          widget.node.children.add(_EditableNode.condition());
                        });
                        widget.onUpdate();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Condition"),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          widget.node.children.add(_EditableNode.group());
                        });
                        widget.onUpdate();
                      },
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text("Nested Group"),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionWidget(BuildContext context) {
    final validTypes = widget.node.getValidTypes();

    // Find matching question from items list by ID to avoid reference mismatch
    Question? selectedQuestion;
    if (widget.node.question != null) {
      try {
        selectedQuestion = widget.availableQuestions
            .firstWhere((q) => q.id == widget.node.question!.id);
      } catch (e) {
        // Question not in list
        selectedQuestion = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppPadding.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Question>(
                  initialValue: selectedQuestion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Question",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppPadding.small, vertical: 0),
                  ),
                  selectedItemBuilder: (context) {
                    return widget.availableQuestions.map((q) {
                      return Text(
                        _getLocalizedPrompt(q),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                  items: widget.availableQuestions.map((q) {
                    return DropdownMenuItem(
                      value: q,
                      child: Text(
                        _getLocalizedPrompt(q),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    );
                  }).toList(),
                  onChanged: (Question? value) {
                    setState(() {
                      widget.node.question = value;
                      widget.node.value = null;
                      final newValidTypes = widget.node.getValidTypes();
                      if (!newValidTypes.contains(widget.node.type)) {
                        widget.node.type = ConditionType.exists;
                      }
                    });
                    widget.onUpdate();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onRemove,
                tooltip: "Remove condition",
              ),
            ],
          ),
          if (widget.node.question != null) ...[
            const SizedBox(height: AppPadding.small),
            // Only show condition type dropdown if there are multiple options
            if (validTypes.length > 1) ...[
              DropdownButtonFormField<ConditionType>(
                initialValue: widget.node.type,
                decoration: const InputDecoration(
                  labelText: "Condition",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppPadding.small, vertical: 0),
                ),
                items: validTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.label));
                }).toList(),
                onChanged: (ConditionType? value) {
                  if (value == null) return;
                  setState(() {
                    widget.node.type = value;
                    widget.node.value = null;
                  });
                  widget.onUpdate();
                },
              ),
              const SizedBox(height: AppPadding.small),
            ],
            _buildValueEditor(),
          ],
        ],
      ),
    );
  }

  Widget _buildValueEditor() {
    final question = widget.node.question!;
    final type = widget.node.type;

    if (type == ConditionType.exists) {
      return Container(
        padding: const EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppPadding.medium),
            Text("Has any response",
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (type == ConditionType.containsText) {
      return TextFormField(
        initialValue: widget.node.value?.toString(),
        decoration: const InputDecoration(
          labelText: "Contains text",
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: 0),
        ),
        onChanged: (val) {
          setState(() => widget.node.value = val);
          widget.onUpdate();
        },
      );
    }

    if (question is MultipleChoice) {
      return _buildMultipleChoiceEditor(question);
    } else if (question is AllThatApply) {
      return _buildAllThatApplyEditor(question);
    } else if (question is Numeric) {
      return _buildNumericEditor();
    } else if (question is FreeResponse) {
      return _buildFreeResponseEditor();
    } else if (question is Check) {
      return Container(
        padding: const EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        child: Row(
          children: [
            Icon(Icons.check_box, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppPadding.medium),
            Text("Is Checked", style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return const Text("Unsupported question type");
  }

  Widget _buildMultipleChoiceEditor(MultipleChoice question) {
    final choices = question.choices;
    String? initialValue;
    if (widget.node.value is int) {
      final index = widget.node.value as int;
      if (index >= 0 && index < choices.length) {
        initialValue = choices[index];
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: "Answer is",
        border: OutlineInputBorder(),
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: 0),
      ),
      items: choices.map((c) {
        return DropdownMenuItem(value: c, child: Text(c));
      }).toList(),
      onChanged: (val) {
        setState(() => widget.node.value = choices.indexOf(val!));
        widget.onUpdate();
      },
    );
  }

  Widget _buildAllThatApplyEditor(AllThatApply question) {
    final type = widget.node.type;
    final choices = question.choices;

    if (type == ConditionType.containsIndex) {
      int? currentIndex =
          widget.node.value is int ? widget.node.value as int : null;
      String? currentChoice = currentIndex != null &&
              currentIndex >= 0 &&
              currentIndex < choices.length
          ? choices[currentIndex]
          : null;

      return DropdownButtonFormField<String>(
        initialValue: currentChoice,
        decoration: const InputDecoration(
          labelText: "Contains selection",
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: 0),
        ),
        items: choices.map((c) {
          return DropdownMenuItem(value: c, child: Text(c));
        }).toList(),
        onChanged: (val) {
          setState(() => widget.node.value = choices.indexOf(val!));
          widget.onUpdate();
        },
      );
    }

    List<int> currentSelection = [];
    if (widget.node.value is List) {
      currentSelection =
          (widget.node.value as List).map((e) => e as int).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Must match exactly:"),
        Wrap(
          spacing: AppPadding.small,
          children: List.generate(choices.length, (index) {
            final isSelected = currentSelection.contains(index);
            return FilterChip(
              label: Text(choices[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    currentSelection.add(index);
                  } else {
                    currentSelection.remove(index);
                  }
                  currentSelection.sort();
                  widget.node.value = List<int>.from(currentSelection);
                });
                widget.onUpdate();
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumericEditor() {
    return TextFormField(
      initialValue: widget.node.value?.toString(),
      decoration: const InputDecoration(
        labelText: "Value equals",
        border: OutlineInputBorder(),
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: 0),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        setState(() => widget.node.value = int.tryParse(val));
        widget.onUpdate();
      },
    );
  }

  Widget _buildFreeResponseEditor() {
    return const Text("Free response matching not supported yet");
  }
}
