import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/condition_editor.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

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
  late Condition? _root;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.initialDependency.groups.isEmpty) {
      _root = null;
      return;
    }

    // Load the first group as the root
    final group = widget.initialDependency.groups.first;

    // If it's a single condition and the group is implicit (just wrapper),
    // we might want to unwrap it, but DependsOn always expects groups.
    // For editing purposes, we treat the content of the first group as our root condition logic.
    if (group.conditions.length == 1 &&
        group.conditions.first is! ConditionGroup) {
      _root = group.conditions.first;
    } else {
      _root = group;
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
          ConditionEditor(
            initialCondition: _root,
            availableQuestions: widget.availableQuestions,
            localizations: QuestionsLocalizations.of(context),
            onChanged: (condition) {
              setState(() {
                _root = condition;
              });
            },
          ),
          const SizedBox(height: AppPadding.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_root != null)
                TextButton(
                  onPressed: () {
                    setState(() => _root = null);
                    widget.onSave(const DependsOn.nothing());
                  },
                  child: const Text("Clear"),
                ),
              const SizedBox(width: AppPadding.small),
              FilledButton(
                onPressed: _save,
                child: const Text("Save Rules"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_root == null) {
      widget.onSave(const DependsOn.nothing());
      return;
    }

    final DependsOn dependency;
    if (_root is ConditionGroup) {
      dependency = DependsOn([_root as ConditionGroup]);
    } else {
      // Wrap single condition in a group
      dependency = DependsOn([
        ConditionGroup(
          conditions: [_root!],
          op: GroupOp.all,
        ),
      ]);
    }
    widget.onSave(dependency);
  }
}
