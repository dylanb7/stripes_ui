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
    );

DetailResponse detail(List<Response> responses, {String? description}) =>
    DetailResponse(
      stamp: 0,
      detailType: 'Pain',
      responses: responses,
      description: description,
    );

NumericResponse number(num value, {String id = 'intensity'}) => NumericResponse(
  question: Numeric(id: id, prompt: 'Intensity', type: 'Pain'),
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
    expect(preview(response), ['Intensity: 6', 'Description: After dinner']);
  });

  test('resolves translated question and choice labels', () {
    final response = MultiResponse(
      question: const MultipleChoice(
        id: 'meal',
        prompt: 'meal_prompt',
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
          prompt: 'Comida',
          choices: ['Desayuno', 'Cena'],
        ),
      ),
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

  test('limits density to two details and preserves a note when present', () {
    final responses = [number(1), number(2), number(3)];
    expect(preview(detail(responses)), ['Intensity: 1', 'Intensity: 2']);
    expect(preview(detail(responses, description: 'A recognizable note')), [
      'Intensity: 1',
      'Description: A recognizable note',
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
      'Description: ${List.filled(100, '👩🏽‍⚕️').join()}…',
    ]);
  });
}
