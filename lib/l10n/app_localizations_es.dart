// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get checkInLabel => 'Revisiones';

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
  String get aboutLineOne =>
      'STRiPES is a symptom tracker that collects information on altered movement of food through the gut (aka motility), pain, bowel movements(BM) and reflux of patients with Phelan-McDermid Syndrome (PMS).';

  @override
  String get aboutLineTwo =>
      'The data will then be used in studies to further our understanding on gastrointestinal issues in patients with PMS.';

  @override
  String get aboutLineThree =>
      'If you want to learn more about the studies STRiPES is collecting data for, please click the link below:';

  @override
  String get aboutQuestionsTitle => 'Questions and/or concerns?';

  @override
  String get aboutCategoriesTitle =>
      'If at any moment you have questions regarding thing such as:';

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
  String get aboutETC =>
      'Something not listed in the above about the study or app';

  @override
  String aboutEmail(String email) {
    return 'Please contact us at: $email';
  }

  @override
  String get aboutMeetTitle => 'Meet the Team';

  @override
  String get preStudySeeing => 'Why am I seeing this:';

  @override
  String get preStudySeeingExp =>
      'If you are on this page, it\'s because you indicated that you were willing to participate in the Blue Meal Study (BMS). If you feel this is incorrect, please let us know at BlueMeal@iu.edu.';

  @override
  String get preStudyEnrollTitle => 'Ready to Start?';

  @override
  String get preStudyEnrollDescPartOne =>
      'If you have read and understand these instructions and are ready to begin the study, click the button below. This will take you directly to Step 1 of the study.';

  @override
  String get preStudyEnrollDescPartTwo =>
      'You can access these instructions again at any time by pressing the icon with the \"i\" at the top of the page.';

  @override
  String get preStudyEnrollButton => 'I am ready to start Step 1';

  @override
  String get inStudySeeingExp =>
      'Note: If you are returning to this page, please make sure to complete all the steps in the study flow. If you have any questions or concerns, don\'t hesitate to contact us at BlueMeal@iu.edu.';

  @override
  String get inStudyWithdrawTitle => 'Withdraw from Study';

  @override
  String get inStudyWithdrawDesc =>
      'You may withdraw at any time by clicking the withdrawal button below. This notifies the research team of your wish to stop participating.';

  @override
  String get inStudyWithdrawButtonText => 'Withdraw from study';

  @override
  String get studyProgessionOne => 'Step 1\nEat Blue\nMeal';

  @override
  String get studyProgessionTwo => 'Step 2\nTrack BM';

  @override
  String get studyProgessionThree => 'Step 3\nEat Blue\nMeal';

  @override
  String get studyProgessionFour => 'Step 4\nTrack BM';

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
  String get stepFourCompletedSubText =>
      'You have completed the Blue Meal Study. Thank you for your participation!';

  @override
  String get studyRecordBMButton => 'Record BM';

  @override
  String get studyInfoButtonLabel => 'Review Study Info';

  @override
  String get studyExpTitle => 'About the study';

  @override
  String get studyExpBody =>
      'This study measures gut motility (the movement of food through the digestive system) in people with Phelan-McDermid Syndrome using a novel blue meal test. It involves eating blue muffins and tracking bowel movements to determine transit time, which is the duration it takes for food to move through the digestive system, from consumption to excretion. The study will measure transit time twice using the blue muffins and this mobile app.';

  @override
  String get studyExpBodyCont =>
      'During the study, you will be asked to report various gastrointestinal (GI) signs and symptoms using this app. While bowel movements are the primary focus of the study, we highly encourage you to track all relevant information, including:';

  @override
  String get studyBodySymptomOne =>
      'Meal times (not a symptom, but important for context)';

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
  String get studyEligibilityFour =>
      'Have an English-speaking caregiver to track symptoms';

  @override
  String get studyFlowTitle => 'Study Flow';

  @override
  String get studyFlowDesc =>
      'The study consists of a pre-study phase, preparation, and two transit time measurements:';

  @override
  String get studyFlowPreStudy => 'Pre-Study:';

  @override
  String get studyFlowPreStudyOne => 'Complete the onboarding questionnaire';

  @override
  String get studyFlowPreStudyTwo =>
      'Track GI symptoms, using this app, for at least 7 days before starting Step 1 (eating the blue meal).';

  @override
  String get studyFlowPrepTitle => 'Preparation:';

  @override
  String get studyFlowPrepOne =>
      'You will receive 4 blue muffins. Store them in the freezer until ready to use.';

  @override
  String get studyFlowPrepTwo =>
      'Muffins contain gluten-free flour, protein powder, egg whites, jam, sugar, and blue food coloring.';

  @override
  String get studyFlowStepOneTitle => 'Step 1: Eat Blue Meal (Transit Time 1)';

  @override
  String get studyFlowStepOnePartOne =>
      'After a 6-8 hour overnight fast, feed the participant 2 blue muffins.';

  @override
  String get studyFlowStepOnePartTwo =>
      'Start the in-app timer when they begin eating. Stop when they finish. This records the muffin eating time.';

  @override
  String get studyFlowStepTwoTitle =>
      'Step 2: Record Bowel Movements (Transit Time 1)';

  @override
  String get studyFlowStepTwoPartOne =>
      'After the blue meal, record all bowel movements (BMs).';

  @override
  String get studyFlowStepTwoPartTwo =>
      'Note the color, consistency, and any other symptoms for each BM.';

  @override
  String get studyFlowStepTwoPartThree =>
      'Continue until a brown BM occurs after a blue one.';

  @override
  String get studyFlowBetweenStepTwoStepThree => 'Between Step 2 & Step 3:';

  @override
  String get studyFlowBetweenStepTwoStepThreeDesc =>
      'Wait 7 days after completing steps 1 and 2 before staring Step 3.';

  @override
  String get studyFlowStepThreeTitle =>
      'Step 3: Eat Blue Meal (Transit Time 2)';

  @override
  String get studyFlowStepThreeDesc =>
      'As in Step 1, after a 6-8 hour overnight fast, feed the participant the remaining 2 blue muffins. Again, start the in-app timer when they begin eating and stop when they finish to record eating time.';

  @override
  String get studyFlowStepFourTitle =>
      'Step 4: Record Bowel Movements (Transit Time 2)';

  @override
  String get studyFlowStepFourDesc =>
      'As in Step 2, after the second blue meal, record all bowel movements (BMs). Continue to note the color, consistency, and any other symptoms for each BM. Record until a brown BM occurs following a blue one.';

  @override
  String get studyFlowComplete =>
      'After completing Step 4, your participation is complete!';

  @override
  String get studyContactTitle => 'Contact Us';

  @override
  String get studyContactBody =>
      'Questions or problems? Email BlueMeal@iu.edu with \"Blue Meal Study\" in the subject line.';

  @override
  String get transitOneLabel => 'Transit Time 1';

  @override
  String get transitTwoLabel => 'Transit Time 2';

  @override
  String get blueMealWaitTimeTitle => 'Step 2 Completed';

  @override
  String get blueMealWaitTimeLineOne =>
      'You have successfully completed Step 2 by recording a bowel movement with no blue color.';

  @override
  String get blueMealWaitTimeLineTwo =>
      'This countdown shows how long before another Blue Dye Meal should be attempted again.';

  @override
  String get blueMealWaitTimeLineThree =>
      'You may add when you are eligible to begin Step 3 to your calendar.';

  @override
  String get blueMealFastHeader => 'Step 1: Eat Blue Meal';

  @override
  String get blueMealFastQuestion =>
      'Before starting, has the participant completed the required 6-8 hour fast?';

  @override
  String get blueMealFastInstructionLineOne =>
      'Feed the (2) blue muffins to the participant';

  @override
  String get blueMealFastInstructionLineTwo =>
      'Record how long it takes the participant to eat the (2) muffins';

  @override
  String get blueMealFastInstructionLineThree =>
      'Once the participant has finished eating the (2) muffins, please record how much was eaten.';

  @override
  String get blueMealDurationTitle => 'Meal Duration';

  @override
  String get blueMealDurationQuestion =>
      'How long did the participant take to eat the (2) muffins?';

  @override
  String get blueMealDurationAnswerOne => '15 minutes or less';

  @override
  String get blueMealDurationAnswerTwo => '15 to 30 minutes';

  @override
  String get blueMealDurationAnswerThree => '30 minutes to 1 hour';

  @override
  String get blueMealDurationAnswerFour => 'Over 1 hour';

  @override
  String get blueMealAmountConsumedTitle => 'About the meal';

  @override
  String get blueMealRecordInstructions =>
      'To record a Bowel Movement, go to the Study tab and tap record, or go to the record tab and select Bowel Movement.';

  @override
  String blueMealRecordDescription(String step) {
    return 'After participant consumes two blue muffins, track their bowel movements (BMs). Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non blue-green BM occurs. At this point $step is complete.';
  }

  @override
  String get studyStepOneExplanationTitle =>
      'Step 1: Eat Blue Meal (Transit Time 1)';

  @override
  String get studyStepOneExplanationPreReq =>
      'Before starting, ensure that the participant has completed a 6-8 hour fast.';

  @override
  String get studyStepOneExplanationPartOne =>
      'Take two of the four blue muffins provided for the study.';

  @override
  String get studyStepOneExplanationPartTwo =>
      'Feed the two blue muffins to the participant.';

  @override
  String get studyStepOneExplanationPartThree =>
      'As soon as the participant starts eating the muffins, press the \"Start Timer\" button below to begin recording the eating time.';

  @override
  String get studyStepOneExplanationPartFour =>
      'Once the participant has finished eating the muffins, press the \"Stop Timer\" button to stop recording the eating time.';

  @override
  String get studyStepOneExplanationNote =>
      'Note: If you make a mistake while timing the participant, press the \"Reset\" button to clear the timer.';

  @override
  String get studyStepTwoExplanationTitle =>
      'Step 2: Record Bowel Movements (Transit Time 1)';

  @override
  String get studyStepTwoExplanationDesc =>
      'After the participant consumes the two blue muffins, track their bowel movements (BMs) using one of the following methods:';

  @override
  String get studyStepTwoExplanationPartOne =>
      '1. On this page (Study Tab): Click \"Record BM\" button to log each BM, noting:';

  @override
  String get studyStepTwoExplanationPartOneDetailOne => 'Date and time';

  @override
  String get studyStepTwoExplanationPartOneDetailTwo =>
      'Presence or absence of blue-green color';

  @override
  String get studyStepTwoExplanationPartOneDetailThree =>
      'Other relevant details (e.g., consistency, symptoms)';

  @override
  String get studyStepTwoExplanationPartTwo => '2. On the Track Tab:';

  @override
  String get studyStepTwoExplanationPartTwoDetailOne =>
      'Press the \"Bowel Movement\" button to record each BM';

  @override
  String get studyStepTwoExplanationPartTwoDetailTwo =>
      'Fill in the required information, including the presence or absence of blue-green color';

  @override
  String get studyStepTwoExplanationColorExp =>
      'Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non-blue BM occurs. The system will automatically complete Step 2 once you record a non-blue BM after a blue-green one.';

  @override
  String get studyStepTwoExplanationProgress =>
      'After submitting, you will have completed the first half of the study. You can begin the second half in 7 days.';

  @override
  String get studyStepThreeExplanationTitle =>
      'Step 3: Eat Blue Meal (Transit Time 2)';

  @override
  String get studyStepThreeExplanationPreReq =>
      'Before starting, ensure that the participant has completed a 6-8 hour fast';

  @override
  String get studyStepThreeExplanationPartOne =>
      'Feed the participant the remaining two blue muffins.';

  @override
  String get studyStepThreeExplanationPartTwo =>
      'Record the start and end time of the meal using the timer below.';

  @override
  String get studyStepFourExplanationTitle =>
      'Step 4: Record Bowel Movements (Transit Time 2)';

  @override
  String get studyStepFourExplanationDesc =>
      'After the participant consumes the two blue muffins, track their bowel movements (BMs) as follows:';

  @override
  String get studyStepFourExplanationPartOne =>
      'Record each BM, noting the date, time, and presence or absence of blue-green color.';

  @override
  String get studyStepFourExplanationPartTwo =>
      'Continue recording all BMs until a non-blue BM occurs after a blue-green one.';

  @override
  String get studyStepFourExplanationPartThree =>
      'The system will automatically submit your recordings once you record the first normal-colored BM after the blue one.';

  @override
  String get studyStepFourExplanationCompletedNotice =>
      'Once the system submits your recordings, you will have completed the Blue Meal Study. Thank you for your participation!';

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
    return '$symptomType Dokumentation';
  }

  @override
  String get nextButton => 'Next';

  @override
  String get firstPageError => 'No previous page';

  @override
  String get bristolLevel =>
      'Select the stool type that most closely resembles the bowel movement.';

  @override
  String get painLocation => 'Select the location (s) of the pain below';

  @override
  String get painLevel => 'Select the pain level';

  @override
  String get painLevelBM =>
      'Select the pain during the bowel movement if applicable';

  @override
  String get selectInstruction => 'Completa esta sección';

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
      other: 'Missing $countString entries',
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
  String get submitBlueQuestion =>
      'Did this bowel movement contain any blue color?';

  @override
  String get submitBlueQuestionError =>
      'Must answer blue question before submitting';

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
  String get errorPreventionLineOne =>
      'Are you sure you want to leave this screen?';

  @override
  String errorPreventionLineTwo(String symptomType) {
    return 'You will lose all information you entered for this $symptomType entry.';
  }

  @override
  String get errorPreventionLeave => 'Leave';

  @override
  String get errorPreventionStay => 'Stay';

  @override
  String get discardEntryTitle => '¿Descartar cambios?';

  @override
  String get discardEntryDescription => 'Se perderán los cambios sin guardar.';

  @override
  String get discardEntryKeep => 'Seguir editando';

  @override
  String get discardEntryDiscard => 'Descartar cambios';

  @override
  String get blueDyeHeader => 'Blue Meal Study';

  @override
  String get blueDyeInfoHeader => 'Blue Dye Test Info';

  @override
  String get blueDyeInfoLineOne =>
      'The Blue Dye Test measures the time it takes for food to transit through the gut.';

  @override
  String get blueDyeInfoLineTwo =>
      'To start the test, your participant(s) should eat two blue muffins in the morning after a minimum of a six hour fasting period.';

  @override
  String get blueDyeInfoLineThree =>
      'Record bowel movements, noting whether there is a blue blue-green color.';

  @override
  String get blueDyeInfoLineFour =>
      'Submit test after recording the first BM that lacks any blue or blue green color.';

  @override
  String get blueDyeInstructionsHeader => 'Instructions';

  @override
  String get blueDyeInstructionsStepOne => '1) Eat Muffins';

  @override
  String get blueDyeInstructionsStepOneA =>
      'When your participant starts eating muffins, select “Start Blue Meal';

  @override
  String get blueDyeInstructionsStepOneB =>
      'When your participant is done eating select \'Finished Blue Meal\'';

  @override
  String get blueDyeInstructionsStepTwo => '2) Record Bowel Movements (BMs)';

  @override
  String get blueDyeInstructionsStepTwoA =>
      'Log BMs from the Record page and indicate whether or not the BM has any (even partial) blue or blue green color.';

  @override
  String get blueDyeInstructionsStepTwoB =>
      'It is common for the first couple of BMs after eating the muffin to not show blue yet.';

  @override
  String get blueDyeInstructionsStepThree => '3) Submit the Test';

  @override
  String get blueDyeInstructionsStepThreeA =>
      'Submit test after recording the first BM that lacks any blue or blue green color.';

  @override
  String get blueMuffinsInfoHeader => 'Blue Muffins Info';

  @override
  String get blueMuffinsInfoLineOne => 'Blue muffins will come in the mail.';

  @override
  String get blueMuffinsInfoLineTwo =>
      'They can be stored in the refrigerator.';

  @override
  String get blueMuffinsInfoLineThree =>
      'To get ready for the test, remove the muffins from their packaging and heat them briefly, 20-30 seconds in the microwave or a few minutes in the oven.';

  @override
  String get blueMuffinsInfoLineFour =>
      'Muffins should be the first thing the participant eats in the morning after an overnight fast of at least 6 hours.';

  @override
  String get blueDyeCancel => 'Cancel Test';

  @override
  String get blueMuffinErrorPreventionLineOne =>
      'Are you sure you want to cancel your Blue Dye Test?';

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
  String get blueDyeLogsInstructionOne =>
      'Record bowel movements from the record screen.';

  @override
  String get blueDyeLogsInstructionTwo =>
      ' Recorded bowel movements will appear below';

  @override
  String get blueDyeLogsSubmitTest => 'Submit Test';

  @override
  String get blueDyeLogsSubmitTestError =>
      'Record a normal colored bowel movement before submitting';

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
  String historyEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
      zero: 'Sin registros',
    );
    return '$_temp0';
  }

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
  String get exportDialog =>
      'Data will be sent to the study coordinators. None of your personal information is included.\nIf there are any changes in the future you may export again.';

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
  String get behaviorsLabel => 'Respuestas';

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
  String get patientProfilesInstruction =>
      'Select a patient to view their profile.';

  @override
  String get patientBirthYear => 'Birth Year';

  @override
  String get patientGender => 'Gender';

  @override
  String get patientRole => 'Role';

  @override
  String get stampDeleteWarningOne => 'Are you sure you want to delete?';

  @override
  String get stampDeleteWarningTwo =>
      'You will lose all information for this entry.';

  @override
  String get stampDeleteConfirm => 'Confirm';

  @override
  String get stampDeleteCancel => 'Cancel';

  @override
  String get exitStudy => 'Exit Study';

  @override
  String get exitStudyWarning =>
      'When you exit the study all exported data will be deleted and your access code will be invalidated';

  @override
  String get passwordConfirm => 'Confirmar contraseña';

  @override
  String get exportDataTitle => 'Export Data';

  @override
  String get exportOptionCsv => 'CSV Export';

  @override
  String get exportOptionCsvDesc => 'Raw data in spreadsheet format';

  @override
  String get exportOptionReport => 'Summary Report';

  @override
  String get exportOptionReportDesc => 'PDF report with summary statistics';

  @override
  String get csvExportTitle => 'CSV Export';

  @override
  String get csvExportPreview => 'Export Preview';

  @override
  String get csvTotalRows => 'Total Rows';

  @override
  String get csvDetailEntries => 'Responses';

  @override
  String get csvBlueDyeTests => 'Blue Dye Transits';

  @override
  String get csvFilesToGenerate => 'Files to Generate';

  @override
  String csvEntriesWithRows(int count, int rows) {
    return '$count entries with $rows rows';
  }

  @override
  String csvBlueDyeTestResults(int count) {
    return '$count Blue Dye Transits';
  }

  @override
  String get csvSampleData => 'Sample Data';

  @override
  String get csvNoDetailEntries => 'No detail entries to preview';

  @override
  String get csvExportButton => 'Export CSV';

  @override
  String get csvExporting => 'Exporting...';

  @override
  String csvExportFailed(String error) {
    return 'Failed to export: $error';
  }

  @override
  String get reportTitle => 'Summary Report';

  @override
  String get reportPreview => 'Report Preview';

  @override
  String get reportTotalEntries => 'Total Entries';

  @override
  String get reportDaysWithData => 'Days with Data';

  @override
  String get reportCategories => 'Categories';

  @override
  String get reportEntriesByCategory => 'Entries by Category';

  @override
  String get reportContents => 'Report Contents';

  @override
  String get reportContentsDesc =>
      'The PDF report will include:\n• Summary statistics for the selected period\n• Breakdown by entry category\n• Response distributions and averages\n• Blue Dye test results (if available)';

  @override
  String get reportGeneratePdf => 'Generate PDF';

  @override
  String get reportGenerating => 'Generating...';

  @override
  String reportGenerationFailed(String error) {
    return 'Failed to generate report: $error';
  }

  @override
  String get tableHeaderDate => 'Date';

  @override
  String get tableHeaderType => 'Category';

  @override
  String get tableHeaderResponse => 'Response';

  @override
  String entriesCount(int count) {
    return '$count entries';
  }

  @override
  String get questionSetsTitle => 'Flujos de registro';

  @override
  String get questionSetsSubtitle =>
      'Adapta el registro de experiencias, rutinas y eventos';

  @override
  String get newQuestionSet => 'Nuevo flujo';

  @override
  String get newQuestionSetTitle => 'Nuevo flujo de registro';

  @override
  String get newQuestionSetDescription =>
      'Crea un flujo que se adapte a cómo quieres registrar una experiencia, rutina o evento.';

  @override
  String get questionSetName => 'Nombre del flujo';

  @override
  String get questionSetNameHint => 'Por ejemplo, Hora de comer';

  @override
  String get questionSetNameRequired =>
      'Introduce un nombre para este flujo de registro';

  @override
  String get recordTiming => '¿Cuándo se puede registrar?';

  @override
  String get recordTimingHelp =>
      'Esto controla dónde y con qué frecuencia está disponible el flujo.';

  @override
  String get eventBased => 'Basado en eventos';

  @override
  String get eventBasedDescription => 'Se inicia cuando eliges registrarlo';

  @override
  String get dailyTiming => 'Diario';

  @override
  String get weeklyTiming => 'Semanal';

  @override
  String get monthlyTiming => 'Mensual';

  @override
  String get yearlyTiming => 'Anual';

  @override
  String get scheduledDescription => 'Aparece según un horario recurrente';

  @override
  String get createQuestionSet => 'Crear flujo de registro';

  @override
  String questionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '$_temp0';
  }

  @override
  String sectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secciones',
      one: '1 sección',
    );
    return '$_temp0';
  }

  @override
  String get customLabel => 'Personalizado';

  @override
  String get reorderAndGroup => 'Ordenar y agrupar';

  @override
  String get reorderHelp =>
      'Arrastra las preguntas para ordenarlas o moverlas entre secciones.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get addQuestion => 'Añadir pregunta';

  @override
  String get previewFlow => 'Probar flujo';

  @override
  String get previewQuestion => 'Probar pregunta';

  @override
  String get previewMode => 'Modo de vista previa';

  @override
  String get previewModeDescription =>
      'Prueba este flujo sin guardar respuestas.';

  @override
  String get closePreview => 'Cerrar vista previa';

  @override
  String get previousButton => 'Anterior';

  @override
  String get doneButton => 'Listo';

  @override
  String sectionNumber(int number) {
    return 'Sección $number';
  }

  @override
  String get newSection => 'Nueva sección';

  @override
  String get alwaysShownFirst => 'Siempre se muestra primero';

  @override
  String get alwaysShown => 'Siempre visible';

  @override
  String get conditionalLabel => 'Condicional';

  @override
  String get editRule => 'Editar regla';

  @override
  String get addRule => 'Añadir regla';

  @override
  String get visibilityRuleTitle => '¿Cuándo se muestra esta sección?';

  @override
  String get visibilityRuleDescription =>
      'Usa respuestas de secciones anteriores para decidir si aparece esta sección.';

  @override
  String get questionVisibilityRuleTitle => '¿Cuándo se muestra esta pregunta?';

  @override
  String get questionVisibilityRuleDescription =>
      'Usa una respuesta de una pregunta anterior para decidir si aparece esta pregunta.';

  @override
  String get ruleOrderingError =>
      'Una regla de visibilidad hace referencia a una pregunta que ya no aparece antes en el flujo. Edita la regla o vuelve a mover la pregunta de origen.';

  @override
  String get saveRule => 'Guardar regla';

  @override
  String get alwaysShow => 'Mostrar siempre';

  @override
  String get addQuestionTitle => 'Nueva pregunta';

  @override
  String get addQuestionDescription =>
      'Elige qué registrar y dónde aparece en este flujo.';

  @override
  String get questionTypeLabel => 'Tipo de respuesta';

  @override
  String get questionPromptLabel => 'Pregunta';

  @override
  String get questionPromptHint => '¿Qué te gustaría registrar?';

  @override
  String get responseRange => 'Rango de respuesta';

  @override
  String get minimumLabel => 'Mínimo';

  @override
  String get maximumLabel => 'Máximo';

  @override
  String get optionsLabel => 'Opciones de respuesta';

  @override
  String optionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opciones',
      one: '1 opción',
    );
    return '$_temp0';
  }

  @override
  String get optionLabel => 'Opción';

  @override
  String get addOption => 'Añadir opción';

  @override
  String get questionPromptRequired => 'Introduce una pregunta';

  @override
  String get rangeRequired => 'Introduce un rango válido';

  @override
  String get rangeInvalid => 'El máximo debe ser mayor que el mínimo';

  @override
  String get optionRequired => 'Añade al menos una opción';

  @override
  String get createQuestion => 'Añadir pregunta';

  @override
  String get continueButton => 'Continuar';

  @override
  String get questionSetDetailsStep => 'Detalles';

  @override
  String get questionsStep => 'Crear flujo';

  @override
  String get questionsStepDescription =>
      'Crea secciones y añade en cada una lo que quieras registrar, en el orden adecuado.';

  @override
  String get addFirstQuestion => 'Añade al menos una pregunta para continuar.';

  @override
  String get reviewStep => 'Revisar';

  @override
  String get reviewQuestionSet => 'Revisa tu flujo de registro';

  @override
  String get reviewQuestionSetDescription =>
      'Prueba el flujo completo y créalo cuando todo esté correcto.';

  @override
  String get questionSetCreationFailed =>
      'No se pudo crear el flujo de registro. No se guardaron cambios.';

  @override
  String get addSection => 'Añadir sección';

  @override
  String get emptySectionDropHere => 'Arrastra una pregunta aquí';

  @override
  String get emptySectionSaveError =>
      'Añade una pregunta a cada sección o elimina la sección vacía.';

  @override
  String get moveSectionUp => 'Mover sección hacia arriba';

  @override
  String get moveSectionDown => 'Mover sección hacia abajo';

  @override
  String get removeEmptySection => 'Eliminar sección vacía';

  @override
  String get buildFlowStep => 'Crear flujo';

  @override
  String get recordFlowDetailsTitle => 'Describe este flujo';

  @override
  String get buildFlowTitle => 'Crea tu flujo de registro';

  @override
  String creationStepLabel(int current, int total, String label) {
    return 'Paso $current de $total · $label';
  }

  @override
  String get addQuestionToSection => 'Añadir pregunta a esta sección';

  @override
  String get sectionEmptyDescription =>
      'Añade una pregunta para definir qué aparece en esta sección.';

  @override
  String get renameSection => 'Cambiar nombre de la sección';

  @override
  String get sectionName => 'Nombre de la sección';

  @override
  String get sectionNameDescription =>
      'Usa un encabezado breve que ayude a entender esta parte del flujo.';

  @override
  String get sectionNameRequired => 'Introduce un nombre para la sección';

  @override
  String get moveQuestion => 'Mover pregunta a otra sección';

  @override
  String get reorderOrMoveQuestion => 'Ordenar o mover pregunta';

  @override
  String get moveQuestionUp => 'Mover pregunta hacia arriba';

  @override
  String get moveQuestionDown => 'Mover pregunta hacia abajo';

  @override
  String moveToSection(String section) {
    return 'Mover a $section';
  }

  @override
  String get deleteQuestionFromDraft => 'Eliminar pregunta';

  @override
  String get appearsInSection => 'Aparece en la sección';

  @override
  String get placementTitle => 'Ubicación';

  @override
  String get placementDescription =>
      'Elige la sección en la que aparecerá esta pregunta.';

  @override
  String get questionContentTitle => '¿Qué se preguntará?';

  @override
  String get questionContentDescription =>
      'Usa un lenguaje claro que tenga sentido durante un registro.';

  @override
  String get responseSetupTitle => '¿Cómo se puede responder?';

  @override
  String get responseSetupDescription =>
      'Elige un formato de respuesta y configúralo debajo.';

  @override
  String get optionsEditorHelp =>
      'Añade al menos dos opciones. Puedes editarlas y arrastrarlas para ordenarlas.';

  @override
  String optionNumber(int number) {
    return 'Opción $number';
  }

  @override
  String get removeOption => 'Eliminar opción';

  @override
  String get optionsMinimumRequired =>
      'Añade al menos dos opciones de respuesta completas';

  @override
  String get optionsMustBeUnique =>
      'Cada opción de respuesta debe ser diferente';

  @override
  String get optionCommaUnsupported =>
      'Las opciones de respuesta no pueden contener comas';

  @override
  String get customQuestionLabel => 'Pregunta personalizada';

  @override
  String get customRecordFlowLabel => 'Flujo de registro personalizado';

  @override
  String get recordFlowSettings => 'Configuración del flujo de registro';

  @override
  String get backToRecordFlows => 'Volver a los flujos de registro';

  @override
  String get noRecordFlowSelected =>
      'No hay ningún flujo de registro seleccionado';

  @override
  String get recordFlowNotFound => 'No se encontró el flujo de registro';

  @override
  String get builtInFlowStructure => 'Estructura de flujo integrada';

  @override
  String get builtInFlowStructureDescription =>
      'Las preguntas y secciones están administradas por la aplicación. Puedes cambiar su visibilidad cuando esté permitido.';

  @override
  String get questionSettingsTitle => 'Configuración de la pregunta';

  @override
  String get questionCardLabel => 'PREGUNTA';

  @override
  String get showInCheckIns => 'Mostrar en los registros';

  @override
  String get settingManagedByApp =>
      'Esta opción está administrada por la aplicación';

  @override
  String get hideQuestionDescription =>
      'Desactívala para ocultar esta pregunta sin eliminarla';

  @override
  String get showRecordFlow => 'Mostrar flujo de registro';

  @override
  String get hideRecordFlowDescription =>
      'Desactívalo para ocultar este flujo del menú de registro sin eliminarlo';

  @override
  String get responseRequirementTitle => 'Requisito de respuesta';

  @override
  String get optionalResponseDescription =>
      'Opcional · esta respuesta se puede omitir';

  @override
  String get requiredResponseDescription =>
      'Obligatoria · hay una regla de respuesta configurada';

  @override
  String get builtInQuestionLabel => 'Pregunta integrada';

  @override
  String get builtInQuestionDescription =>
      'La aplicación administra la pregunta. Puedes cambiar su visibilidad cuando esté permitido.';

  @override
  String get questionTypeCheck => 'Casilla';

  @override
  String get questionTypeSlider => 'Control deslizante';

  @override
  String get questionTypeMultipleChoice => 'Opción única';

  @override
  String get questionTypeAllThatApply => 'Selección múltiple';

  @override
  String get questionTypeFreeResponse => 'Respuesta escrita';

  @override
  String get conditionNoConditions =>
      'Aún no hay condiciones. Esta sección siempre se mostrará.';

  @override
  String get conditionChooseStart => 'Elige cómo empezar';

  @override
  String get conditionOne => 'Una condición';

  @override
  String get conditionSeveral => 'Varias condiciones';

  @override
  String get conditionQuestion => 'Pregunta';

  @override
  String get conditionLabel => 'Condición';

  @override
  String get conditionHasResponse => 'Tiene una respuesta';

  @override
  String get conditionEquals => 'Es igual a';

  @override
  String get conditionContainsSelection => 'Contiene la selección';

  @override
  String get conditionContainsText => 'Contiene el texto';

  @override
  String get conditionMatch => 'Cumplir';

  @override
  String get conditionAll => 'TODAS';

  @override
  String get conditionAny => 'ALGUNA';

  @override
  String get conditionOf => 'de estas';

  @override
  String get conditionAnd => 'Y';

  @override
  String get conditionOr => 'O';

  @override
  String get conditionAdd => 'Condición';

  @override
  String get conditionNestedGroup => 'Grupo anidado';

  @override
  String get conditionRemoveGroup => 'Eliminar grupo';

  @override
  String get conditionRemove => 'Eliminar condición';

  @override
  String get conditionAnswerIs => 'La respuesta es';

  @override
  String get conditionExactMatch => 'Debe coincidir exactamente';

  @override
  String get conditionValueEquals => 'El valor es igual a';

  @override
  String get conditionUnsupported =>
      'Esta condición no está disponible para este tipo de respuesta';

  @override
  String get flowBuilderHelp =>
      'Añade preguntas abajo. Las secciones agrupan preguntas en una pantalla; las reglas de visibilidad muestran preguntas de seguimiento cuando se necesitan.';

  @override
  String get flowListHelp =>
      'Conjuntos de preguntas que definen lo que registras. Abre un flujo para ver y personalizar sus preguntas.';

  @override
  String get builtInFlowLabel => 'Integrado';

  @override
  String get hiddenFlowLabel => 'Oculto';

  @override
  String get editFlowQuestions => 'Editar preguntas';

  @override
  String get ruleNeedsEarlierQuestion =>
      'Add a question to an earlier section to create a rule.';

  @override
  String get readingPreferencesTitle => 'Preferencias de lectura';

  @override
  String get displaySettingsTitle => 'Ajustes de visualización';

  @override
  String get detailLayoutTitle => 'Diseño de los detalles';

  @override
  String get detailLayoutAutomatic => 'Automático';

  @override
  String get detailLayoutAutomaticDescription =>
      'Se adapta al tamaño del texto y al espacio disponible.';

  @override
  String get detailLayoutStacked => 'Pregunta sobre la respuesta';

  @override
  String get detailLayoutStackedDescription =>
      'Muestra siempre cada pregunta encima de su respuesta, usando todo el ancho.';

  @override
  String get detailLayoutDeviceNote =>
      'Se aplica a las respuestas guardadas de todos los perfiles en este dispositivo.';

  @override
  String get detailLayoutSaveError =>
      'No se pudo cargar o guardar esta preferencia. Selecciona una opción para intentarlo de nuevo.';

  @override
  String get detailAnswerSelected => 'Seleccionado';

  @override
  String get detailAnswerUndetermined => 'Sin determinar';

  @override
  String get historyEditEntry => 'Editar entrada';

  @override
  String get recordSelectCategories => 'Selecciona categorías';

  @override
  String get recordSelectHelp =>
      'Elige todo lo que quieras registrar. Revisarás las entradas antes de guardarlas.';

  @override
  String get recordDateAndTime => 'Fecha y hora';

  @override
  String get recordDetails => 'Detalles';

  @override
  String get recordReviewAndSave => 'Revisar y guardar';

  @override
  String get recordToday => 'Hoy';

  @override
  String get recordYesterday => 'Ayer';

  @override
  String get recordEarlier => 'Antes';

  @override
  String get recordSameTime => 'La misma hora para todo';

  @override
  String get recordSeparateTimes => 'Horas diferentes';

  @override
  String get recordSharedTimeHelp =>
      'Esta hora se aplica a todas las categorías seleccionadas.';

  @override
  String get recordSeparateTimeHelp =>
      'Cada categoría conserva su propia hora y precisión.';

  @override
  String get recordExactTime => 'Hora exacta';

  @override
  String get recordTimeOfDay => 'Momento del día';

  @override
  String get recordNotSure => 'No lo sé';

  @override
  String get recordTimeUnknown => 'Hora desconocida';

  @override
  String get recordChoosePeriod => 'Elige un momento del día';

  @override
  String get recordEarlyMorning => 'Madrugada';

  @override
  String get recordMorning => 'Mañana';

  @override
  String get recordAfternoon => 'Tarde';

  @override
  String get recordEvening => 'Atardecer';

  @override
  String get recordNight => 'Noche';

  @override
  String get recordUnknownTimeHelp =>
      'Solo se registrará la fecha. No tienes que adivinar la hora.';

  @override
  String get recordStudyExactTime =>
      'Esta entrada del estudio necesita una hora exacta. Elige horas diferentes para usar horas aproximadas en otras categorías.';

  @override
  String get recordInvalidTime =>
      'Elige una hora válida para cada categoría. Las entradas no pueden estar en el futuro.';

  @override
  String get recordReviewHelp =>
      'Comprueba la fecha, las horas y las respuestas antes de guardar.';

  @override
  String get recordSaveAll => 'Guardar entradas';

  @override
  String get recordReturnToReview => 'Volver a la revisión';

  @override
  String get recordNotes => '¿Algo más que añadir?';

  @override
  String get recordPainLevelUnknown =>
      'No se puede determinar la intensidad del dolor';

  @override
  String get recordEdit => 'Editar';

  @override
  String get recordBack => 'Atrás';

  @override
  String get recordRetry => 'Intentar de nuevo';

  @override
  String get recordLoadError => 'No se pudo cargar el formulario.';

  @override
  String get recordNoCategories =>
      'No hay categorías disponibles para este perfil.';

  @override
  String get recordProfileChanged =>
      'El perfil activo ha cambiado. Vuelve al perfil original para continuar este borrador.';

  @override
  String get recordRequiredAnswers =>
      'Completa las preguntas obligatorias antes de continuar.';

  @override
  String get recordSaved => 'Tus entradas se han guardado.';

  @override
  String get recordSaveError =>
      'No se pudieron guardar todas las entradas. El borrador sigue aquí; inténtalo de nuevo.';

  @override
  String get recordStudyUpdateError =>
      'Tus entradas están guardadas, pero no se pudo actualizar el estudio. Inténtalo de nuevo para completar la actualización.';

  @override
  String get recordSaving => 'Guardando…';

  @override
  String get recordStart => 'Registrar una entrada';

  @override
  String get recordMultipleHint => 'Registra una o varias categorías juntas';

  @override
  String get recordSelectionRetained =>
      'Las respuestas se conservan si desmarcas y vuelves a marcar una categoría. Solo se guardarán las categorías seleccionadas.';

  @override
  String get recordStudyChanged =>
      'El estudio ha cambiado desde que empezaste este borrador. Inicia una nueva entrada para usar las preguntas actuales.';

  @override
  String get recordPartialSaveError =>
      'Es posible que algunas entradas ya estén guardadas. Reintenta para terminar sin duplicados. Al salir, las entradas guardadas permanecen en el historial.';

  @override
  String get recordLeave => 'Salir del registro';

  @override
  String get recordCategoryMealHint => 'Desayuno, almuerzo, cena o tentempiés';

  @override
  String get recordCategoryPainHint =>
      'Señales de dolor, ubicación e intensidad';

  @override
  String get recordCategoryBowelHint =>
      'Tipo de heces, esfuerzo, gases o hinchazón';

  @override
  String get recordCategoryGiHint => 'Arcadas, vómitos o dificultad para comer';

  @override
  String get recordCategorySleepHint =>
      'Problemas de sueño, cambios de ánimo o conducta';

  @override
  String get recordStudyExactTimeOnly =>
      'Esta entrada del estudio necesita una hora exacta.';

  @override
  String recordPageCount(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get recordFollowUpAdded =>
      'Tu respuesta añadió una página de preguntas de seguimiento.';

  @override
  String get recordFollowUpPage => 'Preguntas de seguimiento';

  @override
  String get recordQuestionRequired => 'Obligatorio';

  @override
  String get recordQuestionInvalid =>
      'Revisa esta respuesta antes de continuar.';

  @override
  String recordNextCategory(String category) {
    return 'Siguiente: $category';
  }

  @override
  String recordCategoryCount(int current, int total) {
    return 'Categoría $current de $total';
  }

  @override
  String get recordViewFollowUps => 'Ver preguntas añadidas';

  @override
  String get recordFollowUpsAdded => 'Añadidas según tu respuesta';

  @override
  String get painIntensityNone => 'Sin dolor';

  @override
  String get painIntensityModerate => 'Moderado';

  @override
  String get painIntensityWorst => 'El peor dolor posible';

  @override
  String get painIntensityNotSure => 'No estoy seguro/a';
}
