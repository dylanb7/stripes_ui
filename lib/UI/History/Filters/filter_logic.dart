import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Helpers/history_reducer.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/UI/History/Filters/filter_components.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

enum FilterType {
  category,
  description,
  timeOfDay,
  group,
  numericRange;

  String get name {
    switch (this) {
      case FilterType.category:
        return "Category";
      case FilterType.group:
        return "Group";
      case FilterType.timeOfDay:
        return "Time of Day";
      case FilterType.description:
        return "Description";
      case FilterType.numericRange:
        return "Numeric Range";
    }
  }

  bool isAdvanced() {
    switch (this) {
      /*case FilterType.timeOfDay:
      //case FilterType.numericRange:
      case FilterType.group:
        return true;*/
      default:
        return false;
    }
  }

  FilterContext createContext() {
    switch (this) {
      case FilterType.category:
        return const CategoryContext();
      case FilterType.group:
        return const GroupContext();
      case FilterType.timeOfDay:
        return const TimeOfDayContext();
      case FilterType.description:
        return const DescriptionContext();
      case FilterType.numericRange:
        return const NumericRangeContext();
    }
  }

  static List<FilterType> getValues() =>
      [FilterType.category, FilterType.group];
}

sealed class FilterContext<T extends FilterState> {
  const FilterContext();

  bool hasData(HistoryContext ctx);

  T createInitialState();

  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required T state,
    required Function(T) onStateChanged,
  });

  List<LabeledFilter> createFilters(T state);
}

// =============================================================================
// Filter-Specific Features
// =============================================================================

class AvailableGroupsFeature extends ReducibleFeature<Set<String>> {
  const AvailableGroupsFeature();
  @override
  Set<String> createInitialState() => {};
  @override
  Set<String> reduce(Set<String> state, Response response) {
    if (response is DetailResponse && response.group != null) {
      state.add(response.group!);
    }
    return state;
  }
}

class DescriptionCheckFeature extends ReducibleFeature<bool> {
  const DescriptionCheckFeature();
  @override
  bool createInitialState() => false;
  @override
  bool reduce(bool state, Response response) {
    if (state) return true;
    if (response is DetailResponse &&
        (response.description?.isNotEmpty ?? false)) {
      return true;
    }
    return false;
  }
}

class NumericResponsesFeature extends ReducibleFeature<Set<NumericResponse>> {
  const NumericResponsesFeature();
  @override
  Set<NumericResponse> createInitialState() => {};
  @override
  Set<NumericResponse> reduce(Set<NumericResponse> state, Response response) {
    if (response is DetailResponse) {
      for (final r in response.responses) {
        if (r is NumericResponse) {
          state.add(r);
        }
      }
    }
    return state;
  }
}

abstract class FilterState {}

class CategoryState extends FilterState {
  final Set<String> selectedItems;

  CategoryState({Set<String>? selectedItems})
      : selectedItems = selectedItems ?? {};

  CategoryState copyWith({Set<String>? selectedItems}) {
    return CategoryState(
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }
}

class GroupState extends FilterState {
  final Set<String> selectedItems;

  GroupState({Set<String>? selectedItems})
      : selectedItems = selectedItems ?? {};

  GroupState copyWith({Set<String>? selectedItems}) {
    return GroupState(
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }
}

class TimeOfDayState extends FilterState {
  final Set<String> selectedItems;

  TimeOfDayState({Set<String>? selectedItems})
      : selectedItems = selectedItems ?? {};

  TimeOfDayState copyWith({Set<String>? selectedItems}) {
    return TimeOfDayState(
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }
}

class DescriptionState extends FilterState {
  final bool toggleValue;
  final String searchText;

  DescriptionState({
    this.toggleValue = false,
    this.searchText = '',
  });

  DescriptionState copyWith({
    bool? toggleValue,
    String? searchText,
  }) {
    return DescriptionState(
      toggleValue: toggleValue ?? this.toggleValue,
      searchText: searchText ?? this.searchText,
    );
  }
}

class NumericRangeState extends FilterState {
  final String? selectedCategory;
  final Map<String, (num, num)> ranges;

  NumericRangeState({
    this.selectedCategory,
    Map<String, (num, num)>? ranges,
  }) : ranges = ranges ?? {};

  NumericRangeState copyWith({
    String? selectedCategory,
    Map<String, (num, num)>? ranges,
  }) {
    return NumericRangeState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      ranges: ranges ?? this.ranges,
    );
  }
}

class CategoryContext extends FilterContext<CategoryState> {
  const CategoryContext();

  @override
  CategoryState createInitialState() => CategoryState();

  @override
  bool hasData(HistoryContext ctx) =>
      ctx.use(const AllCategoriesFeature()).length > 1;

  @override
  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required CategoryState state,
    required Function(CategoryState) onStateChanged,
  }) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final categories = historyContext.use(const AllCategoriesFeature());
    // localized name → raw value (for looking up what was selected)
    final Map<String, String> localizedToRaw = {};
    // raw value → localized name (for displaying selected items)
    final Map<String, String> rawToLocalized = {};

    for (final type in categories) {
      final localized = localizations?.value(type) ?? type;
      localizedToRaw[localized] = type;
      rawToLocalized[type] = localized;
    }

    // Get localized display names for all categories
    final List<String> displayItems =
        categories.map((type) => rawToLocalized[type] ?? type).toList();

    // Convert selected raw values to their localized display names
    final Set<String> selectedDisplayItems =
        state.selectedItems.map((type) => rawToLocalized[type] ?? type).toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: FilterChipSection(
        title: context.translate.eventFilterTypesTag,
        items: displayItems,
        selectedItems: selectedDisplayItems,
        onSelected: (localizedItem, selected) {
          // Convert localized item back to raw value
          final rawValue = localizedToRaw[localizedItem];
          if (rawValue == null) return;

          final newSelected = Set<String>.from(state.selectedItems);
          if (selected) {
            newSelected.add(rawValue);
          } else {
            newSelected.remove(rawValue);
          }
          onStateChanged(state.copyWith(selectedItems: newSelected));
        },
      ),
    );
  }

  @override
  List<LabeledFilter> createFilters(CategoryState state) {
    return state.selectedItems.map((type) {
      return LabeledFilter(
        name: type,
        filter: (stamp) => stamp.type == type,
        filterType: FilterType.category,
      );
    }).toList();
  }
}

class GroupContext extends FilterContext<GroupState> {
  const GroupContext();

  @override
  GroupState createInitialState() => GroupState();

  @override
  bool hasData(HistoryContext ctx) =>
      ctx.use(const AvailableGroupsFeature()).isNotEmpty;

  @override
  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required GroupState state,
    required Function(GroupState) onStateChanged,
  }) {
    final groups = historyContext.use(const AvailableGroupsFeature());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: FilterChipSection(
        title: "Study",
        items: groups.toList(),
        selectedItems: state.selectedItems,
        onSelected: (item, selected) {
          final newSelected = Set<String>.from(state.selectedItems);
          if (selected) {
            newSelected.add(item);
          } else {
            newSelected.remove(item);
          }
          onStateChanged(state.copyWith(selectedItems: newSelected));
        },
      ),
    );
  }

  @override
  List<LabeledFilter> createFilters(GroupState state) {
    return state.selectedItems.map((group) {
      return LabeledFilter(
        name: group,
        filter: (stamp) => stamp.group == group,
        filterType: FilterType.group,
      );
    }).toList();
  }
}

class TimeOfDayContext extends FilterContext<TimeOfDayState> {
  const TimeOfDayContext();

  @override
  TimeOfDayState createInitialState() => TimeOfDayState();

  @override
  bool hasData(HistoryContext ctx) => true; // Always show time of day filter

  @override
  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required TimeOfDayState state,
    required Function(TimeOfDayState) onStateChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: FilterChipSection(
        title: "Time of Day",
        items: TimeOfDayFilter.values.map((e) => e.name()).toList(),
        selectedItems: state.selectedItems,
        onSelected: (item, selected) {
          final newSelected = Set<String>.from(state.selectedItems);
          if (selected) {
            newSelected.add(item);
          } else {
            newSelected.remove(item);
          }
          onStateChanged(state.copyWith(selectedItems: newSelected));
        },
      ),
    );
  }

  @override
  List<LabeledFilter> createFilters(TimeOfDayState state) {
    return state.selectedItems.map((timeLabel) {
      final TimeOfDayFilter time = TimeOfDayFilter.fromString(name: timeLabel);
      return LabeledFilter(
        name: timeLabel,
        filter: (stamp) {
          final DateTime date = dateFromStamp(stamp.stamp);
          final int hour = date.hour;
          return time.matchesHour(hour);
        },
        filterType: FilterType.timeOfDay,
      );
    }).toList();
  }
}

class DescriptionContext extends FilterContext<DescriptionState> {
  const DescriptionContext();

  @override
  DescriptionState createInitialState() => DescriptionState();

  @override
  bool hasData(HistoryContext ctx) => ctx.use(const DescriptionCheckFeature());

  @override
  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required DescriptionState state,
    required Function(DescriptionState) onStateChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: DescriptionFilterSection(
        hasDescriptionToggle: state.toggleValue,
        notesSearchText: state.searchText,
        onToggleChanged: (value) {
          onStateChanged(state.copyWith(
            toggleValue: value,
            searchText: value ? state.searchText : '',
          ));
        },
        onTextChanged: (value) {
          onStateChanged(state.copyWith(
            searchText: value,
            toggleValue: value.isNotEmpty || state.toggleValue,
          ));
        },
      ),
    );
  }

  @override
  List<LabeledFilter> createFilters(DescriptionState state) {
    if (!state.toggleValue) return [];

    if (state.searchText.isNotEmpty) {
      return [
        LabeledFilter(
          name: state.searchText,
          filter: (stamp) {
            if (stamp case DetailResponse detail) {
              return detail.description != null &&
                  detail.description!
                      .toLowerCase()
                      .contains(state.searchText.toLowerCase());
            }
            return false;
          },
          filterType: FilterType.description,
        )
      ];
    } else {
      return [
        LabeledFilter(
          name: "Has Description",
          filter: (stamp) {
            if (stamp case DetailResponse detail) {
              return detail.description != null &&
                  detail.description!.isNotEmpty;
            }
            return false;
          },
          filterType: FilterType.description,
        )
      ];
    }
  }
}

class NumericRangeContext extends FilterContext<NumericRangeState> {
  const NumericRangeContext();

  @override
  NumericRangeState createInitialState() => NumericRangeState();

  @override
  bool hasData(HistoryContext ctx) =>
      ctx.use(const NumericResponsesFeature()).isNotEmpty;

  @override
  Widget buildUI({
    required BuildContext context,
    required HistoryContext historyContext,
    required NumericRangeState state,
    required Function(NumericRangeState) onStateChanged,
  }) {
    final numericResponses =
        historyContext.use(const NumericResponsesFeature());
    final Map<String, Question> questionMap = {};
    final Map<String, (num, num)> numericRanges = {};

    for (final resp in numericResponses) {
      final q = resp.question;
      if (!questionMap.containsKey(q.id)) {
        questionMap[q.id] = q;
        numericRanges[q.id] =
            (q.min?.toDouble() ?? 1.0, q.max?.toDouble() ?? 5.0);
      }
    }

    return NumericRangeFilterSection(
      numericRanges: numericRanges,
      questionMap: questionMap,
      selectedNumericCategory: state.selectedCategory,
      selectedRanges: state.ranges,
      onCategorySelected: (question) {
        onStateChanged(NumericRangeState(
            selectedCategory: question, ranges: state.ranges));
      },
      onRangeChanged: (question, min, max) {
        final newRanges = Map<String, (num, num)>.from(state.ranges);
        newRanges[question.id] = (min, max);
        onStateChanged(state.copyWith(ranges: newRanges));
      },
    );
  }

  @override
  List<LabeledFilter> createFilters(NumericRangeState state) {
    if (state.selectedCategory == null ||
        !state.ranges.containsKey(state.selectedCategory)) {
      return [];
    }

    final (min, max) = state.ranges[state.selectedCategory]!;
    return [
      LabeledFilter(
          name:
              "Range: ${min.toInt()}-${max.toInt()}|${state.selectedCategory}",
          filter: (stamp) {
            if (stamp case DetailResponse detail) {
              for (final response in detail.responses) {
                if (response case NumericResponse numResp) {
                  if (numResp.question.id == state.selectedCategory) {
                    if (numResp.response >= min && numResp.response <= max) {
                      return true;
                    }
                  }
                }
              }
            }
            return false;
          },
          filterType: FilterType.category // FilterType.numericRange,
          )
    ];
  }
}

enum TimeOfDayFilter {
  morning,
  afternoon,
  evening,
  night;

  String name() {
    switch (this) {
      case TimeOfDayFilter.morning:
        return "Morning";
      case TimeOfDayFilter.afternoon:
        return "Afternoon";
      case TimeOfDayFilter.evening:
        return "Evening";
      case TimeOfDayFilter.night:
        return "Night";
    }
  }

  static TimeOfDayFilter fromHour(int hour) {
    if (hour >= 6 && hour < 12) {
      return TimeOfDayFilter.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDayFilter.afternoon;
    } else if (hour >= 18 && hour < 24) {
      return TimeOfDayFilter.evening;
    } else {
      return TimeOfDayFilter.night;
    }
  }

  bool matchesHour(int hour) {
    return fromHour(hour) == this;
  }

  static TimeOfDayFilter fromString({required String name}) {
    switch (name) {
      case "Morning":
        return TimeOfDayFilter.morning;
      case "Afternoon":
        return TimeOfDayFilter.afternoon;
      case "Evening":
        return TimeOfDayFilter.evening;
      case "Night":
        return TimeOfDayFilter.night;
      default:
        return TimeOfDayFilter.morning;
    }
  }
}
