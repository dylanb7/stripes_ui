import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String recordTitle(String username) {
    return 'Record for $username';
  }

  @override
  String get recordTab => 'Record';

  @override
  String historyTitle(String username) {
    return '$username\'s History';
  }

  @override
  String get historyTab => 'History';

  @override
  String get noEntryText => 'No Patient Entries';

  @override
  String lastEntry(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last Entry: $dateString';
  }

  @override
  String get categorySelect => 'Wählen Sie eine Kategorie:';

  @override
  String get blueDyeButton => 'Blauer Muffin Test';

  @override
  String get managePatientsButton => 'Manage Patients';

  @override
  String get logOutButton => 'Log Out';

  @override
  String get testInProgressNotif => 'Blue Dye Test in Progress';

  @override
  String recordHeader(String symptomType, String username) {
    return 'Recording $symptomType \nfor $username';
  }

  @override
  String emptyRecordHeader(String symptomType) {
    return '$symptomType Dokumentation';
  }

  @override
  String get selectInstruction => 'Select all behaviors that apply';

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
      other: 'Select slider values',
      one: 'Bitte wählen Sie eine passende Konsistenz!',
    );
    return '$_temp0';
  }

  @override
  String submitHeader(String symptomType) {
    return 'Tragen Sie Informationen zur Ihrer heutigen $symptomType hier ein:';
  }

  @override
  String editSubmitHeader(String symptomType) {
    return '\'Information Entered about $symptomType';
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
  String get submitBlueQuestionError => 'Must answer blue question before submitting';

  @override
  String get blueQuestionYes => 'Ja';

  @override
  String get blueQuestionNo => 'Nein';

  @override
  String get submitDescriptionTag => 'Weitere Anmerkungen';

  @override
  String get submitDescriptionPlaceholder => 'Clicken, um zu chreiben...';

  @override
  String get submitButtonText => 'Eintrag speichern';

  @override
  String get editSubmitButtonText => 'Save Changes';

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
  String get blueDyeInstructionsStepThreeA => 'Sobald Ihr Stuhlgang keinerlei blaue/blau-grüne Farbe mehr zeigt, drücken Sie bitte auf „Test einreichen“. So können wir Ihre Daten anonymisiert erhalten.';

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
  String get blueMuffinErrorPreventionLineOne => 'Are you sure you want to cancel your Blue Dye Test?';

  @override
  String get blueMuffinErrorPreventionLineTwo => 'You will lose all progress';

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
  String get blueDyeLogsInstructionOne => 'Record bowel movements from the record screen.';

  @override
  String get blueDyeLogsInstructionTwo => ' Recorded bowel movements will appear below';

  @override
  String get blueDyeLogsSubmitTest => 'Submit Test';

  @override
  String get blueDyeLogsSubmitTestError => 'Record a normal colored bowel movement before submitting';

  @override
  String get blueMealDurationTag => 'Mahlzeitdauer:';

  @override
  String get blueMealFinishedButton => 'Blaue Mahlzeit Ende';

  @override
  String get blueMealFinalDurationTag => 'Blue Meal Duration:';

  @override
  String get eventViewButton => 'Event View';

  @override
  String get eventViewDayCategoty => 'Day View';

  @override
  String get eventViewMonthCategory => 'Month View';

  @override
  String get eventViewAllCategory => 'All Entries';

  @override
  String get addEventButton => 'Add Event';

  @override
  String get addEventHeader => 'Select a type to record';

  @override
  String get filterEventsButton => 'Filter';

  @override
  String get eventFilterHeader => 'Filters';

  @override
  String eventFilterResults(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get eventFilterReset => 'Reset';

  @override
  String get eventFilterTypesTag => 'Types:';

  @override
  String get eventFiltersFromTag => 'From:';

  @override
  String get eventFiltersToTag => 'To:';

  @override
  String get eventFiltersApply => 'Apply Filters';

  @override
  String get noEventsText => 'No events recorded';

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
}
