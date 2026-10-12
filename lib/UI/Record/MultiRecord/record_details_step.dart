import 'package:flutter/material.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Models/record_time.dart';

import 'record_category_heading.dart';

class RecordDetailsStep extends StatelessWidget {
  final MultiRecordCategory category;
  final int categoryIndex;
  final int categoryCount;
  final RecordTime time;
  final String? nextCategoryType;
  final bool themed;
  final bool returnToReview;
  final TextEditingController notesController;
  final Set<String> addedQuestionIds;
  final List<Question> Function(int) pageQuestions;
  final GlobalKey Function(Question) questionKeyFor;
  const RecordDetailsStep({
    required this.category,
    required this.categoryIndex,
    required this.categoryCount,
    required this.time,
    this.nextCategoryType,
    required this.themed,
    required this.returnToReview,
    required this.notesController,
    required this.addedQuestionIds,
    required this.pageQuestions,
    required this.questionKeyFor,
    super.key,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: category.graph,
    builder: (context, _) {
      final graph = category.graph;
      final strings = AppLocalizations.of(context)!;
      final colors = Theme.of(context).colorScheme;
      final rendered = <String>{};

      final content = <Widget>[];
      for (var i = 0; i < graph.visiblePages.length; i++) {
        final page = graph.visiblePages[i];
        final questions = pageQuestions(i)
            .where((q) => rendered.add(q.id))
            .toList();
        if (questions.isEmpty) continue;
        if (page.dependsOn.groups.isNotEmpty) {
          content.add(
            _FollowUpQuestions(
              key: ValueKey("follow-ups-${page.id}"),
              questions: questions,
              category: category,
              addedQuestionIds: addedQuestionIds,
              questionKeyFor: questionKeyFor,
              title: page.header == null
                  ? null
                  : QuestionsLocalizations.of(context)?.value(page.header!) ??
                        page.header!,
            ),
          );
        } else {
          for (final value in questions) {
            content.add(
              value.dependsOn?.groups.isNotEmpty == true
                  ? _FollowUpQuestions(
                      key: ValueKey("follow-ups-${value.id}"),
                      questions: [value],
                      category: category,
                      addedQuestionIds: addedQuestionIds,
                      questionKeyFor: questionKeyFor,
                    )
                  : _DetailQuestion(
                      question: value,
                      category: category,
                      anchorKey: questionKeyFor(value),
                    ),
            );
          }
        }
      }
      final studyQuestions = category.session.submitQuestions
          .where((q) => rendered.add(q.id))
          .toList();
      if (studyQuestions.isNotEmpty) {
        content.addAll(
          studyQuestions.map(
            (value) => _DetailQuestion(
              question: value,
              category: category,
              anchorKey: questionKeyFor(value),
            ),
          ),
        );
      }

      return Column(
        key: ValueKey('category-details-${category.type}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecordCategoryHeading(type: category.type, themed: themed),
          const SizedBox(height: 8),
          Text(
            '${strings.recordCategoryCount(categoryIndex + 1, categoryCount)} · ${time.label(context, includeRange: true)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          CompactRecordQuestions(
            requiredLabel: strings.recordQuestionRequired,
            invalidLabel: strings.recordQuestionInvalid,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
          ),
          const Divider(height: 32),
          LongTextEntry(
            key: ValueKey('category-notes-${category.type}'),
            textController: notesController,
            hintText: strings.recordNotes,
            labelText: strings.recordNotes,
            helperText: strings.optionalResponseDescription,
            expandToFill: true,
          ),
          if (!returnToReview) ...[
            const SizedBox(height: 24),
            Row(
              key: const ValueKey('record-next-destination'),
              children: [
                Expanded(
                  child: Text(
                    nextCategoryType != null
                        ? strings.recordNextCategory(
                            QuestionsLocalizations.of(context)
                                    ?.value(nextCategoryType!) ??
                                nextCategoryType!,
                          )
                        : strings.recordReviewAndSave,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _DetailQuestion extends StatelessWidget {
  final Question question;
  final MultiRecordCategory category;
  final GlobalKey anchorKey;
  const _DetailQuestion({
    required this.question,
    required this.category,
    required this.anchorKey,
  });
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: anchorKey,
    child: RenderQuestions(
      key: ValueKey('detail-question-${question.id}'),
      questions: [question],
      questionsListener: category.graph,
    ),
  );
}

class _FollowUpQuestions extends StatelessWidget {
  final List<Question> questions;
  final String? title;
  final MultiRecordCategory category;
  final Set<String> addedQuestionIds;
  final GlobalKey Function(Question) questionKeyFor;
  const _FollowUpQuestions({
    required this.questions,
    this.title,
    required this.category,
    required this.addedQuestionIds,
    required this.questionKeyFor,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    // Some page headings repeat the first question verbatim. Let the
    // question own its prompt; reserve this heading for the relationship.
    final heading =
        title ==
            (QuestionsLocalizations.of(context)
                    ?.value(questions.first.prompt) ??
                questions.first.prompt)
        ? strings.recordFollowUpPage
        : title ?? strings.recordFollowUpPage;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                heading,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (questions.any((q) => addedQuestionIds.contains(q.id))) ...[
              const SizedBox(height: 4),
              Text(
                strings.recordFollowUpsAdded,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < questions.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _DetailQuestion(
                question: questions[i],
                category: category,
                anchorKey: questionKeyFor(questions[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
