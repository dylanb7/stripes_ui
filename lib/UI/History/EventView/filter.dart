import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
        onPressed: () {
          ref.read(overlayProvider.notifier).state =
              OverlayQuery(widget: _FilterPopUp());
        },
        child: Row(
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
        ));
  }
}

class _FilterPopUp extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FilterPopUpState();
}

class _FilterPopUpState extends ConsumerState<_FilterPopUp> {
  Set<String> selectedTypes = {};

  late DateListener startDateListener, endDateListener;

  late TimeListener startTimeListener, endTimeListener;

  @override
  void initState() {
    startDateListener = DateListener();
    endDateListener = DateListener();
    startTimeListener = TimeListener();
    endTimeListener = TimeListener();
    initDateRange();
    startDateListener.addListener(_set);
    startTimeListener.addListener(_set);
    endDateListener.addListener(_set);
    endTimeListener.addListener(_set);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Response> availible = ref.watch(availibleStampsProvider).stamps;
    final int start =
        dateToStamp(_combine(startDateListener.date, startTimeListener.time));
    final int end =
        dateToStamp(_combine(endDateListener.date, endTimeListener.time));

    filt(val) {
      bool validType =
          selectedTypes.isEmpty || selectedTypes.contains(val.type);
      return validType && val.stamp >= start && val.stamp <= end;
    }

    final int amount = availible.where(filt).length;

    final Set<String> types = Set.from(availible.map((ent) => ent.type));
    selectedTypes.difference(types);

    final String message = amount == 1 ? '$amount Result' : '$amount Results';
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
                              style: lightBackgroundHeaderStyle,
                            ),
                            IconButton(
                                onPressed: () {
                                  ref.read(overlayProvider.notifier).state =
                                      closedQuery;
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
                                style: lightBackgroundStyle,
                              ),
                              const SizedBox(width: 4.0),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedTypes = {};
                                      initDateRange();
                                    });
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .eventFilterReset,
                                    style: lightBackgroundStyle.copyWith(
                                        decoration: TextDecoration.underline),
                                  ))
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        if (types.isNotEmpty)
                          Text(
                            AppLocalizations.of(context)!.eventFilterTypesTag,
                            style: lightBackgroundHeaderStyle,
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
                        const SizedBox(
                          height: 12.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!.eventFiltersFromTag,
                          style: lightBackgroundHeaderStyle,
                        ),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Center(
                          child: Wrap(
                            spacing: 5.0,
                            runSpacing: 5.0,
                            children: [
                              DateWidget(
                                dateListener: startDateListener,
                                latest: endDateListener.date,
                              ),
                              const SizedBox(
                                width: 25.0,
                              ),
                              TimeWidget(
                                timeListener: startTimeListener,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!.eventFiltersToTag,
                          style: lightBackgroundHeaderStyle,
                        ),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Center(
                          child: Wrap(
                            spacing: 5.0,
                            runSpacing: 5.0,
                            children: [
                              DateWidget(
                                dateListener: endDateListener,
                                earliest: startDateListener.date,
                              ),
                              const SizedBox(
                                width: 25.0,
                              ),
                              TimeWidget(
                                timeListener: endTimeListener,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        FilledButton(
                            child: Text(AppLocalizations.of(context)!
                                .eventFiltersApply),
                            onPressed: () {
                              final Filters filts = ref.read(filtersProvider);
                              ref.read(filtersProvider.notifier).state =
                                  filts.copyWith(filt: filt);
                              ref.read(overlayProvider.notifier).state =
                                  closedQuery;
                            }),
                        const SizedBox(
                          height: 6.0,
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
    );
  }

  _set() {
    setState(() {});
  }

  initDateRange() {
    final List<Response> availible = ref.read(availibleStampsProvider).stamps;
    DateTime startDate = DateTime.now();
    DateTime endDate = startDate;
    if (availible.isNotEmpty) {
      startDate = dateFromStamp(availible.last.stamp);
      endDate = dateFromStamp(availible.first.stamp);
    }
    startDateListener.date = startDate;
    startTimeListener.time = TimeOfDay.fromDateTime(startDate);
    endDateListener.date = endDate;
    endTimeListener.time = TimeOfDay.fromDateTime(endDate);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute,
        date.second, date.millisecond);
  }

  @override
  void dispose() {
    startDateListener.removeListener(_set);
    startTimeListener.removeListener(_set);
    endDateListener.removeListener(_set);
    endTimeListener.removeListener(_set);
    super.dispose();
  }
}
