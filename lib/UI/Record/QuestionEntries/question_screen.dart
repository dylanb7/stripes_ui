import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/Util/paddings.dart';

class QuestionScreen extends StatelessWidget {
  final List<Question> questions;

  final String header;

  final QuestionsListener questionsListener;

  const QuestionScreen(
      {required this.header,
      required this.questions,
      required this.questionsListener,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: AppPadding.small,
        ),
        Text(
          header,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        RenderQuestions(
            questions: questions, questionsListener: questionsListener),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }
}

class RenderQuestions extends ConsumerWidget {
  final List<Question> questions;

  final QuestionsListener questionsListener;

  const RenderQuestions(
      {required this.questions, required this.questionsListener, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<QuestionRepo> questionRepo = ref.watch(questionsProvider);
    final Map<String, QuestionEntry> questionEntries =
        questionRepo.mapOrNull(data: (data) => data.value.entryOverrides) ?? {};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: questions.map((question) {
        final EntryBuilder? override =
            questionEntries[question.id]?.entryBuilder;
        if (override != null) {
          return override(questionsListener, context, question);
        }
        if (question is Check) {
          return CheckBoxWidget(check: question, listener: questionsListener);
        } else if (question is MultipleChoice) {
          return MultiChoiceEntry(
              question: question, listener: questionsListener);
        } else if (question is Numeric) {
          return SeverityWidget(
              question: question, questionsListener: questionsListener);
        } else if (question is FreeResponse) {
          return FreeResponseEntry(
              question: question, listener: questionsListener);
        }
        return Text(question.prompt);
      }).toList(),
    );
  }
}

class QuestionWrap extends ConsumerStatefulWidget {
  final Question question;

  final QuestionsListener listener;

  final Widget child;

  final bool styled;

  const QuestionWrap(
      {required this.question,
      required this.listener,
      required this.child,
      this.styled = true,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => QuestionWrapState();
}

class QuestionWrapState extends ConsumerState<QuestionWrap> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.question.isRequired && !hasEntry) {
        widget.listener.addPending(widget.question);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.styled) return widget.child;
    final bool hasError = widget.listener.tried &&
        widget.listener.pending.contains(widget.question);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRounding.medium)),
          border: hasEntry
              ? Border.all(
                  width: 3.0, color: Theme.of(context).colorScheme.primary)
              : hasError
                  ? Border.all(
                      width: 3.0, color: Theme.of(context).colorScheme.error)
                  : Border.all(
                      width: 3.0, color: Theme.of(context).dividerColor)),
      child: widget.child,
    );
  }

  bool get hasEntry => widget.listener.fromQuestion(widget.question) != null;
}
