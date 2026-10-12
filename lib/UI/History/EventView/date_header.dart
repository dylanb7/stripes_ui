import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final int eventCount;
  final double extent;
  final bool showEventCount;
  final double horizontalInset;

  const DateHeaderDelegate({
    required this.date,
    required this.eventCount,
    this.extent = 44,
    this.showEventCount = true,
    this.horizontalInset = 0,
  });

  factory DateHeaderDelegate.measured({
    required BuildContext context,
    required double width,
    required DateTime date,
    required int eventCount,
    double horizontalInset = 0,
  }) {
    final dateText = _formatDate(context, date);
    final count = context.translate.historyEntryCount(eventCount);
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w600);
    final painter = TextPainter(
      text: TextSpan(text: '$dateText · $count', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      locale: Localizations.localeOf(context),
    )..layout(maxWidth: math.max(0, width - 2 * horizontalInset));
    final showCount = painter.computeLineMetrics().length == 1;
    if (!showCount) {
      painter.text = TextSpan(text: dateText, style: style);
      painter.layout(maxWidth: math.max(0, width - 2 * horizontalInset));
    }
    final height = math.max(44.0, painter.height.ceilToDouble() + 24);
    painter.dispose();
    return DateHeaderDelegate(
      date: date,
      eventCount: eventCount,
      extent: height,
      showEventCount: showCount,
      horizontalInset: horizontalInset,
    );
  }

  static String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return (date.year == DateTime.now().year
            ? DateFormat.MMMd(locale)
            : DateFormat.yMMMd(locale))
        .format(date);
  }

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(covariant DateHeaderDelegate oldDelegate) =>
      oldDelegate.date != date ||
      oldDelegate.eventCount != eventCount ||
      oldDelegate.extent != extent ||
      oldDelegate.showEventCount != showEventCount ||
      oldDelegate.horizontalInset != horizontalInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateText = _formatDate(context, date);
    // Paint only inside the allocated extent. The previous overflow obscured
    // the top of an entry as soon as its day heading pinned.
    return ClipRect(
      child: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(
          vertical: AppPadding.medium,
          horizontal: horizontalInset,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          // This fixed-height header pins once its scroll offset is positive.
          border: shrinkOffset > 0
              ? Border(bottom: BorderSide(color: colors.outlineVariant))
              : null,
        ),
        child: Text.rich(
          TextSpan(
            text: dateText,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            children: [
              if (showEventCount)
                TextSpan(
                  text: ' · ${context.translate.historyEntryCount(eventCount)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          semanticsLabel:
              '$dateText · ${context.translate.historyEntryCount(eventCount)}',
        ),
      ),
    );
  }
}
