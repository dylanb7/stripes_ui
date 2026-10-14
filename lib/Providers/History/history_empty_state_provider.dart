import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';

enum HistoryEmptyKind { noEntries, noEntriesInPeriod, noMatchingEntries }

class HistoryEmptyDetails {
  final HistoryEmptyKind kind;
  final Response? closestEntry;
  final RecordPath? closestReviewPath;
  final int unfilteredPeriodCount;

  const HistoryEmptyDetails({
    required this.kind,
    this.closestEntry,
    this.closestReviewPath,
    this.unfilteredPeriodCount = 0,
  });
}

/// Load the supported history range before offering recovery from an empty
/// period. The normal stream may only contain a recent window. Keep this work
/// scoped to the current repositories and reuse it across empty periods.
///
/// Repository refresh does not expose sync completeness, so the UI deliberately
/// describes the nearest *available* entry, including when working offline.
final historyArchiveReadyProvider = FutureProvider<void>((ref) async {
  final stampRepository = await ref.watch(stampProvider.future);
  final entryRepository = await ref.watch(entryRepoProvider.future);
  if (!ref.mounted) return;
  final start = SigDates.minDate;
  if (stampRepository != null &&
      (stampRepository.earliest == null ||
          stampRepository.earliest!.isAfter(start))) {
    stampRepository.earliestDate = start;
  }
  if (entryRepository != null &&
      (entryRepository.earliest == null ||
          entryRepository.earliest!.isAfter(start))) {
    entryRepository.earliestDate = start;
  }
  await Future.wait([
    if (stampRepository != null) stampRepository.refresh(),
    if (entryRepository != null) entryRepository.refresh(),
  ]);
  // Allow the completed refresh's stream emissions and merged timing metadata
  // to propagate before the consumer reads the current History projection.
  await Future<void>.delayed(Duration.zero);
});

final historyEmptyDetailsProvider =
    FutureProvider.autoDispose<HistoryEmptyDetails>((ref) async {
      final settings = ref.watch(displayDataProvider);
      await ref.watch(historyArchiveReadyProvider.future);
      if (!ref.mounted) throw StateError('History lookup was disposed');
      final stamps = await ref.watch(stampsStreamProvider.future);
      final reviewPaths = await ref.watch(reviewPathsByTypeProvider.future);
      return describeEmptyHistory(
        stamps.whereType<Response>(),
        settings,
        reviewPaths: reviewPaths,
      );
    });

/// Uses the same OR-within-type / AND-between-types rules as History. Keeping
/// the date outside these rules lets a recovery link preserve every filter.
bool matchesHistoryFilters(Response response, List<LabeledFilter> filters) {
  final groups = <String, List<LabeledFilter>>{};
  for (final filter in filters) {
    groups.putIfAbsent(filter.filterType.name, () => []).add(filter);
  }
  return groups.values.every(
    (group) => group.any((filter) => filter.filter(response)),
  );
}

HistoryEmptyDetails describeEmptyHistory(
  Iterable<Response> responses,
  DisplayDataSettings settings, {
  Map<String, RecordPath> reviewPaths = const {},
}) {
  final all = responses.toList();
  if (all.isEmpty) {
    return const HistoryEmptyDetails(kind: HistoryEmptyKind.noEntries);
  }
  final inPeriod = all
      .where(
        (response) => responseOverlapsWindow(
          response,
          settings.window,
          reviewPath: reviewPaths[response.type],
        ),
      )
      .length;
  final closest = closestHistoryEntry(all, settings, reviewPaths: reviewPaths);
  return HistoryEmptyDetails(
    kind: settings.filters.isNotEmpty
        ? HistoryEmptyKind.noMatchingEntries
        : HistoryEmptyKind.noEntriesInPeriod,
    unfilteredPeriodCount: inPeriod,
    closestEntry: closest,
    closestReviewPath: closest == null ? null : reviewPaths[closest.type],
  );
}

/// Distance is measured from the selected interval, not its midpoint. For
/// approximate times use the known occurrence interval instead of inventing an
/// exact timestamp. Equal distances prefer the earlier record, then stable ID.
Response? closestHistoryEntry(
  Iterable<Response> responses,
  DisplayDataSettings settings, {
  Map<String, RecordPath> reviewPaths = const {},
}) {
  final matching = responses
      .where((response) => matchesHistoryFilters(response, settings.filters))
      .toList();
  int distance(Response response) {
    final date = occurrenceTimeForResponse(response);
    final interval =
        reviewPaths[response.type]?.period?.getRange(date) ??
        occurrenceRangeForResponse(response);
    final start = interval?.start ?? date;
    final end = interval?.end ?? date;
    if (!end.isAfter(settings.range.start)) {
      return settings.range.start.difference(end).inMicroseconds;
    }
    if (!start.isBefore(settings.range.end)) {
      return start.difference(settings.range.end).inMicroseconds;
    }
    return 0;
  }

  matching.sort((a, b) {
    var order = distance(a).compareTo(distance(b));
    if (order != 0) return order;
    order = occurrenceTimeForResponse(a)
        .compareTo(occurrenceTimeForResponse(b));
    if (order != 0) return order;
    order = (a.id ?? '').compareTo(b.id ?? '');
    if (order != 0) return order;
    return a.type.compareTo(b.type);
  });
  return matching.isEmpty ? null : matching.first;
}
