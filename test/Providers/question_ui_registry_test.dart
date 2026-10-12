import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/config.dart';

void main() {
  const question = Check(
    id: 'question-id',
    prompt: 'Prompt',
    type: 'record-category',
  );

  QuestionEntry entry(String label) => QuestionEntry(
    isSeparateScreen: false,
    entryBuilder: (_, _, _) => Text(label),
  );

  test('falls back to an input type override', () {
    final typeOverride = entry('type');
    final registry = QuestionUIRegistry(
      entryOverrides: const {},
      entryTypeOverrides: {QuestionType.check: typeOverride},
    );

    expect(registry.entryForQuestion(question), same(typeOverride));
  });

  test('question-specific override takes precedence over entry type', () {
    final questionOverride = entry('question');
    final typeOverride = entry('type');
    final registry = QuestionUIRegistry(
      entryOverrides: {'question-id': questionOverride},
      entryTypeOverrides: {QuestionType.check: typeOverride},
    );

    expect(registry.entryForQuestion(question), same(questionOverride));
  });

  test('resolves each question kind independently', () {
    final multipleChoiceOverride = entry('multiple choice');
    final allThatApplyOverride = entry('all that apply');
    final registry = QuestionUIRegistry(
      entryOverrides: const {},
      entryTypeOverrides: {
        QuestionType.multipleChoice: multipleChoiceOverride,
        QuestionType.allThatApply: allThatApplyOverride,
      },
    );

    const multipleChoice = MultipleChoice(
      id: 'choice',
      prompt: 'Choose one',
      type: 'same-record-category',
      choices: ['One'],
    );
    const allThatApply = AllThatApply(
      id: 'all',
      prompt: 'Choose any',
      type: 'same-record-category',
      choices: ['One'],
    );

    expect(
      registry.entryForQuestion(multipleChoice),
      same(multipleChoiceOverride),
    );
    expect(registry.entryForQuestion(allThatApply), same(allThatApplyOverride));
  });

  test('returns null when neither override matches', () {
    final registry = QuestionUIRegistry(
      entryOverrides: const {},
      entryTypeOverrides: const {},
    );

    expect(registry.entryForQuestion(question), isNull);
  });

  test('config flag gates the full-view type overrides', () {
    final disabled = ProviderContainer(
      overrides: [
        configProvider.overrideWith((ref) => const StripesConfig.sandbox()),
      ],
    );
    final enabled = ProviderContainer(
      overrides: [
        configProvider.overrideWith(
          (ref) => const StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(multiSessionFlow: true),
          ),
        ),
      ],
    );
    addTearDown(disabled.dispose);
    addTearDown(enabled.dispose);

    expect(
      disabled.read(questionUIRegistryProvider).allEntryTypeOverrides,
      isEmpty,
    );
    expect(
      enabled.read(questionUIRegistryProvider).allEntryTypeOverrides.keys,
      containsAll(QuestionType.values),
    );

    final withoutRecording = ProviderContainer(
      overrides: [
        configProvider.overrideWith(
          (ref) => const StripesConfig.sandbox(
            betaUi: BetaUiConfig.enabled(multiSessionFlow: false),
          ),
        ),
      ],
    );
    addTearDown(withoutRecording.dispose);
    expect(
      withoutRecording.read(questionUIRegistryProvider).allEntryTypeOverrides,
      isEmpty,
    );
  });
}
