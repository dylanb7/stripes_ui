import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

final setsProvider =
    FutureProvider.autoDispose<Map<FilterType, FilterContext>>((ref) async {
  final List<Response> stamps = await ref.watch(inRangeProvider.future);

  final Map<FilterType, FilterContext> contexts = {};

  for (final type in FilterType.getValues()) {
    contexts[type] = type.createContext();
  }

  for (final stamp in stamps) {
    for (final type in FilterType.getValues()) {
      contexts[type]!.buildContext(stamp);
    }
  }

  return contexts;
});

class FilterSheet extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const FilterSheet({super.key, this.scrollController});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _FilterSheetState();
  }
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  final Map<FilterType, FilterState> filterStates = {};
  final Set<FilterType> initiallyActiveFilters = {};

  @override
  void initState() {
    super.initState();
  }

  void _initializeStates(Map<FilterType, FilterContext> contexts) {
    if (filterStates.isEmpty) {
      for (final entry in contexts.entries) {
        filterStates[entry.key] = entry.value.createInitialState();
      }

      final DisplayDataSettings filters = ref.read(displayDataProvider);
      for (final filter in filters.filters) {
        final FilterType type = filter.filterType;
        final FilterContext? context = contexts[type];
        if (context == null) continue;

        switch (type) {
          case FilterType.category:
            final state = filterStates[type] as CategoryState;
            filterStates[type] = state.copyWith(
              selectedItems: {...state.selectedItems, filter.name},
            );
          case FilterType.group:
            final state = filterStates[type] as GroupState;
            filterStates[type] = state.copyWith(
              selectedItems: {...state.selectedItems, filter.name},
            );
          case FilterType.timeOfDay:
            final state = filterStates[type] as TimeOfDayState;
            filterStates[type] = state.copyWith(
              selectedItems: {...state.selectedItems, filter.name},
            );
          case FilterType.description:
            final state = filterStates[type] as DescriptionState;
            if (filter.name == "Has Description") {
              filterStates[type] = state.copyWith(toggleValue: true);
            } else {
              filterStates[type] = state.copyWith(
                toggleValue: true,
                searchText: filter.name,
              );
            }
          case FilterType.numericRange:
            final parsed = _parseSelectedRange(filter.name);
            if (parsed != null) {
              final (selectedCategory, min, max) = parsed;
              final state = filterStates[type] as NumericRangeState;
              final currentRanges = Map<String, (num, num)>.from(state.ranges);
              currentRanges[selectedCategory] = (min, max);
              filterStates[type] = state.copyWith(
                selectedCategory: selectedCategory,
                ranges: currentRanges,
              );
            }
        }
      }

      initiallyActiveFilters.clear();
      for (final type in FilterType.values) {
        if (_hasActiveSelection(type)) {
          initiallyActiveFilters.add(type);
        }
      }
    }
  }

  bool _hasActiveSelection(FilterType type) {
    final FilterState? state = filterStates[type];
    if (state == null) return false;

    switch (state) {
      case CategoryState(selectedItems: final Set<String> selectedItems):
        return selectedItems.isNotEmpty;
      case GroupState(selectedItems: final Set<String> selectedItems):
        return selectedItems.isNotEmpty;
      case TimeOfDayState(selectedItems: final Set<String> selectedItems):
        return selectedItems.isNotEmpty;
      case DescriptionState(toggleValue: final bool toggleValue):
        return toggleValue;
      case NumericRangeState(selectedCategory: final String? selectedCategory):
        return selectedCategory != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<FilterType, FilterContext>> available =
        ref.watch(setsProvider);

    return AsyncValueDefaults(
      value: available,
      onLoading: (_) => const LoadingWidget(),
      onError: (error) => ErrorWidget(error),
      onData: (contexts) {
        _initializeStates(contexts);

        List<Widget> visibleFilters = [];

        List<Widget> advancedFilters = [];

        for (final type in FilterType.getValues()) {
          final FilterContext? filterContext = contexts[type];
          if (filterContext == null || !filterContext.hasData) continue;
          final FilterState? filterState = filterStates[type];
          if (filterState == null) continue;

          final bool isVisible =
              !type.isAdvanced() || initiallyActiveFilters.contains(type);

          if (isVisible) {
            visibleFilters.add(
              Builder(builder: (context) {
                return filterContext.buildUI(
                  context: context,
                  state: filterState,
                  onStateChanged: (newState) {
                    setState(() {
                      filterStates[type] = newState;
                    });
                  },
                );
              }),
            );
          } else {
            advancedFilters.add(
              Builder(builder: (context) {
                return filterContext.buildUI(
                  context: context,
                  state: filterState,
                  onStateChanged: (newState) {
                    setState(() {
                      filterStates[type] = newState;
                    });
                  },
                );
              }),
            );
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppPadding.medium, AppPadding.small, AppPadding.medium, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (final entry in contexts.entries) {
                              filterStates[entry.key] =
                                  entry.value.createInitialState();
                            }
                          });
                        },
                        child: const Text("Reset"),
                      ),
                      const SizedBox(width: AppPadding.small),
                      FilledButton(
                        onPressed: () {
                          apply(contexts);
                        },
                        child: const Text("Apply"),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.medium),
              child: Divider(
                thickness: 1.0,
                height: 1.0,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppPadding.medium),
                    ...visibleFilters.separated(by: const Divider()),
                    if (advancedFilters.isNotEmpty)
                      ExpansionTile(
                        title: const Text("Advanced Filters"),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        initiallyExpanded: false,
                        childrenPadding: EdgeInsets.zero,
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.medium),
                        expandedAlignment: Alignment.topLeft,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            advancedFilters.separated(by: const Divider()),
                      ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void apply(Map<FilterType, FilterContext> contexts) {
    final List<LabeledFilter> allFilters = [];

    for (final type in FilterType.values) {
      final context = contexts[type];
      if (context != null) {
        final List<LabeledFilter> filters =
            context.createFilters(filterStates[type]!);
        allFilters.addAll(filters);
      }
    }

    ref.read(displayDataProvider.notifier).updateFilters(allFilters);
    Navigator.of(context).pop();
  }
}

class CurrentFilters extends ConsumerWidget {
  const CurrentFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<LabeledFilter> filters =
        ref.watch(displayDataProvider.select((value) => value.filters));
    if (filters.isEmpty) return const SizedBox.shrink();

    // Import localization for category types
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    String getLocalizedName(LabeledFilter filter) {
      // Only localize category type filters, others use their name directly
      if (filter.filterType == FilterType.category) {
        return localizations?.value(filter.name) ?? filter.name;
      }
      return filter.name;
    }

    return SizedBox(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: AppPadding.xl),
          ...filters.map((filter) {
            return FilterChip(
              label: Text(getLocalizedName(filter)),
              selected: true,
              showCheckmark: false,
              deleteIcon: const Icon(Icons.close),
              visualDensity: VisualDensity.compact,
              onSelected: (value) {
                ref
                    .read(displayDataProvider.notifier)
                    .updateFilters(filters.where((f) => f != filter).toList());
              },
              onDeleted: () {
                ref
                    .read(displayDataProvider.notifier)
                    .updateFilters(filters.where((f) => f != filter).toList());
              },
            );
          }).separated(
            by: const SizedBox(
              width: AppPadding.tiny,
            ),
          ),
        ],
      ),
    );
  }
}

(String, num, num)? _parseSelectedRange(String filterName) {
  final List<String> parts = filterName.split("|");
  if (parts.length == 2) {
    final String rangePart = parts[0];
    final String id = parts[1];
    final List<String> rangeParts =
        rangePart.replaceAll("Range: ", "").split("-");

    if (rangeParts.length == 2) {
      final double? min = double.tryParse(rangeParts[0]);
      final double? max = double.tryParse(rangeParts[1]);
      if (min != null && max != null) {
        return (id, min, max);
      }
    }
  }
  return null;
}
