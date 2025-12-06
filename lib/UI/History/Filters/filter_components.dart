import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class FilterChipSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Set<String> selectedItems;
  final Function(String, bool) onSelected;

  const FilterChipSection({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: AppPadding.tiny),
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: AppPadding.tiny,
          runSpacing: AppPadding.tiny,
          children: items.map((item) {
            final bool selected = selectedItems.contains(item);
            return ChoiceChip(
              padding: const EdgeInsets.all(AppPadding.tiny),
              label: Text(item),
              showCheckmark: false,
              selected: selected,
              onSelected: (value) => onSelected(item, value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DescriptionFilterSection extends StatelessWidget {
  final bool hasDescriptionToggle;
  final String notesSearchText;
  final Function(bool) onToggleChanged;
  final Function(String) onTextChanged;

  const DescriptionFilterSection({
    super.key,
    required this.hasDescriptionToggle,
    required this.notesSearchText,
    required this.onToggleChanged,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: AppPadding.tiny),
        FilterChip(
          label: const Text("Has Description"),
          selected: hasDescriptionToggle,
          onSelected: onToggleChanged,
        ),
        if (hasDescriptionToggle) ...[
          const SizedBox(height: AppPadding.tiny),
          TextField(
            decoration: InputDecoration(
              hintText: "Search in descriptions...",
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small, vertical: AppPadding.tiny),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
            onChanged: onTextChanged,
            controller: TextEditingController(text: notesSearchText)
              ..selection =
                  TextSelection.collapsed(offset: notesSearchText.length),
          ),
        ],
      ],
    );
  }
}

class NumericRangeFilterSection extends StatelessWidget {
  final Map<String, (num, num)> numericRanges;
  final Map<String, Question> questionMap;
  final String? selectedNumericCategory;
  final Map<String, (num, num)> selectedRanges;
  final Function(String?) onCategorySelected;
  final Function(Question, num, num) onRangeChanged;

  const NumericRangeFilterSection({
    super.key,
    required this.numericRanges,
    required this.questionMap,
    required this.selectedNumericCategory,
    required this.selectedRanges,
    required this.onCategorySelected,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (numericRanges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
          child: Text(
            "Numeric Ranges",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: AppPadding.tiny),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            const SizedBox(width: AppPadding.medium),
            ...numericRanges.keys.map((key) {
              final Question question = questionMap[key]!;
              final QuestionsLocalizations? localizations =
                  QuestionsLocalizations.of(context);
              final String questionText =
                  localizations?.value(question.prompt) ?? question.prompt;
              final bool isSelected = selectedNumericCategory == key;
              return Padding(
                padding: const EdgeInsets.only(right: AppPadding.tiny),
                child: ChoiceChip(
                  label: Text(
                    questionText,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (isSelected) {
                      onCategorySelected(null);
                    } else {
                      onCategorySelected(question.id);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Scrollable.of(context).position.animateTo(
                                Scrollable.of(context).position.maxScrollExtent,
                                duration: Durations.medium1,
                                curve: Curves.easeInOut,
                              );
                        }
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRounding.small),
                    side: isSelected
                        ? BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2)
                        : BorderSide.none,
                  ),
                ),
              );
            }),
          ]),
        ),
        if (selectedNumericCategory != null) ...[
          const SizedBox(height: AppPadding.small),
          Builder(builder: (context) {
            final String questionId = selectedNumericCategory!;
            final Question question = questionMap[questionId]!;
            final QuestionsLocalizations? localizations =
                QuestionsLocalizations.of(context);
            final String questionText =
                localizations?.value(question.prompt) ?? question.prompt;

            final (num dataMin, num dataMax) = numericRanges[questionId]!;
            final (num selectedMin, num selectedMax) =
                selectedRanges[questionId] ?? (dataMin, dataMax);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
              child: Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          questionText,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${selectedMin.toInt()} - ${selectedMax.toInt()}",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.tiny),
                    RangeSlider(
                      values: RangeValues(
                        selectedMin.toDouble(),
                        selectedMax.toDouble(),
                      ),
                      min: dataMin.toDouble(),
                      max: dataMax.toDouble(),
                      divisions: (dataMax - dataMin).toInt() > 0
                          ? (dataMax - dataMin).toInt()
                          : 1,
                      labels: RangeLabels(
                        selectedMin.toInt().toString(),
                        selectedMax.toInt().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        onRangeChanged(question, values.start, values.end);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
