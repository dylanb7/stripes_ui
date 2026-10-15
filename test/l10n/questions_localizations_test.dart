import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class _QuestionTranslationBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'questions/en.json') {
      throw FlutterError('Unexpected translation asset: $key');
    }
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'question.full': 'How severe was the pain?',
          'question.short': 'Pain',
          'question.blank': '   ',
          'choice.yes': 'Yes',
          'choice.no': 'No',
          'question.interpolated': 'How severe was {area} pain at {time}?',
          'question.interpolated.short': '{area} pain at {time}',
          'area.stomach': 'Stomach',
        }),
      ),
    );
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late QuestionsLocalizations localizations;

  setUp(() async {
    localizations = await QuestionsLocalizations(
      questionTranslationPath: 'questions',
      bundle: _QuestionTranslationBundle(),
    ).load(const Locale('en'));
  });

  const questions = <Question>[
    FreeResponse(
      id: 'free',
      type: 'Pain',
      prompt: 'question.full',
      shortPrompt: 'question.short',
      previewPriority: 7,
    ),
    Numeric(
      id: 'numeric',
      type: 'Pain',
      prompt: 'question.full',
      shortPrompt: 'question.short',
      previewPriority: 7,
      min: 0,
      max: 10,
    ),
    Check(
      id: 'check',
      type: 'Pain',
      prompt: 'question.full',
      shortPrompt: 'question.short',
      previewPriority: 7,
    ),
    MultipleChoice(
      id: 'multiple',
      type: 'Pain',
      prompt: 'question.full',
      shortPrompt: 'question.short',
      previewPriority: 7,
      choices: ['choice.yes', 'choice.no', 'An untranslated option'],
    ),
    AllThatApply(
      id: 'all',
      type: 'Pain',
      prompt: 'question.full',
      shortPrompt: 'question.short',
      previewPriority: 7,
      choices: ['choice.yes', 'choice.no', 'An untranslated option'],
    ),
  ];

  for (final question in questions) {
    test(
      '${question.runtimeType} keeps full and short translations separate',
      () {
        final translated = localizations.translateQuestion(question);

        expect(translated.runtimeType, question.runtimeType);
        expect(translated.id, question.id);
        expect(translated.type, question.type);
        expect(translated.prompt, 'How severe was the pain?');
        expect(translated.shortPrompt, 'question.short');
        expect(localizations.translateShortPrompt(translated), 'Pain');
        expect(localizations.translateShortPrompt(question), 'Pain');
        expect(translated.previewPriority, 7);
        expect(question.prompt, 'question.full');
        expect(question.shortPrompt, 'question.short');

        if (translated is Numeric) {
          expect(translated.min, 0);
          expect(translated.max, 10);
        }
        if (translated is MultipleChoice) {
          expect(translated.choices, ['Yes', 'No', 'An untranslated option']);
        }
        if (translated is AllThatApply) {
          expect(translated.choices, ['Yes', 'No', 'An untranslated option']);
        }
      },
    );
  }

  test(
    'regional locales use and cache the language translation file',
    () async {
      await localizations.load(const Locale('en', 'US'));
      expect(localizations.translateShortPrompt(questions.first), 'Pain');
      await localizations.load(const Locale('en', 'GB'));
      expect(
        localizations.translateQuestion(questions.first).prompt,
        'How severe was the pain?',
      );
      expect(localizations.questionTranslations.keys, ['en']);
    },
  );

  for (final shortPrompt in <String?>[
    null,
    'question.missing',
    'question.blank',
    '   ',
  ]) {
    test(
      'short prompt $shortPrompt falls back to the translated full prompt',
      () {
        final translated = localizations.translateQuestion(
          Check(
            id: 'fallback',
            type: 'Pain',
            prompt: 'question.full',
            shortPrompt: shortPrompt,
          ),
        );

        expect(translated.prompt, 'How severe was the pain?');
        expect(translated.shortPrompt, shortPrompt);
        expect(
          localizations.translateShortPrompt(translated),
          translated.prompt,
        );
        expect(translated.previewPriority, isNull);
      },
    );
  }

  test('interpolates both prompts with translated and literal values', () {
    final translated = localizations.translateQuestion(
      const Numeric(
        id: 'interpolated',
        type: 'Pain',
        prompt: 'question.interpolated',
        shortPrompt: 'question.interpolated.short',
        previewPriority: -10,
        interpolations: {'area': 'area.stomach', 'time': '08:00'},
      ),
    );

    expect(translated.prompt, 'How severe was Stomach pain at 08:00?');
    expect(translated.shortPrompt, 'question.interpolated.short');
    expect(
      localizations.translateShortPrompt(translated),
      'Stomach pain at 08:00',
    );
    expect(translated.previewPriority, -10);
    expect(translated.interpolations, {
      'area': 'area.stomach',
      'time': '08:00',
    });
  });

  test(
    'missing short translation falls back after full prompt interpolation',
    () {
      final translated = localizations.translateQuestion(
        const Check(
          id: 'interpolated-fallback',
          type: 'Pain',
          prompt: 'question.interpolated',
          shortPrompt: 'question.missing',
          interpolations: {'area': 'area.stomach', 'time': '08:00'},
        ),
      );

      expect(translated.prompt, 'How severe was Stomach pain at 08:00?');
      expect(translated.shortPrompt, 'question.missing');
      expect(localizations.translateShortPrompt(translated), translated.prompt);
    },
  );

  test(
    'custom question without translation metadata retains its full prompt',
    () {
      const question = FreeResponse(
        id: 'custom',
        type: 'My notes',
        prompt: 'What helped today?',
        userCreated: true,
      );
      final translated = localizations.translateQuestion(question);

      expect(translated.prompt, question.prompt);
      expect(translated.shortPrompt, isNull);
      expect(localizations.translateShortPrompt(translated), question.prompt);
      expect(translated.userCreated, isTrue);
      expect(translated.previewPriority, isNull);
    },
  );

  test('repeated translation and stored generated definitions retain shorthand keys', () {
    const question = Numeric(
      id: 'generated-pain-stomach',
      type: 'Pain',
      prompt: 'question.interpolated',
      shortPrompt: 'question.interpolated.short',
      previewPriority: 3,
      interpolations: {'area': 'area.stomach', 'time': '08:00'},
    );

    final first = localizations.translateQuestion(question);
    final repeated = localizations.translateQuestion(first);
    expect(first.shortPrompt, question.shortPrompt);
    expect(repeated.shortPrompt, question.shortPrompt);
    expect(repeated.prompt, first.prompt);
    expect(
      localizations.translateShortPrompt(repeated),
      'Stomach pain at 08:00',
    );

    // Generated responses embed the translated question definition in JSON.
    // History must still be able to resolve its shorthand after deserialization.
    final restored = Question.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(repeated.toJson())) as Map,
      ),
    );
    final historyQuestion = localizations.translateQuestion(restored);
    expect(historyQuestion.shortPrompt, question.shortPrompt);
    expect(historyQuestion.previewPriority, 3);
    expect(historyQuestion.interpolations, question.interpolations);
    expect(historyQuestion.prompt, 'How severe was Stomach pain at 08:00?');
    expect(
      localizations.translateShortPrompt(historyQuestion),
      'Stomach pain at 08:00',
    );
  });
}
