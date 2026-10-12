import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/condition_editor.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class DependencyEditor extends StatefulWidget {
  final DependsOn initialDependency;
  final List<Question> availableQuestions;
  final Function(DependsOn) onSave;
  final String? title;
  final String? description;

  const DependencyEditor({
    required this.initialDependency,
    required this.availableQuestions,
    required this.onSave,
    this.title,
    this.description,
    super.key,
  });

  @override
  State<DependencyEditor> createState() => _DependencyEditorState();
}

class _DependencyEditorState extends State<DependencyEditor> {
  late Condition? _root;
  bool _isValid = true;

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

    final groups = widget.initialDependency.groups;
    final group = groups.length == 1
        ? groups.single
        : ConditionGroup(conditions: groups, op: GroupOp.all);

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
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppPadding.large,
            AppPadding.small,
            AppPadding.large,
            AppPadding.large + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.medium),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? context.translate.visibilityRuleTitle,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                widget.description ??
                    context.translate.visibilityRuleDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppPadding.large),
              Expanded(
                child: SingleChildScrollView(
                  child: ConditionEditor(
                    initialCondition: _root,
                    availableQuestions: widget.availableQuestions,
                    localizations: QuestionsLocalizations.of(context),
                    onValidityChanged: (valid) =>
                        setState(() => _isValid = valid),
                    onChanged: (condition) {
                      setState(() {
                        _root = condition;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.large),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_root != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _root = null);
                        widget.onSave(const DependsOn.nothing());
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: Text(context.translate.alwaysShow),
                    ),
                  const SizedBox(height: AppPadding.small),
                  FilledButton.icon(
                    onPressed: _isValid ? _save : null,
                    icon: const Icon(Icons.check),
                    label: Text(context.translate.saveRule),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        ConditionGroup(conditions: [_root!], op: GroupOp.all),
      ]);
    }
    widget.onSave(dependency);
  }
}
