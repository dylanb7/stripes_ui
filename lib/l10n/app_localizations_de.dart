import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get checkInLabel => 'Ankunft';

  @override
  String get signupWithAccessCode => 'Mit Zugangscode anmelden';

  @override
  String get loginButtonPrefix => 'Sie haben schon ein Benutzerkonto? ';

  @override
  String get loginButtonText => 'Anmelden';

  @override
  String get useWithoutAccount => 'Ohne Benutzerkonto anmelden';

  @override
  String get passwordText => 'Passwort';

  @override
  String get loginText => 'Login';

  @override
  String get forgotPasswordText => 'Passwort vergessen?';

  @override
  String get resetPasswordText => 'Passwort zurücksetzen';

  @override
  String get noAccountPrefix => 'Sie haben noch kein Benutzerkonto?';

  @override
  String get noAccountText => 'Benutzerkonto erstellen';

  @override
  String get sendResetEmail => 'E-Mail zum Zurücksetzen senden';

  @override
  String get createAccountText => 'Konto erstellen';

  @override
  String get passwordRequirementHeader => 'Passwort muss beinhalten:';

  @override
  String get passwordLength => 'Mindestens 8 Zeichen lang';

  @override
  String get passwordLowercase => 'Mindestens ein Großbuchstabe';

  @override
  String get passwordUppercase => 'Mindestens ein Kleinbuchstabe';

  @override
  String get passwordNumber => 'Mindestens eine Zahl';

  @override
  String get passwordMatchError => 'Passwörter stimmen nicht überein';

  @override
  String get emptyFieldText => 'Leeres Feld';

  @override
  String get codeError => 'Ungültiger Code';

  @override
  String get submitCode => 'Senden';

  @override
  String get accessCodePlaceholder => 'Zugangscode';

  @override
  String get withoutCode => 'Verwendung ohne Code';

  @override
  String recordTitle(String username) {
    return 'Record for $username';
  }

  @override
  String get recordTab => 'Dokumentation';

  @override
  String historyTitle(String username) {
    return '$username\'s History';
  }

  @override
  String get testTab => 'Prüfung';

  @override
  String get historyTab => 'Einträge';

  @override
  String get noEntryText => 'Keine Patient*innen Einträge';

  @override
  String lastEntry(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Letzter Eintrag: $dateString';
  }

  @override
  String get categorySelect => 'Wählen Sie eine Kategorie:';

  @override
  String get blueDyeButton => 'Blauer Muffin Test';

  @override
  String get managePatientsButton => 'Manage Patients';

  @override
  String get logOutButton => 'Abmelden';

  @override
  String get testInProgressNotif => 'Blue Dye Test in Progress';

  @override
  String get undo => 'undo';

  @override
  String undoEntry(String symptomType, DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Added $symptomType on $dateString at $timeString';
  }

  @override
  String recordHeader(String symptomType, String username) {
    return 'Recording $symptomType \nfor $username';
  }

  @override
  String emptyRecordHeader(String symptomType) {
    return '$symptomType Dokumentation';
  }

  @override
  String get selectInstruction => 'Wählen Sie alle Verhaltensweisen aus, die angewendet werden';

  @override
  String get mildTag => 'Mild';

  @override
  String get severeTag => 'Severe';

  @override
  String get softTag => 'Weich';

  @override
  String get hardTag => 'Hart';

  @override
  String get levelReminder => 'Wählen Sie eine passende Stufe';

  @override
  String get painLevelZero => 'Tut nicht weh';

  @override
  String get painLevelOne => 'Tut etwas weh';

  @override
  String get painLevelTwo => 'Tut etwas mehr weh';

  @override
  String get painLevelThree => 'Tut noch mehr weh';

  @override
  String get painLevelFour => 'Tut sehr weh';

  @override
  String get painLevelFive => 'Tut am meisten weh';

  @override
  String nLevelError(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fehlende Einträge',
      one: 'Fehlender Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get moodLowLevel => 'Sehr schlecht';

  @override
  String get moodHighLevel => 'Sehr gut';

  @override
  String submitHeader(String symptomType) {
    return 'Tragen Sie weitere Informationen hier ein:';
  }

  @override
  String editSubmitHeader(String symptomType) {
    return '\'Eintrag dokumentiert über $symptomType';
  }

  @override
  String get dateChangeTitle => 'Datum';

  @override
  String dateChangeEntry(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get timeChangeTitle => 'Uhrzeit';

  @override
  String timePickerErrorBoth(String early, String late) {
    return 'Time must be between $early and $late';
  }

  @override
  String timePickerErrorEarly(String early) {
    return 'Time must be after $early';
  }

  @override
  String timePickerErrorLate(String late) {
    return 'Time must be before $late';
  }

  @override
  String get submitBlueQuestion => 'War der Stuhl blau (blaugrün) gefärbt?';

  @override
  String get submitBlueQuestionError => 'Muss vor dem Absenden die blaue Frage beantworten';

  @override
  String get blueQuestionYes => 'Ja';

  @override
  String get blueQuestionNo => 'Nein';

  @override
  String get submitDescriptionTag => 'Weitere Anmerkungen';

  @override
  String get submitDescriptionPlaceholder => 'Clicken, um zu schreiben...';

  @override
  String get submitButtonText => 'Eintrag speichern';

  @override
  String get editSubmitButtonText => 'Änderungen speichern';

  @override
  String get errorPreventionTitle => 'Moment!';

  @override
  String get errorPreventionLineOne => 'Sind Sie sicher, dass Sie diese Anwendung verlassen wollen?';

  @override
  String errorPreventionLineTwo(String symptomType) {
    return 'So gehen alle eingetragenen Informationen verloren.';
  }

  @override
  String get errorPreventionLeave => 'Nicht speichern';

  @override
  String get errorPreventionStay => 'Abbrechen';

  @override
  String get blueDyeHeader => 'Blauer Muffin Test';

  @override
  String get blueDyeInfoHeader => 'Blue Dye Test Info';

  @override
  String get blueDyeInfoLineOne => 'The Blue Dye Test measures the time it takes for food to transit through the gut.';

  @override
  String get blueDyeInfoLineTwo => 'To start the test, your participant(s) should eat two blue muffins in the morning after a minimum of a six hour fasting period.';

  @override
  String get blueDyeInfoLineThree => 'Record bowel movements, noting whether there is a blue blue-green color.';

  @override
  String get blueDyeInfoLineFour => 'Submit test after recording the first BM that lacks any blue or blue green color.';

  @override
  String get blueDyeInstructionsHeader => 'Anweisungen';

  @override
  String get blueDyeInstructionsStepOne => '1) Muffin-Essen';

  @override
  String get blueDyeInstructionsStepOneA => 'Sobald Sie beginnen den blauen Muffin zu essen, drücken Sie bitte auf „Blaue Mahlzeit Start“';

  @override
  String get blueDyeInstructionsStepOneB => 'Sobald Sie den Muffin vollständig verzehrt haben, drücken Sie bitte auf „Blaue Mahlzeit Ende“';

  @override
  String get blueDyeInstructionsStepTwo => '2) Dokumentation zu Hause';

  @override
  String get blueDyeInstructionsStepTwoA => 'Dokumentieren Sie bitte daheim nach Verzehr des Blauen Muffins jeden Stuhlgang unter „Poop Dokumentation“ und geben Sie an, ob dieser (teilweise) blau/blau-grün gefärbt war.';

  @override
  String get blueDyeInstructionsStepTwoB => 'Es ist normal, dass einige Tage vergehen, bis die blaue Farbe erscheint.';

  @override
  String get blueDyeInstructionsStepThree => '3) Einreichen des Tests';

  @override
  String get blueDyeInstructionsStepThreeA => 'Sobald Ihr Stuhlgang keinerlei blaue/blau-grüne Farbe mehr zeigt, drücken Sie bitte auf „Test einreichen“. So können wir Ihre gastrointestinale Passagezeit genau nachverfolgen.';

  @override
  String get blueMuffinsInfoHeader => 'Blue Muffins Info';

  @override
  String get blueMuffinsInfoLineOne => 'Blue muffins will come in the mail.';

  @override
  String get blueMuffinsInfoLineTwo => 'They can be stored in the refrigerator.';

  @override
  String get blueMuffinsInfoLineThree => 'To get ready for the test, remove the muffins from their packaging and heat them briefly, 20-30 seconds in the microwave or a few minutes in the oven.';

  @override
  String get blueMuffinsInfoLineFour => 'Muffins should be the first thing the participant eats in the morning after an overnight fast of at least 6 hours.';

  @override
  String get blueDyeCancel => 'Test abbrechen';

  @override
  String get blueMuffinErrorPreventionLineOne => 'Sind Sie sicher, dass Sie diese Anwendung verlassen wollen?';

  @override
  String get blueMuffinErrorPreventionLineTwo => 'So gehen alle eingetragenen Informationen verloren.';

  @override
  String get blueDyeStart => 'Blaue Mahlzeit Start';

  @override
  String blueMealStartTime(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Started: $dateString $timeString';
  }

  @override
  String get blueDyeLogsInstructionOne => 'Zeichnen Sie den Stuhlgang auf dem Aufnahmebildschirm auf.';

  @override
  String get blueDyeLogsInstructionTwo => ' Aufgezeichneter Stuhlgang wird unten angezeigt';

  @override
  String get blueDyeLogsSubmitTest => 'Test einreichen';

  @override
  String get blueDyeLogsSubmitTestError => 'Zeichnen Sie vor dem Absenden einen normal gefärbten Stuhlgang auf';

  @override
  String get blueMealDurationTag => 'Mahlzeitdauer:';

  @override
  String get blueMealFinishedButton => 'Blaue Mahlzeit Ende';

  @override
  String get blueMealFinalDurationTag => 'Dauer der blauen Mahlzeit:';

  @override
  String get testSubmitSuccess => 'Test erfolgreich eingereicht';

  @override
  String get eventViewButton => 'Event View';

  @override
  String get eventViewDayCategoty => 'Tag';

  @override
  String get eventViewMonthCategory => 'Monat';

  @override
  String get eventViewAllCategory => 'Alle Einträge';

  @override
  String get addEventButton => 'Eintrag hinzufügen';

  @override
  String get addEventHeader => 'Typ zum Aufzeichnen';

  @override
  String get filterEventsButton => 'Filter';

  @override
  String get eventFilterHeader => 'Filter';

  @override
  String eventFilterResults(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Einträge',
      one: 'Ein Eintrag',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get exportError => 'Exportieren ohne Code nicht möglich';

  @override
  String get exportName => 'Datenexport';

  @override
  String get exportDialog => 'Die Daten werden an die Studienkoordinatoren gesendet. Es sind keine Ihrer persönlichen Daten enthalten. Wenn sich in Zukunft Änderungen ergeben, können Sie erneut exportieren.';

  @override
  String recordCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Senden Sie $countString Einträge',
      one: '1 Eintrag senden',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get uploadDone => 'Hochladen erledigt';

  @override
  String get uploadFail => 'Fehler beim Hochladen';

  @override
  String get eventFilterReset => 'Zurücksetzen';

  @override
  String get eventFilterTypesTag => 'Kategorien:';

  @override
  String get eventFiltersFromTag => 'Von:';

  @override
  String get eventFiltersToTag => 'An:';

  @override
  String get eventFiltersApply => 'Filter anwenden';

  @override
  String get noEventsText => 'Keine Einträge dokumentiert';

  @override
  String get behaviorsLabel => 'Verhaltensweisen:';

  @override
  String get descriptionLabel => 'Beschreibung:';

  @override
  String get deleteAction => 'Löschen';

  @override
  String get startTestEntry => 'Teststart:';

  @override
  String get mealDurationEntry => 'Verzehrdauer:';

  @override
  String get firstBlueEntry => 'Erster blauer Poo:';

  @override
  String get lastBlueEntry => 'Letzter blauer Poo:';

  @override
  String get transitDurationEntry => 'Transitzeit:';

  @override
  String get patientProfilesHeader => 'Patient Profiles';

  @override
  String get patientProfilesInstruction => 'Select a patient to view their profile.';

  @override
  String get patientBirthYear => 'Birth Year';

  @override
  String get patientGender => 'Gender';

  @override
  String get patientRole => 'Role';

  @override
  String get stampDeleteWarningOne => 'Sind Sie sicher, dass Sie löschen möchten?';

  @override
  String get stampDeleteWarningTwo => 'Sie verlieren alle Informationen für diesen Eintrag.';

  @override
  String get stampDeleteConfirm => 'Bestätigen';

  @override
  String get stampDeleteCancel => 'Abbrechen';

  @override
  String get exitStudy => 'Exit-Studie';

  @override
  String get exitStudyWarning => 'Wenn Sie die Studie verlassen, werden alle exportierten Daten gelöscht und Ihr Zugangscode wird ungültig.';

  @override
  String get passwordConfirm => 'Passwort bestätigen';
}
