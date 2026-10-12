import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/config.dart';

/// Compact entry card: header row + inline content from DetailDisplay /
/// ResponseDisplay. Content is shown directly when the row is tapped.
///
/// Accent bar widened from 3px → 5px for stronger visual category branding.
class CompactEntryCard extends ConsumerStatefulWidget {
  final Response response;
  final IconData? icon;
  final String label;
  final DateTime time;
  final Color color;
  final bool themed;

  const CompactEntryCard({
    required this.response,
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.themed,
    super.key,
  });

  @override
  ConsumerState<CompactEntryCard> createState() => _CompactEntryCardState();
}

class _CompactEntryCardState extends ConsumerState<CompactEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String timeStr =
        approximateRecordTimeLabel(widget.response, context) ??
        _formatTime(widget.time);

    // Resolve content widget (same logic as EntryDisplay but without wrapper)
    final StripesConfig config = ref.watch(configProvider);
    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;
    final Color accent = colored ? widget.color : colors.primary;

    Widget? content;
    final Map<String, DisplayBuilder> overrides = ref
        .watch(questionUIRegistryProvider)
        .allDisplayOverrides;
    final DisplayBuilder? mainOverride = overrides[widget.response.question.id];

    if (mainOverride != null) {
      content = mainOverride(context, widget.response);
    } else if (widget.response case DetailResponse detail) {
      content = DetailDisplay(
        detail: detail,
        accentColor: colored ? accent : null,
      );
    } else {
      content = ResponseDisplay(
        res: widget.response,
        accentColor: colored ? accent : null,
      );
    }

    final stackHeader =
        MediaQuery.textScalerOf(context).scale(14) > 18.2 ||
        MediaQuery.sizeOf(context).width < 360;
    final label = Text(
      widget.label,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w500),
    );
    final time = Text(
      timeStr,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: colors.onSurfaceVariant),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRounding.small),
            child: Container(
              decoration: BoxDecoration(
                color: _expanded
                    ? accent.withValues(alpha: 0.03)
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRounding.small),
                border: Border.all(
                  color: _expanded
                      ? accent.withValues(alpha: 0.3)
                      : colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  if (colored)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 5,
                      child: ColoredBox(color: widget.color),
                    ),
                  Padding(
                    padding: EdgeInsets.only(left: colored ? 5 : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header row
                        Padding(
                          padding: EdgeInsets.only(
                            left: themed ? AppPadding.small : AppPadding.small,
                            right: AppPadding.small,
                            top: AppPadding.small,
                            bottom: _expanded
                                ? AppPadding.tiny
                                : AppPadding.small,
                          ),
                          child: Row(
                            children: [
                              if (widget.icon != null) ...[
                                if (themed)
                                  CategoryIcon(
                                    appearance: CategoryAppearance(
                                      icon: widget.icon!,
                                      color: widget.color,
                                      svgAsset: CategoryTheme.resolve(
                                        widget.response.type,
                                      ).svgAsset,
                                    ),
                                    size: 16,
                                  )
                                else
                                  Icon(
                                    widget.icon,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                                const SizedBox(width: AppPadding.small),
                              ],
                              if (stackHeader)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      label,
                                      const SizedBox(height: AppPadding.tiny),
                                      time,
                                    ],
                                  ),
                                )
                              else ...[
                                Expanded(child: label),
                                const SizedBox(width: AppPadding.small),
                                Flexible(child: time),
                              ],
                              const SizedBox(width: AppPadding.tiny),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        // Respect the reader's text-size preference here too.
                        if (_expanded)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppPadding.small,
                              right: AppPadding.small,
                              bottom: AppPadding.small,
                            ),
                            child: content,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.jm().format(time.toLocal());
  }
}
