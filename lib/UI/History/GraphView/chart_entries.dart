import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/palette.dart' as palette;
import 'package:stripes_ui/Util/extensions.dart';

/// Resolve chart evidence to its original recordings, never by timestamp.
/// Multiple answers/series from one recording contribute only one entry.
List<Response> chartSourceEntries(
  Iterable<Stamp> evidence,
  Iterable<Response> records,
) {
  final recordings = records.toList();
  for (final record in recordings) {
    attachRecordIdentity(record);
  }
  final ids = evidence
      .whereType<Response>()
      .map(recordIdentityForResponse)
      .toSet();
  final entries = <Object, Response>{};
  for (final record in recordings) {
    final id = recordIdentityForResponse(record);
    if (ids.contains(id)) entries[id] = record;
  }
  return entries.values.toList()..sort(
    (a, b) =>
        occurrenceTimeForResponse(b).compareTo(occurrenceTimeForResponse(a)),
  );
}

class ChartEntries extends ConsumerWidget {
  const ChartEntries({
    super.key,
    required this.keysForGraph,
    required this.selectionController,
    this.showAll = false,
  });

  final List<GraphKey> keysForGraph;
  final GraphSelectionController selectionController;
  final bool showAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphData = ref.watch(graphStampsProvider);
    final records = ref.watch(stampsStreamProvider);
    final settings = ref.watch(displayDataProvider);
    final paths =
        ref.watch(reviewPathsByTypeProvider).asData?.value ??
        <String, RecordPath>{};
    return AsyncValueDefaults(
      value: graphData,
      onData: (data) {
        final graph = GraphPreparer.prepare(
          responses: {
            for (final key in keysForGraph)
              if (data.containsKey(key)) key: data[key]!,
          },
          settings: settings,
          comparison: GraphComparison.separate,
          colorResolver: palette.forGraphKey,
          reviewPaths: paths,
        );
        return AsyncValueDefaults(
          value: records,
          onData: (loadedRecords) =>
              ValueListenableBuilder<GraphSelectionState>(
                valueListenable: selectionController,
                builder: (context, selection, _) {
                  final selectedIds = selection.items
                      .map((item) => item.datum.id)
                      .toSet();
                  final evidence = graph.series
                      .expand((series) => series.data)
                      .where(
                        (datum) =>
                            selection.isEmpty || selectedIds.contains(datum.id),
                      )
                      .expand((datum) => datum.evidence);
                  final entries = chartSourceEntries(
                    evidence,
                    loadedRecords.whereType<Response>(),
                  );
                  Widget entryRow(Response entry) => Padding(
                    key: ValueKey(recordIdentityForResponse(entry)),
                    padding: const EdgeInsets.only(bottom: AppPadding.small),
                    child: EntryDisplay(
                      event: entry,
                      includeFullDate: true,
                      hasControls: false,
                      hasConstraints: false,
                      isReview: paths[entry.type]?.period != null,
                      dateLabel: paths[entry.type]?.period?.getRangeString(
                        occurrenceTimeForResponse(entry),
                        context,
                      ),
                    ),
                  );
                  final title = Semantics(
                    header: true,
                    child: Text(
                      selection.isEmpty
                          ? context.translate.historyChartEntries
                          : context.translate.historyChartSelectedEntries,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                  final count = Text(
                    context.translate.historyEntryCount(entries.length),
                  );
                  if (showAll) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        count,
                        Expanded(
                          child: ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, index) =>
                                entryRow(entries[index]),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      count,
                      const SizedBox(height: AppPadding.small),
                      for (final entry in entries.take(3)) entryRow(entry),
                      if (entries.length > 3)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (sheetContext) => SafeArea(
                                top: false,
                                child: SizedBox(
                                  height:
                                      MediaQuery.sizeOf(sheetContext).height *
                                      0.85,
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppPadding.large,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ChartEntries(
                                            keysForGraph: keysForGraph,
                                            selectionController:
                                                selectionController,
                                            showAll: true,
                                          ),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                Navigator.pop(sheetContext),
                                            icon: const Icon(Icons.close),
                                            label: Text(
                                              MaterialLocalizations.of(
                                                sheetContext,
                                              ).closeButtonTooltip,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              context.translate.historyChartViewAll(
                                entries.length,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        );
      },
    );
  }
}
