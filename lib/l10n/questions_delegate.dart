import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

class QuestionsLocalizations {
  Map<String, dynamic> questionTranslations = {};

  late String currentLocale;

  final String questionTranslationPath;

  final AssetBundle assetBundle;
  QuestionsLocalizations({
    required this.questionTranslationPath,
    AssetBundle? bundle,
  }) : assetBundle = bundle ?? rootBundle;

  Future<Map<String, dynamic>> loadFile(Locale locale) async {
    final languageCode = locale.languageCode;
    try {
      final text = await assetBundle.loadString(
        '$questionTranslationPath/$languageCode.json',
      );
      return json.decode(text);
    } catch (e) {
      debugPrint(e.toString());
    }

    return {};
  }

  Future<QuestionsLocalizations> load(Locale locale) async {
    currentLocale = locale.languageCode;
    if (questionTranslations.containsKey(currentLocale)) {
      return this;
    }
    questionTranslations[currentLocale] = await loadFile(locale);
    return this;
  }

  static QuestionsLocalizations? of(BuildContext context) =>
      Localizations.of<QuestionsLocalizations>(context, QuestionsLocalizations);

  dynamic value(String key) => questionTranslations[currentLocale]?[key];
}

class QuestionsLocalizationsDelegate
    extends LocalizationsDelegate<QuestionsLocalizations> {
  final QuestionsLocalizations localization;

  final AssetBundle? assetBundle;

  QuestionsLocalizationsDelegate({required String path, this.assetBundle})
    : localization = QuestionsLocalizations(
        questionTranslationPath: path,
        bundle: assetBundle,
      );
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<QuestionsLocalizations> load(Locale locale) {
    return localization.load(locale);
  }

  @override
  bool shouldReload(QuestionsLocalizationsDelegate old) => false;
}

extension QuestionsLocalizationsExtensions on QuestionsLocalizations {
  RecordPath translatePath(RecordPath path) {
    return path.copyWith(name: value(path.name) ?? path.name);
  }

  ReviewItem translateReview(ReviewItem item) {
    return ReviewItem(
      path: translatePath(item.path),
      type: item.type,
      response: item.response,
    );
  }

  PagesData translatePage(PagesData page) {
    final List<LoadedPageLayout> currentLayouts = page.loadedLayouts ?? [];
    final List<LoadedPageLayout> translatedLayouts = currentLayouts.map((
      layout,
    ) {
      final List<Question> questions = layout.questions
          .map((question) => translateQuestion(question))
          .toList();
      return layout.copyWith(
        header: layout.header == null ? null : value(layout.header!),
        questions: questions,
      );
    }).toList();

    return PagesData(
      path: page.path == null ? null : translatePath(page.path!),
      loadedLayouts: translatedLayouts,
    );
  }

  String _interpolatePrompt(Question question, String text) {
    for (final entry
        in (question.interpolations ?? <String, String>{}).entries) {
      final translatedValue = (value(entry.value) as String?) ?? entry.value;
      text = text.replaceAll('{${entry.key}}', translatedValue);
    }
    return text;
  }

  /// Resolve compact wording only at display time. The question retains its
  /// shorthand key while being recorded, translated, or serialized, including
  /// generated questions whose definitions are embedded in saved responses.
  String translateShortPrompt(Question question) {
    final key = question.shortPrompt?.trim();
    final translated = key == null || key.isEmpty
        ? null
        : value(key) as String?;
    final text = translated == null || translated.trim().isEmpty
        ? (value(question.prompt) as String?) ?? question.prompt
        : translated;
    return _interpolatePrompt(question, text);
  }

  Question translateQuestion(Question question) {
    final translatedPrompt = _interpolatePrompt(
      question,
      value(question.prompt) ?? question.prompt,
    );

    // Preserve shorthand keys while translating the full question/choices.
    switch (question) {
      case FreeResponse():
        return question.copyWith(prompt: translatedPrompt);
      case Numeric():
        return question.copyWith(prompt: translatedPrompt);
      case Check():
        return question.copyWith(prompt: translatedPrompt);
      case MultipleChoice(choices: final choices):
        return question.copyWith(
          choices: choices
              .map<String>((choice) => value(choice) ?? choice)
              .toList(),
          prompt: translatedPrompt,
        );
      case AllThatApply(choices: final choices):
        return question.copyWith(
          choices: choices
              .map<String>((choice) => value(choice) ?? choice)
              .toList(),
          prompt: translatedPrompt,
        );
    }
  }
}
