import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/Insights/insights.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Collapsible insights section - shows compact by default.
class InsightsList extends StatefulWidget {
  final List<Insight> insights;
  final bool initiallyExpanded;

  const InsightsList({
    super.key,
    required this.insights,
    this.initiallyExpanded = false,
  });

  @override
  State<InsightsList> createState() => _InsightsListState();
}

class _InsightsListState extends State<InsightsList> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    final ColorScheme colors = Theme.of(context).colorScheme;
    final int count = widget.insights.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible header
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppPadding.small,
              horizontal: AppPadding.small,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Text(
                    _isExpanded
                        ? 'Insights'
                        : '$count insight${count != 1 ? 's' : ''} available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expandable content
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppPadding.small),
                  child: Column(
                    children: widget.insights
                        .map((insight) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppPadding.small),
                              child: InsightCard(insight: insight),
                            ))
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A single expandable insight card with optional visualization.
class InsightCard extends StatefulWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget? visualization = widget.insight.buildVisualization(context);
    final bool hasVisualization = visualization != null;

    return GestureDetector(
      onTap: hasVisualization
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRounding.small),
          border: _isExpanded
              ? Border.all(color: colors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.insight.icon ?? Icons.circle,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.insight.getTitle(context),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          widget.insight.getDescriptionSpan(context),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (hasVisualization)
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // Expandable visualization
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded && hasVisualization
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: AppPadding.small,
                          left: 26, // Align with text after icon
                        ),
                        child: visualization,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
