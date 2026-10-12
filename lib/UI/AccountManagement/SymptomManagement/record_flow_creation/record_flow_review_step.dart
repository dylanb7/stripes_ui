import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_creation_presentation.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_draft.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordFlowReviewStep extends StatelessWidget {
  final String flowName;
  final Period? period;
  final List<DraftRecordFlowSection> sections;
  final String Function(DraftRecordFlowSection section, int index) sectionLabel;
  final VoidCallback onPreview;
  final VoidCallback? onEditQuestions;
  final String Function(DraftRecordFlowSection)? sectionRuleSummary;

  const RecordFlowReviewStep({
    required this.flowName,
    this.period,
    required this.sections,
    required this.sectionLabel,
    required this.onPreview,
    this.onEditQuestions,
    this.sectionRuleSummary,
    super.key,
  });

  int get questionCount =>
      sections.fold(0, (count, section) => count + section.questions.length);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppPadding.large),
      children: [
        Text(
          context.translate.reviewQuestionSetDescription,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppPadding.large),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          child: ListTile(
            title: Text(
              flowName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${context.translate.sectionsCount(sections.length)} · '
              '${context.translate.questionsCount(questionCount)} · ${recordFlowTimingLabel(context, period)}',
            ),
          ),
        ),
        const SizedBox(height: AppPadding.medium),
        OutlinedButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.play_circle_outline),
          label: Text(context.translate.previewFlow),
        ),
        if (onEditQuestions != null)
          TextButton.icon(
            onPressed: onEditQuestions,
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.translate.editFlowQuestions),
          ),
        const SizedBox(height: AppPadding.medium),
        ...sections.indexed.map(
          (entry) => _ReviewSectionCard(
            section: entry.$2,
            label: sectionLabel(entry.$2, entry.$1),
            ruleSummary: sectionRuleSummary?.call(entry.$2),
          ),
        ),
      ],
    );
  }
}

class _ReviewSectionCard extends StatelessWidget {
  final DraftRecordFlowSection section;
  final String label;
  final String? ruleSummary;

  const _ReviewSectionCard({
    required this.section,
    required this.label,
    this.ruleSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (ruleSummary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.medium,
                0,
                AppPadding.medium,
                AppPadding.small,
              ),
              child: Text(
                ruleSummary!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          ...section.questions.map(
            (question) => ListTile(
              leading: Icon(
                recordFlowQuestionIcon(QuestionType.from(question)),
              ),
              title: Text(question.prompt),
              subtitle: Text(recordFlowQuestionSummary(context, question)),
            ),
          ),
        ],
      ),
    );
  }
}
