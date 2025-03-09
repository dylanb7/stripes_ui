// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

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
  String get viewMoreButtonText => 'View More';

  @override
  String get viewLessButtonText => 'View Less';

  @override
  String get noDateToAddTo => 'No date selected';

  @override
  String get dateRangeButton => 'Select Date Range';

  @override
  String get eventFilterGroupsTag => 'Groups';

  @override
  String get calendarVisibilityWeek => 'Week';

  @override
  String get calendarVisibilityMonth => 'Month';

  @override
  String get calendarVisibilityHidden => 'Hidden';

  @override
  String get stripesName => 'STRiPES';

  @override
  String get aboutStripes => 'About STRiPES';

  @override
  String get aboutLineOne => 'STRiPES is a symptom tracker that collects information on altered movement of food through the gut (aka motility), pain, bowel movements(BM) and reflux of patients with Phelan-McDermid Syndrome (PMS).';

  @override
  String get aboutLineTwo => 'The data will then be used in studies to further our understanding on gastrointestinal issues in patients with PMS.';

  @override
  String get aboutLineThree => 'If you want to learn more about the studies STRiPES is collecting data for, please click the link below:';

  @override
  String get aboutQuestionsTitle => 'Questions and/or concerns?';

  @override
  String get aboutCategoriesTitle => 'If at any moment you have questions regarding thing such as:';

  @override
  String get aboutDataCollection => 'Data collection';

  @override
  String get aboutDataSecurity => 'Data security';

  @override
  String get aboutStudyQuestions => 'Study questions';

  @override
  String get aboutStudyResults => 'Study results';

  @override
  String get aboutWithdraw => 'How to withdraw from study';

  @override
  String get aboutETC => 'Something not listed in the above about the study or app';

  @override
  String aboutEmail(String email) {
    return 'Please contact us at: $email';
  }

  @override
  String get aboutMeetTitle => 'Meet the Team';

  @override
  String get preStudySeeing => 'Why am I seeing this:';

  @override
  String get preStudySeeingExp => 'If you are on this page, it\'s because you indicated that you were willing to participate in the Blue Meal Study (BMS). If you feel this is incorrect, please let us know at help@symplifysolutions.com.';

  @override
  String get preStudyEnrollTitle => 'Ready to Start?';

  @override
  String get preStudyEnrollDescPartOne => 'If you have read and understand these instructions and are ready to begin the study, click the button below. This will take you directly to Step 1 of the study.';

  @override
  String get preStudyEnrollDescPartTwo => 'You can access these instructions again at any time by pressing the icon with the \"i\" at the top of the page.';

  @override
  String get preStudyEnrollButton => 'I am ready to start Step 1';

  @override
  String get inStudySeeingExp => 'Note: If you are returning to this page, please make sure to complete all the steps in the study flow. If you have any questions or concerns, don\'t hesitate to contact us at help@symplifysolutions.com.';

  @override
  String get inStudyWithdrawTitle => 'Withdraw from Study';

  @override
  String get inStudyWithdrawDesc => 'You may withdraw at any time by clicking the withdrawal button below. This notifies the research team of your wish to stop participating.';

  @override
  String get inStudyWithdrawButtonText => 'Withdraw from study';

  @override
  String get studyProgessionOne => 'Eat Blue Meal';

  @override
  String get studyProgessionTwo => 'Track BM';

  @override
  String get studyProgessionThree => 'Eat Blue Meal';

  @override
  String get studyProgessionFour => 'Track BM';

  @override
  String stepClickWarning(String step) {
    return '$step is not yet active';
  }

  @override
  String get amountConsumedQuestion => 'How much of the blue meal was eaten?';

  @override
  String get amountConsumedUnable => 'Unable to determine amount consumed';

  @override
  String get amountConsumedHalfOrLess => 'Less than half of blue meal';

  @override
  String get amountConsumedHalf => 'Half of blue meal';

  @override
  String get amountConsumedHalfOrMore => 'More than half of blue meal';

  @override
  String get amountConsumedAll => 'All of blue meal';

  @override
  String get mealCompleteTitle => 'Meal Duration';

  @override
  String mealCompleteStartTime(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Start Time: $dateString $timeString';
  }

  @override
  String get mealCompleteDuration => 'Eating Duration:';

  @override
  String get mealCompleteAmountConsumed => 'Amount Eaten:';

  @override
  String get recordingStateTitle => 'Bowel Movement Recording';

  @override
  String get stepOneCompletedText => 'Step 1 - Completed';

  @override
  String get stepTwoCompletedText => 'Step 2 - Completed';

  @override
  String get stepTwoCompletedSubText => 'Start Step 3';

  @override
  String stepTwoCompletedTimeText(String time) {
    return 'in $time';
  }

  @override
  String get stepThreeCompletedText => 'Step 3 - Completed';

  @override
  String get stepFourCompletedText => 'Step 4 - Completed';

  @override
  String get stepFourCompletedSubText => 'You have completed the Blue Meal Study. Thank you for your participation!';

  @override
  String get studyRecordBMButton => 'Record BM';

  @override
  String get studyInfoButtonLabel => 'Review Study Info';

  @override
  String get studyExpTitle => 'About the study';

  @override
  String get studyExpBody => 'This study measures gut motility (the movement of food through the digestive system) in people with Phelan-McDermid Syndrome using a novel blue meal test. It involves eating blue muffins and tracking bowel movements to determine transit time, which is the duration it takes for food to move through the digestive system, from consumption to excretion. The study will measure transit time twice using the blue muffins and this mobile app.';

  @override
  String get studyExpBodyCont => 'During the study, you will be asked to report various gastrointestinal (GI) signs and symptoms using this app. While bowel movements are the primary focus of the study, we highly encourage you to track all relevant information, including:';

  @override
  String get studyBodySymptomOne => 'Meal times (not a symptom, but important for context)';

  @override
  String get studyBodySymptomTwo => 'Pain';

  @override
  String get studyBodySymptomThree => 'Reflux';

  @override
  String get studyBodySymptomFour => 'Neurological behavior';

  @override
  String get studyEligibilityTitle => 'Eligibility';

  @override
  String get studyEligibilityParticipants => 'Participants must:';

  @override
  String get studyEligibilityOne => 'Have Phelan-McDermid Syndrome';

  @override
  String get studyEligibilityTwo => 'Be 4 years of age or older';

  @override
  String get studyEligibilityThree => 'Live in the United States';

  @override
  String get studyEligibilityFour => 'Have an English-speaking caregiver to track symptoms';

  @override
  String get studyFlowTitle => 'Study Flow';

  @override
  String get studyFlowDesc => 'The study consists of a pre-study phase, preparation, and two transit time measurements:';

  @override
  String get studyFlowPreStudy => 'Pre-Study:';

  @override
  String get studyFlowPreStudyOne => 'Complete the onboarding questionnaire';

  @override
  String get studyFlowPreStudyTwo => 'Track GI symptoms, using this app, for at least 7 days before starting Step 1 (eating the blue meal).';

  @override
  String get studyFlowPrepTitle => 'Preparation:';

  @override
  String get studyFlowPrepOne => 'You will receive 4 blue muffins. Store them in the freezer until ready to use.';

  @override
  String get studyFlowPrepTwo => 'Muffins contain gluten-free flour, protein powder, egg whites, jam, sugar, and blue food coloring.';

  @override
  String get studyFlowStepOneTitle => 'Step 1: Eat Blue Meal (Transit Time 1)';

  @override
  String get studyFlowStepOnePartOne => 'After a 6-8 hour overnight fast, feed the participant 2 blue muffins.';

  @override
  String get studyFlowStepOnePartTwo => 'Start the in-app timer when they begin eating. Stop when they finish. This records the muffin eating time.';

  @override
  String get studyFlowStepTwoTitle => 'Step 2: Record Bowel Movements (Transit Time 1)';

  @override
  String get studyFlowStepTwoPartOne => 'After the blue meal, record all bowel movements (BMs).';

  @override
  String get studyFlowStepTwoPartTwo => 'Note the color, consistency, and any other symptoms for each BM.';

  @override
  String get studyFlowStepTwoPartThree => 'Continue until a brown BM occurs after a blue one.';

  @override
  String get studyFlowBetweenStepTwoStepThree => 'Between Step 2 & Step 3:';

  @override
  String get studyFlowBetweenStepTwoStepThreeDesc => 'Wait 7 days after completing steps 1 and 2 before staring Step 3.';

  @override
  String get studyFlowStepThreeTitle => 'Step 3: Eat Blue Meal (Transit Time 2)';

  @override
  String get studyFlowStepThreeDesc => 'As in Step 1, after a 6-8 hour overnight fast, feed the participant the remaining 2 blue muffins. Again, start the in-app timer when they begin eating and stop when they finish to record eating time.';

  @override
  String get studyFlowStepFourTitle => 'Step 4: Record Bowel Movements (Transit Time 2)';

  @override
  String get studyFlowStepFourDesc => 'As in Step 2, after the second blue meal, record all bowel movements (BMs). Continue to note the color, consistency, and any other symptoms for each BM. Record until a brown BM occurs following a blue one.';

  @override
  String get studyFlowComplete => 'After completing Step 4, your participation is complete!';

  @override
  String get studyContactTitle => 'Contact Us';

  @override
  String get studyContactBody => 'Questions or problems? Email help@symplifysolutions.com with \"Blue Meal Study\" in the subject line.';

  @override
  String get transitOneLabel => 'Transit Time 1';

  @override
  String get transitTwoLabel => 'Transit Time 2';

  @override
  String get studyStepOneExplanationTitle => 'Step 1: Eat Blue Meal';

  @override
  String get studyStepOneExplanationPreReq => 'Before starting, ensure that the participant has completed a 6-8 hour fast.';

  @override
  String get studyStepOneExplanationPartOne => 'Take two of the four blue muffins provided for the study.';

  @override
  String get studyStepOneExplanationPartTwo => 'Feed the two blue muffins to the participant.';

  @override
  String get studyStepOneExplanationPartThree => 'As soon as the participant starts eating the muffins, press the \"Start Timer\" button below to begin recording the eating time.';

  @override
  String get studyStepOneExplanationPartFour => 'Once the participant has finished eating the muffins, press the \"Stop Timer\" button to stop recording the eating time.';

  @override
  String get studyStepOneExplanationNote => 'Note: If you make a mistake while timing the participant, press the \"Reset\" button to clear the timer.';

  @override
  String get studyStepTwoExplanationTitle => 'Step 2: Record Bowel Movements';

  @override
  String get studyStepTwoExplanationDesc => 'After the participant consumes the two blue muffins, track their bowel movements (BMs) using one of the following methods:';

  @override
  String get studyStepTwoExplanationPartOne => '1. On this page (Study Tab): Click \"Record BM\" button to log each BM, noting:';

  @override
  String get studyStepTwoExplanationPartOneDetailOne => 'Date and time';

  @override
  String get studyStepTwoExplanationPartOneDetailTwo => 'Presence or absence of blue-green color';

  @override
  String get studyStepTwoExplanationPartOneDetailThree => 'Other relevant details (e.g., consistency, symptoms)';

  @override
  String get studyStepTwoExplanationPartTwo => '2. On the Track Tab:';

  @override
  String get studyStepTwoExplanationPartTwoDetailOne => 'Press the \"Bowel Movement\" button to record each BM';

  @override
  String get studyStepTwoExplanationPartTwoDetailTwo => 'Fill in the required information, including the presence or absence of blue-green color';

  @override
  String get studyStepTwoExplanationColorExp => 'Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non-blue BM occurs. The system will automatically complete Step 2 once you record a non-blue BM after a blue-green one.';

  @override
  String get studyStepTwoExplanationProgress => 'After submitting, you will have completed the first half of the study. You can begin the second half in 7 days.';

  @override
  String get studyStepThreeExplanationTitle => 'Step 3: Eat Blue Meal';

  @override
  String get studyStepThreeExplanationPreReq => 'Before starting, ensure that the participant has completed a 6-8 hour fast';

  @override
  String get studyStepThreeExplanationPartOne => 'Feed the participant the remaining two blue muffins.';

  @override
  String get studyStepThreeExplanationPartTwo => 'Record the start and end time of the meal using the timer below.';

  @override
  String get studyStepFourExplanationTitle => 'Step 4: Record Bowel Movements';

  @override
  String get studyStepFourExplanationDesc => 'After the participant consumes the two blue muffins, track their bowel movements (BMs) as follows:';

  @override
  String get studyStepFourExplanationPartOne => 'Record each BM, noting the date, time, and presence or absence of blue-green color.';

  @override
  String get studyStepFourExplanationPartTwo => 'Continue recording all BMs until a non-blue BM occurs after a blue-green one.';

  @override
  String get studyStepFourExplanationPartThree => 'The system will automatically submit your recordings once you record the first normal-colored BM after the blue one.';

  @override
  String get studyStepFourExplanationCompletedNotice => 'Once the system submits your recordings, you will have completed the Blue Meal Study. Thank you for your participation!';

  @override
  String get studyResetLabel => 'Reset';

  @override
  String get studyPlayLabel => 'Start';

  @override
  String get studyPauseLabel => 'Stop';

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
  String get testTab => 'Study';

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
  String undoEntry(String symptomType, DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Added $symptomType on $dateString at $timeString';
  }

  @override
  String recordUsername(String symptomType, String username) {
    return 'for $username';
  }

  @override
  String recordHeader(String symptomType) {
    return 'Recording $symptomType';
  }

  @override
  String get nextButton => 'Next';

  @override
  String get firstPageError => 'No previous page';

  @override
  String get bristolLevel => 'Select the stool type that most closely resembles the bowel movement.';

  @override
  String get painLocation => 'Select the location (s) of the pain below';

  @override
  String get painLevel => 'Select the pain level';

  @override
  String get painLevelBM => 'Select the pain during the bowel movement if applicable';

  @override
  String get selectInstruction => 'Select all the signs and symptoms that apply';

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
  String get mealTimerTitle => 'Time Tracking';

  @override
  String get errorPreventionTitle => 'Wait!';

  @override
  String get errorPreventionLineOne => 'Are you sure you want to leave this screen?';

  @override
  String errorPreventionLineTwo(String symptomType) {
    return 'You have unsaved information entered for this $symptomType entry. If you leave this screen now, your changes will be discarded. Do you want to stay on this page and save your changes or leave without saving?';
  }

  @override
  String get errorPreventionLeave => 'Discard Changes';

  @override
  String get errorPreventionStay => 'Stay and Save';

  @override
  String get blueDyeHeader => 'Blue Meal Study';

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
  String get behaviorsLabel => 'Behaviors';

  @override
  String get descriptionLabel => 'Description';

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
