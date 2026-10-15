import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/entry_preview.dart';

List<String> preview(Response response, {String? locale}) =>
    entryPreviewDetails(
      response,
      selectedLabel: 'Selected',
      descriptionLabel: 'Description',
      notSureLabel: 'Not sure',
      locale: locale ?? 'en',
    ).map((detail) => detail.label).toList();

DetailResponse detail(List<Response> responses, {String? description}) =>
    DetailResponse(
      stamp: 0,
      detailType: 'Pain',
      responses: responses,
      description: description,
    );

NumericResponse number(
  num value, {
  String id = 'intensity',
  String? shortPrompt,
  int? previewPriority,
}) => NumericResponse(
  question: Numeric(
    id: id,
    prompt: 'Intensity',
    type: 'Pain',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
  stamp: 0,
  response: value,
);

class _SingleResponse extends SingleResponseWrap<Response> {
  _SingleResponse(Response response) : super(response: response);
}

void main() {
  test('uses the saved numeric value without inventing a scale or units', () {
    expect(preview(number(6)), ['Intensity: 6']);
    expect(preview(number(1.234567)), ['Intensity: 1.234567']);
    expect(preview(number(1.5), locale: 'es'), ['Intensity: 1,5']);
    expect(preview(number(double.nan)), isEmpty);
  });

  test('preserves the known pain not-sure answer', () {
    expect(preview(number(-1, id: 'Pain-Rating')), ['Intensity: Not sure']);
    expect(preview(number(-1, id: 'q6')), ['Intensity: Not sure']);
    expect(preview(number(-1)), ['Intensity: -1']);
  });

  test('unwraps nested entries and includes their notes', () {
    final response = detail([
      _SingleResponse(detail([number(6)], description: 'After dinner')),
    ]);
    expect(preview(response), ['Intensity: 6', '“After dinner”']);
  });

  test('resolves translated question and choice labels', () {
    final response = MultiResponse(
      question: const MultipleChoice(
        id: 'meal',
        prompt: 'meal_prompt',
        shortPrompt: 'meal_short',
        type: 'Meals',
        choices: ['breakfast', 'dinner'],
      ),
      stamp: 0,
      index: 1,
    );
    expect(
      entryPreviewDetails(
        response,
        selectedLabel: 'Seleccionado',
        descriptionLabel: 'Descripción',
        notSureLabel: 'No sé',
        translateQuestion: (question) => (question as MultipleChoice).copyWith(
          prompt: '¿Qué comida se sirvió?',
          choices: ['Desayuno', 'Cena'],
        ),
        translateShortPrompt: (question) =>
            question.shortPrompt == 'meal_short' ? 'Comida' : question.prompt,
      ).map((detail) => detail.label).toList(),
      ['Comida: Cena'],
    );
  });

  test('empty, invalid and unresolved answers do not imply absence', () {
    const choice = MultipleChoice(
      id: 'meal',
      prompt: 'Meal',
      type: 'Meals',
      choices: ['Breakfast'],
    );
    const many = AllThatApply(
      id: 'locations',
      prompt: 'Locations',
      type: 'Pain',
      choices: ['Upper', 'Lower'],
    );
    expect(preview(detail([])), isEmpty);
    expect(preview(detail([], description: '  ')), isEmpty);
    expect(
      preview(MultiResponse(question: choice, stamp: 0, index: -1)),
      isEmpty,
    );
    expect(
      preview(MultiResponse(question: choice, stamp: 0, index: 2)),
      isEmpty,
    );
    expect(
      preview(AllResponse(question: many, stamp: 0, responses: [])),
      isEmpty,
    );
    expect(
      preview(AllResponse(question: many, stamp: 0, responses: [-1, 1, 9])),
      ['Locations: Lower'],
    );
    expect(
      preview(Selected(question: Question.empty() as Check, stamp: 0)),
      isEmpty,
    );
    expect(
      preview(
        Selected(
          question: const Check(id: 'dynamic', prompt: '{value}', type: 'Pain'),
          stamp: 0,
        ),
      ),
      isEmpty,
    );
  });

  test('limits density and keeps concise answers ahead of a note', () {
    final responses = <Response>[number(1), number(2), number(3)];
    expect(preview(detail(responses)), ['Intensity: 1', 'Intensity: 2']);
    expect(preview(detail(responses, description: 'A recognizable note')), [
      'Intensity: 1',
      'Intensity: 2',
    ]);
    expect(preview(detail([number(1), number(1), number(2)])), [
      'Intensity: 1',
      'Intensity: 2',
    ]);
  });

  test('keeps saved free text and safely excerpts long notes', () {
    expect(
      preview(
        OpenResponse(
          question: const FreeResponse(
            id: 'note',
            prompt: 'Note',
            type: 'Pain',
          ),
          stamp: 0,
          response: 'After\n   dinner',
        ),
      ),
      ['Note: After dinner'],
    );
    final emoji = List.filled(101, '👩🏽‍⚕️').join();
    expect(preview(detail([], description: emoji)), [
      '“${List.filled(29, '👩🏽‍⚕️').join()}…”',
    ]);
  });

  test('defining pain answers outrank form order and a long note', () {
    final entry = detail([
      Selected(
        question: const Check(
          id: 'q1',
          prompt: 'Pointed to their stomach as if in pain',
          type: 'Pain',
        ),
        stamp: 0,
      ),
      number(0, id: 'Pain-Rating', shortPrompt: 'Pain', previewPriority: 0),
      AllResponse(
        question: const AllThatApply(
          id: 'Pain-Location',
          prompt: 'Where was the pain?',
          shortPrompt: 'Location',
          previewPriority: 10,
          type: 'Pain',
          choices: ['Unknown', 'Lower right'],
        ),
        responses: [1],
        stamp: 0,
      ),
    ], description: 'A long note should not push out the defining answers');
    final result = entryPreviewDetails(
      entry,
      selectedLabel: 'Selected',
      descriptionLabel: 'Note',
      notSureLabel: 'Not sure',
    );
    expect(result.map((item) => item.label), [
      'Pain: 0',
      'Location: Lower right',
    ]);
    expect(result.last.semanticsLabel, 'Where was the pain?: Lower right');
  });

  test('BM type and pain remain ahead of earlier selected symptoms', () {
    final entry = detail([
      Selected(
        question: const Check(
          id: 'q8',
          prompt: 'Struggled or strained during a bowel movement',
          type: 'BM',
        ),
        stamp: 0,
      ),
      number(4, id: 'q4', shortPrompt: 'Stool type', previewPriority: 0),
      number(-1, id: 'q6', shortPrompt: 'Pain', previewPriority: 10),
    ]);
    final result = entryPreviewDetails(
      entry,
      selectedLabel: 'Selected',
      descriptionLabel: 'Note',
      notSureLabel: 'Not sure',
    );
    expect(result.map((item) => item.label), [
      'Stool type: 4',
      'Pain: Not sure',
    ]);
  });

  test('configured choices and checked symptoms avoid form boilerplate', () {
    final meal = MultiResponse(
      question: const MultipleChoice(
        id: 'Meal-Type',
        prompt: 'What meal type was provided?',
        shortPrompt: 'Meal',
        previewPriority: 0,
        type: 'Meals',
        choices: ['Dinner'],
      ),
      stamp: 0,
      index: 0,
    );
    expect(preview(meal), ['Meal: Dinner']);
    final sleep = detail([
      Selected(
        question: const Check(
          id: 'q21',
          prompt: 'Had difficulty falling asleep at night',
          shortPrompt: 'Difficulty falling asleep',
          previewPriority: 30,
          type: 'Sleep',
        ),
        stamp: 0,
      ),
      Selected(
        question: const Check(
          id: 'q24',
          prompt: 'Seemed more irritable than usual',
          shortPrompt: 'Increased irritability',
          previewPriority: 30,
          type: 'Sleep',
        ),
        stamp: 0,
      ),
    ]);
    final result = entryPreviewDetails(
      sleep,
      selectedLabel: 'Selected',
      descriptionLabel: 'Note',
      notSureLabel: 'Not sure',
    );
    expect(result.map((item) => item.label), [
      'Difficulty falling asleep',
      'Increased irritability',
    ]);
    expect(
      result.first.semanticsLabel,
      'Had difficulty falling asleep at night: Selected',
    );
  });

  test(
    'custom prompt and answer have separate budgets with full semantics',
    () {
      const prompt =
          'A custom question that takes up a lot of space in a history card';
      const value = 'A distinctive recorded answer that also has several words';
      final response = OpenResponse(
        question: const FreeResponse(
          id: 'custom',
          prompt: prompt,
          type: 'Custom',
        ),
        stamp: 0,
        response: value,
      );
      final result = entryPreviewDetails(
        detail([response, number(6)]),
        selectedLabel: 'Selected',
        descriptionLabel: 'Note',
        notSureLabel: 'Not sure',
      );
      expect(result.last.label.length, lessThanOrEqualTo(36));
      expect(result.last.label, contains(': A distinctive'));
      expect(result.last.semanticsLabel, '$prompt: $value');
      final single = preview(response).single;
      expect(single, contains('A distinctive recorded answer'));
      expect(single.length, lessThanOrEqualTo(62));
    },
  );

  test('short custom answers outrank verbose prompts and IDs do not supply labels', () {
    final verbose = NumericResponse(
      question: const Numeric(
        id: 'custom-long',
        prompt:
            'A very long custom measurement question that occupies the preview',
        type: 'Custom',
      ),
      stamp: 0,
      response: 2,
    );
    final entry = detail([verbose, number(6)]);
    expect(preview(entry).first, 'Intensity: 6');
    final wrongType = Selected(
      question: const Check(id: 'q4', prompt: 'Custom check', type: 'Custom'),
      stamp: 0,
    );
    final result = entryPreviewDetails(
      wrongType,
      selectedLabel: 'Selected',
      descriptionLabel: 'Note',
      notSureLabel: 'Not sure',
    );
    expect(result.single.label, 'Custom check');
  });

  test(
    'user-created questions keep their meaning when reusing built-in IDs',
    () {
      final response = NumericResponse(
        question: const Numeric(
          id: 'q6',
          prompt: 'Temperature change',
          type: 'Custom',
          userCreated: true,
        ),
        stamp: 0,
        response: -1,
      );
      final result = entryPreviewDetails(
        response,
        selectedLabel: 'Selected',
        descriptionLabel: 'Note',
        notSureLabel: 'Not sure',
      );
      expect(result.single.label, 'Temperature change: -1');
      expect(result.single.semanticsLabel, 'Temperature change: -1');
    },
  );

  test(
    'unknown location remains distinguishable from an unknown pain rating',
    () {
      final response = AllResponse(
        question: const AllThatApply(
          id: 'Pain-Location',
          prompt: 'Where was the pain?',
          shortPrompt: 'Location',
          previewPriority: 10,
          type: 'Pain',
          choices: ['Unknown', 'Lower right'],
        ),
        stamp: 0,
        responses: [0],
      );
      final result = entryPreviewDetails(
        response,
        selectedLabel: 'Selected',
        descriptionLabel: 'Note',
        notSureLabel: 'Not sure',
      );
      expect(result.single.label, 'Location: Unknown');
    },
  );

  test(
    'metadata sets preview labels and order independently of question IDs',
    () {
      final responses = <Response>[
        Selected(
          question: const Check(
            id: 'user-check',
            prompt: 'A lengthy custom observation question',
            shortPrompt: 'Restless',
            previewPriority: 10,
            type: 'Custom',
            userCreated: true,
          ),
          stamp: 0,
        ),
        NumericResponse(
          question: const Numeric(
            id: 'arbitrary-measurement',
            prompt: 'A lengthy numeric question',
            shortPrompt: 'Score',
            previewPriority: 0,
            type: 'Custom',
          ),
          response: 5,
          stamp: 0,
        ),
        number(9),
      ];
      expect(preview(detail(responses)), ['Score: 5', 'Restless']);
    },
  );

  test('missing or blank shorthand falls back without changing ranking', () {
    final question = const Check(
      id: 'no-short-label',
      prompt: 'A long question without any shorthand configured',
      type: 'Custom',
    );
    final plain = Selected(question: question, stamp: 0);
    for (final shorthand in ['', '  ', '{unresolved}', question.prompt]) {
      final response = Selected(
        question: question.copyWith(shortPrompt: shorthand),
        stamp: 0,
      );
      expect(preview(response), preview(plain));
      expect(preview(detail([response, number(2)])).first, 'Intensity: 2');
    }
  });

  test(
    'equal configured priorities retain saved order, regardless of value',
    () {
      expect(
        preview(
          detail([
            number(0, id: 'first', shortPrompt: 'First', previewPriority: 10),
            number(9, id: 'second', shortPrompt: 'Second', previewPriority: 10),
            number(5, id: 'third', shortPrompt: 'Third', previewPriority: 20),
          ]),
        ),
        ['First: 0', 'Second: 9'],
      );
    },
  );
}
