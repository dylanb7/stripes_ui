import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class DateRangeSelector extends StatefulWidget {
  final String rangeText;

  final bool canGoPrev;

  final bool canGoNext;

  final VoidCallback onPrev;

  final VoidCallback onNext;

  final VoidCallback onTap;

  final String Function(bool forward)? getPreviewText;

  const DateRangeSelector({
    super.key,
    required this.rangeText,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    this.getPreviewText,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  double _dragOffset = 0.0;
  String? _previewText;
  static const double _threshold = 80.0;

  @override
  Widget build(BuildContext context) {
    final hasPreview = _previewText != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous period',
          visualDensity: VisualDensity.comfortable,
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: widget.canGoPrev ? widget.onPrev : null,
        ),
        const SizedBox(width: AppPadding.tiny),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dx;
                final bool forward = _dragOffset < 0;

                if (forward && !widget.canGoNext) {
                  _dragOffset = 0;
                  return;
                }
                if (!forward && !widget.canGoPrev) {
                  _dragOffset = 0;
                  return;
                }

                if (_dragOffset.abs() > _threshold &&
                    widget.getPreviewText != null) {
                  _previewText = widget.getPreviewText!(forward);
                } else {
                  _previewText = null;
                }
              });
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffset.abs() > _threshold) {
                if (_dragOffset < 0) {
                  widget.onNext();
                } else {
                  widget.onPrev();
                }
              } else if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 1000) {
                // Fast swipe support
                final bool forward = details.primaryVelocity! < 0;
                if ((forward && widget.canGoNext) ||
                    (!forward && widget.canGoPrev)) {
                  if (forward) {
                    widget.onNext();
                  } else {
                    widget.onPrev();
                  }
                }
              }
              setState(() {
                _dragOffset = 0;
                _previewText = null;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragOffset = 0;
                _previewText = null;
              });
            },
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Opacity(
                opacity: 1.0 -
                    (_dragOffset.abs() / (_threshold * 2)).clamp(0.0, 0.5),
                child: Semantics(
                  label: 'Select date range. Current: ${widget.rangeText}',
                  button: true,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(AppRounding.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.medium,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: Durations.short3,
                            child: Text(
                              _previewText ?? widget.rangeText,
                              key: ValueKey(_previewText ?? widget.rangeText),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: hasPreview
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    fontWeight: hasPreview
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppPadding.tiny),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: hasPreview
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.tiny),
        IconButton(
          tooltip: 'Next period',
          visualDensity: VisualDensity.comfortable,
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          icon: const Icon(Icons.keyboard_arrow_right),
          onPressed: widget.canGoNext ? widget.onNext : null,
        ),
      ],
    );
  }
}
