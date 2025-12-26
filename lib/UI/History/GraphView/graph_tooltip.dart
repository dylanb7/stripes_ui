import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class GraphTooltip extends ConsumerWidget {
  final ChartHitTestResult<GraphPoint, DateTime> hit;
  final String? label;
  final bool isAbove;
  final double arrowOffset;

  const GraphTooltip(
      {super.key,
      required this.hit,
      this.label,
      this.isAbove = true,
      this.arrowOffset = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final QuestionsLocalizations? questionsLocalizations =
        QuestionsLocalizations.of(context);

    final bool scatter = settings.axis == GraphYAxis.entrytime;
    final List<Stamp> stamps = hit.item.data;

    if (stamps.isEmpty) return const SizedBox.shrink();

    bool showCount = true;

    Widget? getStat() {
      List<Response> flatStamps = [];
      for (final s in stamps) {
        if (s is DetailResponse) {
          flatStamps.addAll(s.responses);
        } else if (s is Response) {
          flatStamps.add(s);
        }
      }

      if (flatStamps.isEmpty && stamps.isNotEmpty && stamps.first is Response) {
        flatStamps = stamps.whereType<Response>().toList();
      }

      if (flatStamps.isEmpty) return null;

      final Response firstResponse = flatStamps.first;
      switch (firstResponse) {
        case NumericResponse():
          final List<NumericResponse> numerics =
              flatStamps.whereType<NumericResponse>().toList();
          if (numerics.isNotEmpty && numerics.length == flatStamps.length) {
            if (scatter) {
              return _RowInfo(
                label: "Value",
                value: numerics.first.response.toStringAsFixed(1),
              );
            }
            final double avg = numerics.map((e) => e.response).average;

            if (avg > 0) {
              return _RowInfo(
                label: "Average",
                value: avg.toStringAsFixed(1),
              );
            }
          }
          break;
        case MultiResponse():
          final List<MultiResponse> multis =
              flatStamps.whereType<MultiResponse>().toList();
          if (multis.isNotEmpty && multis.length == flatStamps.length) {
            final Map<String, int> counts = {};
            for (final multi in multis) {
              counts[multi.choice] = (counts[multi.choice] ?? 0) + 1;
            }
            showCount = false;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: counts.entries
                  .sorted((a, b) => b.value.compareTo(a.value))
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: _RowInfo(
                          label: questionsLocalizations?.value(e.key) ?? e.key,
                          value: e.value.toString(),
                        ),
                      ))
                  .toList(),
            );
          }
          break;
        case AllResponse():
          final List<AllResponse> alls =
              flatStamps.whereType<AllResponse>().toList();
          if (alls.isNotEmpty && alls.length == flatStamps.length) {
            final Map<String, int> counts = {};
            for (final all in alls) {
              for (final choice in all.choices) {
                counts[choice] = (counts[choice] ?? 0) + 1;
              }
            }
            showCount = false;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: counts.entries
                  .sorted((a, b) => b.value.compareTo(a.value))
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: _RowInfo(
                          label: questionsLocalizations?.value(e.key) ?? e.key,
                          value: e.value.toString(),
                        ),
                      ))
                  .toList(),
            );
          }
          break;
        default:
          return null;
      }
      return null;
    }

    final Widget? stat = getStat();

    final DateTime date =
        scatter ? dateFromStamp(hit.item.data.first.stamp) : hit.xValue;
    DateFormat format = DateFormat.MMMEd();
    final bool shortCustom = (settings.cycle == TimeCycle.custom &&
        settings.range.duration < const Duration(days: 5));
    if (settings.cycle == TimeCycle.day || scatter || shortCustom) {
      format.add_jm();
    }
    final String dateStr = format.format(date);

    const double arrowHeight = 10.0;

    final Widget content = Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          if (stat != null || !scatter) const SizedBox(height: 8),
          if (stat != null) stat,
          if (!scatter && showCount)
            _RowInfo(
              label: "Count",
              value: stamps.length.toString(),
            ),
        ],
      ),
    );

    if (!scatter) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRounding.medium),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return ClipPath(
      clipper: BubbleClipper(
          isAbove: isAbove, arrowHeight: arrowHeight, arrowOffset: arrowOffset),
      child: CustomPaint(
        painter: BubblePainter(
            isAbove: isAbove,
            arrowHeight: arrowHeight,
            arrowOffset: arrowOffset,
            borderColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            fillColor:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.85)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: content,
        ),
      ),
    );
  }
}

class BubbleClipper extends CustomClipper<Path> {
  final bool isAbove;
  final double arrowHeight;
  final double arrowOffset;
  final double radius;

  BubbleClipper(
      {required this.isAbove,
      this.arrowHeight = 10.0,
      this.arrowOffset = 0.0,
      this.radius = 12.0});

  @override
  Path getClip(Size size) {
    return _getBubblePath(size, isAbove, arrowHeight, radius, arrowOffset);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class BubblePainter extends CustomPainter {
  final bool isAbove;
  final double arrowHeight;
  final double arrowOffset;
  final double radius;
  final Color borderColor;
  final Color fillColor;

  BubblePainter(
      {required this.isAbove,
      required this.arrowHeight,
      required this.arrowOffset,
      required this.borderColor,
      required this.fillColor,
      this.radius = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path =
        _getBubblePath(size, isAbove, arrowHeight, radius, arrowOffset);

    // Fill
    canvas.drawPath(path, Paint()..color = fillColor);

    // Border
    canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Path _getBubblePath(Size size, bool isAbove, double arrowHeight, double radius,
    double arrowOffset) {
  final Path path = Path();
  final double w = size.width;
  final double h = size.height;

  double center = (w / 2) + arrowOffset;
  const double arrowWidthHalf = 8.0;

  if (center < radius + arrowWidthHalf) {
    center = radius + arrowWidthHalf;
  }
  if (center > w - radius - arrowWidthHalf) {
    center = w - radius - arrowWidthHalf;
  }

  if (isAbove) {
    final double bottom = h - arrowHeight;
    path.moveTo(radius, 0);
    path.lineTo(w - radius, 0);
    path.arcToPoint(Offset(w, radius), radius: Radius.circular(radius));
    path.lineTo(w, bottom - radius);
    path.arcToPoint(Offset(w - radius, bottom),
        radius: Radius.circular(radius));

    path.lineTo(center + arrowWidthHalf, bottom);
    path.lineTo(center, h); // Tip
    path.lineTo(center - arrowWidthHalf, bottom);
    path.lineTo(radius, bottom);

    path.arcToPoint(Offset(0, bottom - radius),
        radius: Radius.circular(radius));
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
  } else {
    final double top = arrowHeight;
    path.moveTo(radius, top);

    path.lineTo(center - arrowWidthHalf, top);
    path.lineTo(center, 0); // Tip
    path.lineTo(center + arrowWidthHalf, top);
    path.lineTo(w - radius, top);

    path.arcToPoint(Offset(w, top + radius), radius: Radius.circular(radius));
    path.lineTo(w, h - radius);
    path.arcToPoint(Offset(w - radius, h), radius: Radius.circular(radius));
    path.lineTo(radius, h);
    path.arcToPoint(Offset(0, h - radius), radius: Radius.circular(radius));
    path.lineTo(0, top + radius);
    path.arcToPoint(Offset(radius, top), radius: Radius.circular(radius));
  }
  path.close();
  return path;
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  const _RowInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
