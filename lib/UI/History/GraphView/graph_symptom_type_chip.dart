import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// Derives the display label and icon for a symptom based on its first response.
///
/// Uses a sealed-class switch so the compiler enforces exhaustiveness.
/// [DetailResponse] and abstract wrappers fall through to the [Selected] arm
/// since they don't represent a distinct question type.
({IconData icon, String label}) symptomTypeInfo(List<Response> responses) {
  if (responses.isEmpty) return (icon: Icons.help_outline_rounded, label: '');

  return switch (responses.first) {
    NumericResponse() => (icon: Icons.show_chart_rounded, label: 'Scale'),
    MultiResponse() => (
      icon: Icons.radio_button_checked_rounded,
      label: 'Multiple choice',
    ),
    AllResponse() => (icon: Icons.checklist_rounded, label: 'All that apply'),
    OpenResponse() => (icon: Icons.short_text_rounded, label: 'Free response'),
    // Selected, DetailResponse, and any abstract wrappers all fall here
    _ => (icon: Icons.check_box_outline_blank_rounded, label: 'Selectable'),
  };
}

/// A compact pill chip that communicates the response type for a symptom.
///
/// Pass [responses] and the type is inferred from the first item in the list
/// (safe because questions have a predefined response type).
class SymptomTypeChip extends StatelessWidget {
  final List<Response> responses;

  /// If true, hides the text label and shows only the icon.
  final bool iconOnly;

  const SymptomTypeChip({
    super.key,
    required this.responses,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) return const SizedBox.shrink();

    final (:icon, :label) = symptomTypeInfo(responses);
    if (label.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: iconOnly ? 4.0 : 6.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colorScheme.onSurfaceVariant),
          if (!iconOnly) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
