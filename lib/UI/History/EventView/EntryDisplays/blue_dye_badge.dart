import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

/// A saved blue-dye answer identifies this recording as a test observation.
/// A generic recording session ID alone does not identify a blue-dye test.
bool? recordedBlueDyeResult(DetailResponse detail) {
  if (!const {'category.BM', 'Bowel Movement', 'BM'}.contains(detail.type)) {
    return null;
  }
  final answers = detail.responses.whereType<MultiResponse>().where(
    (answer) =>
        answer.question.id == 'BlueDyeQuestion' && !answer.question.userCreated,
  );
  if (answers.isNotEmpty) {
    if (answers.length != 1) return null;
    return switch (answers.single.index) {
      0 => true,
      1 => false,
      _ => null,
    };
  }
  // Older projected entries may retain test metadata without the question.
  final saved = entryForResponse(detail)?.data['isBlue'];
  return saved is bool ? saved : null;
}

/// Test context belongs beside the category, without a second illustration.
/// Text distinguishes the results even without their color treatment.
class HistoryBlueDyeBadge extends StatelessWidget {
  final bool isBlue;

  const HistoryBlueDyeBadge({required this.isBlue, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = isBlue
        ? context.translate.historyTestBlue
        : context.translate.historyTestNoBlue;
    final description = isBlue
        ? context.translate.historyTestBlueDescription
        : context.translate.historyTestNoBlueDescription;
    final foreground = isBlue
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Tooltip(
      message: description,
      excludeFromSemantics: true,
      child: Semantics(
        label: description,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isBlue
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
