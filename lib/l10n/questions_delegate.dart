import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

class QuestionsLocalizations {
  Map<String, dynamic> questionTranslations = {};

  late String currentLocale;

  final String questionTranslationPath;

  final AssetBundle assetBundle;
  QuestionsLocalizations(
      {required this.questionTranslationPath, AssetBundle? bundle})
      : assetBundle = bundle ?? rootBundle;

  Future<Map<String, dynamic>> loadFile(Locale locale) async {
    if (currentLocale != locale.languageCode) {
      currentLocale = locale.languageCode;
    }

    try {
      final text = await assetBundle
          .loadString('$questionTranslationPath/$currentLocale.json');
      return json.decode(text);
    } catch (e) {
      debugPrint(e.toString());
    }

    return {};
  }

  Future<QuestionsLocalizations> load(Locale locale) async {
    currentLocale = locale.toLanguageTag();
    if (questionTranslations.containsKey(currentLocale)) {
      return this;
    }
    questionTranslations[currentLocale] = await loadFile(locale);
    return this;
  }

  static QuestionsLocalizations? of(BuildContext context) =>
      Localizations.of<QuestionsLocalizations>(context, QuestionsLocalizations);

  dynamic value(String key) => questionTranslations[currentLocale]![key];
}

class QuestionsLocalizationsDelegate
    extends LocalizationsDelegate<QuestionsLocalizations> {
  final QuestionsLocalizations localization;

  final AssetBundle? assetBundle;

  QuestionsLocalizationsDelegate({required String path, this.assetBundle})
      : localization = QuestionsLocalizations(
            questionTranslationPath: path, bundle: assetBundle);
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
        response: item.response);
  }

  PagesData translatePage(PagesData page) {
    final List<LoadedPageLayout> currentLayouts = page.loadedLayouts ?? [];
    final List<LoadedPageLayout> translatedLayouts =
        currentLayouts.map((layout) {
      final List<Question> questions = layout.questions
          .map((question) => translateQuestion(question))
          .toList();
      return layout.copyWith(
          header: layout.header == null ? null : value(layout.header!),
          questions: questions);
    }).toList();

    return PagesData(
        path: page.path == null ? null : translatePath(page.path!),
        loadedLayouts: translatedLayouts);
  }

  Question translateQuestion(Question question) {
    switch (question) {
      case FreeResponse(prompt: final prompt):
        return question.copyWith(prompt: value(prompt) ?? prompt);
      case Numeric(prompt: final prompt):
        return question.copyWith(prompt: value(prompt) ?? prompt);
      case Check(prompt: final prompt):
        return question.copyWith(prompt: value(prompt) ?? prompt);
      case MultipleChoice(choices: final choices, prompt: final prompt):
        return question.copyWith(
            choices: choices
                .map<String>((choice) => value(choice) ?? choice)
                .toList(),
            prompt: value(prompt) ?? prompt);
      case AllThatApply(choices: final choices, prompt: final prompt):
        return question.copyWith(
            choices: choices
                .map<String>((choice) => value(choice) ?? choice)
                .toList(),
            prompt: value(prompt) ?? prompt);
    }
  }

  /// Translates a question that was generated via Transform.
  ///
  /// For generated questions (those with '::' in their ID), this method:
  /// 1. Tries to find a translation for the prompt template (with {value} placeholder)
  /// 2. Translates the interpolated value if a translation exists
  /// 3. Reconstructs the prompt with translated pieces
  ///
  /// Falls back to standard translateQuestion if no template translation found.
  Question translateGeneratedQuestion(
      Question question, Question? templateQuestion) {
    // First try standard translation
    final standardTranslation = translateQuestion(question);

    // If prompt was translated, we're done
    if (standardTranslation.prompt != question.prompt) {
      return standardTranslation;
    }

    // Try to extract template and value from the prompt
    // The template question should have the original prompt with {value} placeholder
    if (templateQuestion != null) {
      final templatePrompt = templateQuestion.prompt;
      final translatedTemplate = value(templatePrompt) as String?;

      if (translatedTemplate != null &&
          translatedTemplate.contains('{value}')) {
        // Find what value was interpolated by comparing prompts
        final extractedValue =
            _extractInterpolatedValue(templatePrompt, question.prompt);

        if (extractedValue != null) {
          // Translate the value if possible
          final translatedValue =
              (value(extractedValue) as String?) ?? extractedValue;

          // Reconstruct with translated template and value
          final newPrompt =
              translatedTemplate.replaceAll('{value}', translatedValue);

          return _copyQuestionWithPrompt(question, newPrompt);
        }
      }
    }

    // Also translate choices if applicable
    return standardTranslation;
  }

  /// Extracts the value that was interpolated into a template.
  /// Returns null if extraction failed.
  String? _extractInterpolatedValue(String template, String result) {
    // Find where {value} is in the template
    final placeholderIndex = template.indexOf('{value}');
    if (placeholderIndex == -1) return null;

    // Get the text before and after placeholder
    final prefix = template.substring(0, placeholderIndex);
    final suffix = template.substring(placeholderIndex + '{value}'.length);

    // Extract the value from the result
    if (!result.startsWith(prefix)) return null;
    if (suffix.isNotEmpty && !result.endsWith(suffix)) return null;

    final valueStart = prefix.length;
    final valueEnd =
        suffix.isNotEmpty ? result.length - suffix.length : result.length;

    if (valueStart >= valueEnd) return null;
    return result.substring(valueStart, valueEnd);
  }

  Question _copyQuestionWithPrompt(Question question, String newPrompt) {
    return switch (question) {
      FreeResponse() => question.copyWith(prompt: newPrompt),
      Numeric() => question.copyWith(prompt: newPrompt),
      Check() => question.copyWith(prompt: newPrompt),
      MultipleChoice() => question.copyWith(prompt: newPrompt),
      AllThatApply() => question.copyWith(prompt: newPrompt),
    };
  }
}
