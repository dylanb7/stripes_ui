import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Insights/Engine/finding.dart';
import 'package:stripes_ui/Insights/Engine/insight_dataset.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/CommonWidgets/AppStyleHelpers/app_surface.dart';
import 'package:stripes_ui/UI/History/Insights/finding_presentation.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// A quiet empty state for periods that have logs but no presentable finding.
class EngineFindingsNotice extends StatelessWidget {
  final FindingFeedState state;
  final bool compact;

  const EngineFindingsNotice({
    super.key,
    required this.state,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (state == FindingFeedState.ready || state == FindingFeedState.noData) {
      return const SizedBox.shrink();
    }
    final (IconData icon, String title, String message) = switch (state) {
      FindingFeedState.stillLearning => (
        Icons.info_outline,
        'Not enough data for patterns',
        'Patterns require more repeated logs to make a reliable comparison.',
      ),
      FindingFeedState.noNotablePattern => (
        Icons.check_circle_outline,
        'No notable patterns',
        'Nothing in this period passed the evidence thresholds for a pattern.',
      ),
      FindingFeedState.unavailable => (
        Icons.info_outline,
        'Findings unavailable',
        'Your history is still available while this analysis is unavailable.',
      ),
      _ => throw StateError('Unexpected finding feed state: $state'),
    };
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title. $message',
      child: AppSurface(
        level: SurfaceLevel.low,
        rounding: AppRounding.medium,
        borderAlpha: 0.2,
        padding: EdgeInsets.all(compact ? AppPadding.small : AppPadding.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: AppPadding.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents raw engine findings with labels resolved from their source dataset.
class EngineFindingsList extends StatelessWidget {
  final List<Finding> findings;
  final InsightDataset dataset;
  final FindingPresenterRegistry? registry;
  final bool compact;
  final bool showGroupHeadings;
  final bool showGraphics;

  const EngineFindingsList({
    super.key,
    required this.findings,
    required this.dataset,
    this.registry,
    this.compact = false,
    this.showGroupHeadings = true,
    this.showGraphics = true,
  });

  @override
  Widget build(BuildContext context) {
    final labels = FindingLabels.fromContext(context, dataset);
    final presentations = (registry ?? FindingPresenterRegistry.standard())
        .presentAll(findings, labels);
    return FindingsList(
      findings: presentations,
      compact: compact,
      showGroupHeadings: showGroupHeadings,
      showGraphics: showGraphics,
    );
  }
}

/// A list that keeps observational findings separate from exact summaries.
class FindingsList extends StatelessWidget {
  final List<FindingPresentation> findings;
  final bool compact;
  final bool showGroupHeadings;
  final bool showGraphics;

  const FindingsList({
    super.key,
    required this.findings,
    this.compact = false,
    this.showGroupHeadings = true,
    this.showGraphics = true,
  });

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    final patterns = findings.where((finding) => !finding.isSummary).toList();
    final summaries = findings.where((finding) => finding.isSummary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (patterns.isNotEmpty)
          _FindingGroup(
            title: 'Patterns',
            icon: Icons.auto_graph_rounded,
            findings: patterns,
            compact: compact,
            showHeading: showGroupHeadings,
            showGraphics: showGraphics,
          ),
        if (patterns.isNotEmpty && summaries.isNotEmpty)
          const SizedBox(height: AppPadding.large),
        if (summaries.isNotEmpty)
          _FindingGroup(
            title: 'Summaries',
            icon: Icons.data_usage_outlined,
            findings: summaries,
            compact: compact,
            showHeading: showGroupHeadings,
            showGraphics: showGraphics,
          ),
      ],
    );
  }
}

class _FindingGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FindingPresentation> findings;
  final bool compact;
  final bool showHeading;
  final bool showGraphics;

  const _FindingGroup({
    required this.title,
    required this.icon,
    required this.findings,
    required this.compact,
    required this.showHeading,
    required this.showGraphics,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showHeading) ...[
        Row(
          children: [
            Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppPadding.small),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppPadding.small),
            Text(
              '${findings.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.small),
      ],
      for (var index = 0; index < findings.length; index++) ...[
        FindingCard(
          finding: findings[index],
          compact: compact,
          showGraphic: showGraphics,
        ),
        if (index < findings.length - 1)
          const SizedBox(height: AppPadding.small),
      ],
    ],
  );
}

/// Reusable full or compact card for dashboard and history surfaces.
class FindingCard extends StatelessWidget {
  final FindingPresentation finding;
  final bool compact;
  final bool showGraphic;

  const FindingCard({
    super.key,
    required this.finding,
    this.compact = false,
    this.showGraphic = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themed = _usesCategoryTheme(context);
    final categoryColors = _usesCategoryTheme(context, colorsOnly: true)
        ? finding.categoryIds
              .map((id) => CategoryTheme.resolve(id).color)
              .toList()
        : <Color>[];
    final accent = categoryColors.firstOrNull ?? colors.primary;
    final graphic = showGraphic ? finding.graphic : null;
    final semanticsLabel = [
      finding.eyebrow,
      finding.title,
      ?finding.metricValue,
      ?finding.metricLabel,
      ...finding.highlights.map((highlight) => highlight.label),
      finding.description,
      finding.evidenceText,
      ?finding.qualification,
    ].join('. ');

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: AppSurface(
        level: SurfaceLevel.low,
        rounding: AppRounding.medium,
        borderAlpha: 0.22,
        padding: EdgeInsets.all(compact ? AppPadding.medium : AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindIcon(
                  kind: finding.kind,
                  compact: compact,
                  color: accent,
                  categoryAppearance: themed && finding.categoryIds.length == 1
                      ? CategoryTheme.resolve(finding.categoryIds.first)
                      : null,
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finding.eyebrow.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppPadding.tiny),
                      Text(
                        finding.title,
                        style:
                            (compact
                                    ? Theme.of(context).textTheme.titleSmall
                                    : Theme.of(context).textTheme.titleMedium)
                                ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? AppPadding.small : AppPadding.medium),
            if (finding.metricValue case final metric?) ...[
              Text(
                metric,
                style:
                    (compact
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(color: accent, fontWeight: FontWeight.w800),
              ),
              if (finding.metricLabel case final label?)
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: AppPadding.small),
            ],
            if (finding.highlights.isNotEmpty)
              Wrap(
                spacing: AppPadding.small,
                runSpacing: AppPadding.small,
                children: [
                  for (final highlight in finding.highlights)
                    _FindingHighlightChip(
                      highlight: highlight,
                      themed: themed,
                      fallbackColor: accent,
                    ),
                ],
              )
            else
              Text(
                finding.description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface, height: 1.3),
              ),
            if (graphic != null) ...[
              SizedBox(height: compact ? AppPadding.small : AppPadding.medium),
              _FindingGraphic(
                data: graphic,
                compact: compact,
                themed: _usesCategoryTheme(context, colorsOnly: true),
                accent: accent,
              ),
            ],
            SizedBox(height: compact ? AppPadding.small : AppPadding.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Text(
                    finding.evidenceText,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (finding.qualification case final qualification?) ...[
              const SizedBox(height: AppPadding.small),
              Text(
                qualification,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _usesCategoryTheme(BuildContext context, {bool colorsOnly = false}) {
  try {
    final beta = ProviderScope.containerOf(context).read(configProvider).betaUi;
    return colorsOnly ? beta.categoryColorsEnabled : beta.useCategoryTheme;
  } on StateError {
    // FindingCard is also reusable in previews and isolated widget tests.
    return false;
  }
}

class _KindIcon extends StatelessWidget {
  final FindingKind kind;
  final bool compact;
  final Color color;
  final CategoryAppearance? categoryAppearance;

  const _KindIcon({
    required this.kind,
    required this.compact,
    required this.color,
    this.categoryAppearance,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = switch (kind) {
      FindingKind.aggregate => Icons.data_usage_outlined,
      FindingKind.observation => Icons.auto_graph_rounded,
      FindingKind.anomaly => Icons.notification_important_outlined,
      FindingKind.inferential => Icons.hub_outlined,
    };
    final size = compact ? 32.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: categoryAppearance == null
          ? Icon(resolvedIcon, size: compact ? 18 : 20, color: color)
          : CategoryIcon(
              appearance: categoryAppearance!,
              size: compact ? 18 : 20,
            ),
    );
  }
}

class _FindingHighlightChip extends StatelessWidget {
  final FindingHighlight highlight;
  final bool themed;
  final Color fallbackColor;

  const _FindingHighlightChip({
    required this.highlight,
    required this.themed,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final categoryId = highlight.categoryId;
    final appearance = categoryId == null
        ? null
        : CategoryTheme.resolve(categoryId);
    final color =
        _usesCategoryTheme(context, colorsOnly: true) && appearance != null
        ? appearance.color
        : fallbackColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.tiny,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRounding.small),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (themed && appearance != null) ...[
            CategoryIcon(appearance: appearance, size: 14),
            const SizedBox(width: AppPadding.tiny),
          ],
          Text(
            highlight.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FindingGraphic extends StatelessWidget {
  final FindingGraphicData data;
  final bool compact;
  final bool themed;
  final Color accent;

  const _FindingGraphic({
    required this.data,
    required this.compact,
    required this.themed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => switch (data) {
    RelationshipGraphicData() => _RelationshipGraphic(
      data: data as RelationshipGraphicData,
      compact: compact,
    ),
    DistributionGraphicData() => _DistributionGraphic(
      data: data as DistributionGraphicData,
      compact: compact,
      accent: accent,
    ),
    HistogramGraphicData() => _HistogramGraphic(
      data: data as HistogramGraphicData,
      compact: compact,
      accent: accent,
    ),
    CoOccurrenceGraphicData() => _CoOccurrenceGraphic(
      data: data as CoOccurrenceGraphicData,
      themed: themed,
      fallbackColor: accent,
    ),
    ActivityStripGraphicData() => _ActivityStripGraphic(
      data: data as ActivityStripGraphicData,
      accent: accent,
    ),
  };
}

class _RelationshipGraphic extends StatelessWidget {
  final RelationshipGraphicData data;
  final bool compact;

  const _RelationshipGraphic({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compact ? 54 : 70,
          width: double.infinity,
          child: CustomPaint(
            painter: _RelationshipPainter(
              leftValues: data.leftValues,
              rightValues: data.rightValues,
              leftColor: colors.primary,
              rightColor: colors.tertiary,
              gridColor: colors.outlineVariant,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppPadding.small),
          Wrap(
            spacing: AppPadding.medium,
            runSpacing: AppPadding.tiny,
            children: [
              _LegendItem(color: colors.primary, label: data.leftLabel),
              _LegendItem(color: colors.tertiary, label: data.rightLabel),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: AppPadding.tiny),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _RelationshipPainter extends CustomPainter {
  final List<double> leftValues;
  final List<double> rightValues;
  final Color leftColor;
  final Color rightColor;
  final Color gridColor;

  const _RelationshipPainter({
    required this.leftValues,
    required this.rightValues,
    required this.leftColor,
    required this.rightColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leftValues.isEmpty || rightValues.isEmpty || size.isEmpty) return;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );
    _drawSeries(canvas, size, leftValues, leftColor);
    _drawSeries(canvas, size, rightValues, rightColor);
  }

  void _drawSeries(Canvas canvas, Size size, List<double> values, Color color) {
    final finite = values.where((value) => value.isFinite).toList();
    if (finite.isEmpty) return;
    final minimum = finite.reduce(math.min);
    final maximum = finite.reduce(math.max);
    final spread = maximum - minimum;
    final usableHeight = math.max(0.0, size.height - 8);
    final path = Path();
    var started = false;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (!value.isFinite) continue;
      final x = values.length == 1
          ? size.width / 2
          : index / (values.length - 1) * size.width;
      final normalized = spread == 0 ? 0.5 : (value - minimum) / spread;
      final y = 4 + (1 - normalized) * usableHeight;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter oldDelegate) =>
      oldDelegate.leftValues != leftValues ||
      oldDelegate.rightValues != rightValues ||
      oldDelegate.leftColor != leftColor ||
      oldDelegate.rightColor != rightColor ||
      oldDelegate.gridColor != gridColor;
}

class _DistributionGraphic extends StatelessWidget {
  final DistributionGraphicData data;
  final bool compact;
  final Color accent;

  const _DistributionGraphic({
    required this.data,
    required this.compact,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < data.values.length; index++) ...[
          _DistributionRow(value: data.values[index], accent: accent),
          if (index < data.values.length - 1)
            SizedBox(height: compact ? AppPadding.tiny : AppPadding.small),
        ],
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final FindingBarDatum value;
  final Color accent;

  const _DistributionRow({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (value.fraction * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            value.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: value.emphasized ? accent : colors.onSurfaceVariant,
              fontWeight: value.emphasized ? FontWeight.w700 : null,
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRounding.tiny),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: colors.surfaceContainerHighest),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        key: Key('distribution-fill-${value.label}'),
                        width:
                            constraints.maxWidth *
                            value.fraction.clamp(0.0, 1.0),
                        height: constraints.maxHeight,
                        color: value.emphasized ? accent : colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        SizedBox(
          width: 38,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: value.emphasized ? FontWeight.w700 : null,
              color: value.emphasized ? accent : colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistogramGraphic extends StatelessWidget {
  final HistogramGraphicData data;
  final bool compact;
  final Color accent;

  const _HistogramGraphic({
    required this.data,
    required this.compact,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maximum = data.values.fold<int>(
      0,
      (current, value) => math.max(current, value.count),
    );
    return SizedBox(
      key: const Key('finding-histogram'),
      height: compact ? 70 : 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < data.values.length; index++) ...[
            Expanded(
              child: _HistogramColumn(
                value: data.values[index],
                maximum: maximum,
                accent: accent,
                trackColor: colors.surfaceContainerHighest,
              ),
            ),
            if (index < data.values.length - 1)
              SizedBox(width: data.values.length > 12 ? 2 : 5),
          ],
        ],
      ),
    );
  }
}

class _HistogramColumn extends StatelessWidget {
  final FindingHistogramDatum value;
  final int maximum;
  final Color accent;
  final Color trackColor;

  const _HistogramColumn({
    required this.value,
    required this.maximum,
    required this.accent,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maximum == 0 ? 0.0 : value.count / maximum;
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(child: ColoredBox(color: trackColor)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      key: value.emphasized
                          ? const Key('finding-histogram-peak')
                          : null,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight * fraction,
                      color: value.emphasized
                          ? accent
                          : accent.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 14,
          child: Text(
            value.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoOccurrenceGraphic extends StatelessWidget {
  final CoOccurrenceGraphicData data;
  final bool themed;
  final Color fallbackColor;

  const _CoOccurrenceGraphic({
    required this.data,
    required this.themed,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (data.days.isEmpty) return const SizedBox.shrink();

    final left = themed
        ? CategoryTheme.resolve(data.leftCategoryId).color
        : fallbackColor;
    final right = themed
        ? CategoryTheme.resolve(data.rightCategoryId).color
        : fallbackColor;
    final empty = colors.surfaceContainerHighest;

    return LayoutBuilder(
      key: const Key('co-occurrence-days'),
      builder: (context, constraints) {
        final ranges = _adaptiveStripRanges(
          data.days.length,
          constraints.maxWidth,
        );
        final grouped = ranges.length < data.days.length;
        final gap = _adaptiveStripGap(ranges.length, grouped: grouped);

        return Column(
          children: [
            SizedBox(
              height: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRounding.tiny),
                child: Row(
                  children: [
                    for (var index = 0; index < ranges.length; index++) ...[
                      Expanded(
                        child: _CoOccurrenceStripSegment(
                          key: Key(
                            grouped
                                ? 'co-occurrence-group-$index'
                                : 'co-occurrence-day-$index',
                          ),
                          sourceDays: data.days.sublist(
                            ranges[index].start,
                            ranges[index].end,
                          ),
                          left: left,
                          right: right,
                          empty: empty,
                          leftLabel: data.leftLabel,
                          rightLabel: data.rightLabel,
                          keyPrefix: grouped
                              ? 'co-occurrence-group-$index'
                              : 'co-occurrence-day-$index',
                        ),
                      ),
                      if (index < ranges.length - 1) SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.tiny),
            _FullPeriodStripCaption(
              days: data.days.length,
              grouped: grouped,
              activeDays: true,
              minimumDaysPerSegment: _minimumStripRangeLength(ranges),
              maximumDaysPerSegment: _maximumStripRangeLength(ranges),
            ),
          ],
        );
      },
    );
  }
}

class _CoOccurrenceStripSegment extends StatelessWidget {
  final List<CoOccurrenceDayDatum> sourceDays;
  final Color left;
  final Color right;
  final Color empty;
  final String? leftLabel;
  final String? rightLabel;
  final String keyPrefix;

  const _CoOccurrenceStripSegment({
    super.key,
    required this.sourceDays,
    required this.left,
    required this.right,
    required this.empty,
    required this.leftLabel,
    required this.rightLabel,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final leftCount = sourceDays.where((day) => day.leftLogged).length;
    final rightCount = sourceDays.where((day) => day.rightLogged).length;
    final overlapCount = sourceDays
        .where((day) => day.leftLogged && day.rightLogged)
        .length;
    final leftRate = leftCount / sourceDays.length;
    final rightRate = rightCount / sourceDays.length;
    return Semantics(
      label:
          '${leftLabel ?? 'First category'} on $leftCount, ${rightLabel ?? 'second category'} on $rightCount, and both on $overlapCount of ${sourceDays.length} active days.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                key: Key('$keyPrefix-left'),
                color: Color.lerp(empty, left, leftRate)!,
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: ColoredBox(
                key: Key('$keyPrefix-right'),
                color: Color.lerp(empty, right, rightRate)!,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStripSegment extends StatelessWidget {
  final List<bool> sourceDays;
  final Color accent;
  final Color empty;

  const _ActivityStripSegment({
    super.key,
    required this.sourceDays,
    required this.accent,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = sourceDays.where((active) => active).length;
    return Semantics(
      label: '$activeCount of ${sourceDays.length} days logged.',
      child: ExcludeSemantics(
        child: ColoredBox(
          color: Color.lerp(empty, accent, activeCount / sourceDays.length)!,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ActivityStripGraphic extends StatelessWidget {
  final ActivityStripGraphicData data;
  final Color accent;

  const _ActivityStripGraphic({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (data.activeDays.isEmpty) return const SizedBox.shrink();
    final empty = Theme.of(context).colorScheme.surfaceContainerHighest;

    return LayoutBuilder(
      key: const Key('activity-days'),
      builder: (context, constraints) {
        final ranges = _adaptiveStripRanges(
          data.activeDays.length,
          constraints.maxWidth,
        );
        final grouped = ranges.length < data.activeDays.length;
        final gap = _adaptiveStripGap(ranges.length, grouped: grouped);

        return Column(
          children: [
            SizedBox(
              height: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRounding.tiny),
                child: Row(
                  children: [
                    for (var index = 0; index < ranges.length; index++) ...[
                      Expanded(
                        child: _ActivityStripSegment(
                          key: Key(
                            grouped
                                ? 'activity-group-$index'
                                : 'activity-day-$index',
                          ),
                          sourceDays: data.activeDays.sublist(
                            ranges[index].start,
                            ranges[index].end,
                          ),
                          accent: accent,
                          empty: empty,
                        ),
                      ),
                      if (index < ranges.length - 1) SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.tiny),
            _FullPeriodStripCaption(
              days: data.activeDays.length,
              grouped: grouped,
              minimumDaysPerSegment: _minimumStripRangeLength(ranges),
              maximumDaysPerSegment: _maximumStripRangeLength(ranges),
            ),
          ],
        );
      },
    );
  }
}

class _FullPeriodStripCaption extends StatelessWidget {
  final int days;
  final bool grouped;
  final bool activeDays;
  final int minimumDaysPerSegment;
  final int maximumDaysPerSegment;

  const _FullPeriodStripCaption({
    required this.days,
    required this.grouped,
    required this.minimumDaysPerSegment,
    required this.maximumDaysPerSegment,
    this.activeDays = false,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = activeDays ? 'active days' : 'days';
    final centerLabel = grouped
        ? 'All $days $dayLabel · grouped to fit'
        : 'All $days $dayLabel';
    final segmentSizeLabel = minimumDaysPerSegment == maximumDaysPerSegment
        ? '$minimumDaysPerSegment'
        : '$minimumDaysPerSegment–$maximumDaysPerSegment';
    final groupingLabel = grouped
        ? '$segmentSizeLabel days per block · darker = ${activeDays ? 'logged more often' : 'more days logged'}'
        : null;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 9,
    );
    return Semantics(
      label:
          'Earlier to later. $centerLabel.${groupingLabel == null ? '' : ' $groupingLabel.'}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                Text('Earlier', style: style),
                Expanded(
                  child: Text(
                    centerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
                Text('Later', style: style),
              ],
            ),
            if (groupingLabel case final label?) ...[
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: style,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef _StripRange = ({int start, int end});

List<_StripRange> _adaptiveStripRanges(int itemCount, double availableWidth) {
  if (itemCount <= 0) return const [];
  const minimumSegmentExtent = 5.0;
  final width = availableWidth.isFinite && availableWidth > 0
      ? availableWidth
      : minimumSegmentExtent;
  final maximumSegments = math.max(1, (width / minimumSegmentExtent).floor());
  final segmentCount = math.min(itemCount, maximumSegments);
  return [
    for (var index = 0; index < segmentCount; index++)
      (
        start: index * itemCount ~/ segmentCount,
        end: (index + 1) * itemCount ~/ segmentCount,
      ),
  ];
}

double _adaptiveStripGap(int segmentCount, {required bool grouped}) {
  if (grouped) return 0.5;
  if (segmentCount <= 14) return 3;
  if (segmentCount <= 31) return 1.5;
  return 0.5;
}

int _minimumStripRangeLength(List<_StripRange> ranges) =>
    ranges.map((range) => range.end - range.start).reduce(math.min);

int _maximumStripRangeLength(List<_StripRange> ranges) =>
    ranges.map((range) => range.end - range.start).reduce(math.max);

/// History-friendly collapsible wrapper around [EngineFindingsList].
class EngineFindingsPanel extends StatefulWidget {
  final List<Finding> findings;
  final InsightDataset dataset;
  final FindingPresenterRegistry? registry;
  final bool initiallyExpanded;

  const EngineFindingsPanel({
    super.key,
    required this.findings,
    required this.dataset,
    this.registry,
    this.initiallyExpanded = false,
  });

  @override
  State<EngineFindingsPanel> createState() => _EngineFindingsPanelState();
}

class _EngineFindingsPanelState extends State<EngineFindingsPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.findings.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final patternCount = widget.findings
        .where((finding) => finding.kind != FindingKind.aggregate)
        .length;
    final summaryCount = widget.findings.length - patternCount;
    final title = patternCount > 0
        ? summaryCount > 0
              ? 'Patterns & summaries'
              : 'Patterns'
        : 'At a glance';
    final countLabel = [
      if (patternCount > 0)
        '$patternCount ${patternCount == 1 ? 'pattern' : 'patterns'}',
      if (summaryCount > 0)
        '$summaryCount ${summaryCount == 1 ? 'summary' : 'summaries'}',
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRounding.medium),
          child: AppSurface(
            level: SurfaceLevel.low,
            rounding: AppRounding.medium,
            borderAlpha: 0.3,
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Row(
              children: [
                Icon(
                  patternCount > 0
                      ? Icons.auto_graph_rounded
                      : Icons.data_usage_outlined,
                  size: 19,
                  color: colors.primary,
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        countLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 220),
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppPadding.medium),
                  child: EngineFindingsList(
                    findings: widget.findings,
                    dataset: widget.dataset,
                    registry: widget.registry,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
