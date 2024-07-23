import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class FilterView extends ConsumerWidget {
  const FilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Filters filters = ref.watch(filtersProvider);
    final String range = filters.toRange(context);
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        FilledButton(
          onPressed: () {
            ref.read(overlayProvider.notifier).state =
                CurrentOverlay(widget: _FilterPopUp());
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.filterEventsButton,
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
        if (range.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(filtersProvider.notifier).state = Filters(
                  rangeStart: null,
                  rangeEnd: null,
                  selectedDate: null,
                  latestRequired: filters.latestRequired,
                  earliestRequired: filters.earliestRequired,
                  stampFilters: filters.stampFilters);
            },
            label: Text(range),
            icon: const Icon(Icons.close),
            iconAlignment: IconAlignment.end,
          ),
        ...filters.stampFilters?.map(
              (filter) => FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(filtersProvider.notifier).state = filters.copyWith(
                      stampFilters: filters.stampFilters?..remove(filter));
                },
                label: Text(filter.name),
                icon: const Icon(Icons.close),
                iconAlignment: IconAlignment.end,
              ),
            ) ??
            []
      ],
    );
  }
}

class _FilterPopUp extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FilterPopUpState();
}

class _FilterPopUpState extends ConsumerState<_FilterPopUp> {
  Set<String> selectedTypes = {};

  Set<String> selectedGroups = {};

  DateTimeRange? newRange;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Available> availible = ref.watch(availibleStampsProvider);

    final Filters filters = ref.watch(filtersProvider);

    final DateTime? currentStart = filters.rangeStart ?? filters.selectedDate;

    final DateTime? currentEnd = filters.rangeEnd ?? filters.selectedDate;

    if (availible.isLoading) {
      return const _PopUpStyle(
          child: Center(
        child: CircularProgressIndicator(),
      ));
    }

    final List<Response> stamps = availible.valueOrNull?.visible ?? [];

    bool filt(Response val) {
      final bool validType =
          selectedTypes.isEmpty || selectedTypes.contains(val.type);
      final bool validGroup =
          selectedGroups.isEmpty || selectedGroups.contains(val.group);
      bool validDate() {
        if (newRange != null) {
          return inRange(newRange!.start, newRange!.end, val);
        }
        return (currentStart != null &&
            currentEnd != null &&
            inRange(currentStart, currentEnd, val));
      }

      return validType && validGroup && validDate();
    }

    final int amount = stamps.where(filt).length;

    final Set<String> types = Set.from(stamps.map((ent) => ent.type));

    final Set<String> groups =
        Set.from(stamps.map((ent) => ent.group).whereType<String>());

    final String message = amount == 1 ? '$amount Result' : '$amount Results';
    return _PopUpStyle(
      child: Column(
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
                AppLocalizations.of(context)!.eventFilterHeader,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                  onPressed: () {
                    ref.read(overlayProvider.notifier).state = closedQuery;
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
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 4.0),
                TextButton(
                    onPressed: () {
                      setState(() {
                        selectedTypes = {};
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context)!.eventFilterReset,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(decoration: TextDecoration.underline),
                    ))
              ],
            ),
          ),
          const SizedBox(
            height: 12.0,
          ),
          if (types.length > 1) ...[
            Text(
              AppLocalizations.of(context)!.eventFilterTypesTag,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: 6.0,
            ),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.center,
              spacing: 5.0,
              runSpacing: 5.0,
              children: types.map((type) {
                final bool selected = selectedTypes.contains(type);
                return ChoiceChip(
                  padding: const EdgeInsets.all(5.0),
                  label: Text(
                    type,
                  ),
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
          const SizedBox(
            height: 12.0,
          ),
          if (groups.length > 1) ...[
            Text(
              AppLocalizations.of(context)!.eventFilterGroupsTag,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: 6.0,
            ),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.center,
              spacing: 5.0,
              runSpacing: 5.0,
              children: groups.map((tag) {
                final bool selected = selectedGroups.contains(tag);
                return ChoiceChip(
                  padding: const EdgeInsets.all(5.0),
                  label: Text(
                    tag,
                  ),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedGroups.add(tag);
                      } else {
                        selectedGroups.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(
            height: 12.0,
          ),
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
            initialStart: filters.rangeStart ?? filters.selectedDate,
            initialEnd: filters.rangeEnd ?? filters.selectedDate,
            restorationId: "filters_range_picker",
          ),
          const SizedBox(
            height: 12.0,
          ),
          FilledButton(
              child: Text(AppLocalizations.of(context)!.eventFiltersApply),
              onPressed: () {
                final List<LabeledFilter> typeFilters =
                    selectedTypes.map((type) {
                  return LabeledFilter(
                      name: type, filter: (stamp) => stamp.type == type);
                }).toList();
                final List<LabeledFilter> groupFilters =
                    selectedGroups.map((group) {
                  return LabeledFilter(
                      name: group, filter: (stamp) => stamp.group == group);
                }).toList();
                final DateTime? newStart = newRange?.start ?? currentStart;
                final DateTime? newEnd = newRange?.end ?? currentEnd;
                final bool isSameDay = ((newStart != null && newEnd != null) &&
                        sameDay(newStart, newEnd)) ||
                    newStart == null ||
                    newEnd == null;
                ref.read(filtersProvider.notifier).state = Filters(
                    rangeStart: isSameDay ? null : newStart,
                    rangeEnd: isSameDay ? null : newEnd,
                    selectedDate: isSameDay ? newStart ?? newEnd : null,
                    stampFilters: [...typeFilters, ...groupFilters]);
                ref.read(overlayProvider.notifier).state = closedQuery;
              }),
          const SizedBox(
            height: 6.0,
          ),
        ],
      ),
    );
  }
}

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
