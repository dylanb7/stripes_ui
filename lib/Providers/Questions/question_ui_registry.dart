import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/blue_dye_entry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bristol_entry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_numeric.dart';

typedef DisplayBuilder<T extends Response<Question>> = Widget Function(
  BuildContext context,
  T response,
);

typedef EntryBuilder<T extends Question> = Widget Function(
  SessionGraph graph,
  BuildContext context,
  T question,
);

@immutable
class QuestionEntry {
  final bool isSeparateScreen;

  final EntryBuilder entryBuilder;

  const QuestionEntry({
    required this.isSeparateScreen,
    required this.entryBuilder,
  });
}

class QuestionUIRegistry {
  final Map<String, DisplayBuilder> _displayBuilders;
  final Map<String, QuestionEntry> _entryBuilders;
  final Map<QuestionType, QuestionEntry> _entryTypeBuilders;

  static final Map<String, QuestionEntry> defaultEntryOverrides = {
    'q4': QuestionEntry(
      isSeparateScreen: true,
      entryBuilder: (listener, context, question) =>
          BMSlider(listener: listener, question: question as Numeric),
    ),
    'Pain-Location': QuestionEntry(
      isSeparateScreen: true,
      entryBuilder: (listener, context, question) => PainAreaWidget(
        questionsListener: listener,
        question: question as AllThatApply,
      ),
    ),
    'Pain-Rating': QuestionEntry(
      isSeparateScreen: true,
      entryBuilder: (listener, context, question) =>
          PainIntensityWidget(graph: listener, question: question as Numeric),
    ),
    'q6': QuestionEntry(
      isSeparateScreen: true,
      entryBuilder: (listener, context, question) =>
          PainIntensityWidget(graph: listener, question: question as Numeric),
    ),
    'BlueDyeQuestion': QuestionEntry(
      isSeparateScreen: true,
      entryBuilder: (listener, context, question) => BlueDyeEntry(
        listener: listener,
        question: question as MultipleChoice,
      ),
    ),
  };

  static final Map<String, DisplayBuilder> defaultDisplayOverrides = {
    'q4': (context, numeric) => BMRow(response: numeric as NumericResponse),
    'Pain-Rating': (context, numeric) =>
        PainSliderDisplay(response: numeric as NumericResponse),
    'Pain-Location': (context, all) =>
        PainLocationDisplay(painLocation: all as AllResponse),
    'q6': (context, numeric) =>
        PainSliderDisplay(response: numeric as NumericResponse),
  };

  QuestionUIRegistry({
    Map<String, DisplayBuilder>? displayOverrides,
    Map<String, QuestionEntry>? entryOverrides,
    Map<QuestionType, QuestionEntry>? entryTypeOverrides,
  }) : _displayBuilders = Map.unmodifiable(
         displayOverrides ?? defaultDisplayOverrides,
       ),
       _entryBuilders = Map.unmodifiable(
         entryOverrides ?? defaultEntryOverrides,
       ),
       _entryTypeBuilders = Map.unmodifiable(entryTypeOverrides ?? const {});

  DisplayBuilder? displayFor(String questionId) => _displayBuilders[questionId];

  Map<String, DisplayBuilder> get allDisplayOverrides => _displayBuilders;

  QuestionEntry? entryFor(String questionId) => _entryBuilders[questionId];

  /// Resolves the entry override for [question].
  ///
  /// A question-specific override takes precedence over an entry type override.
  QuestionEntry? entryForQuestion(Question question) =>
      _entryBuilders[question.id] ??
      _entryTypeBuilders[QuestionType.from(question)];

  Map<String, QuestionEntry> get allEntryOverrides => _entryBuilders;

  Map<QuestionType, QuestionEntry> get allEntryTypeOverrides =>
      _entryTypeBuilders;
}
