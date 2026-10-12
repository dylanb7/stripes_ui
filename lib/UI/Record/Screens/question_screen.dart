import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_ui/Providers/Questions/baseline_version_provider.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class QuestionScreen extends StatelessWidget {
  final List<Question> questions;

  final String header;

  final SessionGraph questionsListener;

  final DetailResponse? baseline;
  final bool compact;

  const QuestionScreen({
    required this.header,
    required this.questions,
    required this.questionsListener,
    this.baseline,
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
        if (baseline != null) _BaselineReferencePanel(baseline: baseline!),
        RenderQuestions(
          questions: questions,
          questionsListener: questionsListener,
          baseline: baseline,
        ),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }
}

/// A collapsible panel that shows the user's baseline answers for reference
/// while filling out an interim check-in. This gives context to questions like
/// "Has your child's seizure control changed?" by showing what was originally
/// reported.
class _BaselineReferencePanel extends StatefulWidget {
  final DetailResponse baseline;

  const _BaselineReferencePanel({required this.baseline});

  @override
  State<_BaselineReferencePanel> createState() =>
      _BaselineReferencePanelState();
}

class _BaselineReferencePanelState extends State<_BaselineReferencePanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baselineColor = CategoryTheme.resolve(widget.baseline.type).color;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppPadding.small,
        right: AppPadding.small,
        bottom: AppPadding.medium,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: baselineColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRounding.small),
          border: Border.all(color: baselineColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Tap header
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppRounding.small),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.small,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: baselineColor,
                    ),
                    const SizedBox(width: AppPadding.small),
                    Expanded(
                      child: Text(
                        'Your Baseline',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: baselineColor,
                        ),
                      ),
                    ),
                    Text(
                      _expanded ? 'Hide' : 'Show',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.medium,
                  right: AppPadding.medium,
                  bottom: AppPadding.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      color: baselineColor.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: AppPadding.small),
                    DetailDisplay(
                      detail: widget.baseline,
                      accentColor: baselineColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RenderQuestions extends ConsumerWidget {
  final List<Question> questions;

  final SessionGraph questionsListener;

  final DetailResponse? baseline;

  const RenderQuestions({
    required this.questions,
    required this.questionsListener,
    this.baseline,
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
        return _buildRecursive(
          context,
          displayQuestion,
          questionsListener,
          registry,
        );
      }).toList(),
    );
  }

  Widget _buildRecursive(
    BuildContext context,
    Question question,
    SessionGraph listener,
    QuestionUIRegistry registry,
  ) {
    return QuestionResolverWrapper(
      question: question,
      questionsListener: listener,
      baseline: baseline,
      builder: (resolved) {
        if (resolved.id == question.id) {
          return _buildEntry(context, resolved, listener, registry);
        }
        return _buildRecursive(context, resolved, listener, registry);
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
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    if (question.fromBaseline != null) {
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
    // If baseline is provided explicitly, use it without watching provider
    if (baseline != null) {
      if (baseline!.type != question.fromBaseline) {
        // Should match, but if not, fallback or validation?
        // Assuming the passed baseline is the correct one for the path.
      }
      return _resolveAndBuild(baseline, localizations);
    }

    final AsyncValue<DetailResponse?> baselineResponse = ref.watch(
      baselineResponseProvider((
        baselineType: question.fromBaseline!,
        version: null,
      )),
    );

    return baselineResponse.when(
      data: (latest) => _resolveAndBuild(latest, localizations),
      error: (_, _) => builder(question),
      loading: () => builder(question),
    );
  }

  Widget _resolveAndBuild(
    DetailResponse? latest,
    QuestionsLocalizations? localizations,
  ) {
    if (latest == null) return builder(question);

    final int baselineVersion = _extractVersion(latest);

    final List<Question> resolvedQuestions = question.resolveFromBaseline(
      baseline: latest,
      baselineVersion: baselineVersion,
    );

    // Translate the resolved questions using template-aware translation
    final translatedQuestions = resolvedQuestions
        .map((q) => localizations?.translateQuestion(q) ?? q)
        .toList();

    return _buildResolvedQuestions(translatedQuestions);
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
