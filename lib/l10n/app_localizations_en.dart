import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get checkInLabel => 'Check-ins';

  @override
  String get signupWithAccessCode => 'Sign up with access code';

  @override
  String get loginButtonPrefix => 'Already have an account? ';

  @override
  String get loginButtonText => 'Login';

  @override
  String get useWithoutAccount => 'Use without account';

  @override
  String get passwordText => 'Password';

  @override
  String get loginText => 'Login';

  @override
  String get forgotPasswordText => 'Forgot password?';

  @override
  String get resetPasswordText => 'Reset Password';

  @override
  String get noAccountPrefix => 'Do not have an account?';

  @override
  String get noAccountText => 'Create an account';

  @override
  String get sendResetEmail => 'Send reset email';

  @override
  String get createAccountText => 'Create account';

  @override
  String get passwordRequirementHeader => 'Password must:';

  @override
  String get passwordLength => 'Be a minimum of 8 characters long';

  @override
  String get passwordLowercase => 'Include a lowercase letter (a-z)';

  @override
  String get passwordUppercase => 'Include an uppercase letter (A-Z)';

  @override
  String get passwordNumber => 'Include a number (1-9)';

  @override
  String get passwordMatchError => 'Passwords do not match';

  @override
  String get emptyFieldText => 'Empty Field';

  @override
  String get codeError => 'Invalid Code';

  @override
  String get submitCode => 'Submit';

  @override
  String get accessCodePlaceholder => 'Access Code';

  @override
  String get withoutCode => 'Use without code';

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
  String get testTab => 'Tests';

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
  String get categorySelect => 'Select a category to record:';

  @override
  String get blueDyeButton => 'Blue Dye Test';

  @override
  String get managePatientsButton => 'Manage Patients';

  @override
  String get logOutButton => 'Log Out';

  @override
  String get testInProgressNotif => 'Blue Dye Test in Progress';

  @override
  String get undo => 'undo';

  @override
  String recordHeader(String symptomType, String username) {
    return 'Recording $symptomType \nfor $username';
  }

  @override
  String emptyRecordHeader(String symptomType) {
    return 'Recording $symptomType';
  }

  @override
  String get selectInstruction => 'Select all behaviors that apply';

  @override
  String get mildTag => 'Mild';

  @override
  String get severeTag => 'Severe';

  @override
  String get softTag => 'Soft';

  @override
  String get hardTag => 'Hard';

  @override
  String get levelReminder => 'Select Level';

  @override
  String get painLevelZero => 'No Hurt';

  @override
  String get painLevelOne => 'Hurts Little Bit';

  @override
  String get painLevelTwo => 'Hurts Little More';

  @override
  String get painLevelThree => 'Hurts Even More';

  @override
  String get painLevelFour => 'Hurts Whole Lot';

  @override
  String get painLevelFive => 'Hurts Worst';

  @override
  String nLevelError(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Missing entries',
      one: 'Missing entry',
    );
    return '$_temp0';
  }

  @override
  String get moodLowLevel => 'Best Mood';

  @override
  String get moodHighLevel => 'Worst Mood';

  @override
  String submitHeader(String symptomType) {
    return 'Enter information about the $symptomType entry below';
  }

  @override
  String editSubmitHeader(String symptomType) {
    return 'Information entered about $symptomType';
  }

  @override
  String get dateChangeTitle => 'Date';

  @override
  String dateChangeEntry(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get timeChangeTitle => 'Time';

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
  String get submitBlueQuestion => 'Did this bowel movement contain any blue color?';

  @override
  String get submitBlueQuestionError => 'Must answer blue question before submitting';

  @override
  String get blueQuestionYes => 'Yes';

  @override
  String get blueQuestionNo => 'No';

  @override
  String get submitDescriptionTag => 'Description';

  @override
  String get submitDescriptionPlaceholder => 'Tap to type...';

  @override
  String get submitButtonText => 'Submit Entry';

  @override
  String get editSubmitButtonText => 'Save Changes';

  @override
  String get errorPreventionTitle => 'Wait!';

  @override
  String get errorPreventionLineOne => 'Are you sure you want to leave this screen?';

  @override
  String errorPreventionLineTwo(String symptomType) {
    return 'You will lose all information you entered for this $symptomType entry.';
  }

  @override
  String get errorPreventionLeave => 'Leave';

  @override
  String get errorPreventionStay => 'Stay';

  @override
  String get blueDyeHeader => 'Blue Dye Test';

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
  String get blueDyeInstructionsHeader => 'Instructions';

  @override
  String get blueDyeInstructionsStepOne => '1) Eat Muffins';

  @override
  String get blueDyeInstructionsStepOneA => 'When your participant starts eating muffins, select “Start Blue Meal';

  @override
  String get blueDyeInstructionsStepOneB => 'When your participant is done eating select \'Finished Blue Meal\'';

  @override
  String get blueDyeInstructionsStepTwo => '2) Record Bowel Movements (BMs)';

  @override
  String get blueDyeInstructionsStepTwoA => 'Log BMs from the Record page and indicate whether or not the BM has any (even partial) blue or blue green color.';

  @override
  String get blueDyeInstructionsStepTwoB => 'It is common for the first couple of BMs after eating the muffin to not show blue yet.';

  @override
  String get blueDyeInstructionsStepThree => '3) Submit the Test';

  @override
  String get blueDyeInstructionsStepThreeA => 'Submit test after recording the first BM that lacks any blue or blue green color.';

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
  String get blueDyeCancel => 'Cancel Test';

  @override
  String get blueMuffinErrorPreventionLineOne => 'Are you sure you want to cancel your Blue Dye Test?';

  @override
  String get blueMuffinErrorPreventionLineTwo => 'You will lose all progress';

  @override
  String get blueDyeStart => 'Start Blue Meal';

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
  String get blueMealDurationTag => 'Meal Duration:';

  @override
  String get blueMealFinishedButton => 'Finished Blue Meal';

  @override
  String get blueMealFinalDurationTag => 'Blue Meal Duration:';

  @override
  String get testSubmitSuccess => 'Test successfully submitted';

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
  String get exportError => 'Cannot export without a code';

  @override
  String get exportName => 'Export';

  @override
  String get exportDialog => 'Data will be sent to the study coordinators. None of your personal information is included.\nIf there are any changes in the future you may export again.';

  @override
  String recordCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Entries',
      one: '1 Entry',
      zero: 'No Entries',
    );
    return '$_temp0';
  }

  @override
  String get uploadDone => 'Upload Done';

  @override
  String get uploadFail => 'Upload Failed';

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
  String get behaviorsLabel => 'Behaviors:';

  @override
  String get descriptionLabel => 'Description:';

  @override
  String get deleteAction => 'Delete';

  @override
  String get startTestEntry => 'Started Test:';

  @override
  String get mealDurationEntry => 'Eating Duration:';

  @override
  String get firstBlueEntry => 'First Blue BM:';

  @override
  String get lastBlueEntry => 'Last Blue BM:';

  @override
  String get transitDurationEntry => 'Transit Duration:';

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
  String get stampDeleteWarningOne => 'Are you sure you want to delete?';

  @override
  String get stampDeleteWarningTwo => 'You will lose all information for this entry.';

  @override
  String get stampDeleteConfirm => 'Confirm';

  @override
  String get stampDeleteCancel => 'Cancel';

  @override
  String get exitStudy => 'Exit Study';

  @override
  String get exitStudyWarning => 'When you exit the study all exported data will be deleted and your access code will be invalidated';

  @override
  String get passwordConfirm => 'Confirm Password';
}
