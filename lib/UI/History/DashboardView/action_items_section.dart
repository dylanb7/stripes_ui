import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:go_router/go_router.dart';

abstract class ActionItem {
  Widget build(BuildContext context, WidgetRef ref);
}

final actionItemsProvider = Provider<List<ActionItem>>((ref) {
  final List<ActionItem> items = [];

  final AsyncValue<List<ReviewItem>> checkinsAsync = ref.watch(
    reviewPaths(const ReviewPathsProps()),
  );
  if (checkinsAsync.hasValue) {
    final activeCheckins = (checkinsAsync.value ?? const <ReviewItem>[]).where(
      (item) => item.response == null,
    );
    items.addAll(activeCheckins.map((c) => CheckinActionItem(item: c)));
  }

  ref
      .watch(hasTestsProvider)
      .when(
        data: (hasTests) {
          if (!hasTests) return;
          ref
              .watch(blueDyeTestProgressProvider)
              .when(
                data: (progress) {
                  final progression = progress.getProgression();
                  if (progression != null &&
                      progression != BlueDyeProgression.completed) {
                    items.add(TestActionItem(progress: progress));
                  }
                },
                loading: () {},
                error: (error, stackTrace) {},
              );
        },
        loading: () {},
        error: (error, stackTrace) {},
      );

  return items;
});

class OngoingTasksSection extends ConsumerWidget {
  const OngoingTasksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionItems = ref.watch(actionItemsProvider);

    if (actionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppPadding.small),
              Text(
                'Action Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          ...actionItems.map((item) => item.build(context, ref)),
          const Divider(
            height: AppPadding.xl,
            thickness: 2.0,
            indent: AppPadding.medium,
            endIndent: AppPadding.medium,
          ),
        ],
      ),
    );
  }
}

class ActionItemCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context, WidgetRef ref) onTap;
  final Widget? extraContent;

  const ActionItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onTap(context, ref),
        borderRadius: BorderRadius.circular(AppRounding.medium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRounding.medium),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            color: colors.primaryContainer.withValues(alpha: 0.1),
          ),
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.onPrimary, size: 20),
              ),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ?extraContent,
                  ],
                ),
              ),
              const SizedBox(width: AppPadding.medium),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckinActionItem implements ActionItem {
  final ReviewItem item;
  CheckinActionItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = QuestionsLocalizations.of(context);
    final translatedItem = localizations?.translateReview(item) ?? item;

    // Modular test system handles additions via stage injections
    final List<Widget> additions = [];

    final DateTimeRange range = translatedItem.path.period!.getRange(
      DateTime.now(),
    );
    final Duration timeRemaining = range.end.difference(DateTime.now());

    String timeRemainingStr = 'Ending soon';
    if (!timeRemaining.isNegative) {
      if (timeRemaining.inDays > 0) {
        timeRemainingStr = '${timeRemaining.inDays}d remaining';
      } else if (timeRemaining.inHours > 0) {
        timeRemainingStr = '${timeRemaining.inHours}h remaining';
      } else if (timeRemaining.inMinutes > 0) {
        timeRemainingStr = '${timeRemaining.inMinutes}m remaining';
      }
    }

    Widget? extra;
    if (additions.isNotEmpty) {
      extra = Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: additions,
        ),
      );
    }

    return ActionItemCard(
      title: translatedItem.path.name,
      subtitle: timeRemainingStr,
      icon: Icons.assignment,
      onTap: (ctx, ref) async {
        await ctx.pushNamed(
          'recordType',
          pathParameters: {'type': translatedItem.type},
        );
        if (ctx.mounted) {
          ref.invalidate(stampsStreamProvider);
        }
      },
      extraContent: extra,
    );
  }
}

class TestActionItem implements ActionItem {
  final BlueDyeTestProgress progress;
  TestActionItem({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currentStage = progress.getProgression();

    return ActionItemCard(
      title: 'Blue Dye Transit',
      subtitle: currentStage != null
          ? currentStage.getLabel(context)
          : 'In Progress',
      icon: Icons.science,
      onTap: (ctx, ref) {
        ref.read(navigationControllerProvider).navigate(ctx, Routes.TEST);
      },
      extraContent: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          children: List.generate(5, (index) {
            final int stageValue = currentStage?.value ?? 0;
            final bool isActive = index <= stageValue;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary
                      : colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
