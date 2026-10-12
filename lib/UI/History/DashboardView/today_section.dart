import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Dashboard/today_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/DashboardView/compact_entry_card.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Util/constants.dart';

class TodayActivitySection extends ConsumerStatefulWidget {
  const TodayActivitySection({super.key});

  @override
  ConsumerState<TodayActivitySection> createState() =>
      _TodayActivitySectionState();
}

class _TodayActivitySectionState extends ConsumerState<TodayActivitySection> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> todayCounts = ref
        .watch(todayCategoryCountsProvider)
        .when(
          data: (value) => value,
          loading: () => const {},
          error: (_, _) => const {},
        );
    final StripesConfig config = ref.watch(configProvider);
    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;

    final paths = ref.watch(availableRecordPaths);
    final List<String> allCategories = paths.when(
      data: (value) => value.map((item) => item.path.name).toList(),
      loading: () => const [],
      error: (_, _) => const [],
    );

    if (allCategories.isEmpty) return const SizedBox.shrink();

    final localizations = QuestionsLocalizations.of(context);

    final List<Response> todayResponses = ref
        .watch(todayResponsesProvider)
        .when(
          data: (value) => value,
          loading: () => const [],
          error: (_, _) => const [],
        );
    final Map<String, List<Response>> responsesByCategory = {};
    for (final r in todayResponses) {
      responsesByCategory.putIfAbsent(r.type, () => []).add(r);
    }

    final bool hasExpanded =
        _expandedCategory != null &&
        (responsesByCategory[_expandedCategory]?.isNotEmpty ?? false);
    final List<Response> expandedResponses = hasExpanded
        ? responsesByCategory[_expandedCategory]!
        : [];
    final String expandedLabel = hasExpanded
        ? (localizations?.value(_expandedCategory!) ?? _expandedCategory!)
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: allCategories.map((categoryType) {
            final int count = todayCounts[categoryType] ?? 0;
            final appearance = CategoryTheme.resolve(categoryType);
            final Color color = colored
                ? appearance.color
                : Theme.of(context).colorScheme.primary;
            final String displayName =
                localizations?.value(categoryType) ?? categoryType;

            return _CategoryActions(
              icon: themed ? appearance.icon : null,
              label: displayName,
              categoryType: categoryType,
              count: count,
              color: color,
              themed: themed,
              isExpanded: _expandedCategory == categoryType,
              onToggle: count > 0
                  ? () {
                      setState(() {
                        _expandedCategory = _expandedCategory == categoryType
                            ? null
                            : categoryType;
                      });
                    }
                  : null,
              onRecord: () => _recordForCategory(context, ref, categoryType),
            );
          }).toList(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: hasExpanded
              ? _InlineCategoryPanel(
                  key: ValueKey(_expandedCategory),
                  responses: expandedResponses,
                  label: expandedLabel,
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  void _recordForCategory(
    BuildContext context,
    WidgetRef ref,
    String categoryType,
  ) {
    final paths = ref
        .read(availableRecordPaths)
        .when(
          data: (value) => value,
          loading: () => const [],
          error: (_, _) => const [],
        );
    for (final item in paths) {
      if (item.path.name == categoryType) {
        if (ref.read(configProvider).betaUi.multiSessionFlow) {
          context.pushNamed(
            RouteName.MULTI_RECORD,
            queryParameters: {'category': categoryType},
          );
          return;
        }
        context.pushNamed(
          'recordType',
          pathParameters: {'type': categoryType},
          extra: item.baseline,
        );
        return;
      }
    }
  }
}

/// Logging and reviewing stay separate as today's entry counts change.
class _CategoryActions extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String categoryType;
  final int count;
  final Color color;
  final bool themed;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback onRecord;

  const _CategoryActions({
    required this.icon,
    required this.label,
    required this.categoryType,
    required this.count,
    required this.color,
    required this.themed,
    required this.isExpanded,
    required this.onToggle,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.small,
      ),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
    final record = TextButton(
      key: ValueKey('today-log-$categoryType'),
      onPressed: onRecord,
      style: style,
      child: Row(
        children: [
          if (themed && icon != null)
            CategoryIcon(
              appearance: CategoryTheme.resolve(categoryType),
              size: 20,
            )
          else
            const Icon(Icons.add, size: 20),
          const SizedBox(width: AppPadding.small),
          Expanded(child: Text('Log $label')),
        ],
      ),
    );
    if (count == 0) return record;

    final review = Semantics(
      label: '$label: $count entries today',
      expanded: isExpanded,
      child: TextButton(
        key: ValueKey('today-review-$categoryType'),
        onPressed: onToggle,
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            isExpanded ? color.withValues(alpha: 0.08) : null,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text('$count today')),
            const SizedBox(width: AppPadding.tiny),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Give enlarged labels the full width instead of squeezing two actions.
        final needsStack =
            MediaQuery.textScalerOf(context).scale(14) > 20 ||
            constraints.maxWidth < 280;
        if (needsStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [record, review],
          );
        }
        return Row(
          children: [
            Expanded(child: record),
            const SizedBox(width: AppPadding.tiny),
            Flexible(child: review),
          ],
        );
      },
    );
  }
}

class _InlineCategoryPanel extends ConsumerWidget {
  final List<Response> responses;
  final String label;

  const _InlineCategoryPanel({
    super.key,
    required this.responses,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = QuestionsLocalizations.of(context);
    final betaUi = ref.watch(configProvider).betaUi;
    final colored = betaUi.categoryColorsEnabled;
    final themed = betaUi.useCategoryTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppPadding.small),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                child: Text(
                  '$label today',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
          ...responses.map((response) {
            final DateTime time = dateFromStamp(response.stamp);
            final String displayName =
                localizations?.value(response.type) ?? response.type;
            final appearance = CategoryTheme.resolve(response.type);

            return CompactEntryCard(
              response: response,
              icon: themed ? appearance.icon : null,
              label: displayName,
              time: time,
              color: colored
                  ? appearance.color
                  : Theme.of(context).colorScheme.primary,
              themed: themed,
            );
          }),
        ],
      ),
    );
  }
}
