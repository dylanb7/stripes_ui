import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/chart_hit_tester.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_point.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';

class GraphTooltipHelper {
  static List<String>? getTooltipValue({
    required BuildContext context,
    required GraphKey graphKey,
    required Map<GraphKey, List<Response>> loadedData,
    required List<ChartHitTestResult<GraphPoint, DateTime>> hits,
  }) {
    if (hits.isEmpty) return null;

    for (final h in hits) {
      final myResponses = loadedData[graphKey];
      if (myResponses != null &&
          myResponses.any((r) => h.item.data.contains(r))) {
        final isScatter =
            h.yValue > 0 && h.yValue.toInt() != h.yValue.toDouble();
        final String valStr = isScatter
            ? h.yValue.toStringAsFixed(1)
            : h.yValue.toInt().toString();

        final List<Stamp> stamps = h.item.data;
        List<Response> flat = [];
        for (final s in stamps) {
          if (s case DetailResponse(:List<Response> responses)) {
            flat.addAll(responses);
          } else if (s case Response()) {
            flat.add(s);
          }
        }
        if (flat.isEmpty && stamps.isNotEmpty && stamps.first is Response) {
          flat = stamps.whereType<Response>().toList();
        }

        String? summary;
        if (flat.isNotEmpty) {
          summary = _formatResponseSummary(context, flat);
        }
        return [valStr, if (summary != null) summary];
      }
    }
    return null;
  }

  static String? _formatResponseSummary(
      BuildContext context, List<Response> flat) {
    if (flat.isEmpty) return null;

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final first = flat.first;
    if (first is NumericResponse) {
      if (flat.length > 1) {
        final double avg = flat
                .whereType<NumericResponse>()
                .map((e) => e.response)
                .reduce((a, b) => a + b) /
            flat.length;
        return "Avg: ${avg.toStringAsFixed(1)}";
      }
      return null;
    }

    final Map<String, int> counts = {};
    for (final res in flat) {
      if (res is MultiResponse) {
        if (res.index < res.question.choices.length) {
          final choice = res.question.choices[res.index];
          counts[choice] = (counts[choice] ?? 0) + 1;
        }
      } else if (res is AllResponse) {
        for (final index in res.responses) {
          if (index < res.question.choices.length) {
            final choice = res.question.choices[index];
            counts[choice] = (counts[choice] ?? 0) + 1;
          }
        }
      }
    }

    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final String tops = sorted.take(2).map((e) {
      final String choiceLabel = localizations?.value(e.key) ?? e.key;
      return "$choiceLabel: ${e.value}";
    }).join(", ");

    return tops.isEmpty ? null : tops;
  }
}
