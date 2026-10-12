import 'package:flutter/material.dart';

/// A segmented progress divider whose structure can change at runtime.
///
/// Stable [segmentIds] let retained segments resize in place while inserted
/// segments grow from a neighbor and removed segments collapse back into the
/// track. When [pageController] is attached, progress fills and drains with
/// the page transition rather than fading between discrete states.
class AnimatedSegmentedProgress extends StatefulWidget {
  final List<String> segmentIds;
  final int currentIndex;
  final bool currentHasError;
  final PageController? pageController;
  final double height;
  final double gap;
  final double cornerRadius;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? errorColor;
  final Duration structureDuration;
  final Duration errorDuration;
  final Key? semanticsKey;

  const AnimatedSegmentedProgress({
    required this.segmentIds,
    required this.currentIndex,
    this.currentHasError = false,
    this.pageController,
    this.height = 4,
    this.gap = 3,
    this.cornerRadius = 1,
    this.activeColor,
    this.inactiveColor,
    this.errorColor,
    this.structureDuration = const Duration(milliseconds: 420),
    this.errorDuration = const Duration(milliseconds: 180),
    this.semanticsKey,
    super.key,
  });

  @override
  State<AnimatedSegmentedProgress> createState() =>
      _AnimatedSegmentedProgressState();
}

class _AnimatedSegmentedProgressState extends State<AnimatedSegmentedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late List<String> _previousSegmentIds;
  late int _previousCurrentIndex;
  late bool _previousHasError;

  @override
  void initState() {
    super.initState();
    _previousSegmentIds = widget.segmentIds;
    _previousCurrentIndex = widget.currentIndex;
    _previousHasError = widget.currentHasError;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.structureDuration,
      value: 1,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(AnimatedSegmentedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    final structureChanged = !_sameIds(oldWidget.segmentIds, widget.segmentIds);
    final errorChanged = oldWidget.currentHasError != widget.currentHasError;
    if (!structureChanged && !errorChanged) return;

    _previousSegmentIds = List.unmodifiable(oldWidget.segmentIds);
    _previousCurrentIndex = oldWidget.currentIndex;
    _previousHasError = oldWidget.currentHasError;
    _animationController.duration = structureChanged
        ? widget.structureDuration
        : widget.errorDuration;
    _animationController.forward(from: 0);
  }

  bool _sameIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final segmentCount = widget.segmentIds.length;
    final current = segmentCount == 0
        ? 0
        : widget.currentIndex.clamp(0, segmentCount - 1);
    final semanticsValue = widget.currentHasError
        ? 'Current step has validation errors'
        : current == segmentCount - 1
        ? 'Final step'
        : '${current + 1} steps reached';

    final pageController = widget.pageController;
    final repaint = pageController == null
        ? _animation
        : Listenable.merge([_animation, pageController]);

    return Semantics(
      key: widget.semanticsKey,
      container: true,
      label: segmentCount == 0
          ? 'No steps'
          : 'Step ${current + 1} of $segmentCount',
      value: semanticsValue,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: repaint,
          builder: (context, _) {
            return CustomPaint(
              painter: _SegmentedProgressPainter(
                previousSegmentIds: _previousSegmentIds,
                segmentIds: widget.segmentIds,
                previousCurrentIndex: _previousCurrentIndex,
                position: _position,
                previousHasError: _previousHasError,
                currentHasError: widget.currentHasError,
                animationProgress: _animation.value,
                activeColor: widget.activeColor ?? colors.primary,
                inactiveColor:
                    widget.inactiveColor ??
                    colors.outlineVariant.withValues(alpha: 0.55),
                errorColor: widget.errorColor ?? colors.error,
                gap: widget.gap,
                cornerRadius: widget.cornerRadius,
              ),
            );
          },
        ),
      ),
    );
  }

  double get _position {
    final pageController = widget.pageController;
    if (pageController?.hasClients ?? false) {
      return pageController!.page ?? widget.currentIndex.toDouble();
    }
    return widget.currentIndex.toDouble();
  }
}

class _SegmentedProgressPainter extends CustomPainter {
  final List<String> previousSegmentIds;
  final List<String> segmentIds;
  final int previousCurrentIndex;
  final double position;
  final bool previousHasError;
  final bool currentHasError;
  final double animationProgress;
  final Color activeColor;
  final Color inactiveColor;
  final Color errorColor;
  final double gap;
  final double cornerRadius;

  const _SegmentedProgressPainter({
    required this.previousSegmentIds,
    required this.segmentIds,
    required this.previousCurrentIndex,
    required this.position,
    required this.previousHasError,
    required this.currentHasError,
    required this.animationProgress,
    required this.activeColor,
    required this.inactiveColor,
    required this.errorColor,
    required this.gap,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || (previousSegmentIds.isEmpty && segmentIds.isEmpty)) {
      return;
    }

    final previousRects = _layout(previousSegmentIds, size);
    final targetRects = _layout(segmentIds, size);
    final allIds = <String>{...previousSegmentIds, ...segmentIds};

    for (final id in allIds) {
      var startRect = previousRects[id];
      var endRect = targetRects[id];

      if (startRect == null && endRect != null) {
        startRect = _collapsedRect(
          id: id,
          ids: segmentIds,
          neighborRects: previousRects,
          fallback: endRect,
          height: size.height,
        );
      } else if (endRect == null && startRect != null) {
        endRect = _collapsedRect(
          id: id,
          ids: previousSegmentIds,
          neighborRects: targetRects,
          fallback: startRect,
          height: size.height,
        );
      }

      if (startRect == null || endRect == null) continue;
      final rect = Rect.lerp(startRect, endRect, animationProgress)!;
      if (rect.width <= 0.01) continue;

      final radius = Radius.circular(cornerRadius.clamp(0, size.height / 2));
      final segment = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(segment, Paint()..color = inactiveColor);

      final previousFill = _fillFor(
        id,
        previousSegmentIds,
        previousCurrentIndex.toDouble(),
      );
      final currentFill = _fillFor(id, segmentIds, position);
      final fill =
          previousFill + (currentFill - previousFill) * animationProgress;
      if (fill <= 0) continue;

      final previousColor = _activeColorFor(
        id,
        previousSegmentIds,
        previousCurrentIndex,
        previousHasError,
      );
      final targetCurrentIndex = segmentIds.isEmpty
          ? 0
          : position.round().clamp(0, segmentIds.length - 1);
      final currentColor = _activeColorFor(
        id,
        segmentIds,
        targetCurrentIndex,
        currentHasError,
      );

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width * fill, rect.height),
      );
      canvas.drawRRect(
        segment,
        Paint()
          ..color = Color.lerp(previousColor, currentColor, animationProgress)!,
      );
      canvas.restore();
    }
  }

  Map<String, Rect> _layout(List<String> ids, Size size) {
    if (ids.isEmpty) return const {};
    final gaps = gap * (ids.length - 1);
    final segmentWidth = ((size.width - gaps) / ids.length).clamp(
      0.0,
      size.width,
    );
    return {
      for (var index = 0; index < ids.length; index++)
        ids[index]: Rect.fromLTWH(
          index * (segmentWidth + gap),
          0,
          segmentWidth,
          size.height,
        ),
    };
  }

  Rect _collapsedRect({
    required String id,
    required List<String> ids,
    required Map<String, Rect> neighborRects,
    required Rect fallback,
    required double height,
  }) {
    final index = ids.indexOf(id);
    for (var cursor = index - 1; cursor >= 0; cursor--) {
      final neighbor = neighborRects[ids[cursor]];
      if (neighbor != null) {
        return Rect.fromLTWH(neighbor.right, 0, 0, height);
      }
    }
    for (var cursor = index + 1; cursor < ids.length; cursor++) {
      final neighbor = neighborRects[ids[cursor]];
      if (neighbor != null) {
        return Rect.fromLTWH(neighbor.left, 0, 0, height);
      }
    }
    return Rect.fromLTWH(fallback.center.dx, 0, 0, height);
  }

  double _fillFor(String id, List<String> ids, double currentPosition) {
    final index = ids.indexOf(id);
    if (index < 0) return 0;
    return (currentPosition - index + 1).clamp(0.0, 1.0);
  }

  Color _activeColorFor(
    String id,
    List<String> ids,
    int selectedIndex,
    bool hasError,
  ) {
    final index = ids.indexOf(id);
    if (index < 0) return activeColor;
    final current = selectedIndex.clamp(0, ids.length - 1);
    if (hasError && index == current) return errorColor;
    return activeColor;
  }

  @override
  bool shouldRepaint(_SegmentedProgressPainter oldDelegate) => true;
}
