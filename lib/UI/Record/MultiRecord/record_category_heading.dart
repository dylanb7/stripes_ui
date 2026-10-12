import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class RecordCategoryHeading extends StatelessWidget {
  final String type;
  final bool themed;
  final Widget? trailing;
  const RecordCategoryHeading({
    required this.type,
    required this.themed,
    this.trailing,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (themed) ...[
        CategoryIcon(appearance: CategoryTheme.resolve(type), size: 28),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Text(
          QuestionsLocalizations.of(context)?.value(type) ?? type,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      ?trailing,
    ],
  );
}
