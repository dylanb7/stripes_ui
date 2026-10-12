import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Opts a recording page into compact question presentation without changing
/// question definitions or presentations outside this scope.
class CompactRecordQuestions extends InheritedWidget {
  final String requiredLabel;
  final String invalidLabel;

  const CompactRecordQuestions({
    required super.child,
    required this.requiredLabel,
    required this.invalidLabel,
    super.key,
  });

  static CompactRecordQuestions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompactRecordQuestions>();

  @override
  bool updateShouldNotify(CompactRecordQuestions oldWidget) =>
      requiredLabel != oldWidget.requiredLabel ||
      invalidLabel != oldWidget.invalidLabel;
}

/// Shared prompt, validation and spacing for questions in the beta form.
/// Complex custom controls use the same hierarchy as standard question types.
class CompactRecordQuestion extends StatelessWidget {
  final String prompt;
  final bool promptInChild;
  final Widget child;

  const CompactRecordQuestion({
    required this.prompt,
    required this.child,
    this.promptInChild = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final compact = CompactRecordQuestions.maybeOf(context)!;
    final controller = QuestionEntryScope.maybeOf(context);
    final colors = Theme.of(context).colorScheme;
    final isRequired =
        controller?.question.isRequired == true ||
        controller?.question.requirement?.groups.isNotEmpty == true;
    final hasError = controller?.hasError == true;
    final foreground = hasError ? colors.error : colors.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: promptInChild ? AppPadding.small : AppPadding.xl,
      ),
      child: AnimatedContainer(
        key: controller == null
            ? null
            : ValueKey('compact-question-${controller.question.id}'),
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hasError ? colors.errorContainer.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(AppRounding.small),
          border: hasError ? Border.all(color: colors.error) : null,
        ),
        padding: hasError
            ? const EdgeInsets.all(AppPadding.small)
            : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!promptInChild) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      prompt,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (isRequired) ...[
                    const SizedBox(width: AppPadding.small),
                    _RequiredMarker(
                      label: compact.requiredLabel,
                      color: foreground,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppPadding.small),
            ],
            if (promptInChild && isRequired)
              Row(
                children: [
                  Expanded(child: child),
                  const SizedBox(width: AppPadding.small),
                  _RequiredMarker(
                    label: compact.requiredLabel,
                    color: foreground,
                  ),
                ],
              )
            else
              child,
            if (hasError) ...[
              const SizedBox(height: AppPadding.small),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: colors.error),
                    const SizedBox(width: AppPadding.tiny),
                    Expanded(
                      child: Text(
                        compact.invalidLabel,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequiredMarker extends StatelessWidget {
  final String label;
  final Color color;

  const _RequiredMarker({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Tooltip(
      message: label,
      child: ExcludeSemantics(
        child: Text(
          '*',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

/// A mutually exclusive alternative to a visual answer, kept in its question.
class CompactAlternativeAnswer extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const CompactAlternativeAnswer({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRounding.small),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRounding.small),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.small),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
