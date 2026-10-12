import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// The Bristol stool question is the one intentional ID-level escape hatch in
/// this preset. Every other entry is selected by [QuestionType].
const String bowelMovementStoolTypeQuestionId = 'q4';

const Color _navy = Color(0xFF17245E);
const Color _blue = Color(0xFF185EAA);
const Color _paleBlue = Color(0xFFF0F6FC);
const Color _outline = Color(0xFFD4DEEC);
const Color _brown = Color(0xFFA85A18);

/// Experimental full-view recording preset inspired by the bowel-movement
/// design. This is only selected when
/// `StripesConfig.betaUi.multiSessionFlow` is true.
QuestionUIRegistry bowelMovementFullViewRegistry() => QuestionUIRegistry(
  entryOverrides: {
    ...QuestionUIRegistry.defaultEntryOverrides,
    bowelMovementStoolTypeQuestionId: const QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildBristolEntry,
    ),
  },
  entryTypeOverrides: const {
    QuestionType.check: QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildCheckEntry,
    ),
    QuestionType.multipleChoice: QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildMultipleChoiceEntry,
    ),
    QuestionType.allThatApply: QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildAllThatApplyEntry,
    ),
    QuestionType.slider: QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildNumericEntry,
    ),
    QuestionType.freeResponse: QuestionEntry(
      isSeparateScreen: false,
      entryBuilder: _buildFreeResponseEntry,
    ),
  },
);

Widget _buildCheckEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementCheckEntry(graph: graph, question: question as Check);

Widget _buildMultipleChoiceEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementMultipleChoiceEntry(
  graph: graph,
  question: question as MultipleChoice,
);

Widget _buildAllThatApplyEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementAllThatApplyEntry(
  graph: graph,
  question: question as AllThatApply,
);

Widget _buildNumericEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementNumericEntry(graph: graph, question: question as Numeric);

Widget _buildFreeResponseEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementFreeResponseEntry(
  graph: graph,
  question: question as FreeResponse,
);

Widget _buildBristolEntry(
  SessionGraph graph,
  BuildContext context,
  Question question,
) => BowelMovementBristolEntry(graph: graph, question: question as Numeric);

class BowelMovementCheckEntry extends StatelessWidget {
  final SessionGraph graph;
  final Check question;

  const BowelMovementCheckEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => BowelMovementQuestionCard(
            key: ValueKey('bowel-card-${question.id}'),
            title: _entryTitle(context, question),
            prompt: 'Select if this applies.',
            promptInChild: true,
            child: BowelMovementChoiceButton(
              key: ValueKey('bowel-${question.id}-check'),
              label: question.prompt,
              selected: controller.hasResponse,
              leadingCheck: true,
              onPressed: () => controller.toggleResponse(
                () => Selected(question: question, stamp: controller.stamp),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class BowelMovementMultipleChoiceEntry extends StatelessWidget {
  final SessionGraph graph;
  final MultipleChoice question;

  const BowelMovementMultipleChoiceEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final response = controller.response;
            final selectedIndex = response is MultiResponse
                ? response.index
                : null;
            return BowelMovementQuestionCard(
              key: ValueKey('bowel-card-${question.id}'),
              title: _entryTitle(context, question),
              prompt: question.prompt,
              child: _ChoiceGrid(
                questionId: question.id,
                choices: question.choices,
                multiple: false,
                onClear:
                    selectedIndex == null ||
                        question.isRequired ||
                        (question.requirement?.groups.isNotEmpty ?? false)
                    ? null
                    : controller.removeResponse,
                selected: (index) => selectedIndex == index,
                onPressed: (index) {
                  if (selectedIndex == index) return;
                  controller.addResponse(
                    MultiResponse(
                      question: question,
                      stamp: controller.stamp,
                      index: index,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ),
  );
}

class BowelMovementAllThatApplyEntry extends StatelessWidget {
  final SessionGraph graph;
  final AllThatApply question;

  const BowelMovementAllThatApplyEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final response = controller.response;
            final selected = response is AllResponse
                ? response.responses.toSet()
                : <int>{};
            return BowelMovementQuestionCard(
              key: ValueKey('bowel-card-${question.id}'),
              title: _entryTitle(context, question),
              prompt: question.prompt,
              child: _ChoiceGrid(
                questionId: question.id,
                choices: question.choices,
                multiple: true,
                selected: selected.contains,
                onPressed: (index) {
                  final updated = <int>{...selected};
                  if (!updated.add(index)) updated.remove(index);
                  if (updated.isEmpty) {
                    controller.removeResponse();
                    return;
                  }
                  controller.addResponse(
                    AllResponse(
                      question: question,
                      stamp: controller.stamp,
                      responses: updated.toList()..sort(),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ),
  );
}

class BowelMovementNumericEntry extends StatelessWidget {
  final SessionGraph graph;
  final Numeric question;

  const BowelMovementNumericEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final response = controller.response;
            final selected = response is NumericResponse
                ? response.response
                : null;
            final min = question.min ?? 1;
            final max = question.max ?? 5;
            final integerScale =
                min == min.truncateToDouble() &&
                max == max.truncateToDouble() &&
                (selected == null || selected == selected.truncateToDouble());
            final useChoices = integerScale && max - min <= 6;

            void saveValue(num value) => controller.addResponse(
              NumericResponse(
                question: question,
                stamp: controller.stamp,
                response: value,
              ),
            );

            return BowelMovementQuestionCard(
              key: ValueKey('bowel-card-${question.id}'),
              title: _entryTitle(context, question),
              prompt: question.prompt,
              child: useChoices
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppPadding.small,
                          runSpacing: AppPadding.small,
                          children: [
                            for (var value = min.toInt(); value <= max; value++)
                              SizedBox(
                                width: math.max(
                                  48,
                                  MediaQuery.textScalerOf(context).scale(
                                        (Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.fontSize ??
                                                12) *
                                            '$value'.length,
                                      ) +
                                      AppPadding.medium * 2,
                                ),
                                child: BowelMovementChoiceButton(
                                  key: ValueKey(
                                    'bowel-${question.id}-value-$value',
                                  ),
                                  label: '$value',
                                  selected: selected == value,
                                  onPressed: () {
                                    if (selected != value) saveValue(value);
                                  },
                                ),
                              ),
                          ],
                        ),
                        if (selected != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: ValueKey('bowel-${question.id}-clear'),
                              onPressed: controller.removeResponse,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text('Clear answer'),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          selected == null ? 'Select a value' : '$selected',
                          textAlign: TextAlign.center,
                        ),
                        Slider(
                          key: ValueKey('bowel-${question.id}-slider'),
                          min: min.toDouble(),
                          max: max.toDouble(),
                          value: (selected ?? (min + max) / 2)
                              .clamp(min, max)
                              .toDouble(),
                          divisions: integerScale ? (max - min).toInt() : null,
                          label: selected?.toString(),
                          onChanged: saveValue,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('$min'), Text('$max')],
                        ),
                        if (selected != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: ValueKey('bowel-${question.id}-clear'),
                              onPressed: controller.removeResponse,
                              child: const Text('Clear answer'),
                            ),
                          ),
                      ],
                    ),
            );
          },
        );
      },
    ),
  );
}

class BowelMovementFreeResponseEntry extends StatefulWidget {
  final SessionGraph graph;
  final FreeResponse question;

  const BowelMovementFreeResponseEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  State<BowelMovementFreeResponseEntry> createState() =>
      _BowelMovementFreeResponseEntryState();
}

class _BowelMovementFreeResponseEntryState
    extends State<BowelMovementFreeResponseEntry> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final response = widget.graph.fromQuestion(widget.question);
    _controller = TextEditingController(
      text: response is OpenResponse ? response.response : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: widget.question,
    listener: widget.graph,
    child: Builder(
      builder: (context) {
        final entryController = QuestionEntryScope.of(context);
        return BowelMovementQuestionCard(
          key: ValueKey('bowel-card-${widget.question.id}'),
          title: _entryTitle(context, widget.question),
          prompt: widget.question.prompt,
          child: TextField(
            key: const ValueKey('bowel-free-response'),
            controller: _controller,
            minLines: 5,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Type here…',
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _outline, width: 1.5),
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRounding.small),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _blue, width: 2),
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRounding.small),
                ),
              ),
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                entryController.removeResponse();
              } else {
                entryController.addResponse(
                  OpenResponse(
                    question: widget.question,
                    stamp: entryController.stamp,
                    response: value,
                  ),
                );
              }
            },
          ),
        );
      },
    ),
  );
}

class BowelMovementBristolEntry extends StatelessWidget {
  final SessionGraph graph;
  final Numeric question;

  const BowelMovementBristolEntry({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final response = controller.response;
            final selected = response is NumericResponse
                ? response.response.round()
                : null;
            return BowelMovementQuestionCard(
              key: ValueKey('bowel-card-${question.id}'),
              title: _entryTitle(context, question),
              prompt: question.prompt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bristol Stool Scale',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const ResourceInfoButton(
                        topic: ResourceTopic.bristolScale,
                        sectionId: 'stool-types',
                        tooltip: 'About the Bristol Stool Scale',
                      ),
                    ],
                  ),
                  for (final section in _bristolSections) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppPadding.small,
                        bottom: AppPadding.tiny,
                      ),
                      child: Text(
                        section.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    for (final type in section.types)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppPadding.small,
                        ),
                        child: _BristolTypeButton(
                          type: type,
                          selected: selected == type.number,
                          onPressed: () => controller.addResponse(
                            NumericResponse(
                              question: question,
                              stamp: controller.stamp,
                              response: type.number,
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (controller.hasResponse)
                    TextButton(
                      onPressed: controller.removeResponse,
                      child: const Text('Clear answer'),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class BowelMovementQuestionCard extends StatelessWidget {
  final String title;
  final String prompt;
  final Widget child;
  final bool promptInChild;

  const BowelMovementQuestionCard({
    required this.title,
    required this.prompt,
    required this.child,
    this.promptInChild = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final compact = CompactRecordQuestions.maybeOf(context);
    if (compact != null) {
      return CompactRecordQuestion(
        prompt: prompt,
        promptInChild: promptInChild,
        child: child,
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.large),
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRounding.medium),
        border: Border.all(color: _outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17245E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'packages/stripes_ui/assets/images/Brown_Poop.png',
                width: 18,
                height: 18,
                color: _brown,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.water_drop_rounded,
                  color: _brown,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: _navy, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.tiny),
          Text(
            prompt,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: const Color(0xFF69758A)),
          ),
          const SizedBox(height: AppPadding.medium),
          child,
        ],
      ),
    );
  }
}

class BowelMovementChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool leadingCheck;
  final bool? multiple;

  const BowelMovementChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.leadingCheck = false,
    this.multiple,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: multiple == null && !leadingCheck,
    selected: multiple == null && !leadingCheck ? selected : null,
    checked: multiple != null || leadingCheck ? selected : null,
    inMutuallyExclusiveGroup: multiple == false,
    child: Material(
      color: selected ? _navy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRounding.small),
        side: BorderSide(color: selected ? _navy : _outline, width: 1.5),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRounding.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.small,
            ),
            child: Row(
              mainAxisAlignment: leadingCheck || multiple != null
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (leadingCheck || multiple != null) ...[
                  Icon(
                    multiple == false
                        ? (selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked)
                        : (selected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank),
                    size: 18,
                    color: selected ? Colors.white : _blue,
                  ),
                  const SizedBox(width: AppPadding.small),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: leadingCheck || multiple != null
                        ? TextAlign.start
                        : TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ChoiceGrid extends StatelessWidget {
  final String questionId;
  final List<String> choices;
  final bool Function(int index) selected;
  final ValueChanged<int> onPressed;
  final bool multiple;
  final VoidCallback? onClear;

  const _ChoiceGrid({
    required this.questionId,
    required this.choices,
    required this.selected,
    required this.onPressed,
    required this.multiple,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final regular = <MapEntry<int, String>>[];
    final fullWidth = <MapEntry<int, String>>[];
    for (final choice in choices.indexed) {
      final entry = MapEntry(choice.$1, choice.$2);
      if (choice.$2.trim().toLowerCase() == 'not sure') {
        fullWidth.add(entry);
      } else {
        regular.add(entry);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasLongChoices = regular.any((entry) => entry.value.length > 38);
        final columns = hasLongChoices
            ? 1
            : regular.length <= 3
            ? regular.length
            : 2;
        final effectiveColumns =
            constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? 1
            : math.max(1, columns);
        final itemWidth =
            (constraints.maxWidth - (effectiveColumns - 1) * AppPadding.small) /
            effectiveColumns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              multiple ? 'Select all that apply' : 'Choose one',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPadding.small),
            Wrap(
              spacing: AppPadding.small,
              runSpacing: AppPadding.small,
              children: regular
                  .map(
                    (entry) => SizedBox(
                      width: itemWidth,
                      child: BowelMovementChoiceButton(
                        key: ValueKey('bowel-$questionId-choice-${entry.key}'),
                        label: entry.value,
                        multiple: multiple,
                        selected: selected(entry.key),
                        onPressed: () => onPressed(entry.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
            for (final entry in fullWidth) ...[
              const SizedBox(height: AppPadding.small),
              BowelMovementChoiceButton(
                key: ValueKey('bowel-$questionId-choice-${entry.key}'),
                label: entry.value,
                multiple: multiple,
                selected: selected(entry.key),
                onPressed: () => onPressed(entry.key),
              ),
            ],
            if (onClear != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: ValueKey('bowel-$questionId-clear'),
                  onPressed: onClear,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Clear answer'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BristolTypeButton extends StatelessWidget {
  final _BristolType type;
  final bool selected;
  final VoidCallback onPressed;

  const _BristolTypeButton({
    required this.type,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Bristol stool type ${type.number}: ${type.title}',
    child: Material(
      color: selected ? const Color(0xFFE9F1FC) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRounding.small),
        side: BorderSide(color: selected ? _navy : _outline, width: 1.5),
      ),
      child: InkWell(
        key: ValueKey('bristol-type-${type.number}'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRounding.small),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.small),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 46,
                child: Image.asset(
                  'packages/stripes_ui/assets/images/poop${type.number}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: _brown,
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type ${type.number}',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: _navy, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      type.title,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: _navy, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      type.description,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: const Color(0xFF69758A)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? _navy : _blue,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BristolSection {
  final String label;
  final List<_BristolType> types;

  const _BristolSection(this.label, this.types);
}

class _BristolType {
  final int number;
  final String title;
  final String description;

  const _BristolType(this.number, this.title, this.description);
}

const _bristolSections = [
  _BristolSection('Constipation', [
    _BristolType(1, 'Hard separate lumps', 'Difficult to pass'),
    _BristolType(2, 'Lumpy sausage', 'Usually indicates constipation'),
  ]),
  _BristolSection('Normal range', [
    _BristolType(3, 'Cracked surface sausage', 'Normal · easy to pass'),
    _BristolType(4, 'Smooth & soft sausage', 'Normal · easy to pass'),
    _BristolType(5, 'Soft blobs', 'Clear-cut edges'),
  ]),
  _BristolSection('Diarrhea', [
    _BristolType(6, 'Mushy stool', 'Fluffy pieces · ragged edges'),
    _BristolType(7, 'Entirely liquid', 'No solid pieces'),
  ]),
];

String _entryTitle(BuildContext context, Question question) {
  final localizations = QuestionsLocalizations.of(context);
  return localizations?.value(question.type) as String? ?? question.type;
}

/// Background used by the standalone demo screen.
const Color bowelMovementFullViewBackground = _paleBlue;
