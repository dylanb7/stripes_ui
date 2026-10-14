import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/history_empty_state_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// Empty collection recovery shared by the beta Entries and Graph views.
/// The parent owns the beta gate and renders this only for a resolved empty
/// collection; a chart with entries but no compatible measure is different.
class HistoryEmptyState extends ConsumerWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(historyEmptyDetailsProvider);
    final settings = ref.watch(displayDataProvider);
    final colors = Theme.of(context).colorScheme;
    final loaded = details.asData?.value;

    final String title;
    final String message;
    if (details.isLoading) {
      title = 'No entries in this selection';
      message = 'Looking for entries near this period…';
    } else if (details.hasError) {
      title = 'No entries in this selection';
      message = 'Nearby entries could not be loaded. Try again or choose another date.';
    } else {
      switch (loaded!.kind) {
        case HistoryEmptyKind.noEntries:
          title = 'No entries available yet';
          message =
              'Your entries will appear here, ready to revisit and explore.';
        case HistoryEmptyKind.noEntriesInPeriod:
          title = 'No entries in this period';
          message = loaded.closestEntry == null
              ? 'Choose another date to explore your history.'
              : 'There are entries outside this period. Here is the closest available one.';
        case HistoryEmptyKind.noMatchingEntries:
          title = 'No entries match these filters';
          message = loaded.unfilteredPeriodCount > 0
              ? '${loaded.unfilteredPeriodCount} ${loaded.unfilteredPeriodCount == 1 ? 'entry is' : 'entries are'} available in this period without filters.'
              : loaded.closestEntry != null
              ? 'No matches in this period. The closest available match keeps your filters.'
              : 'Try clearing your filters or choosing another date.';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppPadding.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.history, color: colors.primary, size: 32),
              const SizedBox(height: AppPadding.medium),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppPadding.small),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              if (details.isLoading) ...[
                const SizedBox(height: AppPadding.medium),
                const LinearProgressIndicator(
                  semanticsLabel: 'Looking for nearby entries',
                ),
              ],
              if (!details.isLoading && loaded?.closestEntry != null) ...[
                const SizedBox(height: AppPadding.large),
                _ClosestEntryButton(
                  entry: loaded!.closestEntry!,
                  reviewPath: loaded.closestReviewPath,
                ),
              ],
              const SizedBox(height: AppPadding.medium),
              Wrap(
                spacing: AppPadding.small,
                runSpacing: AppPadding.small,
                children: [
                  if (details.hasError)
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(historyArchiveReadyProvider);
                        ref.invalidate(historyEmptyDetailsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  if (settings.filters.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => ref
                          .read(displayDataProvider.notifier)
                          .updateFilters(const []),
                      child: const Text('Clear filters'),
                    ),
                  if (loaded?.kind == HistoryEmptyKind.noEntries &&
                      ref.watch(configProvider).hasLogging)
                    FilledButton.icon(
                      onPressed: () {
                        final config = ref.read(configProvider);
                        if (config.betaUi.multiSessionFlow) {
                          context.pushNamed(RouteName.MULTI_RECORD);
                        } else {
                          context.goNamed(RouteName.HOME);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Record an entry'),
                    ),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(sheetControllerProvider)
                        .show(
                          context: context,
                          scrollControlled: true,
                          child: (_) => const BottomSheetCalendar(),
                        ),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Choose dates'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosestEntryButton extends ConsumerWidget {
  final Response entry;
  final RecordPath? reviewPath;

  const _ClosestEntryButton({required this.entry, this.reviewPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = occurrenceTimeForResponse(entry);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final category =
        QuestionsLocalizations.of(context)?.value(entry.type) ?? entry.type;
    final period = reviewPath?.period;
    final time = period != null
        ? null
        : approximateRecordTimeLabel(entry, context) ??
              TimeOfDay.fromDateTime(date).format(context);
    final dateLabel =
        period?.getRangeString(date, context) ??
        DateFormat.yMMMd(locale).format(date);
    return OutlinedButton(
      key: const ValueKey('history-closest-entry'),
      onPressed: () {
        ref
            .read(sheetControllerProvider)
            .show(
              context: context,
              scrollControlled: true,
              child: (_) =>
                  _ClosestEntrySheet(entry: entry, reviewPath: reviewPath),
            );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(AppPadding.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('View closest entry'),
                Text('$category · $dateLabel'),
                if (time != null) Text(time),
              ],
            ),
          ),
          const SizedBox(width: AppPadding.small),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}

/// Show the promised entry immediately, even when its chronological row would
/// be outside a lazy list's viewport. Reading it preserves the user's scope.
class _ClosestEntrySheet extends ConsumerWidget {
  final Response entry;
  final RecordPath? reviewPath;

  const _ClosestEntrySheet({required this.entry, this.reviewPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stamps = ref.watch(stampsStreamProvider);
    Response? currentEntry = entry;
    if (entry.id != null && !stamps.isLoading && stamps.asData != null) {
      currentEntry = null;
      for (final candidate in stamps.asData!.value.whereType<Response>()) {
        if (candidate.id == entry.id) {
          currentEntry = candidate;
          break;
        }
      }
    }
    final date = occurrenceTimeForResponse(currentEntry ?? entry);
    final period = reviewPath?.period;
    // Large headings and a fixed footer otherwise leave only a few lines of
    // the actual entry visible on a short phone. Keep Close reachable while
    // letting the context action scroll with the complete entry.
    final scrollingActions =
        MediaQuery.sizeOf(context).height < 600 ||
        MediaQuery.textScalerOf(context).scale(16) >= 32;
    final contextAction = Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            final scroll = ref.read(historyScrollControllerProvider);
            final notifier = ref.read(displayDataProvider.notifier);
            if (period == null) {
              notifier.setCycle(TimeCycle.day, seedStartTime: date);
            } else {
              notifier.setRange(period.getRange(date), cycle: TimeCycle.custom);
            }
            ref.read(viewModeProvider.notifier).setMode(ViewMode.events);
            ref.read(historyCalendarNavVisibleProvider.notifier).hide();
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scroll.hasClients) {
                scroll.jumpTo(scroll.position.minScrollExtent);
              }
            });
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(period == null ? 'View this day' : 'View this period'),
        ),
      ),
    );
    final entryContent = currentEntry == null
        ? const Text('This entry is no longer available.')
        : EntryDisplay(
            event: currentEntry,
            initiallyExpanded: true,
            hasConstraints: false,
            includeFullDate: true,
            isReview: period != null,
            dateLabel: period?.getRangeString(date, context),
          );
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            if (scrollingActions)
              Semantics(
                namesRoute: true,
                label: 'Entry details',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.medium,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(
                        MaterialLocalizations.of(context).closeButtonTooltip,
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.xl,
                  right: AppPadding.medium,
                  top: AppPadding.small,
                  bottom: AppPadding.small,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Entry details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    entryContent,
                    if (scrollingActions) ...[
                      const SizedBox(height: AppPadding.medium),
                      const Divider(height: 1),
                      contextAction,
                    ],
                  ],
                ),
              ),
            ),
            if (!scrollingActions) ...[const Divider(height: 1), contextAction],
          ],
        ),
      ),
    );
  }
}
