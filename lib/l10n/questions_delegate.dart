import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class QuestionsLocalizations {
  Map<String, dynamic> questionTranslations = {};

  late String currentLocale;

  final String questionTranslationPath;

  QuestionsLocalizations(this.questionTranslationPath);

  Future<Map<String, dynamic>> loadFile(Locale locale) async {
    if (currentLocale != locale.languageCode) {
      currentLocale = locale.languageCode;
    }

    try {
      final text = await rootBundle
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

  QuestionsLocalizationsDelegate({required String path})
      : localization = QuestionsLocalizations(path);
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<QuestionsLocalizations> load(Locale locale) {
    return localization.load(locale);
  }

  @override
  bool shouldReload(QuestionsLocalizationsDelegate old) => false;
}
