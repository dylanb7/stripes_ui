import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/Util/extensions.dart';

class FilterView extends ConsumerWidget {
  const FilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Filters filters = ref.watch(filtersProvider);
    final String range = filters.toRange(context);
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        FilledButton(
          onPressed: () {
            ref.read(overlayProvider.notifier).state = CurrentOverlay(
              widget: _PopUpStyle(
                child: _FilterPopUp(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate.filterEventsButton,
              ),
              const SizedBox(
                width: 4.0,
              ),
              const Icon(
                Icons.filter_list,
              ),
            ],
          ),
        ),
        if (false && range.isNotEmpty)
          RemoveChip(
              onPressed: () {
                ref.read(filtersProvider.notifier).state = Filters(
                    calendarSelection:
                        CalendarSelection.selected(DateTime.now()),
                    latestRequired: filters.latestRequired,
                    earliestRequired: filters.earliestRequired,
                    stampFilters: filters.stampFilters);
              },
              text: range),
        ...filters.stampFilters?.map(
              (filter) => RemoveChip(
                onPressed: () {
                  ref.read(filtersProvider.notifier).state = filters.copyWith(
                      stampFilters: filters.stampFilters?..remove(filter));
                },
                text: filter.name,
              ),
            ) ??
            []
      ],
    );
  }
}

class RemoveChip extends StatelessWidget {
  final VoidCallback onPressed;

  final String text;

  const RemoveChip({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      label: Text(text),
      icon: const Icon(Icons.close),
      style: Theme.of(context).filledButtonTheme.style?.copyWith(
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 6.0))),
      iconAlignment: IconAlignment.end,
    );
  }
}

class _FilterPopUp extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FilterPopUpState();
}

class _FilterPopUpState extends ConsumerState<_FilterPopUp> {
  Set<String> selectedTypes = {};

  DateTimeRange? newRange;

  @override
  void initState() {
    final Filters filters = ref.read(filtersProvider);
    final DateTime? start = filters.calendarSelection.rangeStart ??
        filters.calendarSelection.selectedDate;
    final DateTime? end = filters.calendarSelection.rangeEnd ??
        filters.calendarSelection.selectedDate;
    if (start != null && end != null) {
      newRange = DateTimeRange(start: start, end: end);
    }
    selectedTypes.addAll(
        filters.stampFilters?.map((filter) => filter.name).toList() ?? []);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<String, Set<String>>> availible =
        ref.watch(setsProvider);

    final Filters filters = ref.watch(filtersProvider);

    if (availible.isLoading) {
      return const _PopUpStyle(child: LoadingWidget());
    }

    final Set<String> availibleTypes =
        (availible.valueOrNull ?? {})[types] ?? {};

    final Set<String> availibleGroups =
        (availible.valueOrNull ?? {})[groups] ?? {};

    void apply() {
      final List<LabeledFilter> typeFilters = selectedTypes.map((type) {
        if (availibleTypes.contains(type)) {
          return LabeledFilter(
              name: type,
              filter: (stamp) => stamp.type == type,
              filterClass: type);
        }
        return LabeledFilter(
            name: type,
            filter: (stamp) => stamp.group == type,
            filterClass: groups);
      }).toList();

      final DateTime? newStart = newRange?.start;
      final DateTime? newEnd = newRange?.end;
      final bool isSameDay =
          ((newStart != null && newEnd != null) && sameDay(newStart, newEnd)) ||
              newStart == null ||
              newEnd == null;
      DateTime? newEarliest() {
        if (newRange == null || filters.earliestRequired == null) {
          return filters.earliestRequired;
        }
        if (newRange!.start.isBefore(filters.earliestRequired!)) {
          return newRange!.start;
        }
        return filters.earliestRequired;
      }

      ref.read(filtersProvider.notifier).state = Filters(
          calendarSelection: CalendarSelection(
              selectedDate: isSameDay ? newStart ?? newEnd : null,
              rangeStart: isSameDay ? null : newStart,
              rangeEnd: isSameDay ? null : newEnd),
          earliestRequired: newEarliest(),
          latestRequired: filters.latestRequired,
          stampFilters: [
            ...typeFilters,
          ]);
      ref.read(overlayProvider.notifier).state = closedOverlay;
    }

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 35,
              ),
              Text(
                context.translate.eventFilterHeader,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                  onPressed: () {
                    ref.read(overlayProvider.notifier).state = closedOverlay;
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 35,
                  ))
            ],
          ),
          const SizedBox(
            height: 6.0,
          ),
          if (availibleTypes.length > 1) ...[
            Text(
              context.translate.eventFilterTypesTag,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: 6.0,
            ),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 5.0,
              runSpacing: 5.0,
              children: availibleTypes.map((type) {
                final bool selected = selectedTypes.contains(type);
                return ChoiceChip(
                  padding: const EdgeInsets.all(5.0),
                  label: Text(
                    type,
                  ),
                  showCheckmark: false,
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedTypes.add(type);
                      } else {
                        selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(
              height: 6.0,
            ),
            if (availibleGroups.isNotEmpty) ...[
              Text(
                "Study",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: 6.0,
              ),
              Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 5.0,
                runSpacing: 5.0,
                children: availibleGroups.map((type) {
                  final bool selected = selectedTypes.contains(type);
                  return ChoiceChip(
                    padding: const EdgeInsets.all(5.0),
                    label: Text(
                      type,
                    ),
                    showCheckmark: false,
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            /*
              Text(
                AppLocalizations.of(context)!.eventFiltersFromTag,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(
                height: 6.0,
              ),
              DateRangePicker(
                onSelection: (dateRange) {
                  if (dateRange != null) {
                    setState(() {
                      newRange = dateRange;
                    });
                  }
                },
                initialStart: newRange?.start,
                initialEnd: newRange?.end,
              ),*/
            const SizedBox(
              height: 12.0,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedTypes = {};
                      });
                    },
                    child: Text(
                      context.translate.eventFilterReset,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12.0,
                ),
                Expanded(
                  child: FilledButton(
                    child: Text(context.translate.eventFiltersApply),
                    onPressed: () {
                      apply();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 6.0,
            ),
          ],
        ]);
  }
}

const String types = "types";
const String groups = "groups";

final setsProvider = FutureProvider.autoDispose((ref) async {
  final List<Response> stamps =
      (await ref.watch(availibleStampsProvider.future)).all;

  final Map<String, Set<String>> values = {types: {}, groups: {}};

  for (Response res in stamps) {
    values[types]!.add(res.type);
    if (res.group != null) {
      values[groups]!.add(res.group!);
    }
  }

  return values;
});

class _PopUpStyle extends StatelessWidget {
  final Widget child;

  const _PopUpStyle({required this.child});

  @override
  Widget build(BuildContext context) {
    return OverlayBackdrop(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 15.0),
                      child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
