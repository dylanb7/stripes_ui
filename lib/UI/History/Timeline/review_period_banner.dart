import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/UI/History/Timeline/review_period_data.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// A floating banner that shows when the user is within a review period.
class ReviewPeriodBanner extends StatelessWidget {
  final List<ReviewPeriod> activePeriods;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ReviewPeriodBanner({
    super.key,
    required this.activePeriods,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (activePeriods.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final localizations = QuestionsLocalizations.of(context);

    // Group by type
    final Map<String, List<ReviewPeriod>> byType = {};
    for (final period in activePeriods) {
      byType.putIfAbsent(period.type, () => []).add(period);
    }

    return Material(
      elevation: 4,
      shadowColor: colors.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRounding.small),
      color: colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRounding.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_repeat,
                size: 18,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: AppPadding.small),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'During:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    ...byType.entries.take(2).map((entry) {
                      final typeName =
                          localizations?.value(entry.key) ?? entry.key;
                      final count = entry.value.length;
                      return Text(
                        count > 1 ? '$typeName (×$count)' : typeName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onPrimaryContainer,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    if (byType.length > 2)
                      Text(
                        '+${byType.length - 2} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                  ],
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: AppPadding.small),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that overlays the event list with floating review period banners.
///
/// It tracks scroll position and shows banners when events within a review
/// period's date range are visible.
class ReviewPeriodOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final void Function(List<ReviewPeriod> periods)? onPeriodsTap;

  const ReviewPeriodOverlay({
    super.key,
    required this.child,
    required this.scrollController,
    this.onPeriodsTap,
  });

  @override
  ConsumerState<ReviewPeriodOverlay> createState() =>
      _ReviewPeriodOverlayState();
}

class _ReviewPeriodOverlayState extends ConsumerState<ReviewPeriodOverlay> {
  bool _isVisible = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Show banner only when scrolled past threshold
    if (!mounted) return;
    final offset = widget.scrollController.offset;
    final shouldShow = offset > 100;

    if (shouldShow != _isVisible && !_isAnimating) {
      setState(() {
        _isVisible = shouldShow;
      });
    }
  }

  void _onDismiss() {
    setState(() {
      _isAnimating = true;
      _isVisible = false;
    });
    // Re-enable after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reviewPeriodsProvider);

    return periodsAsync.when(
      loading: () => widget.child,
      error: (_, __) => widget.child,
      data: (periods) {
        if (periods.isEmpty) return widget.child;

        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  offset: _isVisible ? Offset.zero : const Offset(0, -2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isVisible ? 1.0 : 0.0,
                    child: ReviewPeriodBanner(
                      activePeriods: periods,
                      onTap: widget.onPeriodsTap != null
                          ? () => widget.onPeriodsTap!(periods)
                          : null,
                      onDismiss: _onDismiss,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
