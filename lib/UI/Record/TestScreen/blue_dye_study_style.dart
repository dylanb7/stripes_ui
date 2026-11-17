import 'package:flutter/material.dart';

/// Colors and surfaces from the Blue Meal study redesign, scoped to this flow.
abstract final class BlueDyeStudyStyle {
  static const navy = Color(0xFF303A78);
  static const orange = Color(0xFFF2A52B);
  static const background = Color(0xFFEDF2F8);
  static const border = Color(0xFFD8DFF0);

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color canvas(BuildContext context) =>
      _dark(context) ? Theme.of(context).colorScheme.surface : background;
  static Color surface(BuildContext context) => _dark(context)
      ? Theme.of(context).colorScheme.surfaceContainerLow
      : Colors.white;
  static Color outline(BuildContext context) =>
      _dark(context) ? Theme.of(context).colorScheme.outlineVariant : border;
  static Color ink(BuildContext context) =>
      _dark(context) ? Theme.of(context).colorScheme.primary : navy;
  static Color currentLabel(BuildContext context) =>
      _dark(context) ? orange : const Color(0xFF986000);
}

class BlueDyeStudyCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;
  final bool enabled;

  const BlueDyeStudyCard({
    this.title,
    this.description,
    required this.child,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? BlueDyeStudyStyle.surface(context)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: BlueDyeStudyStyle.outline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BlueDyeStudyStyle.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (title != null || description != null)
              const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class BlueDyeStudyChoice<T> extends StatelessWidget {
  final T value;
  final T? selected;
  final String label;
  final ValueChanged<T>? onChanged;

  const BlueDyeStudyChoice({
    required this.value,
    required this.selected,
    required this.label,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = selected == value;
    final ink = BlueDyeStudyStyle.ink(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        checked: chosen,
        inMutuallyExclusiveGroup: true,
        enabled: onChanged != null,
        child: OutlinedButton(
          onPressed: onChanged == null ? null : () => onChanged!(value),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            backgroundColor: chosen ? ink.withValues(alpha: 0.08) : null,
            side: BorderSide(
              color: chosen ? ink : BlueDyeStudyStyle.outline(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              const SizedBox(width: 12),
              Icon(
                chosen
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlueDyeStudyAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const BlueDyeStudyAction({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BlueDyeStudyStyle.ink(context),
        foregroundColor: BlueDyeStudyStyle.surface(context),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}
