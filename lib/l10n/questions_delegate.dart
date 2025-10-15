import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';

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

  CheckinItem translateCheckin(CheckinItem item) {
    return CheckinItem(
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
}
