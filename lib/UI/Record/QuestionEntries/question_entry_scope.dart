import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class QuestionEntryController extends ChangeNotifier {
  final Question question;
  final QuestionsListener listener;

  bool _isHighlighted = false;
  bool _disposed = false;

  QuestionEntryController({
    required this.question,
    required this.listener,
  }) {
    listener.addListener(_onListenerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && !hasResponse) {
        // Initialize pending state
        listener.setResponse(question,
            response: listener.fromQuestion(question));
      }
    });
  }

  void _onListenerChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool get hasResponse => listener.fromQuestion(question) != null;

  bool get isPending => listener.pending.contains(question);

  bool get hasError => isPending && listener.tried;

  bool get isHighlighted => _isHighlighted;

  Response? get response => listener.fromQuestion(question);

  void addResponse(Response response) {
    listener.setResponse(question, response: response);
  }

  void removeResponse() {
    listener.setResponse(question, response: null);
  }

  void toggleResponse(Response Function() createResponse) {
    if (hasResponse) {
      removeResponse();
    } else {
      addResponse(createResponse());
    }
  }

  Future<void> highlight(
      {Duration duration = const Duration(milliseconds: 600)}) async {
    if (_disposed) return;
    _isHighlighted = true;
    notifyListeners();
    await Future.delayed(duration);
    if (!_disposed) {
      _isHighlighted = false;
      notifyListeners();
    }
  }

  int get stamp => dateToStamp(DateTime.now());

  @override
  void dispose() {
    _disposed = true;
    listener.removeListener(_onListenerChanged);
    super.dispose();
  }
}

class QuestionEntryScope extends StatefulWidget {
  final Question question;
  final QuestionsListener listener;
  final Widget child;

  const QuestionEntryScope({
    super.key,
    required this.question,
    required this.listener,
    required this.child,
  });

  static QuestionEntryController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_QuestionEntryScopeInherited>();
    assert(scope != null, 'No QuestionEntryScope found in context');
    return scope!.controller;
  }

  static QuestionEntryController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_QuestionEntryScopeInherited>()
        ?.controller;
  }

  @override
  State<QuestionEntryScope> createState() => _QuestionEntryScopeState();
}

class _QuestionEntryScopeState extends State<QuestionEntryScope> {
  late QuestionEntryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuestionEntryController(
      question: widget.question,
      listener: widget.listener,
    );
  }

  @override
  void didUpdateWidget(QuestionEntryScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If question or listener changes, recreate controller
    if (oldWidget.question != widget.question ||
        oldWidget.listener != widget.listener) {
      _controller.dispose();
      _controller = QuestionEntryController(
        question: widget.question,
        listener: widget.listener,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _QuestionEntryScopeInherited(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _QuestionEntryScopeInherited
    extends InheritedNotifier<QuestionEntryController> {
  final QuestionEntryController controller;

  const _QuestionEntryScopeInherited({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);
}

class QuestionEntryCard extends StatefulWidget {
  final Widget child;
  final bool styled;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const QuestionEntryCard({
    super.key,
    required this.child,
    this.styled = true,
    this.padding,
    this.margin,
  });

  @override
  State<QuestionEntryCard> createState() => _QuestionEntryCardState();
}

class _QuestionEntryCardState extends State<QuestionEntryCard> {
  @override
  Widget build(BuildContext context) {
    final controller = QuestionEntryScope.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool hasResponse = controller.hasResponse;
        final bool hasError = controller.hasError;
        final bool isHighlighted = controller.isHighlighted;

        Widget content = widget.child;

        if (widget.styled) {
          final colors = Theme.of(context).colorScheme;
          final BorderSide border;
          final Color backgroundColor;

          if (hasResponse) {
            border = BorderSide(width: 3.0, color: colors.primary);
            backgroundColor = Theme.of(context).cardColor;
          } else if (hasError) {
            border = BorderSide(width: 3.0, color: colors.error);
            // Subtle error background tint
            backgroundColor = colors.errorContainer.withValues(alpha: 0.3);
          } else {
            border =
                BorderSide(width: 3.0, color: Theme.of(context).dividerColor);
            backgroundColor = Theme.of(context).cardColor;
          }

          content = Padding(
            padding: widget.margin ??
                const EdgeInsets.symmetric(vertical: AppPadding.tiny),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRounding.medium)),
                border: Border.fromBorderSide(border),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ),
          );
        }

        return AnimatedScale(
          scale: isHighlighted ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: content,
        );
      },
    );
  }
}
