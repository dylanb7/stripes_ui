import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/History/button_style.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    open() {
      ref.read(overlayProvider.notifier).state =
          OverlayQuery(widget: _FilterPopUp());
    }

    return ElevatedButton(
        onPressed: () {
          open();
        },
        style: historyButtonStyle,
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.filterEventsButton,
              style: buttonText,
            ),
            const SizedBox(
              width: 4.0,
            ),
            const Icon(
              Icons.filter_list,
              color: darkIconButton,
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
  late Set<String> types;

  Set<String> selectedTypes = {};

  late DateTime startDate, endDate;

  late DateListener startDateListener, endDateListener;

  late TimeListener startTimeListener, endTimeListener;

  late List<Response> availible;

  @override
  void initState() {
    reset();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filt(val) {
      bool validType =
          selectedTypes.isEmpty || selectedTypes.contains(val.type);
      final int start =
          dateToStamp(_combine(startDateListener.date, startTimeListener.time));
      final int end =
          dateToStamp(_combine(endDateListener.date, endTimeListener.time));
      return validType && val.stamp >= start && val.stamp <= end;
    }

    startDateListener.addListener(_set);
    startTimeListener.addListener(_set);
    endDateListener.addListener(_set);
    endTimeListener.addListener(_set);
    final int amount = availible.where(filt).length;
    final String message = amount == 1 ? '$amount Result' : '$amount Results';
    return OverlayBackdrop(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                  color: darkBackgroundText,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
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
                          style: darkBackgroundScreenHeaderStyle.copyWith(
                              color: darkIconButton),
                        ),
                        IconButton(
                            onPressed: () {
                              ref.read(overlayProvider.notifier).state =
                                  closedQuery;
                            },
                            icon: const Icon(
                              Icons.close,
                              color: darkIconButton,
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
                                  reset();
                                });
                              },
                              child: Text(
                                AppLocalizations.of(context)!.eventFilterReset,
                                style: lightBackgroundStyle.copyWith(
                                    color: darkIconButton),
                              ))
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.eventFilterTypesTag,
                        style: lightBackgroundHeaderStyle.copyWith(
                            color: darkIconButton),
                      ),
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
                            style: darkBackgroundStyle.copyWith(
                                color: selected
                                    ? darkIconButton
                                    : lightBackgroundText.withOpacity(0.7)),
                          ),
                          selected: selected,
                          elevation: selected ? 2.0 : 1.0,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                selectedTypes.add(type);
                              } else {
                                selectedTypes.remove(type);
                              }
                            });
                          },
                          selectedColor: darkIconButton.withOpacity(0.45),
                          backgroundColor: Colors.grey.withOpacity(0.8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!.eventFiltersFromTag,
                      style: lightBackgroundHeaderStyle.copyWith(
                          color: darkIconButton),
                    ),
                    const SizedBox(
                      height: 6.0,
                    ),
                    Center(
                      child: ProviderScope(
                        overrides: [
                          dateProvider.overrideWith((_) => startDateListener),
                          timeProvider.overrideWith((_) => startTimeListener)
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DateWidget(
                              latest: endDateListener.date,
                            ),
                            const SizedBox(
                              width: 25.0,
                            ),
                            const TimeWidget(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!.eventFiltersToTag,
                      style: lightBackgroundHeaderStyle.copyWith(
                          color: darkIconButton),
                    ),
                    const SizedBox(
                      height: 6.0,
                    ),
                    Center(
                      child: ProviderScope(
                        overrides: [
                          dateProvider.overrideWith((_) => endDateListener),
                          timeProvider.overrideWith((_) => endTimeListener)
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DateWidget(
                              earliest: startDateListener.date,
                            ),
                            const SizedBox(
                              width: 25.0,
                            ),
                            const TimeWidget(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    StripesRoundedButton(
                        text: AppLocalizations.of(context)!.eventFiltersApply,
                        onClick: () {
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
    );
  }

  _set() {
    setState(() {});
  }

  reset() {
    availible = ref.read(availibleStampsProvider).stamps;
    types = {};
    types.addAll(availible.map((ent) => ent.type));
    selectedTypes = {};
    if (availible.isNotEmpty) {
      startDate = dateFromStamp(availible.last.stamp);
      endDate = dateFromStamp(availible.first.stamp);
    } else {
      startDate = endDate = DateTime.now();
    }
    startDateListener = DateListener()..quietSet(startDate);
    startTimeListener = TimeListener()
      ..quietSet(TimeOfDay.fromDateTime(startDate));
    endDateListener = DateListener()..quietSet(endDate);
    endTimeListener = TimeListener()..quietSet(TimeOfDay.fromDateTime(endDate));
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
