import 'package:flutter/material.dart' hide Transform;
import 'package:stripes_ui/UI/Record/QuestionEntries/baseline_question_reference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class QuestionScreen extends StatelessWidget {
  final List<Question> questions;

  final String header;

  final SessionGraph questionsListener;

  /// Retained for source compatibility. References use the session snapshot;
  /// supply baselines when constructing the SessionGraph.
  final DetailResponse? baseline;
  final BaselineReferenceBuilder? baselineReferenceBuilder;
  final bool compact;

  const QuestionScreen({
    required this.header,
    required this.questions,
    required this.questionsListener,
    this.baseline,
    this.baselineReferenceBuilder,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final headerDuplicatesPrompt =
        compact &&
        questions.any(
          (question) =>
              (QuestionsLocalizations.of(context)
                          ?.translateQuestion(question) ??
                      question)
                  .prompt
                  .trim() ==
              header.trim(),
        );
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        if (header.isNotEmpty && !headerDuplicatesPrompt) ...[
          const SizedBox(height: AppPadding.small),
          Text(
            header,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: compact
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: compact ? TextAlign.start : TextAlign.center,
          ),
          const SizedBox(height: AppPadding.small),
        ],
        RenderQuestions(
          questions: questions,
          questionsListener: questionsListener,
          baseline: baseline,
          baselineReferenceBuilder: baselineReferenceBuilder,
        ),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }
}

class RenderQuestions extends ConsumerWidget {
  final List<Question> questions;

  final SessionGraph questionsListener;

  /// Retained for source compatibility. References use the session snapshot;
  /// supply baselines when constructing the SessionGraph.
  final DetailResponse? baseline;
  final BaselineReferenceBuilder? baselineReferenceBuilder;

  const RenderQuestions({
    required this.questions,
    required this.questionsListener,
    this.baseline,
    this.baselineReferenceBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionUIRegistry registry = ref.watch(questionUIRegistryProvider);
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: questions.map((question) {
        final Question displayQuestion =
            localizations?.translateQuestion(question) ?? question;
        return _buildQuestion(
          context,
          displayQuestion,
          questionsListener,
          registry,
        );
      }).toList(),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    Question question,
    SessionGraph listener,
    QuestionUIRegistry registry,
  ) {
    return QuestionResolverWrapper(
      question: question,
      questionsListener: listener,
      baseline: baseline,
      baselineReferenceBuilder: baselineReferenceBuilder,
      builder: (resolved) {
        return _buildEntry(context, resolved, listener, registry);
      },
    );
  }

  Widget _buildEntry(
    BuildContext context,
    Question question,
    SessionGraph listener,
    QuestionUIRegistry registry,
  ) {
    final EntryBuilder? override = registry
        .entryForQuestion(question)
        ?.entryBuilder;
    if (override != null) {
      return override(listener, context, question);
    }
    switch (question) {
      case FreeResponse():
        return FreeResponseEntry(question: question, listener: listener);
      case Numeric():
        return SeverityWidget(question: question, questionsListener: listener);
      case Check():
        return CheckBoxWidget(check: question, listener: listener);
      case MultipleChoice():
        return MultiChoiceEntry(question: question, listener: listener);
      case AllThatApply():
        return AllThatApplyEntry(question: question, listener: listener);
    }
  }
}

class QuestionResolverWrapper extends ConsumerWidget {
  final Question question;
  final SessionGraph questionsListener;
  final Widget Function(Question) builder;

  /// Retained for source compatibility. References use the session snapshot;
  /// supply baselines when constructing the SessionGraph.
  final DetailResponse? baseline;
  final BaselineReferenceBuilder? baselineReferenceBuilder;

  const QuestionResolverWrapper({
    required this.question,
    required this.questionsListener,
    required this.builder,
    this.baseline,
    this.baselineReferenceBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    final templateId = parseGeneratedId(question.id)?.templateId;
    if (question.fromBaseline != null ||
        (templateId != null &&
            questionsListener.baselineForQuestion(templateId) != null)) {
      return _buildBaselineResolved(context, ref, localizations);
    }

    if (question.transform != null) {
      return _buildMidRecordingResolved(context, localizations);
    }

    return builder(question);
  }

  Widget _buildBaselineResolved(
    BuildContext context,
    WidgetRef ref,
    QuestionsLocalizations? localizations,
  ) {
    // Resolve and display the same snapshot used by session validation. A
    // provider lookup here could choose a newer (or preferred) version.
    final generated = parseGeneratedId(question.id);
    final selected = questionsListener.baselineForQuestion(
      generated?.templateId ?? question.id,
    );
    final expectedType = question.fromBaseline;
    final DetailResponse? reference =
        selected is DetailResponse &&
            (expectedType == null || selected.type == expectedType)
        ? selected
        : null;
    if (reference == null) return builder(question);

    // A single generated question can already have been resolved by the graph.
    final resolved = generated != null
        ? [question]
        : question.resolveFromBaseline(
            baseline: reference,
            baselineVersion: _extractVersion(reference),
          );
    final translated = resolved
        .map((q) => localizations?.translateQuestion(q) ?? q)
        .toList();
    final sourceId = Transform.parse(question.transform)?.sourceId;
    final sourceResponses = sourceId == null
        ? <Response>[]
        : getSourceResponses(reference, sourceId, null);
    final referenceContext = BaselineQuestionContext(
      baseline: reference,
      question: question,
      resolvedQuestions: translated,
      sourceResponses: sourceResponses,
    );
    final child = _buildResolvedQuestions(translated);
    return baselineReferenceBuilder?.call(context, referenceContext, child) ??
        BaselineQuestionReference(reference: referenceContext, child: child);
  }

  Widget _buildMidRecordingResolved(
    BuildContext context,
    QuestionsLocalizations? localizations,
  ) {
    return ListenableBuilder(
      listenable: questionsListener,
      builder: (context, _) {
        final List<Response> currentResponses = questionsListener
            .responses
            .values
            .toList();

        // Always show the original question first
        final Widget originalQuestion = builder(question);

        if (currentResponses.isEmpty) {
          return originalQuestion;
        }

        final ResponseWrap sessionWrapper = DetailResponse(
          responses: currentResponses,
          stamp: DateTime.now().millisecondsSinceEpoch,
          detailType: 'current_session',
        );

        final List<Question> resolvedQuestions = question
            .resolve(current: sessionWrapper)
            .map((q) => localizations?.translateQuestion(q) ?? q)
            .toList();

        final bool noGeneration =
            resolvedQuestions.length == 1 &&
            resolvedQuestions.first.id == question.id;

        if (noGeneration) {
          return originalQuestion;
        }

        // Translate the resolved questions using template-aware translation
        final translatedQuestions = resolvedQuestions
            .map((q) => localizations?.translateQuestion(q) ?? q)
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            originalQuestion,
            _GeneratedQuestionsGroup(
              sourceQuestion: question,
              resolvedQuestions: translatedQuestions,
              builder: builder,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResolvedQuestions(List<Question> resolvedQuestions) {
    if (resolvedQuestions.isEmpty) {
      return builder(question);
    }

    if (resolvedQuestions.length == 1) {
      return builder(resolvedQuestions.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: resolvedQuestions.map(builder).toList(),
    );
  }

  int _extractVersion(DetailResponse response) {
    if (response.id == null) return 1;
    final parsed = BaselineId.parse(response.id!);
    return parsed?.version ?? 1;
  }
}

class _GeneratedQuestionsGroup extends StatefulWidget {
  final Question sourceQuestion;
  final List<Question> resolvedQuestions;
  final Widget Function(Question) builder;

  const _GeneratedQuestionsGroup({
    required this.sourceQuestion,
    required this.resolvedQuestions,
    required this.builder,
  });

  @override
  State<_GeneratedQuestionsGroup> createState() =>
      _GeneratedQuestionsGroupState();
}

class _GeneratedQuestionsGroupState extends State<_GeneratedQuestionsGroup>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.resolvedQuestions.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOut);
    }).toList();

    // Stagger the animations with 100ms delay between each (only for visible)
    for (int i = 0; i < widget.resolvedQuestions.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && i < _controllers.length) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(_GeneratedQuestionsGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resolvedQuestions.length != oldWidget.resolvedQuestions.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _initAnimations();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int totalCount = widget.resolvedQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grouping header
        Padding(
          padding: const EdgeInsets.only(
            top: AppPadding.small,
            bottom: AppPadding.tiny,
          ),
          child: Text(
            '$totalCount questions based on your selections',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.secondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        for (int i = 0; i < totalCount; i++)
          FadeTransition(
            opacity: _animations[i],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_animations[i]),
              child: widget.builder(widget.resolvedQuestions[i]),
            ),
          ),
      ],
    );
  }
}
