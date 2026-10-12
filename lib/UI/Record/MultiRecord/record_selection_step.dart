import 'package:flutter/material.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class RecordSelectionStep extends StatelessWidget {
  final MultiRecordDraft draft;
  final bool themed;
  const RecordSelectionStep({
    required this.draft,
    required this.themed,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.recordSelectHelp),
        const SizedBox(height: 24),
        if (draft.context.categories.isEmpty) Text(strings.recordNoCategories),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 300 &&
                    MediaQuery.textScalerOf(context).scale(14) < 18
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in draft.context.categories)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: draft.isSelected(item.path.name),
                      child: OutlinedButton(
                        key: ValueKey('select-category-${item.path.name}'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: draft.isSelected(item.path.name)
                              ? colors.primary
                              : colors.surface,
                          foregroundColor: draft.isSelected(item.path.name)
                              ? colors.onPrimary
                              : colors.onSurface,
                          padding: const EdgeInsets.all(16),
                          alignment: AlignmentDirectional.centerStart,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => draft.toggle(item),
                        child: columns == 2
                            ? ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 100,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (themed)
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: CategoryIcon(
                                                appearance:
                                                    CategoryTheme.resolve(
                                                      item.path.name,
                                                    ),
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        const Spacer(),
                                        Icon(
                                          draft.isSelected(item.path.name)
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _SelectionLabel(
                                      type: item.path.name,
                                      selected: draft.isSelected(
                                        item.path.name,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                children: [
                                  if (themed) ...[
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: CategoryIcon(
                                          appearance: CategoryTheme.resolve(
                                            item.path.name,
                                          ),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: _SelectionLabel(
                                      type: item.path.name,
                                      selected: draft.isSelected(
                                        item.path.name,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    draft.isSelected(item.path.name)
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 22,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          strings.recordCount(draft.selected.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _SelectionLabel extends StatelessWidget {
  final String type;
  final bool selected;
  const _SelectionLabel({required this.type, required this.selected});
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final hint = switch (type) {
      'category.Meal-Time' => strings.recordCategoryMealHint,
      'category.PAIN' => strings.recordCategoryPainHint,
      'category.BM' => strings.recordCategoryBowelHint,
      'category.REFLUX' => strings.recordCategoryGiHint,
      'category.NB' => strings.recordCategorySleepHint,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(QuestionsLocalizations.of(context)?.value(type) ?? type),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
