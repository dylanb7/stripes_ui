import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_ui/Providers/baseline_version_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class QuestionScreen extends StatelessWidget {
  final List<Question> questions;

  final String header;

  final QuestionsListener questionsListener;

  final DetailResponse? baseline;

  const QuestionScreen(
      {required this.header,
      required this.questions,
      required this.questionsListener,
      this.baseline,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (header.isNotEmpty) ...[
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
        ],
        RenderQuestions(
            questions: questions,
            questionsListener: questionsListener,
            baseline: baseline),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }
}

class RenderQuestions extends ConsumerWidget {
  final List<Question> questions;

  final QuestionsListener questionsListener;

  final DetailResponse? baseline;

  const RenderQuestions(
      {required this.questions,
      required this.questionsListener,
      this.baseline,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<QuestionRepo?> questionRepo = ref.watch(questionsProvider);
    final Map<String, QuestionEntry> questionEntries =
        questionRepo.mapOrNull(data: (data) => data.value?.entryOverrides) ??
            {};

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: questions.map((question) {
        return QuestionResolverWrapper(
          question: question,
          questionsListener: questionsListener,
          baseline: baseline,
          builder: (question) {
            final EntryBuilder? override =
                questionEntries[question.id]?.entryBuilder;
            if (override != null) {
              return override(questionsListener, context, question);
            }
            switch (question) {
              case FreeResponse():
                return FreeResponseEntry(
                    question: question, listener: questionsListener);
              case Numeric():
                return SeverityWidget(
                    question: question, questionsListener: questionsListener);
              case Check():
                return CheckBoxWidget(
                    check: question, listener: questionsListener);
              case MultipleChoice():
                return MultiChoiceEntry(
                    question: question, listener: questionsListener);
              case AllThatApply():
                return AllThatApplyEntry(
                    question: question, listener: questionsListener);
            }
          },
        );
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

class QuestionResolverWrapper extends ConsumerWidget {
  final Question question;
  final QuestionsListener questionsListener;
  final Widget Function(Question) builder;
  final DetailResponse? baseline;

  const QuestionResolverWrapper({
    required this.question,
    required this.questionsListener,
    required this.builder,
    this.baseline,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    if (question.fromBaseline != null) {
      return _buildBaselineResolved(context, ref, localizations);
    }

    if (question.transform != null) {
      return _buildMidRecordingResolved(context, localizations);
    }

    return builder(question);
  }

  Widget _buildBaselineResolved(BuildContext context, WidgetRef ref,
      QuestionsLocalizations? localizations) {
    // If baseline is provided explicitly, use it without watching provider
    if (baseline != null) {
      if (baseline!.type != question.fromBaseline) {
        // Should match, but if not, fallback or validation?
        // Assuming the passed baseline is the correct one for the path.
      }
      return _resolveAndBuild(baseline, localizations);
    }

    final AsyncValue<DetailResponse?> baselineResponse = ref.watch(
      baselineResponseProvider(
        (baselineType: question.fromBaseline!, version: null),
      ),
    );

    return baselineResponse.when(
      data: (latest) => _resolveAndBuild(latest, localizations),
      error: (_, __) => builder(question),
      loading: () => builder(question),
    );
  }

  Widget _resolveAndBuild(
      DetailResponse? latest, QuestionsLocalizations? localizations) {
    if (latest == null) return builder(question);

    final int baselineVersion = _extractVersion(latest);

    final List<Question> resolvedQuestions = question.resolveFromBaseline(
      baseline: latest,
      baselineVersion: baselineVersion,
    );

    // Translate the resolved questions using template-aware translation
    final translatedQuestions = resolvedQuestions
        .map((q) => localizations?.translateGeneratedQuestion(q, question) ?? q)
        .toList();

    return _buildResolvedQuestions(translatedQuestions);
  }

  Widget _buildMidRecordingResolved(
      BuildContext context, QuestionsLocalizations? localizations) {
    return ListenableBuilder(
      listenable: questionsListener,
      builder: (context, _) {
        final List<Response> currentResponses =
            questionsListener.questions.values.toList();

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

        final List<Question> resolvedQuestions = question.resolve(
          current: sessionWrapper,
        );

        final bool noGeneration = resolvedQuestions.length == 1 &&
            resolvedQuestions.first.id == question.id;

        if (noGeneration) {
          return originalQuestion;
        }

        // Translate the resolved questions using template-aware translation
        final translatedQuestions = resolvedQuestions
            .map((q) =>
                localizations?.translateGeneratedQuestion(q, question) ?? q)
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

    return _GeneratedQuestionsGroup(
      sourceQuestion: question,
      resolvedQuestions: resolvedQuestions,
      builder: builder,
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
