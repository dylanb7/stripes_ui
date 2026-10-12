import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Dashboard/today_provider.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/DashboardView/compact_entry_card.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class RecentEntriesSection extends ConsumerWidget {
  const RecentEntriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentEntriesProvider);
    return recentAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Text('Unable to load recent entries: $error'),
      data: (recent) => _buildLoaded(context, ref, recent),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    WidgetRef ref,
    List<Response> recent,
  ) {
    final StripesConfig config = ref.watch(configProvider);
    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;
    final colors = Theme.of(context).colorScheme;

    // Show at most 5 recent entries
    final displayEntries = recent.take(5).toList();
    final localizations = QuestionsLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with inline record button
        Row(
          children: [
            Text(
              'Recent',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.small),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
            child: Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppPadding.small),
                Text(
                  'No entries in the last 24 hours',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          )
        else ...[
          ...displayEntries.map((response) {
            final appearance = CategoryTheme.resolve(response.type);
            final Color color = colored ? appearance.color : colors.primary;
            final DateTime time = dateFromStamp(response.stamp);
            final String displayName =
                localizations?.value(response.type) ?? response.type;

            return CompactEntryCard(
              response: response,
              icon: themed ? appearance.icon : null,
              label: displayName,
              time: time,
              color: color,
              themed: themed,
            );
          }),
          // "+N more" → tappable link navigating to history
          if (recent.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: AppPadding.tiny),
              child: InkWell(
                onTap: () {
                  ref
                      .read(navigationControllerProvider)
                      .navigate(context, Routes.HISTORY);
                },
                borderRadius: BorderRadius.circular(AppRounding.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.small,
                    horizontal: AppPadding.tiny,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View ${recent.length - 5} more in History',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
