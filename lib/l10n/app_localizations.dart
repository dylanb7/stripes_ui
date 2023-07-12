import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @codeError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Code'**
  String get codeError;

  /// No description provided for @submitCode.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitCode;

  /// No description provided for @accessCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Access Code'**
  String get accessCodePlaceholder;

  /// No description provided for @withoutCode.
  ///
  /// In en, this message translates to:
  /// **'Use without code'**
  String get withoutCode;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record for {username}'**
  String recordTitle(String username);

  /// No description provided for @recordTab.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordTab;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s History'**
  String historyTitle(String username);

  /// No description provided for @testTab.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get testTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @noEntryText.
  ///
  /// In en, this message translates to:
  /// **'No Patient Entries'**
  String get noEntryText;

  /// No description provided for @lastEntry.
  ///
  /// In en, this message translates to:
  /// **'Last Entry: {date}'**
  String lastEntry(DateTime date);

  /// No description provided for @categorySelect.
  ///
  /// In en, this message translates to:
  /// **'Select a category to record:'**
  String get categorySelect;

  /// No description provided for @blueDyeButton.
  ///
  /// In en, this message translates to:
  /// **'Blue Dye Test'**
  String get blueDyeButton;

  /// No description provided for @managePatientsButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Patients'**
  String get managePatientsButton;

  /// No description provided for @logOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutButton;

  /// No description provided for @testInProgressNotif.
  ///
  /// In en, this message translates to:
  /// **'Blue Dye Test in Progress'**
  String get testInProgressNotif;

  /// No description provided for @recordHeader.
  ///
  /// In en, this message translates to:
  /// **'Recording {symptomType} \nfor {username}'**
  String recordHeader(String symptomType, String username);

  /// No description provided for @emptyRecordHeader.
  ///
  /// In en, this message translates to:
  /// **'Recording {symptomType}'**
  String emptyRecordHeader(String symptomType);

  /// No description provided for @selectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select all behaviors that apply'**
  String get selectInstruction;

  /// No description provided for @mildTag.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get mildTag;

  /// No description provided for @severeTag.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severeTag;

  /// No description provided for @softTag.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get softTag;

  /// No description provided for @hardTag.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hardTag;

  /// No description provided for @levelReminder.
  ///
  /// In en, this message translates to:
  /// **'Select Level'**
  String get levelReminder;

  /// No description provided for @painLevelZero.
  ///
  /// In en, this message translates to:
  /// **'No Hurt'**
  String get painLevelZero;

  /// No description provided for @painLevelOne.
  ///
  /// In en, this message translates to:
  /// **'Hurts Little Bit'**
  String get painLevelOne;

  /// No description provided for @painLevelTwo.
  ///
  /// In en, this message translates to:
  /// **'Hurts Little More'**
  String get painLevelTwo;

  /// No description provided for @painLevelThree.
  ///
  /// In en, this message translates to:
  /// **'Hurts Even More'**
  String get painLevelThree;

  /// No description provided for @painLevelFour.
  ///
  /// In en, this message translates to:
  /// **'Hurts Whole Lot'**
  String get painLevelFour;

  /// No description provided for @painLevelFive.
  ///
  /// In en, this message translates to:
  /// **'Hurts Worst'**
  String get painLevelFive;

  /// No description provided for @nLevelError.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Missing entry} other{Missing entries}}'**
  String nLevelError(num count);

  /// No description provided for @moodLowLevel.
  ///
  /// In en, this message translates to:
  /// **'Worst Mood'**
  String get moodLowLevel;

  /// No description provided for @moodHighLevel.
  ///
  /// In en, this message translates to:
  /// **'Best Mood'**
  String get moodHighLevel;

  /// No description provided for @submitHeader.
  ///
  /// In en, this message translates to:
  /// **'Enter information about the {symptomType} entry below'**
  String submitHeader(String symptomType);

  /// No description provided for @editSubmitHeader.
  ///
  /// In en, this message translates to:
  /// **'\'Information Entered about {symptomType}'**
  String editSubmitHeader(String symptomType);

  /// No description provided for @dateChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateChangeTitle;

  /// No description provided for @dateChangeEntry.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String dateChangeEntry(DateTime date);

  /// No description provided for @timeChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeChangeTitle;

  /// No description provided for @timePickerErrorBoth.
  ///
  /// In en, this message translates to:
  /// **'Time must be between {early} and {late}'**
  String timePickerErrorBoth(String early, String late);

  /// No description provided for @timePickerErrorEarly.
  ///
  /// In en, this message translates to:
  /// **'Time must be after {early}'**
  String timePickerErrorEarly(String early);

  /// No description provided for @timePickerErrorLate.
  ///
  /// In en, this message translates to:
  /// **'Time must be before {late}'**
  String timePickerErrorLate(String late);

  /// No description provided for @submitBlueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did this bowel movement contain any blue color?'**
  String get submitBlueQuestion;

  /// No description provided for @submitBlueQuestionError.
  ///
  /// In en, this message translates to:
  /// **'Must answer blue question before submitting'**
  String get submitBlueQuestionError;

  /// No description provided for @blueQuestionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get blueQuestionYes;

  /// No description provided for @blueQuestionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get blueQuestionNo;

  /// No description provided for @submitDescriptionTag.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get submitDescriptionTag;

  /// No description provided for @submitDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tap to type...'**
  String get submitDescriptionPlaceholder;

  /// No description provided for @submitButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit Entry'**
  String get submitButtonText;

  /// No description provided for @editSubmitButtonText.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editSubmitButtonText;

  /// No description provided for @errorPreventionTitle.
  ///
  /// In en, this message translates to:
  /// **'Wait!'**
  String get errorPreventionTitle;

  /// No description provided for @errorPreventionLineOne.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this screen?'**
  String get errorPreventionLineOne;

  /// No description provided for @errorPreventionLineTwo.
  ///
  /// In en, this message translates to:
  /// **'You will lose all information you entered for this {symptomType} entry.'**
  String errorPreventionLineTwo(String symptomType);

  /// No description provided for @errorPreventionLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get errorPreventionLeave;

  /// No description provided for @errorPreventionStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get errorPreventionStay;

  /// No description provided for @blueDyeHeader.
  ///
  /// In en, this message translates to:
  /// **'Blue Dye Test'**
  String get blueDyeHeader;

  /// No description provided for @blueDyeInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Blue Dye Test Info'**
  String get blueDyeInfoHeader;

  /// No description provided for @blueDyeInfoLineOne.
  ///
  /// In en, this message translates to:
  /// **'The Blue Dye Test measures the time it takes for food to transit through the gut.'**
  String get blueDyeInfoLineOne;

  /// No description provided for @blueDyeInfoLineTwo.
  ///
  /// In en, this message translates to:
  /// **'To start the test, your participant(s) should eat two blue muffins in the morning after a minimum of a six hour fasting period.'**
  String get blueDyeInfoLineTwo;

  /// No description provided for @blueDyeInfoLineThree.
  ///
  /// In en, this message translates to:
  /// **'Record bowel movements, noting whether there is a blue blue-green color.'**
  String get blueDyeInfoLineThree;

  /// No description provided for @blueDyeInfoLineFour.
  ///
  /// In en, this message translates to:
  /// **'Submit test after recording the first BM that lacks any blue or blue green color.'**
  String get blueDyeInfoLineFour;

  /// No description provided for @blueDyeInstructionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get blueDyeInstructionsHeader;

  /// No description provided for @blueDyeInstructionsStepOne.
  ///
  /// In en, this message translates to:
  /// **'1) Eat Muffins'**
  String get blueDyeInstructionsStepOne;

  /// No description provided for @blueDyeInstructionsStepOneA.
  ///
  /// In en, this message translates to:
  /// **'When your participant starts eating muffins, select “Start Blue Meal'**
  String get blueDyeInstructionsStepOneA;

  /// No description provided for @blueDyeInstructionsStepOneB.
  ///
  /// In en, this message translates to:
  /// **'When your participant is done eating select \'Finished Blue Meal\''**
  String get blueDyeInstructionsStepOneB;

  /// No description provided for @blueDyeInstructionsStepTwo.
  ///
  /// In en, this message translates to:
  /// **'2) Record Bowel Movements (BMs)'**
  String get blueDyeInstructionsStepTwo;

  /// No description provided for @blueDyeInstructionsStepTwoA.
  ///
  /// In en, this message translates to:
  /// **'Log BMs from the Record page and indicate whether or not the BM has any (even partial) blue or blue green color.'**
  String get blueDyeInstructionsStepTwoA;

  /// No description provided for @blueDyeInstructionsStepTwoB.
  ///
  /// In en, this message translates to:
  /// **'It is common for the first couple of BMs after eating the muffin to not show blue yet.'**
  String get blueDyeInstructionsStepTwoB;

  /// No description provided for @blueDyeInstructionsStepThree.
  ///
  /// In en, this message translates to:
  /// **'3) Submit the Test'**
  String get blueDyeInstructionsStepThree;

  /// No description provided for @blueDyeInstructionsStepThreeA.
  ///
  /// In en, this message translates to:
  /// **'Submit test after recording the first BM that lacks any blue or blue green color.'**
  String get blueDyeInstructionsStepThreeA;

  /// No description provided for @blueMuffinsInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Blue Muffins Info'**
  String get blueMuffinsInfoHeader;

  /// No description provided for @blueMuffinsInfoLineOne.
  ///
  /// In en, this message translates to:
  /// **'Blue muffins will come in the mail.'**
  String get blueMuffinsInfoLineOne;

  /// No description provided for @blueMuffinsInfoLineTwo.
  ///
  /// In en, this message translates to:
  /// **'They can be stored in the refrigerator.'**
  String get blueMuffinsInfoLineTwo;

  /// No description provided for @blueMuffinsInfoLineThree.
  ///
  /// In en, this message translates to:
  /// **'To get ready for the test, remove the muffins from their packaging and heat them briefly, 20-30 seconds in the microwave or a few minutes in the oven.'**
  String get blueMuffinsInfoLineThree;

  /// No description provided for @blueMuffinsInfoLineFour.
  ///
  /// In en, this message translates to:
  /// **'Muffins should be the first thing the participant eats in the morning after an overnight fast of at least 6 hours.'**
  String get blueMuffinsInfoLineFour;

  /// No description provided for @blueDyeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Test'**
  String get blueDyeCancel;

  /// No description provided for @blueMuffinErrorPreventionLineOne.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your Blue Dye Test?'**
  String get blueMuffinErrorPreventionLineOne;

  /// No description provided for @blueMuffinErrorPreventionLineTwo.
  ///
  /// In en, this message translates to:
  /// **'You will lose all progress'**
  String get blueMuffinErrorPreventionLineTwo;

  /// No description provided for @blueDyeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Blue Meal'**
  String get blueDyeStart;

  /// No description provided for @blueMealStartTime.
  ///
  /// In en, this message translates to:
  /// **'Started: {date} {time}'**
  String blueMealStartTime(DateTime date, DateTime time);

  /// No description provided for @blueDyeLogsInstructionOne.
  ///
  /// In en, this message translates to:
  /// **'Record bowel movements from the record screen.'**
  String get blueDyeLogsInstructionOne;

  /// No description provided for @blueDyeLogsInstructionTwo.
  ///
  /// In en, this message translates to:
  /// **' Recorded bowel movements will appear below'**
  String get blueDyeLogsInstructionTwo;

  /// No description provided for @blueDyeLogsSubmitTest.
  ///
  /// In en, this message translates to:
  /// **'Submit Test'**
  String get blueDyeLogsSubmitTest;

  /// No description provided for @blueDyeLogsSubmitTestError.
  ///
  /// In en, this message translates to:
  /// **'Record a normal colored bowel movement before submitting'**
  String get blueDyeLogsSubmitTestError;

  /// No description provided for @blueMealDurationTag.
  ///
  /// In en, this message translates to:
  /// **'Meal Duration:'**
  String get blueMealDurationTag;

  /// No description provided for @blueMealFinishedButton.
  ///
  /// In en, this message translates to:
  /// **'Finished Blue Meal'**
  String get blueMealFinishedButton;

  /// No description provided for @blueMealFinalDurationTag.
  ///
  /// In en, this message translates to:
  /// **'Blue Meal Duration:'**
  String get blueMealFinalDurationTag;

  /// No description provided for @eventViewButton.
  ///
  /// In en, this message translates to:
  /// **'Event View'**
  String get eventViewButton;

  /// No description provided for @eventViewDayCategoty.
  ///
  /// In en, this message translates to:
  /// **'Day View'**
  String get eventViewDayCategoty;

  /// No description provided for @eventViewMonthCategory.
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get eventViewMonthCategory;

  /// No description provided for @eventViewAllCategory.
  ///
  /// In en, this message translates to:
  /// **'All Entries'**
  String get eventViewAllCategory;

  /// No description provided for @addEventButton.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEventButton;

  /// No description provided for @addEventHeader.
  ///
  /// In en, this message translates to:
  /// **'Select a type to record'**
  String get addEventHeader;

  /// No description provided for @filterEventsButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterEventsButton;

  /// No description provided for @eventFilterHeader.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get eventFilterHeader;

  /// No description provided for @eventFilterResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String eventFilterResults(num count);

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Cannot export without a code'**
  String get exportError;

  /// No description provided for @exportName.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportName;

  /// No description provided for @exportDialog.
  ///
  /// In en, this message translates to:
  /// **'Data will be sent to the study coordinators. None of your personal information is included.\nIf there are any changes in the future you may export again.'**
  String get exportDialog;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Keine Einträge} =1{1 Eintrag senden} other{Senden Sie {count} Einträge}}'**
  String recordCount(num count);

  /// No description provided for @uploadDone.
  ///
  /// In en, this message translates to:
  /// **'Upload Done'**
  String get uploadDone;

  /// No description provided for @uploadFail.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFail;

  /// No description provided for @eventFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get eventFilterReset;

  /// No description provided for @eventFilterTypesTag.
  ///
  /// In en, this message translates to:
  /// **'Types:'**
  String get eventFilterTypesTag;

  /// No description provided for @eventFiltersFromTag.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get eventFiltersFromTag;

  /// No description provided for @eventFiltersToTag.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get eventFiltersToTag;

  /// No description provided for @eventFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get eventFiltersApply;

  /// No description provided for @noEventsText.
  ///
  /// In en, this message translates to:
  /// **'No events recorded'**
  String get noEventsText;

  /// No description provided for @behaviorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Behaviors:'**
  String get behaviorsLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionLabel;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @startTestEntry.
  ///
  /// In en, this message translates to:
  /// **'Started Test:'**
  String get startTestEntry;

  /// No description provided for @mealDurationEntry.
  ///
  /// In en, this message translates to:
  /// **'Eating Duration:'**
  String get mealDurationEntry;

  /// No description provided for @firstBlueEntry.
  ///
  /// In en, this message translates to:
  /// **'First Blue BM:'**
  String get firstBlueEntry;

  /// No description provided for @lastBlueEntry.
  ///
  /// In en, this message translates to:
  /// **'Last Blue BM:'**
  String get lastBlueEntry;

  /// No description provided for @transitDurationEntry.
  ///
  /// In en, this message translates to:
  /// **'Transit Duration:'**
  String get transitDurationEntry;

  /// No description provided for @patientProfilesHeader.
  ///
  /// In en, this message translates to:
  /// **'Patient Profiles'**
  String get patientProfilesHeader;

  /// No description provided for @patientProfilesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select a patient to view their profile.'**
  String get patientProfilesInstruction;

  /// No description provided for @patientBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Birth Year'**
  String get patientBirthYear;

  /// No description provided for @patientGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get patientGender;

  /// No description provided for @patientRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get patientRole;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
