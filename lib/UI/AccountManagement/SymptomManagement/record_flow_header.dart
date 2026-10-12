import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Shared navigation and context for flow management and editing.
class RecordFlowHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? action;

  const RecordFlowHeader({
    required this.title,
    required this.onBack,
    this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.small,
        AppPadding.medium,
        AppPadding.large,
        AppPadding.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppPadding.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (subtitle?.isNotEmpty == true) ...[
                        const SizedBox(height: AppPadding.tiny),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppPadding.medium),
            Padding(
              padding: const EdgeInsets.only(left: AppPadding.small),
              child: action!,
            ),
          ],
        ],
      ),
    );
  }
}
