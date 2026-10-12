import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/animated_segmented_progress.dart';

/// A pinned step header. The current label stays visible as its profile line
/// scrolls away and the progress bar moves alongside the label.
class RecordFlowHeader extends SliverPersistentHeaderDelegate {
  final String label;
  final String profileLabel;
  final int step;
  final bool collapsible;
  final double width;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final String backTooltip;
  final String closeTooltip;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final GlobalKey measureKey;

  RecordFlowHeader({
    required this.label,
    required this.profileLabel,
    required this.step,
    this.collapsible = true,
    required this.width,
    required this.textScaler,
    required this.textDirection,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.backTooltip,
    required this.closeTooltip,
    required this.onBack,
    required this.onClose,
    required this.measureKey,
  });

  double _height(String text, TextStyle style, double availableWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: math.max(40, availableWidth));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  double get _titleHeight => _height(label, titleStyle, width - 112);

  double get _collapsedExtent =>
      math.max(56, _height(label, titleStyle, width - 216) + 20);

  @override
  double get maxExtent => math.max(
    _collapsedExtent + 36,
    _titleHeight + _height(profileLabel, subtitleStyle, width - 112) + 48,
  );

  @override
  double get minExtent => collapsible ? _collapsedExtent : maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final fraction = collapsible
        ? (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0)
        : 0.0;
    final height = lerpDouble(maxExtent, minExtent, fraction)!;
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('multi-record-header'),
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: measureKey,
            width: width,
            height: height,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 4,
                  top: lerpDouble(4, (minExtent - 48) / 2, fraction),
                  child: IconButton(
                    tooltip: backTooltip,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                PositionedDirectional(
                  end: 4,
                  top: lerpDouble(4, (minExtent - 48) / 2, fraction),
                  child: IconButton(
                    tooltip: closeTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ),
                PositionedDirectional(
                  start: 56,
                  end: lerpDouble(56, 160, fraction),
                  top: lerpDouble(
                    10,
                    (minExtent - _height(label, titleStyle, width - 216)) / 2,
                    fraction,
                  ),
                  child: Text(
                    label,
                    key: const ValueKey('record-step-label'),
                    style: titleStyle,
                  ),
                ),
                if (fraction < 1)
                  PositionedDirectional(
                    start: 56,
                    end: 56,
                    top: 14 + _titleHeight,
                    child: Opacity(
                      opacity: (1 - fraction * 2).clamp(0.0, 1.0),
                      child: Text(profileLabel, style: subtitleStyle),
                    ),
                  ),
                PositionedDirectional(
                  start: lerpDouble(24, width - 144, fraction),
                  end: lerpDouble(24, 56, fraction),
                  top: lerpDouble(height - 16, minExtent / 2 - 1.5, fraction),
                  child: AnimatedSegmentedProgress(
                    key: const ValueKey('record-step-progress'),
                    segmentIds: const [
                      'categories',
                      'time',
                      'questions',
                      'review',
                    ],
                    currentIndex: step,
                    height: lerpDouble(5, 3, fraction)!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant RecordFlowHeader oldDelegate) => true;
}
