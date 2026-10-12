import 'package:flutter/material.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';

import 'record_category_heading.dart';

class RecordReviewStep extends StatelessWidget {
  final MultiRecordDraft draft;
  final bool themed;
  final bool colored;
  final VoidCallback onEditTime;
  final ValueChanged<int> onEditCategory;
  const RecordReviewStep({
    required this.draft,
    required this.themed,
    required this.colored,
    required this.onEditTime,
    required this.onEditCategory,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.recordReviewHelp),
        const SizedBox(height: 16),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat.yMMMMEEEEd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(draft.date),
                  ),
                ),
                TextButton(
                  key: const ValueKey('review-edit-time'),
                  onPressed: onEditTime,
                  child: Text(strings.recordEdit),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < draft.selected.length; index++) ...[
          Card.outlined(
            key: ValueKey('review-category-${draft.selected[index].type}'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RecordCategoryHeading(
                    type: draft.selected[index].type,
                    themed: themed,
                    trailing: TextButton(
                      key: ValueKey(
                        'review-edit-${draft.selected[index].type}',
                      ),
                      onPressed: () => onEditCategory(index),
                      child: Text(strings.recordEdit),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${strings.timeChangeTitle}: ${draft.timeFor(draft.selected[index].type).label(context, includeRange: true)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Divider(height: 28),
                  DetailDisplay(
                    detail: draft.selected[index].graph.createDetailResponse(
                      detailType: draft.selected[index].type,
                    ),
                    accentColor: colored
                        ? CategoryTheme.resolve(draft.selected[index].type)
                              .color
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          strings.recordCount(draft.selected.length),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
