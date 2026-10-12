import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class CategoryChip extends StatelessWidget {
  final CategoryAppearance appearance;
  final String categoryName;
  final double iconSize;
  final bool useColor;

  const CategoryChip({
    super.key,
    required this.appearance,
    required this.categoryName,
    this.iconSize = 18.0,
    this.useColor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: useColor
            ? appearance.color.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryIcon(appearance: appearance, size: iconSize),
          const SizedBox(width: AppPadding.tiny),
          Flexible(
            child: Text(
              categoryName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: useColor
                    ? appearance.color
                    : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
