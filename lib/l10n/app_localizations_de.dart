import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

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
  String get preStudySeeingExp => 'If you are on this page, it\'s because you indicated that you were willing to participate in the Blue Meal Study (BMS). If you feel this is incorrect, please let us know at BlueMeal@iu.edu.';

  @override
  String get preStudyEnrollTitle => 'Ready to Start?';

  @override
  String get preStudyEnrollDescPartOne => 'If you have read and understand these instructions and are ready to begin the study, click the button below. This will take you directly to Step 1 of the study.';

  @override
  String get preStudyEnrollDescPartTwo => 'You can access these instructions again at any time by pressing the icon with the \"i\" at the top of the page.';

  @override
  String get preStudyEnrollButton => 'I am ready to start Step 1';

  @override
  String get inStudySeeingExp => 'Note: If you are returning to this page, please make sure to complete all the steps in the study flow. If you have any questions or concerns, don\'t hesitate to contact us at BlueMeal@iu.edu.';

  @override
  String get inStudyWithdrawTitle => 'Withdraw from Study';

  @override
  String get inStudyWithdrawDesc => 'You may withdraw at any time by clicking the withdrawal button below. This notifies the research team of your wish to stop participating.';

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
  String get stepFourCompletedSubText => 'You have completed the Blue Meal Study. Thank you for your participation!';

  @override
  String get studyRecordBMButton => 'Record a Bowel Movement';

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
  String get studyContactBody => 'Questions or problems? Email [email@university.edu] with \"Blue Meal Study\" in the subject line.';

  @override
  String get transitOneLabel => 'Transit Time 1';

  @override
  String get transitTwoLabel => 'Transit Time 2';

  @override
  String get blueMealWaitTimeTitle => 'Step 2 Completed';

  @override
  String get blueMealWaitTimeLineOne => 'You have successfully completed Step 2 by recording a bowel movement with no blue color.';

  @override
  String get blueMealWaitTimeLineTwo => 'This countdown shows how long before another Blue Dye Meal should be attempted again.';

  @override
  String get blueMealWaitTimeLineThree => 'You may add when you are eligible to begin Step 3 to your calendar.';

  @override
  String get blueMealFastHeader => 'Step 1: Eat Blue Meal';

  @override
  String get blueMealFastQuestion => 'Before starting, has the participant completed the required 6-8 hour fast?';

  @override
  String get blueMealFastInstructionLineOne => 'Feed the (2) blue muffins to the participant';

  @override
  String get blueMealFastInstructionLineTwo => 'Record how long it takes the participant to eat the (2) muffins';

  @override
  String get blueMealFastInstructionLineThree => 'Once the participant has finished eating the (2) muffins, please record how much was eaten.';

  @override
  String get blueMealDurationTitle => 'Meal Duration';

  @override
  String get blueMealDurationQuestion => 'How long did the participant take to eat the (2) muffins?';

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
  String get blueMealRecordInstructions => 'To record a Bowel Movement, go to the Study tab and tap record, or go to the record tab and select Bowel Movement.';

  @override
  String blueMealRecordDescription(String step) {
    return 'After participant consumes two blue muffins, track their bowel movements (BMs). Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non blue-green BM occurs. At this point $step is complete.';
  }

  @override
  String get studyStepOneExplanationTitle => 'Step 1: Eat Blue Meal (Transit Time 1)';

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
  String get studyStepTwoExplanationTitle => 'Step 2: Record Bowel Movements (Transit Time 1)';

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
  String get studyStepThreeExplanationTitle => 'Step 3: Eat Blue Meal (Transit Time 2)';

  @override
  String get studyStepThreeExplanationPreReq => 'Before starting, ensure that the participant has completed a 6-8 hour fast';

  @override
  String get studyStepThreeExplanationPartOne => 'Feed the participant the remaining two blue muffins.';

  @override
  String get studyStepThreeExplanationPartTwo => 'Record the start and end time of the meal using the timer below.';

  @override
  String get studyStepFourExplanationTitle => 'Step 4: Record Bowel Movements (Transit Time 2)';

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
  String get bristolLevel => 'Select the stool type that most closely resembles the bowel movement.';

  @override
  String get painLocation => 'Select the location (s) of the pain below';

  @override
  String get painLevel => 'Select the pain level';

  @override
  String get painLevelBM => 'Select the pain during the bowel movement if applicable';

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
  String get mealTimerTitle => 'Time Tracking';

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
  String get blueDyeHeader => 'Blauer Meal Study';

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
  String get behaviorsLabel => 'Verhaltensweisen';

  @override
  String get descriptionLabel => 'Beschreibung';

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
