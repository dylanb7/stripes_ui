import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/Insights/insights.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Displays a list of insights with optional header.
class InsightsList extends StatelessWidget {
  final List<Insight> insights;
  final bool showHeader;

  const InsightsList({
    super.key,
    required this.insights,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            'Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppPadding.small),
        ],
        ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.small),
              child: InsightCard(insight: insight),
            )),
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
