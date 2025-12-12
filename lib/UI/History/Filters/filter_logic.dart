import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/UI/History/Filters/filter_components.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
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
      case FilterType.timeOfDay:
      //case FilterType.numericRange:
      case FilterType.group:
        return true;
      default:
        return false;
    }
  }

  FilterContext createContext() {
    switch (this) {
      case FilterType.category:
        return CategoryContext();
      case FilterType.group:
        return GroupContext();
      case FilterType.timeOfDay:
        return TimeOfDayContext();
      case FilterType.description:
        return DescriptionContext();
      case FilterType.numericRange:
        return NumericRangeContext();
    }
  }

  static List<FilterType> getValues() => [
        FilterType.category,
        FilterType.description,
        FilterType.timeOfDay,
        FilterType.group
      ];
}

sealed class FilterContext<T extends FilterState> {
  void buildContext(Stamp stamp);

  bool get hasData;

  T createInitialState();

  Widget buildUI({
    required BuildContext context,
    required T state,
    required Function(T) onStateChanged,
  });

  List<LabeledFilter> createFilters(T state);
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
  final Set<String> categories = {};
  CategoryContext();

  @override
  void buildContext(Stamp stamp) {
    if (stamp case DetailResponse(type: String type)) {
      categories.add(type);
    }
  }

  @override
  CategoryState createInitialState() => CategoryState();

  @override
  bool get hasData => categories.length > 1;

  @override
  Widget buildUI({
    required BuildContext context,
    required CategoryState state,
    required Function(CategoryState) onStateChanged,
  }) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    // Create mappings for ALL categories, not just selected ones
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
  final Set<String> groups = {};
  GroupContext();

  @override
  void buildContext(Stamp stamp) {
    if (stamp case DetailResponse(group: String? group)) {
      if (group != null) groups.add(group);
    }
  }

  @override
  GroupState createInitialState() => GroupState();

  @override
  bool get hasData => groups.isNotEmpty;

  @override
  Widget buildUI({
    required BuildContext context,
    required GroupState state,
    required Function(GroupState) onStateChanged,
  }) {
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
  final Set<TimeOfDayFilter> times = {};
  TimeOfDayContext();

  @override
  void buildContext(Stamp stamp) {
    final DateTime date = dateFromStamp(stamp.stamp);
    times.add(TimeOfDayFilter.fromHour(date.hour));
  }

  @override
  TimeOfDayState createInitialState() => TimeOfDayState();

  @override
  bool get hasData => true; // Always show time of day filter

  @override
  Widget buildUI({
    required BuildContext context,
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
  bool hasDescription = false;
  DescriptionContext();

  @override
  void buildContext(Stamp stamp) {
    if (hasDescription) return;
    if (stamp case DetailResponse(description: String? description)) {
      hasDescription = description?.isNotEmpty ?? false;
    }
  }

  @override
  DescriptionState createInitialState() => DescriptionState();

  @override
  bool get hasData => hasDescription;

  @override
  Widget buildUI({
    required BuildContext context,
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
  final Set<NumericResponse> numericResponses = {};
  NumericRangeContext();

  @override
  void buildContext(Stamp stamp) {
    if (stamp case DetailResponse(responses: List<Response> responses)) {
      for (final response in responses) {
        if (response is NumericResponse) {
          numericResponses.add(response);
        }
      }
    }
  }

  @override
  NumericRangeState createInitialState() => NumericRangeState();

  @override
  bool get hasData => numericResponses.isNotEmpty;

  @override
  Widget buildUI({
    required BuildContext context,
    required NumericRangeState state,
    required Function(NumericRangeState) onStateChanged,
  }) {
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
