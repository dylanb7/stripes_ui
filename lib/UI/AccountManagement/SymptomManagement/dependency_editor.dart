import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Util/paddings.dart';

class DependencyEditor extends StatefulWidget {
  final DependsOn initialDependency;
  final List<Question> availableQuestions;
  final Function(DependsOn) onSave;

  const DependencyEditor({
    required this.initialDependency,
    required this.availableQuestions,
    required this.onSave,
    super.key,
  });

  @override
  State<DependencyEditor> createState() => _DependencyEditorState();
}

class _DependencyEditorState extends State<DependencyEditor> {
  late Op _matchStrategy;
  final List<_Condition> _conditions = [];

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.initialDependency.operations.isNotEmpty) {
      final op = widget.initialDependency.operations.first;
      _matchStrategy = op.op;
      for (final rel in op.relations) {
        try {
          final question =
              widget.availableQuestions.firstWhere((q) => q.id == rel.qid);
          _conditions.add(_Condition(question: question, relation: rel));
        } catch (e) {
          // Question might have been deleted
        }
      }
    } else {
      _matchStrategy = Op.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Visibility Rules",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppPadding.medium),
          if (_conditions.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRounding.small),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppPadding.medium),
                  Expanded(
                    child: Text(
                      "This page is always visible.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text.rich(
              TextSpan(
                text: "Show this page when ",
                children: [
                  TextSpan(
                    text: _matchStrategy == Op.all ? "ALL" : "ANY",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " of the following are true:"),
                ],
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppPadding.small),
            _buildMatchStrategySelector(),
            const SizedBox(height: AppPadding.medium),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _conditions.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _matchStrategy == Op.all ? "AND" : "OR",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, index) {
                return _ConditionRow(
                  condition: _conditions[index],
                  availableQuestions: widget.availableQuestions,
                  onRemove: () {
                    setState(() {
                      _conditions.removeAt(index);
                    });
                  },
                  onUpdate: (newCondition) {
                    setState(() {
                      _conditions[index] = newCondition;
                    });
                  },
                );
              },
            ),
          ],
          const SizedBox(height: AppPadding.medium),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _conditions.add(_Condition());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Rule"),
          ),
          const SizedBox(height: AppPadding.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _conditions.clear();
                    _matchStrategy = Op.all;
                  });
                  widget.onSave(const DependsOn.nothing());
                },
                child: const Text("Clear All"),
              ),
              const SizedBox(width: AppPadding.small),
              FilledButton(
                onPressed: _isValid() ? _save : null,
                child: const Text("Save Rules"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStrategySelector() {
    return SegmentedButton<Op>(
      segments: const [
        ButtonSegment(
          value: Op.all,
          label: Text("Require All"),
          icon: Icon(Icons.playlist_add_check),
        ),
        ButtonSegment(
          value: Op.one,
          label: Text("Require Any"),
          icon: Icon(Icons.playlist_play),
        ),
      ],
      selected: {_matchStrategy},
      onSelectionChanged: (Set<Op> newSelection) {
        setState(() {
          _matchStrategy = newSelection.first;
        });
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  bool _isValid() {
    if (_conditions.isEmpty) return true; // Empty means always visible
    return _conditions.every((c) => c.isValid);
  }

  void _save() {
    if (_conditions.isEmpty) {
      widget.onSave(const DependsOn.nothing());
      return;
    }

    final relations = _conditions.map((c) => c.toRelation()).toList();
    final dependency = DependsOn([
      RelationOp(relations: relations, op: _matchStrategy),
    ]);
    widget.onSave(dependency);
  }
}

class _Condition {
  Question? question;
  dynamic response;
  Relation? relation;

  _Condition({this.question, this.relation}) {
    if (relation != null) {
      response = relation!.response;
    } else if (question != null && question is Check) {}
  }

  bool get isValid {
    if (question == null) return false;
    if (question is Check) return true;
    return response != null;
  }

  Relation toRelation() {
    if (question is Check || response == null) {
      return Relation.exists(qid: question!.id);
    }
    return Relation(
      qid: question!.id,
      questionType: QuestionType.from(question!),
      response: response,
      type: CheckType.equals,
    );
  }
}

class _ConditionRow extends StatefulWidget {
  final _Condition condition;
  final List<Question> availableQuestions;
  final VoidCallback onRemove;
  final ValueChanged<_Condition> onUpdate;

  const _ConditionRow({
    required this.condition,
    required this.availableQuestions,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_ConditionRow> createState() => _ConditionRowState();
}

class _ConditionRowState extends State<_ConditionRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Question>(
                  initialValue: widget.condition.question,
                  decoration: const InputDecoration(
                      labelText: "Question",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                  items: widget.availableQuestions.map((q) {
                    return DropdownMenuItem(
                      value: q,
                      child: Text(
                        q.prompt,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (Question? value) {
                    setState(() {
                      widget.condition.question = value;
                      widget.condition.response = null;
                      widget.onUpdate(widget.condition);
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          if (widget.condition.question != null) ...[
            const SizedBox(height: AppPadding.small),
            _buildResponseEditor(),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseEditor() {
    final question = widget.condition.question!;

    if (question is Check) {
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
            Expanded(
              child: Text(
                "Is Checked",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    } else if (question is MultipleChoice) {
      final choices = question.choices;
      // Map index to choice string for display if response is int
      String? initialValue;
      if (widget.condition.response is int) {
        final index = widget.condition.response as int;
        if (index >= 0 && index < choices.length) {
          initialValue = choices[index];
        }
      }

      return DropdownButtonFormField<String>(
        initialValue: initialValue,
        decoration: const InputDecoration(
            labelText: "Answer is",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
        items: choices.map((c) {
          return DropdownMenuItem(value: c, child: Text(c));
        }).toList(),
        onChanged: (val) {
          setState(() {
            widget.condition.response = choices.indexOf(val!);
            widget.onUpdate(widget.condition);
          });
        },
      );
    } else if (question is Numeric) {
      return TextFormField(
        initialValue: widget.condition.response?.toString(),
        decoration: const InputDecoration(
            labelText: "Value equals",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          setState(() {
            widget.condition.response = int.tryParse(val);
            widget.onUpdate(widget.condition);
          });
        },
      );
    } else if (question is FreeResponse) {
      return TextFormField(
        initialValue: widget.condition.response?.toString(),
        decoration: const InputDecoration(
            labelText: "Text equals",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
        onChanged: (val) {
          setState(() {
            widget.condition.response = val;
            widget.onUpdate(widget.condition);
          });
        },
      );
    } else if (question is AllThatApply) {
      List<int> currentSelection = [];
      if (widget.condition.response is List) {
        currentSelection =
            (widget.condition.response as List).map((e) => e as int).toList();
      }

      final choices = question.choices;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Must match exactly:"),
          Wrap(
            spacing: 8.0,
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
                    // Sort for consistency
                    currentSelection.sort();
                    widget.condition.response =
                        List<int>.from(currentSelection);
                    widget.onUpdate(widget.condition);
                  });
                },
              );
            }),
          ),
        ],
      );
    }

    return const Text("Unsupported question type");
  }
}
