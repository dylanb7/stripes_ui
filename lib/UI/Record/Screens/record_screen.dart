import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(onPressed: () {}, child: const Text('About')),
            ],
          ),
          const SizedBox(height: AppPadding.xxl),
        ],
      ),
    );
  }
}

class Options extends ConsumerWidget {
  final bool hideCheckins;
  const Options({super.key, this.hideCheckins = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final AsyncValue<List<RecordItem>> paths = ref.watch(availableRecordPaths);
    final AsyncValue<List<ReviewItem>> checkins = ref.watch(
      reviewPaths(const ReviewPathsProps()),
    );

    // Modular test system handles injections via stage_ui_registry

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.xl),
        if (!hideCheckins)
          AsyncValueDefaults(
            value: checkins,
            onData: (loadedReviews) {
              var reviews = loadedReviews.map(
                (review) => localizations?.translateReview(review) ?? review,
              );
              final activeCheckins = reviews
                  .where((item) => item.response == null)
                  .toList();
              final completedCheckins = reviews
                  .where((item) => item.response != null)
                  .toList();

              return Column(
                children: [
                  if (completedCheckins.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppPadding.medium),
                      child: ReviewsPageView(
                        reviews: completedCheckins,
                        title: "Completed Check-ins",
                        initiallyExpanded: false,
                        additions: (item) {
                          return null;
                        },
                      ),
                    ),
                  if (activeCheckins.isNotEmpty)
                    ReviewsPageView(
                      reviews: activeCheckins,
                      title: context.translate.checkInLabel,
                      initiallyExpanded: true,
                      additions: (item) {
                        return null;
                      },
                    ),
                ],
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
          child: AsyncValueDefaults(
            value: paths,
            onLoading: (_) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppPadding.tiny,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Breakpoint.small.value,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRounding.small),
                            ),
                            color: Theme.of(context).disabledColor,
                          ),
                          height: 65.0,
                        ),
                      ),
                    ),
                  ).separated(by: const SizedBox(height: AppPadding.small)),
                ],
              );
            },
            onData: (loadedItems) {
              if (ref.watch(configProvider).betaUi.multiSessionFlow) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('start-multi-record'),
                    onPressed: loadedItems.isEmpty
                        ? null
                        : () => context.pushNamed(RouteName.MULTI_RECORD),
                    icon: const Icon(Icons.add),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Text(context.translate.recordStart),
                          Text(
                            context.translate.recordMultipleHint,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // Translate record paths inside items
              final List<RecordItem> translatedItems = loadedItems
                  .map(
                    (item) => RecordItem(
                      path:
                          localizations?.translatePath(item.path) ?? item.path,
                      baselines: item.baselines,
                    ),
                  )
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...translatedItems.mapIndexed((index, item) {
                    final String unlocalizedPathName =
                        loadedItems[index].path.name;
                    final List<Widget> additions = [];
                    return RecordButton(
                      item.path.name,
                      (context) async {
                        await context.pushNamed(
                          'recordType',
                          pathParameters: {'type': unlocalizedPathName},
                          extra: item.baseline,
                        );
                        if (context.mounted) {
                          ref.invalidate(stampsStreamProvider);
                        }
                      },
                      additions,
                      categoryType: unlocalizedPathName,
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppPadding.xl),
      ],
    );
  }
}

class ReviewsPageView extends StatefulWidget {
  final List<ReviewItem> reviews;

  final List<Widget>? Function(ReviewItem) additions;

  final String? title;
  final bool initiallyExpanded;

  const ReviewsPageView({
    super.key,
    required this.reviews,
    required this.additions,
    this.title,
    this.initiallyExpanded = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReviewsPageViewState();
  }
}

class _ReviewsPageViewState extends State<ReviewsPageView> {
  late final ExpansibleController expansionController;

  @override
  void initState() {
    super.initState();
    expansionController = ExpansibleController();
    if (widget.initiallyExpanded) expansionController.expand();
  }

  @override
  void dispose() {
    expansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return const SizedBox();

    return Expansible(
      controller: expansionController,
      headerBuilder: (context, animation) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
        child: Semantics(
          button: true,
          expanded: expansionController.isExpanded,
          child: InkWell(
            onTap: () {
              if (expansionController.isExpanded) {
                expansionController.collapse();
              } else {
                expansionController.expand();
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Icon(
                    Icons.event_repeat,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppPadding.tiny),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: Durations.medium1,
                      style: expansionController.isExpanded
                          ? Theme.of(context).textTheme.titleMedium!
                          : Theme.of(context).textTheme.bodySmall!,
                      child: Text(
                        "${widget.title ?? context.translate.checkInLabel} (${widget.reviews.length})",
                      ),
                    ),
                  ),
                  Icon(
                    expansionController.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bodyBuilder: (context, animation) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
        // Check-ins have variable-length titles, dates, and status text. Let
        // each one grow in the screen's scroll view instead of a fixed-height
        // carousel that clips at larger reading sizes.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in widget.reviews) ...[
              Text(
                item.path.period!.getRangeString(DateTime.now(), context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ReviewButton(item: item, additions: widget.additions(item) ?? []),
              const SizedBox(height: AppPadding.small),
            ],
          ],
        ),
      ),
    );
  }
}

class Header extends ConsumerWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Expanded(child: PatientChanger())],
          ),
        ],
      ),
    );
  }
}

class LastEntryText extends ConsumerWidget {
  const LastEntryText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Stamp>> stamps = ref.watch(stampsStreamProvider);
    return stamps.map(
      data: (data) {
        final String lastEntry = data.value.isEmpty
            ? context.translate.noEntryText
            : context.translate.lastEntry(
                dateFromStamp(data.value.first.stamp),
              );
        return Text(lastEntry, style: Theme.of(context).textTheme.bodyMedium);
      },
      error: (error) => Container(
        height: 10,
        width: 10,
        color: Theme.of(context).colorScheme.error,
      ),
      loading: (loading) => const CircularProgressIndicator(),
    );
  }
}

class ReviewButton extends ConsumerWidget {
  final ReviewItem item;
  final List<Widget> additions;

  const ReviewButton({required this.item, required this.additions, super.key});

  String _formatTimeRemaining(Duration duration, BuildContext context) {
    if (duration.isNegative) return '';
    if (duration.inDays > 0) {
      return '${duration.inDays}d remaining';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h remaining';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m remaining';
    }
    return 'Ending soon';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCompleted = item.response != null;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Calculate time remaining for pending check-ins
    final DateTimeRange range = item.path.period!.getRange(DateTime.now());
    final Duration timeRemaining = range.end.difference(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (item.response != null) {
                String? routeName = item.response!.type;
                await context.pushNamed(
                  'recordType',
                  pathParameters: {'type': routeName},
                  extra: SessionData(
                    responses: {
                      for (final r in item.response!.responses)
                        r.question.id: r,
                    },
                    editId: item.response?.id,
                    submitTime: dateFromStamp(item.response!.stamp),
                    description: item.response!.description,
                  ),
                );
              } else {
                await context.pushNamed(
                  'recordType',
                  pathParameters: {'type': item.type},
                );
              }
              if (context.mounted) {
                ref.invalidate(stampsStreamProvider);
              }
            },
            borderRadius: BorderRadius.circular(AppRounding.medium),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.medium),
                border: Border.all(
                  color: isCompleted
                      ? colors.outlineVariant.withValues(alpha: 0.5)
                      : colors.primary,
                  width: isCompleted ? 1 : 2,
                ),
                color: isCompleted ? colors.surfaceContainerLow : null,
                gradient: isCompleted
                    ? null
                    : LinearGradient(
                        colors: [
                          colors.primaryContainer.withValues(alpha: 0.4),
                          colors.primaryContainer.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              padding: const EdgeInsets.all(AppPadding.small),
              child: Row(
                children: [
                  // Check indicator
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? colors.surfaceContainerHighest
                          : colors.primary,
                      border: isCompleted
                          ? Border.all(color: colors.outlineVariant, width: 1)
                          : null,
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, color: colors.outline, size: 20)
                        : Icon(Icons.add, color: colors.onPrimary, size: 24),
                  ),
                  const SizedBox(width: AppPadding.medium),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.path.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface,
                              ),
                        ),
                        const SizedBox(height: 2),
                        if (isCompleted)
                          Text(
                            'Completed ${_formatLastUpdated(item.response!.stamp, context)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.outline),
                          )
                        else
                          Text(
                            _formatTimeRemaining(timeRemaining, context),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        if (additions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ...additions,
                        ],
                      ],
                    ),
                  ),

                  // Trailing icon
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ).showCursorOnHover,
      ),
    );
  }

  String _formatLastUpdated(int stamp, BuildContext context) {
    final DateTime date = dateFromStamp(stamp);
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

class CheckIndicator extends StatelessWidget {
  final bool checked;

  const CheckIndicator({required this.checked, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 35,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRounding.small),
            border: Border.all(
              width: 3.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: checked
              ? const SizedBox.expand(
                  child: FittedBox(fit: BoxFit.fill, child: Icon(Icons.check)),
                )
              : null,
        ),
      ),
    );
  }
}

class RecordButton extends ConsumerWidget {
  final String text;
  final String? subText;

  /// Raw YAML type code for locale-independent theme resolution.
  final String? categoryType;
  final List<Widget> additions;
  final Function(BuildContext) onClick;

  const RecordButton(
    this.text,
    this.onClick,
    this.additions, {
    this.subText,
    this.categoryType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);
    final CategoryAppearance appearance = CategoryTheme.resolve(
      categoryType ?? text,
    );
    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;

    final Color accentColor = colored
        ? appearance.color
        : Theme.of(context).colorScheme.primary;

    if (!themed) {
      // Non-themed: preserve original style exactly
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
          child: OutlinedButton(
            onPressed: () => onClick(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.small,
                vertical: AppPadding.large,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                        ),
                        ...additions,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppPadding.small),
                  Icon(Icons.add, size: 35, color: accentColor),
                ],
              ),
            ),
          ).showCursorOnHover,
        ),
      );
    }

    // ── Themed layout ──────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRounding.medium),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onClick(context),
            borderRadius: BorderRadius.circular(AppRounding.medium),
            splashColor: accentColor.withValues(alpha: 0.10),
            highlightColor: accentColor.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.medium),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accentColor.withValues(alpha: 0.08),
                    accentColor.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left accent bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRounding.medium),
                          bottomLeft: Radius.circular(AppRounding.medium),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    // Icon badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CategoryIcon(appearance: appearance, size: 24),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    // Label + additions
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppPadding.large,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            if (additions.isNotEmpty) ...additions,
                          ],
                        ),
                      ),
                    ),
                    // Arrow indicator
                    Padding(
                      padding: const EdgeInsets.only(right: AppPadding.medium),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).showCursorOnHover,
      ),
    );
  }
}
