import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordFlowStepHeading extends StatelessWidget {
  final String title;
  final String description;

  const RecordFlowStepHeading({
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.tiny),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String recordFlowQuestionTypeLabel(BuildContext context, QuestionType type) =>
    switch (type) {
      QuestionType.check => context.translate.questionTypeCheck,
      QuestionType.slider => context.translate.questionTypeSlider,
      QuestionType.multipleChoice =>
        context.translate.questionTypeMultipleChoice,
      QuestionType.allThatApply => context.translate.questionTypeAllThatApply,
      QuestionType.freeResponse => context.translate.questionTypeFreeResponse,
    };

IconData recordFlowQuestionIcon(QuestionType type) => switch (type) {
  QuestionType.check => Icons.check_box_outlined,
  QuestionType.slider => Icons.linear_scale,
  QuestionType.multipleChoice => Icons.radio_button_checked,
  QuestionType.allThatApply => Icons.checklist,
  QuestionType.freeResponse => Icons.short_text,
};

String recordFlowTimingLabel(BuildContext context, Period? period) =>
    switch (period) {
      null => context.translate.eventBased,
      Period.day => context.translate.dailyTiming,
      Period.week => context.translate.weeklyTiming,
      Period.month => context.translate.monthlyTiming,
      Period.year => context.translate.yearlyTiming,
    };

String recordFlowQuestionSummary(BuildContext context, Question question) {
  final label = recordFlowQuestionTypeLabel(
    context,
    QuestionType.from(question),
  );
  final details = switch (question) {
    Numeric() => '$label · ${question.min ?? 1}–${question.max ?? 5}',
    MultipleChoice() =>
      '$label · ${context.translate.optionsCount(question.choices.length)}',
    AllThatApply() =>
      '$label · ${context.translate.optionsCount(question.choices.length)}',
    _ => label,
  };
  return question.dependsOn?.groups.isNotEmpty == true
      ? '$details · ${context.translate.conditionalLabel}'
      : details;
}
