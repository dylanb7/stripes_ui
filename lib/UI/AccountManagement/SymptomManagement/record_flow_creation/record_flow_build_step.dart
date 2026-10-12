import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_creation_presentation.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_draft.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

typedef SectionLabelBuilder = String Function(
  DraftRecordFlowSection section,
  int index,
);
typedef SectionIndexedCallback = void Function(
  DraftRecordFlowSection section,
  int index,
);
typedef MoveSectionCallback = void Function(int from, int to);
typedef ReorderQuestionCallback = void Function(
  DraftRecordFlowSection section,
  int from,
  int to,
);
typedef MoveQuestionCallback = void Function(
  Question question,
  DraftRecordFlowSection source,
  String targetId,
);
typedef DeleteQuestionCallback = void Function(
  DraftRecordFlowSection section,
  int questionIndex,
);

class RecordFlowBuildStep extends StatelessWidget {
  final String? flowName;
  final VoidCallback? onPreview;
  final List<DraftRecordFlowSection> sections;
  final SectionLabelBuilder sectionLabel;
  final String Function(DraftRecordFlowSection section) sectionRuleSummary;
  final VoidCallback onAddSection;
  final ValueChanged<String> onAddQuestion;
  final SectionIndexedCallback onRenameSection;
  final SectionIndexedCallback onEditSectionDependency;
  final MoveSectionCallback onMoveSection;
  final ValueChanged<DraftRecordFlowSection> onRemoveSection;
  final ReorderQuestionCallback onReorderQuestion;
  final MoveQuestionCallback onMoveQuestion;
  final DeleteQuestionCallback onDeleteQuestion;
  final ValueChanged<Question>? onEditQuestion;

  const RecordFlowBuildStep({
    this.flowName,
    this.onPreview,
    required this.sections,
    required this.sectionLabel,
    required this.sectionRuleSummary,
    required this.onAddSection,
    required this.onAddQuestion,
    required this.onRenameSection,
    required this.onEditSectionDependency,
    required this.onMoveSection,
    required this.onRemoveSection,
    required this.onReorderQuestion,
    required this.onMoveQuestion,
    required this.onDeleteQuestion,
    this.onEditQuestion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppPadding.large),
      children: [
        Text(
          context.translate.flowBuilderHelp,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppPadding.small),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppPadding.small,
          children: [
            Text(
              '${context.translate.questionsCount(sections.fold<int>(0, (n, s) => n + s.questions.length))} · ${context.translate.sectionsCount(sections.length)}',
            ),
            if (onPreview != null)
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(context.translate.previewFlow),
              ),
          ],
        ),
        const SizedBox(height: AppPadding.small),
        ...sections.indexed.map(
          (entry) => DraftRecordFlowSectionCard(
            section: entry.$2,
            sectionIndex: entry.$1,
            sections: sections,
            sectionLabel: sectionLabel,
            sectionRuleSummary: sectionRuleSummary,
            onAddQuestion: onAddQuestion,
            onRenameSection: onRenameSection,
            onEditSectionDependency: onEditSectionDependency,
            onMoveSection: onMoveSection,
            onRemoveSection: onRemoveSection,
            onReorderQuestion: onReorderQuestion,
            onMoveQuestion: onMoveQuestion,
            onDeleteQuestion: onDeleteQuestion,
            onEditQuestion: onEditQuestion,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddSection,
          icon: const Icon(Icons.add),
          label: Text(context.translate.addSection),
        ),
        const SizedBox(height: AppPadding.xxl),
      ],
    );
  }
}

class DraftRecordFlowSectionCard extends StatelessWidget {
  final DraftRecordFlowSection section;
  final int sectionIndex;
  final List<DraftRecordFlowSection> sections;
  final SectionLabelBuilder sectionLabel;
  final String Function(DraftRecordFlowSection section) sectionRuleSummary;
  final ValueChanged<String> onAddQuestion;
  final SectionIndexedCallback onRenameSection;
  final SectionIndexedCallback onEditSectionDependency;
  final MoveSectionCallback onMoveSection;
  final ValueChanged<DraftRecordFlowSection> onRemoveSection;
  final ReorderQuestionCallback onReorderQuestion;
  final MoveQuestionCallback onMoveQuestion;
  final DeleteQuestionCallback onDeleteQuestion;
  final ValueChanged<Question>? onEditQuestion;

  const DraftRecordFlowSectionCard({
    required this.section,
    required this.sectionIndex,
    required this.sections,
    required this.sectionLabel,
    required this.sectionRuleSummary,
    required this.onAddQuestion,
    required this.onRenameSection,
    required this.onEditSectionDependency,
    required this.onMoveSection,
    required this.onRemoveSection,
    required this.onReorderQuestion,
    required this.onMoveQuestion,
    required this.onDeleteQuestion,
    this.onEditQuestion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            section: section,
            label: sectionLabel(section, sectionIndex),
            onRename: () => onRenameSection(section, sectionIndex),
            onMoveUp: sectionIndex == 0
                ? null
                : () => onMoveSection(sectionIndex, sectionIndex - 1),
            onMoveDown: sectionIndex == sections.length - 1
                ? null
                : () => onMoveSection(sectionIndex, sectionIndex + 1),
            onRemove: sections.length > 1 && section.questions.isEmpty
                ? () => onRemoveSection(section)
                : null,
          ),
          Divider(height: 1, color: colors.outline),
          if (sectionIndex > 0) ...[
            ListTile(
              leading: Icon(
                section.dependsOn.groups.isEmpty
                    ? Icons.visibility_outlined
                    : Icons.rule_outlined,
                color: colors.primary,
              ),
              title: Text(
                section.dependsOn.groups.isEmpty
                    ? context.translate.addRule
                    : context.translate.editRule,
              ),
              subtitle: Text(
                sections.take(sectionIndex).any((s) => s.questions.isNotEmpty)
                    ? sectionRuleSummary(section)
                    : context.translate.ruleNeedsEarlierQuestion,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  sections.take(sectionIndex).any((s) => s.questions.isNotEmpty)
                  ? () => onEditSectionDependency(section, sectionIndex)
                  : null,
            ),
            Divider(height: 1, color: colors.outlineVariant),
          ],
          if (section.questions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Text(
                context.translate.sectionEmptyDescription,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          else
            Column(
              children: section.questions.indexed
                  .map(
                    (entry) => DraftRecordFlowQuestionTile(
                      key: ValueKey(entry.$2.id),
                      question: entry.$2,
                      questionIndex: entry.$1,
                      section: section,
                      sections: sections,
                      sectionLabel: sectionLabel,
                      onReorderQuestion: onReorderQuestion,
                      onMoveQuestion: onMoveQuestion,
                      onDeleteQuestion: onDeleteQuestion,
                      onEditQuestion: onEditQuestion,
                    ),
                  )
                  .toList(),
            ),
          Padding(
            padding: const EdgeInsets.all(AppPadding.small),
            child: OutlinedButton.icon(
              onPressed: () => onAddQuestion(section.id),
              icon: const Icon(Icons.add),
              label: Text(context.translate.addQuestionToSection),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final DraftRecordFlowSection section;
  final String label;
  final VoidCallback onRename;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;

  const _SectionHeader({
    required this.section,
    required this.label,
    required this.onRename,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.primaryContainer.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(
        AppPadding.medium,
        AppPadding.small,
        AppPadding.tiny,
        AppPadding.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  context.translate.questionsCount(section.questions.length),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.translate.renameSection,
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined),
          ),
          if (onMoveUp != null || onMoveDown != null || onRemove != null)
            PopupMenuButton<VoidCallback>(
              tooltip: context.translate.reorderAndGroup,
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                if (onMoveUp != null)
                  PopupMenuItem(
                    value: onMoveUp,
                    child: Text(context.translate.moveSectionUp),
                  ),
                if (onMoveDown != null)
                  PopupMenuItem(
                    value: onMoveDown,
                    child: Text(context.translate.moveSectionDown),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: onRemove,
                    child: Text(context.translate.removeEmptySection),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class DraftRecordFlowQuestionTile extends StatelessWidget {
  final Question question;
  final int questionIndex;
  final DraftRecordFlowSection section;
  final List<DraftRecordFlowSection> sections;
  final SectionLabelBuilder sectionLabel;
  final ReorderQuestionCallback onReorderQuestion;
  final MoveQuestionCallback onMoveQuestion;
  final DeleteQuestionCallback onDeleteQuestion;
  final ValueChanged<Question>? onEditQuestion;

  const DraftRecordFlowQuestionTile({
    required this.question,
    required this.questionIndex,
    required this.section,
    required this.sections,
    required this.sectionLabel,
    required this.onReorderQuestion,
    required this.onMoveQuestion,
    required this.onDeleteQuestion,
    this.onEditQuestion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = QuestionType.from(question);
    return Column(
      children: [
        ListTile(
          onTap: onEditQuestion == null
              ? null
              : () => onEditQuestion!(question),
          leading: CircleAvatar(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.primary,
            child: Icon(recordFlowQuestionIcon(type), size: 20),
          ),
          title: Text(
            question.prompt,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(recordFlowQuestionSummary(context, question)),
          trailing: PopupMenuButton<String>(
            tooltip: context.translate.reorderOrMoveQuestion,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleAction(action),
            itemBuilder: (context) => _menuItems(context),
          ),
        ),
        if (questionIndex < section.questions.length - 1)
          Divider(
            height: 1,
            indent: AppPadding.large,
            endIndent: AppPadding.large,
            color: colors.outlineVariant,
          ),
      ],
    );
  }

  void _handleAction(String action) {
    if (action == 'edit') {
      onEditQuestion?.call(question);
    } else if (action == 'up') {
      onReorderQuestion(section, questionIndex, questionIndex - 1);
    } else if (action == 'down') {
      onReorderQuestion(section, questionIndex, questionIndex + 1);
    } else if (action == 'delete') {
      onDeleteQuestion(section, questionIndex);
    } else if (action.startsWith('section:')) {
      onMoveQuestion(question, section, action.substring('section:'.length));
    }
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return [
      if (onEditQuestion != null)
        PopupMenuItem(
          value: 'edit',
          child: Text(context.translate.questionSettingsTitle),
        ),
      if (questionIndex > 0)
        PopupMenuItem(
          value: 'up',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_upward),
            title: Text(context.translate.moveQuestionUp),
          ),
        ),
      if (questionIndex < section.questions.length - 1)
        PopupMenuItem(
          value: 'down',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_downward),
            title: Text(context.translate.moveQuestionDown),
          ),
        ),
      if (sections.length > 1) ...[
        const PopupMenuDivider(),
        ...sections
            .where((candidate) => candidate != section)
            .map(
              (candidate) => PopupMenuItem(
                value: 'section:${candidate.id}',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: Text(
                    context.translate.moveToSection(
                      sectionLabel(candidate, sections.indexOf(candidate)),
                    ),
                  ),
                ),
              ),
            ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_outline, color: colors.error),
          title: Text(
            context.translate.deleteQuestionFromDraft,
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
    ];
  }
}
