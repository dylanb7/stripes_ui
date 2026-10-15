import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @checkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get checkInLabel;

  /// No description provided for @signupWithAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Sign up with access code'**
  String get signupWithAccessCode;

  /// No description provided for @loginButtonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get loginButtonPrefix;

  /// No description provided for @loginButtonText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonText;

  /// No description provided for @useWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Use without account'**
  String get useWithoutAccount;

  /// No description provided for @passwordText.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordText;

  /// No description provided for @loginText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginText;

  /// No description provided for @forgotPasswordText.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordText;

  /// No description provided for @resetPasswordText.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordText;

  /// No description provided for @noAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Do not have an account?'**
  String get noAccountPrefix;

  /// No description provided for @noAccountText.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get noAccountText;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmail;

  /// No description provided for @createAccountText.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountText;

  /// No description provided for @viewMoreButtonText.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMoreButtonText;

  /// No description provided for @viewLessButtonText.
  ///
  /// In en, this message translates to:
  /// **'View Less'**
  String get viewLessButtonText;

  /// No description provided for @noDateToAddTo.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get noDateToAddTo;

  /// No description provided for @dateRangeButton.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get dateRangeButton;

  /// No description provided for @eventFilterGroupsTag.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get eventFilterGroupsTag;

  /// No description provided for @calendarVisibilityWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarVisibilityWeek;

  /// No description provided for @calendarVisibilityMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarVisibilityMonth;

  /// No description provided for @calendarVisibilityHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get calendarVisibilityHidden;

  /// No description provided for @stripesName.
  ///
  /// In en, this message translates to:
  /// **'STRiPES'**
  String get stripesName;

  /// No description provided for @aboutStripes.
  ///
  /// In en, this message translates to:
  /// **'About STRiPES'**
  String get aboutStripes;

  /// No description provided for @aboutLineOne.
  ///
  /// In en, this message translates to:
  /// **'STRiPES is a symptom tracker that collects information on altered movement of food through the gut (aka motility), pain, bowel movements(BM) and reflux of patients with Phelan-McDermid Syndrome (PMS).'**
  String get aboutLineOne;

  /// No description provided for @aboutLineTwo.
  ///
  /// In en, this message translates to:
  /// **'The data will then be used in studies to further our understanding on gastrointestinal issues in patients with PMS.'**
  String get aboutLineTwo;

  /// No description provided for @aboutLineThree.
  ///
  /// In en, this message translates to:
  /// **'If you want to learn more about the studies STRiPES is collecting data for, please click the link below:'**
  String get aboutLineThree;

  /// No description provided for @aboutQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions and/or concerns?'**
  String get aboutQuestionsTitle;

  /// No description provided for @aboutCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'If at any moment you have questions regarding thing such as:'**
  String get aboutCategoriesTitle;

  /// No description provided for @aboutDataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data collection'**
  String get aboutDataCollection;

  /// No description provided for @aboutDataSecurity.
  ///
  /// In en, this message translates to:
  /// **'Data security'**
  String get aboutDataSecurity;

  /// No description provided for @aboutStudyQuestions.
  ///
  /// In en, this message translates to:
  /// **'Study questions'**
  String get aboutStudyQuestions;

  /// No description provided for @aboutStudyResults.
  ///
  /// In en, this message translates to:
  /// **'Study results'**
  String get aboutStudyResults;

  /// No description provided for @aboutWithdraw.
  ///
  /// In en, this message translates to:
  /// **'How to withdraw from study'**
  String get aboutWithdraw;

  /// No description provided for @aboutETC.
  ///
  /// In en, this message translates to:
  /// **'Something not listed in the above about the study or app'**
  String get aboutETC;

  /// No description provided for @aboutEmail.
  ///
  /// In en, this message translates to:
  /// **'Please contact us at: {email}'**
  String aboutEmail(String email);

  /// No description provided for @aboutMeetTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet the Team'**
  String get aboutMeetTitle;

  /// No description provided for @preStudySeeing.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing this:'**
  String get preStudySeeing;

  /// No description provided for @preStudySeeingExp.
  ///
  /// In en, this message translates to:
  /// **'If you are on this page, it\'s because you indicated that you were willing to participate in the Blue Meal Study (BMS). If you feel this is incorrect, please let us know at BlueMeal@iu.edu.'**
  String get preStudySeeingExp;

  /// No description provided for @preStudyEnrollTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start?'**
  String get preStudyEnrollTitle;

  /// No description provided for @preStudyEnrollDescPartOne.
  ///
  /// In en, this message translates to:
  /// **'If you have read and understand these instructions and are ready to begin the study, click the button below. This will take you directly to Step 1 of the study.'**
  String get preStudyEnrollDescPartOne;

  /// No description provided for @preStudyEnrollDescPartTwo.
  ///
  /// In en, this message translates to:
  /// **'You can access these instructions again at any time by pressing the icon with the \"i\" at the top of the page.'**
  String get preStudyEnrollDescPartTwo;

  /// No description provided for @preStudyEnrollButton.
  ///
  /// In en, this message translates to:
  /// **'I am ready to start Step 1'**
  String get preStudyEnrollButton;

  /// No description provided for @inStudySeeingExp.
  ///
  /// In en, this message translates to:
  /// **'Note: If you are returning to this page, please make sure to complete all the steps in the study flow. If you have any questions or concerns, don\'t hesitate to contact us at BlueMeal@iu.edu.'**
  String get inStudySeeingExp;

  /// No description provided for @inStudyWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw from Study'**
  String get inStudyWithdrawTitle;

  /// No description provided for @inStudyWithdrawDesc.
  ///
  /// In en, this message translates to:
  /// **'You may request withdrawal at any time by clicking the withdraw button below. This composes an email to the research team of your wish to stop participating.'**
  String get inStudyWithdrawDesc;

  /// No description provided for @inStudyWithdrawButtonText.
  ///
  /// In en, this message translates to:
  /// **'Withdraw from study'**
  String get inStudyWithdrawButtonText;

  /// No description provided for @studyProgessionOne.
  ///
  /// In en, this message translates to:
  /// **'Eat Blue Meal'**
  String get studyProgessionOne;

  /// No description provided for @studyProgessionTwo.
  ///
  /// In en, this message translates to:
  /// **'Track BM'**
  String get studyProgessionTwo;

  /// No description provided for @studyProgessionThree.
  ///
  /// In en, this message translates to:
  /// **'Eat Blue Meal'**
  String get studyProgessionThree;

  /// No description provided for @studyProgessionFour.
  ///
  /// In en, this message translates to:
  /// **'Track BM'**
  String get studyProgessionFour;

  /// No description provided for @stepClickWarning.
  ///
  /// In en, this message translates to:
  /// **'{step} is not yet active'**
  String stepClickWarning(String step);

  /// No description provided for @amountConsumedQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much of the blue meal was eaten?'**
  String get amountConsumedQuestion;

  /// No description provided for @amountConsumedUnable.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine amount consumed'**
  String get amountConsumedUnable;

  /// No description provided for @amountConsumedHalfOrLess.
  ///
  /// In en, this message translates to:
  /// **'Less than half of blue meal'**
  String get amountConsumedHalfOrLess;

  /// No description provided for @amountConsumedHalf.
  ///
  /// In en, this message translates to:
  /// **'Half of blue meal'**
  String get amountConsumedHalf;

  /// No description provided for @amountConsumedHalfOrMore.
  ///
  /// In en, this message translates to:
  /// **'More than half of blue meal'**
  String get amountConsumedHalfOrMore;

  /// No description provided for @amountConsumedAll.
  ///
  /// In en, this message translates to:
  /// **'All of blue meal'**
  String get amountConsumedAll;

  /// No description provided for @mealCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Duration'**
  String get mealCompleteTitle;

  /// No description provided for @mealCompleteStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time: {date} {time}'**
  String mealCompleteStartTime(DateTime date, DateTime time);

  /// No description provided for @mealCompleteDuration.
  ///
  /// In en, this message translates to:
  /// **'Eating Duration:'**
  String get mealCompleteDuration;

  /// No description provided for @mealCompleteAmountConsumed.
  ///
  /// In en, this message translates to:
  /// **'Amount Eaten:'**
  String get mealCompleteAmountConsumed;

  /// No description provided for @recordingStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Bowel Movement Recording'**
  String get recordingStateTitle;

  /// No description provided for @stepOneCompletedText.
  ///
  /// In en, this message translates to:
  /// **'Step 1 - Completed'**
  String get stepOneCompletedText;

  /// No description provided for @stepTwoCompletedText.
  ///
  /// In en, this message translates to:
  /// **'Step 2 - Completed'**
  String get stepTwoCompletedText;

  /// No description provided for @stepTwoCompletedSubText.
  ///
  /// In en, this message translates to:
  /// **'Start Step 3'**
  String get stepTwoCompletedSubText;

  /// No description provided for @stepTwoCompletedTimeText.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String stepTwoCompletedTimeText(String time);

  /// No description provided for @stepThreeCompletedText.
  ///
  /// In en, this message translates to:
  /// **'Step 3 - Completed'**
  String get stepThreeCompletedText;

  /// No description provided for @stepFourCompletedText.
  ///
  /// In en, this message translates to:
  /// **'Step 4 - Completed'**
  String get stepFourCompletedText;

  /// No description provided for @stepFourCompletedSubText.
  ///
  /// In en, this message translates to:
  /// **'You have completed the Blue Meal Study. Thank you for your participation!'**
  String get stepFourCompletedSubText;

  /// No description provided for @studyRecordBMButton.
  ///
  /// In en, this message translates to:
  /// **'Record BM'**
  String get studyRecordBMButton;

  /// No description provided for @studyInfoButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Review Study Info'**
  String get studyInfoButtonLabel;

  /// No description provided for @studyExpTitle.
  ///
  /// In en, this message translates to:
  /// **'About the study'**
  String get studyExpTitle;

  /// No description provided for @studyExpBody.
  ///
  /// In en, this message translates to:
  /// **'This study measures gut motility (the movement of food through the digestive system) in people with Phelan-McDermid Syndrome using a novel blue meal test. It involves eating blue muffins and tracking bowel movements to determine transit time, which is the duration it takes for food to move through the digestive system, from consumption to excretion. The study will measure transit time twice using the blue muffins and this mobile app.'**
  String get studyExpBody;

  /// No description provided for @studyExpBodyCont.
  ///
  /// In en, this message translates to:
  /// **'During the study, you will be asked to report various gastrointestinal (GI) signs and symptoms using this app. While bowel movements are the primary focus of the study, we highly encourage you to track all relevant information, including:'**
  String get studyExpBodyCont;

  /// No description provided for @studyBodySymptomOne.
  ///
  /// In en, this message translates to:
  /// **'Meal times (not a symptom, but important for context)'**
  String get studyBodySymptomOne;

  /// No description provided for @studyBodySymptomTwo.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get studyBodySymptomTwo;

  /// No description provided for @studyBodySymptomThree.
  ///
  /// In en, this message translates to:
  /// **'Reflux'**
  String get studyBodySymptomThree;

  /// No description provided for @studyBodySymptomFour.
  ///
  /// In en, this message translates to:
  /// **'Neurological behavior'**
  String get studyBodySymptomFour;

  /// No description provided for @studyEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get studyEligibilityTitle;

  /// No description provided for @studyEligibilityParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants must:'**
  String get studyEligibilityParticipants;

  /// No description provided for @studyEligibilityOne.
  ///
  /// In en, this message translates to:
  /// **'Have Phelan-McDermid Syndrome'**
  String get studyEligibilityOne;

  /// No description provided for @studyEligibilityTwo.
  ///
  /// In en, this message translates to:
  /// **'Be 4 years of age or older'**
  String get studyEligibilityTwo;

  /// No description provided for @studyEligibilityThree.
  ///
  /// In en, this message translates to:
  /// **'Live in the United States'**
  String get studyEligibilityThree;

  /// No description provided for @studyEligibilityFour.
  ///
  /// In en, this message translates to:
  /// **'Have an English-speaking caregiver to track symptoms'**
  String get studyEligibilityFour;

  /// No description provided for @studyFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Flow'**
  String get studyFlowTitle;

  /// No description provided for @studyFlowDesc.
  ///
  /// In en, this message translates to:
  /// **'The study consists of a pre-study phase, preparation, and two transit time measurements:'**
  String get studyFlowDesc;

  /// No description provided for @studyFlowPreStudy.
  ///
  /// In en, this message translates to:
  /// **'Pre-Study:'**
  String get studyFlowPreStudy;

  /// No description provided for @studyFlowPreStudyOne.
  ///
  /// In en, this message translates to:
  /// **'Complete the onboarding questionnaire'**
  String get studyFlowPreStudyOne;

  /// No description provided for @studyFlowPreStudyTwo.
  ///
  /// In en, this message translates to:
  /// **'Track GI symptoms, using this app, for at least 7 days before starting Step 1 (eating the blue meal).'**
  String get studyFlowPreStudyTwo;

  /// No description provided for @studyFlowPrepTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation:'**
  String get studyFlowPrepTitle;

  /// No description provided for @studyFlowPrepOne.
  ///
  /// In en, this message translates to:
  /// **'You will receive 4 blue muffins. Store them in the freezer until ready to use.'**
  String get studyFlowPrepOne;

  /// No description provided for @studyFlowPrepTwo.
  ///
  /// In en, this message translates to:
  /// **'Muffins contain gluten-free flour, protein powder, egg whites, jam, sugar, and blue food coloring.'**
  String get studyFlowPrepTwo;

  /// No description provided for @studyFlowStepOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Eat Blue Meal (Transit Time 1)'**
  String get studyFlowStepOneTitle;

  /// No description provided for @studyFlowStepOnePartOne.
  ///
  /// In en, this message translates to:
  /// **'After a 6-8 hour overnight fast, feed the participant 2 blue muffins.'**
  String get studyFlowStepOnePartOne;

  /// No description provided for @studyFlowStepOnePartTwo.
  ///
  /// In en, this message translates to:
  /// **'Start the in-app timer when they begin eating. Stop when they finish. This records the muffin eating time.'**
  String get studyFlowStepOnePartTwo;

  /// No description provided for @studyFlowStepTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Record Bowel Movements (Transit Time 1)'**
  String get studyFlowStepTwoTitle;

  /// No description provided for @studyFlowStepTwoPartOne.
  ///
  /// In en, this message translates to:
  /// **'After the blue meal, record all bowel movements (BMs).'**
  String get studyFlowStepTwoPartOne;

  /// No description provided for @studyFlowStepTwoPartTwo.
  ///
  /// In en, this message translates to:
  /// **'Note the color, consistency, and any other symptoms for each BM.'**
  String get studyFlowStepTwoPartTwo;

  /// No description provided for @studyFlowStepTwoPartThree.
  ///
  /// In en, this message translates to:
  /// **'Continue until a brown BM occurs after a blue one.'**
  String get studyFlowStepTwoPartThree;

  /// No description provided for @studyFlowBetweenStepTwoStepThree.
  ///
  /// In en, this message translates to:
  /// **'Between Step 2 & Step 3:'**
  String get studyFlowBetweenStepTwoStepThree;

  /// No description provided for @studyFlowBetweenStepTwoStepThreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Wait 7 days after completing steps 1 and 2 before staring Step 3.'**
  String get studyFlowBetweenStepTwoStepThreeDesc;

  /// No description provided for @studyFlowStepThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Eat Blue Meal (Transit Time 2)'**
  String get studyFlowStepThreeTitle;

  /// No description provided for @studyFlowStepThreeDesc.
  ///
  /// In en, this message translates to:
  /// **'As in Step 1, after a 6-8 hour overnight fast, feed the participant the remaining 2 blue muffins. Again, start the in-app timer when they begin eating and stop when they finish to record eating time.'**
  String get studyFlowStepThreeDesc;

  /// No description provided for @studyFlowStepFourTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Record Bowel Movements (Transit Time 2)'**
  String get studyFlowStepFourTitle;

  /// No description provided for @studyFlowStepFourDesc.
  ///
  /// In en, this message translates to:
  /// **'As in Step 2, after the second blue meal, record all bowel movements (BMs). Continue to note the color, consistency, and any other symptoms for each BM. Record until a brown BM occurs following a blue one.'**
  String get studyFlowStepFourDesc;

  /// No description provided for @studyFlowComplete.
  ///
  /// In en, this message translates to:
  /// **'After completing Step 4, your participation is complete!'**
  String get studyFlowComplete;

  /// No description provided for @studyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get studyContactTitle;

  /// No description provided for @studyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions or problems? Email BlueMeal@iu.edu with \"Blue Meal Study\" in the subject line.'**
  String get studyContactBody;

  /// No description provided for @transitOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Transit Time 1'**
  String get transitOneLabel;

  /// No description provided for @transitTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Transit Time 2'**
  String get transitTwoLabel;

  /// No description provided for @blueMealWaitTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 Completed'**
  String get blueMealWaitTimeTitle;

  /// No description provided for @blueMealWaitTimeLineOne.
  ///
  /// In en, this message translates to:
  /// **'You have successfully completed Step 2 by recording a bowel movement with no blue color.'**
  String get blueMealWaitTimeLineOne;

  /// No description provided for @blueMealWaitTimeLineTwo.
  ///
  /// In en, this message translates to:
  /// **'This countdown shows how long before another Blue Dye Meal should be attempted again.'**
  String get blueMealWaitTimeLineTwo;

  /// No description provided for @blueMealWaitTimeLineThree.
  ///
  /// In en, this message translates to:
  /// **'You may add when you are eligible to begin Step 3 to your calendar.'**
  String get blueMealWaitTimeLineThree;

  /// No description provided for @blueMealFastHeader.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Eat Blue Meal'**
  String get blueMealFastHeader;

  /// No description provided for @blueMealFastQuestion.
  ///
  /// In en, this message translates to:
  /// **'Before starting, has the participant completed the required 6-8 hour fast?'**
  String get blueMealFastQuestion;

  /// No description provided for @blueMealFastInstructionLineOne.
  ///
  /// In en, this message translates to:
  /// **'Feed the (2) blue muffins to the participant'**
  String get blueMealFastInstructionLineOne;

  /// No description provided for @blueMealFastInstructionLineTwo.
  ///
  /// In en, this message translates to:
  /// **'Record how long it takes the participant to eat the (2) muffins'**
  String get blueMealFastInstructionLineTwo;

  /// No description provided for @blueMealFastInstructionLineThree.
  ///
  /// In en, this message translates to:
  /// **'Once the participant has finished eating the (2) muffins, please record how much was eaten.'**
  String get blueMealFastInstructionLineThree;

  /// No description provided for @blueMealDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Duration'**
  String get blueMealDurationTitle;

  /// No description provided for @blueMealDurationQuestion.
  ///
  /// In en, this message translates to:
  /// **'How long did the participant take to eat the (2) muffins?'**
  String get blueMealDurationQuestion;

  /// No description provided for @blueMealDurationAnswerOne.
  ///
  /// In en, this message translates to:
  /// **'15 minutes or less'**
  String get blueMealDurationAnswerOne;

  /// No description provided for @blueMealDurationAnswerTwo.
  ///
  /// In en, this message translates to:
  /// **'15 to 30 minutes'**
  String get blueMealDurationAnswerTwo;

  /// No description provided for @blueMealDurationAnswerThree.
  ///
  /// In en, this message translates to:
  /// **'30 minutes to 1 hour'**
  String get blueMealDurationAnswerThree;

  /// No description provided for @blueMealDurationAnswerFour.
  ///
  /// In en, this message translates to:
  /// **'Over 1 hour'**
  String get blueMealDurationAnswerFour;

  /// No description provided for @blueMealAmountConsumedTitle.
  ///
  /// In en, this message translates to:
  /// **'About the meal'**
  String get blueMealAmountConsumedTitle;

  /// No description provided for @blueMealRecordInstructions.
  ///
  /// In en, this message translates to:
  /// **'To record a Bowel Movement, go to the Study tab and tap record, or go to the record tab and select Bowel Movement.'**
  String get blueMealRecordInstructions;

  /// No description provided for @blueMealRecordDescription.
  ///
  /// In en, this message translates to:
  /// **'After participant consumes two blue muffins, track their bowel movements (BMs). Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non blue-green BM occurs. At this point {step} is complete.'**
  String blueMealRecordDescription(String step);

  /// No description provided for @studyStepOneExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Eat Blue Meal'**
  String get studyStepOneExplanationTitle;

  /// No description provided for @studyStepOneExplanationPreReq.
  ///
  /// In en, this message translates to:
  /// **'Before starting, ensure that the participant has completed a 6-8 hour fast.'**
  String get studyStepOneExplanationPreReq;

  /// No description provided for @studyStepOneExplanationPartOne.
  ///
  /// In en, this message translates to:
  /// **'Take two of the four blue muffins provided for the study.'**
  String get studyStepOneExplanationPartOne;

  /// No description provided for @studyStepOneExplanationPartTwo.
  ///
  /// In en, this message translates to:
  /// **'Feed the two blue muffins to the participant.'**
  String get studyStepOneExplanationPartTwo;

  /// No description provided for @studyStepOneExplanationPartThree.
  ///
  /// In en, this message translates to:
  /// **'As soon as the participant starts eating the muffins, press the \"Start Timer\" button below to begin recording the eating time.'**
  String get studyStepOneExplanationPartThree;

  /// No description provided for @studyStepOneExplanationPartFour.
  ///
  /// In en, this message translates to:
  /// **'Once the participant has finished eating the muffins, press the \"Stop Timer\" button to stop recording the eating time.'**
  String get studyStepOneExplanationPartFour;

  /// No description provided for @studyStepOneExplanationNote.
  ///
  /// In en, this message translates to:
  /// **'Note: If you make a mistake while timing the participant, press the \"Reset\" button to clear the timer.'**
  String get studyStepOneExplanationNote;

  /// No description provided for @studyStepTwoExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Record Bowel Movements'**
  String get studyStepTwoExplanationTitle;

  /// No description provided for @studyStepTwoExplanationDesc.
  ///
  /// In en, this message translates to:
  /// **'After the participant consumes the two blue muffins, track their bowel movements (BMs) using one of the following methods:'**
  String get studyStepTwoExplanationDesc;

  /// No description provided for @studyStepTwoExplanationPartOne.
  ///
  /// In en, this message translates to:
  /// **'1. On this page (Study Tab): Click \"Record BM\" button to log each BM, noting:'**
  String get studyStepTwoExplanationPartOne;

  /// No description provided for @studyStepTwoExplanationPartOneDetailOne.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get studyStepTwoExplanationPartOneDetailOne;

  /// No description provided for @studyStepTwoExplanationPartOneDetailTwo.
  ///
  /// In en, this message translates to:
  /// **'Presence or absence of blue-green color'**
  String get studyStepTwoExplanationPartOneDetailTwo;

  /// No description provided for @studyStepTwoExplanationPartOneDetailThree.
  ///
  /// In en, this message translates to:
  /// **'Other relevant details (e.g., consistency, symptoms)'**
  String get studyStepTwoExplanationPartOneDetailThree;

  /// No description provided for @studyStepTwoExplanationPartTwo.
  ///
  /// In en, this message translates to:
  /// **'2. On the Track Tab:'**
  String get studyStepTwoExplanationPartTwo;

  /// No description provided for @studyStepTwoExplanationPartTwoDetailOne.
  ///
  /// In en, this message translates to:
  /// **'Press the \"Bowel Movement\" button to record each BM'**
  String get studyStepTwoExplanationPartTwoDetailOne;

  /// No description provided for @studyStepTwoExplanationPartTwoDetailTwo.
  ///
  /// In en, this message translates to:
  /// **'Fill in the required information, including the presence or absence of blue-green color'**
  String get studyStepTwoExplanationPartTwoDetailTwo;

  /// No description provided for @studyStepTwoExplanationColorExp.
  ///
  /// In en, this message translates to:
  /// **'Continue recording all BMs, even if not blue-green. After the first blue-green BM, keep tracking until a non-blue BM occurs. The system will automatically complete Step 2 once you record a non-blue BM after a blue-green one.'**
  String get studyStepTwoExplanationColorExp;

  /// No description provided for @studyStepTwoExplanationProgress.
  ///
  /// In en, this message translates to:
  /// **'After submitting, you will have completed the first half of the study. You can begin the second half in 7 days.'**
  String get studyStepTwoExplanationProgress;

  /// No description provided for @studyStepThreeExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Eat Blue Meal'**
  String get studyStepThreeExplanationTitle;

  /// No description provided for @studyStepThreeExplanationPreReq.
  ///
  /// In en, this message translates to:
  /// **'Before starting, ensure that the participant has completed a 6-8 hour fast'**
  String get studyStepThreeExplanationPreReq;

  /// No description provided for @studyStepThreeExplanationPartOne.
  ///
  /// In en, this message translates to:
  /// **'Feed the participant the remaining two blue muffins.'**
  String get studyStepThreeExplanationPartOne;

  /// No description provided for @studyStepThreeExplanationPartTwo.
  ///
  /// In en, this message translates to:
  /// **'Record the start and end time of the meal using the timer below.'**
  String get studyStepThreeExplanationPartTwo;

  /// No description provided for @studyStepFourExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Record Bowel Movements'**
  String get studyStepFourExplanationTitle;

  /// No description provided for @studyStepFourExplanationDesc.
  ///
  /// In en, this message translates to:
  /// **'After the participant consumes the two blue muffins, track their bowel movements (BMs) as follows:'**
  String get studyStepFourExplanationDesc;

  /// No description provided for @studyStepFourExplanationPartOne.
  ///
  /// In en, this message translates to:
  /// **'Record each BM, noting the date, time, and presence or absence of blue-green color.'**
  String get studyStepFourExplanationPartOne;

  /// No description provided for @studyStepFourExplanationPartTwo.
  ///
  /// In en, this message translates to:
  /// **'Continue recording all BMs until a non-blue BM occurs after a blue-green one.'**
  String get studyStepFourExplanationPartTwo;

  /// No description provided for @studyStepFourExplanationPartThree.
  ///
  /// In en, this message translates to:
  /// **'The system will automatically submit your recordings once you record the first normal-colored BM after the blue one.'**
  String get studyStepFourExplanationPartThree;

  /// No description provided for @studyStepFourExplanationCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Once the system submits your recordings, you will have completed the Blue Meal Study. Thank you for your participation!'**
  String get studyStepFourExplanationCompletedNotice;

  /// No description provided for @studyResetLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get studyResetLabel;

  /// No description provided for @studyPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get studyPlayLabel;

  /// No description provided for @studyPauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get studyPauseLabel;

  /// No description provided for @passwordRequirementHeader.
  ///
  /// In en, this message translates to:
  /// **'Password must:'**
  String get passwordRequirementHeader;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Be a minimum of 8 characters long'**
  String get passwordLength;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Include a lowercase letter (a-z)'**
  String get passwordLowercase;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Include an uppercase letter (A-Z)'**
  String get passwordUppercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Include a number (1-9)'**
  String get passwordNumber;

  /// No description provided for @passwordMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMatchError;

  /// No description provided for @emptyFieldText.
  ///
  /// In en, this message translates to:
  /// **'Empty Field'**
  String get emptyFieldText;

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
  /// **'Study'**
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

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'undo'**
  String get undo;

  /// No description provided for @undoEntry.
  ///
  /// In en, this message translates to:
  /// **'Added {symptomType} on {date} at {time}'**
  String undoEntry(String symptomType, DateTime date, DateTime time);

  /// No description provided for @recordUsername.
  ///
  /// In en, this message translates to:
  /// **'for {username}'**
  String recordUsername(String symptomType, String username);

  /// No description provided for @recordHeader.
  ///
  /// In en, this message translates to:
  /// **'Recording {symptomType}'**
  String recordHeader(String symptomType);

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @firstPageError.
  ///
  /// In en, this message translates to:
  /// **'No previous page'**
  String get firstPageError;

  /// No description provided for @bristolLevel.
  ///
  /// In en, this message translates to:
  /// **'Select the stool type that most closely resembles the bowel movement.'**
  String get bristolLevel;

  /// No description provided for @painLocation.
  ///
  /// In en, this message translates to:
  /// **'Select the location (s) of the pain below'**
  String get painLocation;

  /// No description provided for @painLevel.
  ///
  /// In en, this message translates to:
  /// **'Select the pain level'**
  String get painLevel;

  /// No description provided for @painLevelBM.
  ///
  /// In en, this message translates to:
  /// **'Select the pain during the bowel movement if applicable'**
  String get painLevelBM;

  /// No description provided for @selectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Complete this section'**
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
  /// **'{count, plural, =1{Missing entry} other{Missing {count} entries}}'**
  String nLevelError(num count);

  /// No description provided for @moodLowLevel.
  ///
  /// In en, this message translates to:
  /// **'Best Mood'**
  String get moodLowLevel;

  /// No description provided for @moodHighLevel.
  ///
  /// In en, this message translates to:
  /// **'Worst Mood'**
  String get moodHighLevel;

  /// No description provided for @submitHeader.
  ///
  /// In en, this message translates to:
  /// **'Enter information about the {symptomType} entry below'**
  String submitHeader(String symptomType);

  /// No description provided for @editSubmitHeader.
  ///
  /// In en, this message translates to:
  /// **'Information entered about {symptomType}'**
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

  /// No description provided for @mealTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Tracking'**
  String get mealTimerTitle;

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
  /// **'You have unsaved information entered for this {symptomType} entry. If you leave this screen now, your changes will be discarded. Do you want to stay on this page and save your changes or leave without saving?'**
  String errorPreventionLineTwo(String symptomType);

  /// No description provided for @errorPreventionLeave.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get errorPreventionLeave;

  /// No description provided for @errorPreventionStay.
  ///
  /// In en, this message translates to:
  /// **'Stay and Save'**
  String get errorPreventionStay;

  /// No description provided for @discardEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardEntryTitle;

  /// No description provided for @discardEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get discardEntryDescription;

  /// No description provided for @discardEntryKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardEntryKeep;

  /// No description provided for @discardEntryDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardEntryDiscard;

  /// No description provided for @blueDyeHeader.
  ///
  /// In en, this message translates to:
  /// **'Blue Meal Study'**
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

  /// No description provided for @testSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test successfully submitted'**
  String get testSubmitSuccess;

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

  /// No description provided for @historyEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 entry} other{{count} entries}}'**
  String historyEntryCount(int count);

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
  /// **'{count, plural, =0{No Entries} =1{1 Entry} other{{count} Entries}}'**
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
  /// **'Categories'**
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
  /// **'Responses'**
  String get behaviorsLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
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

  /// No description provided for @stampDeleteWarningOne.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get stampDeleteWarningOne;

  /// No description provided for @stampDeleteWarningTwo.
  ///
  /// In en, this message translates to:
  /// **'You will lose all information for this entry.'**
  String get stampDeleteWarningTwo;

  /// No description provided for @stampDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stampDeleteConfirm;

  /// No description provided for @stampDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get stampDeleteCancel;

  /// No description provided for @exitStudy.
  ///
  /// In en, this message translates to:
  /// **'Exit Study'**
  String get exitStudy;

  /// No description provided for @exitStudyWarning.
  ///
  /// In en, this message translates to:
  /// **'When you exit the study all exported data will be deleted and your access code will be invalidated'**
  String get exitStudyWarning;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordConfirm;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataTitle;

  /// No description provided for @exportOptionCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get exportOptionCsv;

  /// No description provided for @exportOptionCsvDesc.
  ///
  /// In en, this message translates to:
  /// **'Raw data in spreadsheet format'**
  String get exportOptionCsvDesc;

  /// No description provided for @exportOptionReport.
  ///
  /// In en, this message translates to:
  /// **'Summary Report'**
  String get exportOptionReport;

  /// No description provided for @exportOptionReportDesc.
  ///
  /// In en, this message translates to:
  /// **'PDF report with summary statistics'**
  String get exportOptionReportDesc;

  /// No description provided for @csvExportTitle.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get csvExportTitle;

  /// No description provided for @csvExportPreview.
  ///
  /// In en, this message translates to:
  /// **'Export Preview'**
  String get csvExportPreview;

  /// No description provided for @csvTotalRows.
  ///
  /// In en, this message translates to:
  /// **'Total Rows'**
  String get csvTotalRows;

  /// No description provided for @csvDetailEntries.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get csvDetailEntries;

  /// No description provided for @csvBlueDyeTests.
  ///
  /// In en, this message translates to:
  /// **'Blue Dye Transits'**
  String get csvBlueDyeTests;

  /// No description provided for @csvFilesToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Files to Generate'**
  String get csvFilesToGenerate;

  /// No description provided for @csvEntriesWithRows.
  ///
  /// In en, this message translates to:
  /// **'{count} entries with {rows} rows'**
  String csvEntriesWithRows(int count, int rows);

  /// No description provided for @csvBlueDyeTestResults.
  ///
  /// In en, this message translates to:
  /// **'{count} Blue Dye Transits'**
  String csvBlueDyeTestResults(int count);

  /// No description provided for @csvSampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample Data'**
  String get csvSampleData;

  /// No description provided for @csvNoDetailEntries.
  ///
  /// In en, this message translates to:
  /// **'No detail entries to preview'**
  String get csvNoDetailEntries;

  /// No description provided for @csvExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get csvExportButton;

  /// No description provided for @csvExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get csvExporting;

  /// No description provided for @csvExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {error}'**
  String csvExportFailed(String error);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary Report'**
  String get reportTitle;

  /// No description provided for @reportPreview.
  ///
  /// In en, this message translates to:
  /// **'Report Preview'**
  String get reportPreview;

  /// No description provided for @reportTotalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get reportTotalEntries;

  /// No description provided for @reportDaysWithData.
  ///
  /// In en, this message translates to:
  /// **'Days with Data'**
  String get reportDaysWithData;

  /// No description provided for @reportCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportCategories;

  /// No description provided for @reportEntriesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Entries by Category'**
  String get reportEntriesByCategory;

  /// No description provided for @reportContents.
  ///
  /// In en, this message translates to:
  /// **'Report Contents'**
  String get reportContents;

  /// No description provided for @reportContentsDesc.
  ///
  /// In en, this message translates to:
  /// **'The PDF report will include:\n• Summary statistics for the selected period\n• Breakdown by entry category\n• Response distributions and averages\n• Blue Dye test results (if available)'**
  String get reportContentsDesc;

  /// No description provided for @reportGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get reportGeneratePdf;

  /// No description provided for @reportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get reportGenerating;

  /// No description provided for @reportGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report: {error}'**
  String reportGenerationFailed(String error);

  /// No description provided for @tableHeaderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tableHeaderDate;

  /// No description provided for @tableHeaderType.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tableHeaderType;

  /// No description provided for @tableHeaderResponse.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get tableHeaderResponse;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String entriesCount(int count);

  /// No description provided for @questionSetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Record flows'**
  String get questionSetsTitle;

  /// No description provided for @questionSetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shape how experiences, routines, and events are recorded'**
  String get questionSetsSubtitle;

  /// No description provided for @newQuestionSet.
  ///
  /// In en, this message translates to:
  /// **'New flow'**
  String get newQuestionSet;

  /// No description provided for @newQuestionSetTitle.
  ///
  /// In en, this message translates to:
  /// **'New record flow'**
  String get newQuestionSetTitle;

  /// No description provided for @newQuestionSetDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a record flow that fits how you want to capture an experience, routine, or event.'**
  String get newQuestionSetDescription;

  /// No description provided for @questionSetName.
  ///
  /// In en, this message translates to:
  /// **'Record flow name'**
  String get questionSetName;

  /// No description provided for @questionSetNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Meal time'**
  String get questionSetNameHint;

  /// No description provided for @questionSetNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this record flow'**
  String get questionSetNameRequired;

  /// No description provided for @recordTiming.
  ///
  /// In en, this message translates to:
  /// **'When can this be recorded?'**
  String get recordTiming;

  /// No description provided for @recordTimingHelp.
  ///
  /// In en, this message translates to:
  /// **'This controls where and how often the record flow is available.'**
  String get recordTimingHelp;

  /// No description provided for @eventBased.
  ///
  /// In en, this message translates to:
  /// **'Event-based'**
  String get eventBased;

  /// No description provided for @eventBasedDescription.
  ///
  /// In en, this message translates to:
  /// **'Started when you choose to record it'**
  String get eventBasedDescription;

  /// No description provided for @dailyTiming.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyTiming;

  /// No description provided for @weeklyTiming.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyTiming;

  /// No description provided for @monthlyTiming.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyTiming;

  /// No description provided for @yearlyTiming.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyTiming;

  /// No description provided for @scheduledDescription.
  ///
  /// In en, this message translates to:
  /// **'Appears on a repeating schedule'**
  String get scheduledDescription;

  /// No description provided for @createQuestionSet.
  ///
  /// In en, this message translates to:
  /// **'Create record flow'**
  String get createQuestionSet;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionsCount(int count);

  /// No description provided for @sectionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 section} other{{count} sections}}'**
  String sectionsCount(int count);

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @reorderAndGroup.
  ///
  /// In en, this message translates to:
  /// **'Reorder & group'**
  String get reorderAndGroup;

  /// No description provided for @reorderHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag questions to reorder them or move them between sections.'**
  String get reorderHelp;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get addQuestion;

  /// No description provided for @previewFlow.
  ///
  /// In en, this message translates to:
  /// **'Preview flow'**
  String get previewFlow;

  /// No description provided for @previewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Preview question'**
  String get previewQuestion;

  /// No description provided for @previewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview mode'**
  String get previewMode;

  /// No description provided for @previewModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Try this flow without saving any responses.'**
  String get previewModeDescription;

  /// No description provided for @closePreview.
  ///
  /// In en, this message translates to:
  /// **'Close preview'**
  String get closePreview;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @sectionNumber.
  ///
  /// In en, this message translates to:
  /// **'Section {number}'**
  String sectionNumber(int number);

  /// No description provided for @newSection.
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get newSection;

  /// No description provided for @alwaysShownFirst.
  ///
  /// In en, this message translates to:
  /// **'Always shown first'**
  String get alwaysShownFirst;

  /// No description provided for @alwaysShown.
  ///
  /// In en, this message translates to:
  /// **'Always shown'**
  String get alwaysShown;

  /// No description provided for @conditionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get conditionalLabel;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get editRule;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @visibilityRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'When do you want to see this section?'**
  String get visibilityRuleTitle;

  /// No description provided for @visibilityRuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your answers from earlier sections to choose when this section appears.'**
  String get visibilityRuleDescription;

  /// No description provided for @questionVisibilityRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'When do you want to see this question?'**
  String get questionVisibilityRuleTitle;

  /// No description provided for @questionVisibilityRuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your earlier answers to choose when this question appears.'**
  String get questionVisibilityRuleDescription;

  /// No description provided for @ruleOrderingError.
  ///
  /// In en, this message translates to:
  /// **'A visibility rule refers to a question that no longer appears earlier in the flow. Edit that rule or move its source question back.'**
  String get ruleOrderingError;

  /// No description provided for @saveRule.
  ///
  /// In en, this message translates to:
  /// **'Save rule'**
  String get saveRule;

  /// No description provided for @alwaysShow.
  ///
  /// In en, this message translates to:
  /// **'Always show'**
  String get alwaysShow;

  /// No description provided for @addQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get addQuestionTitle;

  /// No description provided for @addQuestionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what to record and where it appears in this flow.'**
  String get addQuestionDescription;

  /// No description provided for @questionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Response type'**
  String get questionTypeLabel;

  /// No description provided for @questionPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionPromptLabel;

  /// No description provided for @questionPromptHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to record?'**
  String get questionPromptHint;

  /// No description provided for @responseRange.
  ///
  /// In en, this message translates to:
  /// **'Response range'**
  String get responseRange;

  /// No description provided for @minimumLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimumLabel;

  /// No description provided for @maximumLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximumLabel;

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Response options'**
  String get optionsLabel;

  /// No description provided for @optionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 option} other{{count} options}}'**
  String optionsCount(int count);

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get optionLabel;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @questionPromptRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a question'**
  String get questionPromptRequired;

  /// No description provided for @rangeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid range'**
  String get rangeRequired;

  /// No description provided for @rangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Maximum must be greater than minimum'**
  String get rangeInvalid;

  /// No description provided for @optionRequired.
  ///
  /// In en, this message translates to:
  /// **'Add response options'**
  String get optionRequired;

  /// No description provided for @createQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get createQuestion;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @questionSetDetailsStep.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get questionSetDetailsStep;

  /// No description provided for @questionsStep.
  ///
  /// In en, this message translates to:
  /// **'Build flow'**
  String get questionsStep;

  /// No description provided for @questionsStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Create sections, then add and arrange what you want to record in each one.'**
  String get questionsStepDescription;

  /// No description provided for @addFirstQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question to continue.'**
  String get addFirstQuestion;

  /// No description provided for @reviewStep.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStep;

  /// No description provided for @reviewQuestionSet.
  ///
  /// In en, this message translates to:
  /// **'Review your record flow'**
  String get reviewQuestionSet;

  /// No description provided for @reviewQuestionSetDescription.
  ///
  /// In en, this message translates to:
  /// **'Test the complete flow, then create it when everything looks right.'**
  String get reviewQuestionSetDescription;

  /// No description provided for @questionSetCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'The record flow could not be created. No changes were saved.'**
  String get questionSetCreationFailed;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get addSection;

  /// No description provided for @emptySectionDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drag a question here'**
  String get emptySectionDropHere;

  /// No description provided for @emptySectionSaveError.
  ///
  /// In en, this message translates to:
  /// **'Add a question to every section or remove the empty section.'**
  String get emptySectionSaveError;

  /// No description provided for @moveSectionUp.
  ///
  /// In en, this message translates to:
  /// **'Move section up'**
  String get moveSectionUp;

  /// No description provided for @moveSectionDown.
  ///
  /// In en, this message translates to:
  /// **'Move section down'**
  String get moveSectionDown;

  /// No description provided for @removeEmptySection.
  ///
  /// In en, this message translates to:
  /// **'Remove empty section'**
  String get removeEmptySection;

  /// No description provided for @buildFlowStep.
  ///
  /// In en, this message translates to:
  /// **'Build flow'**
  String get buildFlowStep;

  /// No description provided for @recordFlowDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Describe this flow'**
  String get recordFlowDetailsTitle;

  /// No description provided for @buildFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your record flow'**
  String get buildFlowTitle;

  /// No description provided for @creationStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} · {label}'**
  String creationStepLabel(int current, int total, String label);

  /// No description provided for @addQuestionToSection.
  ///
  /// In en, this message translates to:
  /// **'Add question to this section'**
  String get addQuestionToSection;

  /// No description provided for @sectionEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a question to define what appears in this section.'**
  String get sectionEmptyDescription;

  /// No description provided for @renameSection.
  ///
  /// In en, this message translates to:
  /// **'Name your section'**
  String get renameSection;

  /// No description provided for @sectionName.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get sectionName;

  /// No description provided for @sectionNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a short heading that makes sense to you.'**
  String get sectionNameDescription;

  /// No description provided for @sectionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a section name'**
  String get sectionNameRequired;

  /// No description provided for @moveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Move question to another section'**
  String get moveQuestion;

  /// No description provided for @reorderOrMoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reorder or move question'**
  String get reorderOrMoveQuestion;

  /// No description provided for @moveQuestionUp.
  ///
  /// In en, this message translates to:
  /// **'Move question up'**
  String get moveQuestionUp;

  /// No description provided for @moveQuestionDown.
  ///
  /// In en, this message translates to:
  /// **'Move question down'**
  String get moveQuestionDown;

  /// No description provided for @moveToSection.
  ///
  /// In en, this message translates to:
  /// **'Move to {section}'**
  String moveToSection(String section);

  /// No description provided for @deleteQuestionFromDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete question'**
  String get deleteQuestionFromDraft;

  /// No description provided for @appearsInSection.
  ///
  /// In en, this message translates to:
  /// **'Appears in section'**
  String get appearsInSection;

  /// No description provided for @placementTitle.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get placementTitle;

  /// No description provided for @placementDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the section where this question will appear.'**
  String get placementDescription;

  /// No description provided for @questionContentTitle.
  ///
  /// In en, this message translates to:
  /// **'What will this ask?'**
  String get questionContentTitle;

  /// No description provided for @questionContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Use clear language that will make sense during a check-in.'**
  String get questionContentDescription;

  /// No description provided for @responseSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to respond?'**
  String get responseSetupTitle;

  /// No description provided for @responseSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to record your answer.'**
  String get responseSetupDescription;

  /// No description provided for @optionsEditorHelp.
  ///
  /// In en, this message translates to:
  /// **'Add at least two options. You can edit and drag them into order.'**
  String get optionsEditorHelp;

  /// No description provided for @optionNumber.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String optionNumber(int number);

  /// No description provided for @removeOption.
  ///
  /// In en, this message translates to:
  /// **'Remove option'**
  String get removeOption;

  /// No description provided for @optionsMinimumRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least two complete response options'**
  String get optionsMinimumRequired;

  /// No description provided for @optionsMustBeUnique.
  ///
  /// In en, this message translates to:
  /// **'Each response option must be different'**
  String get optionsMustBeUnique;

  /// No description provided for @optionCommaUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Response options cannot contain commas'**
  String get optionCommaUnsupported;

  /// No description provided for @customQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom question'**
  String get customQuestionLabel;

  /// No description provided for @customRecordFlowLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom record flow'**
  String get customRecordFlowLabel;

  /// No description provided for @recordFlowSettings.
  ///
  /// In en, this message translates to:
  /// **'Record flow settings'**
  String get recordFlowSettings;

  /// No description provided for @backToRecordFlows.
  ///
  /// In en, this message translates to:
  /// **'Back to record flows'**
  String get backToRecordFlows;

  /// No description provided for @noRecordFlowSelected.
  ///
  /// In en, this message translates to:
  /// **'No record flow selected'**
  String get noRecordFlowSelected;

  /// No description provided for @recordFlowNotFound.
  ///
  /// In en, this message translates to:
  /// **'Record flow not found'**
  String get recordFlowNotFound;

  /// No description provided for @builtInFlowStructure.
  ///
  /// In en, this message translates to:
  /// **'Built-in flow structure'**
  String get builtInFlowStructure;

  /// No description provided for @builtInFlowStructureDescription.
  ///
  /// In en, this message translates to:
  /// **'Questions and sections are managed by the app. You can still change visibility when it is allowed.'**
  String get builtInFlowStructureDescription;

  /// No description provided for @questionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Question settings'**
  String get questionSettingsTitle;

  /// No description provided for @questionCardLabel.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get questionCardLabel;

  /// No description provided for @showInCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Show in check-ins'**
  String get showInCheckIns;

  /// No description provided for @settingManagedByApp.
  ///
  /// In en, this message translates to:
  /// **'This setting is managed by the app'**
  String get settingManagedByApp;

  /// No description provided for @hideQuestionDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide this question without deleting it'**
  String get hideQuestionDescription;

  /// No description provided for @showRecordFlow.
  ///
  /// In en, this message translates to:
  /// **'Show record flow'**
  String get showRecordFlow;

  /// No description provided for @hideRecordFlowDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide this flow from the record menu without deleting it'**
  String get hideRecordFlowDescription;

  /// No description provided for @responseRequirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Response requirement'**
  String get responseRequirementTitle;

  /// No description provided for @optionalResponseDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional · this response can be skipped'**
  String get optionalResponseDescription;

  /// No description provided for @requiredResponseDescription.
  ///
  /// In en, this message translates to:
  /// **'Required · a response rule is set'**
  String get requiredResponseDescription;

  /// No description provided for @builtInQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Built-in question'**
  String get builtInQuestionLabel;

  /// No description provided for @builtInQuestionDescription.
  ///
  /// In en, this message translates to:
  /// **'The question itself is managed by the app. You can change its visibility when allowed.'**
  String get builtInQuestionDescription;

  /// No description provided for @questionTypeCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get questionTypeCheck;

  /// No description provided for @questionTypeSlider.
  ///
  /// In en, this message translates to:
  /// **'Slider'**
  String get questionTypeSlider;

  /// No description provided for @questionTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get questionTypeMultipleChoice;

  /// No description provided for @questionTypeAllThatApply.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get questionTypeAllThatApply;

  /// No description provided for @questionTypeFreeResponse.
  ///
  /// In en, this message translates to:
  /// **'Written response'**
  String get questionTypeFreeResponse;

  /// No description provided for @conditionNoConditions.
  ///
  /// In en, this message translates to:
  /// **'No conditions yet. This section will always be shown.'**
  String get conditionNoConditions;

  /// No description provided for @conditionChooseStart.
  ///
  /// In en, this message translates to:
  /// **'Choose how to start'**
  String get conditionChooseStart;

  /// No description provided for @conditionOne.
  ///
  /// In en, this message translates to:
  /// **'One condition'**
  String get conditionOne;

  /// No description provided for @conditionSeveral.
  ///
  /// In en, this message translates to:
  /// **'Several conditions'**
  String get conditionSeveral;

  /// No description provided for @conditionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get conditionQuestion;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @conditionHasResponse.
  ///
  /// In en, this message translates to:
  /// **'Has a response'**
  String get conditionHasResponse;

  /// No description provided for @conditionEquals.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get conditionEquals;

  /// No description provided for @conditionContainsSelection.
  ///
  /// In en, this message translates to:
  /// **'Contains selection'**
  String get conditionContainsSelection;

  /// No description provided for @conditionContainsText.
  ///
  /// In en, this message translates to:
  /// **'Contains text'**
  String get conditionContainsText;

  /// No description provided for @conditionMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get conditionMatch;

  /// No description provided for @conditionAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get conditionAll;

  /// No description provided for @conditionAny.
  ///
  /// In en, this message translates to:
  /// **'ANY'**
  String get conditionAny;

  /// No description provided for @conditionOf.
  ///
  /// In en, this message translates to:
  /// **'of these'**
  String get conditionOf;

  /// No description provided for @conditionAnd.
  ///
  /// In en, this message translates to:
  /// **'AND'**
  String get conditionAnd;

  /// No description provided for @conditionOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get conditionOr;

  /// No description provided for @conditionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add condition'**
  String get conditionAdd;

  /// No description provided for @conditionNestedGroup.
  ///
  /// In en, this message translates to:
  /// **'Nested group'**
  String get conditionNestedGroup;

  /// No description provided for @conditionRemoveGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove group'**
  String get conditionRemoveGroup;

  /// No description provided for @conditionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove condition'**
  String get conditionRemove;

  /// No description provided for @conditionAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'Answer is'**
  String get conditionAnswerIs;

  /// No description provided for @conditionExactMatch.
  ///
  /// In en, this message translates to:
  /// **'Must match exactly'**
  String get conditionExactMatch;

  /// No description provided for @conditionValueEquals.
  ///
  /// In en, this message translates to:
  /// **'Value equals'**
  String get conditionValueEquals;

  /// No description provided for @conditionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This condition is not available for this response type'**
  String get conditionUnsupported;

  /// No description provided for @flowBuilderHelp.
  ///
  /// In en, this message translates to:
  /// **'Add questions below. Sections group questions onto a screen; visibility rules let you show follow-ups only when needed.'**
  String get flowBuilderHelp;

  /// No description provided for @flowListHelp.
  ///
  /// In en, this message translates to:
  /// **'Question sets that define what you record. Open a flow to view its questions and customize it.'**
  String get flowListHelp;

  /// No description provided for @builtInFlowLabel.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInFlowLabel;

  /// No description provided for @hiddenFlowLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenFlowLabel;

  /// No description provided for @editFlowQuestions.
  ///
  /// In en, this message translates to:
  /// **'Edit questions'**
  String get editFlowQuestions;

  /// No description provided for @ruleNeedsEarlierQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add a question to an earlier section to create a rule.'**
  String get ruleNeedsEarlierQuestion;

  /// No description provided for @readingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading preferences'**
  String get readingPreferencesTitle;

  /// No description provided for @displaySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Display settings'**
  String get displaySettingsTitle;

  /// No description provided for @detailLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail layout'**
  String get detailLayoutTitle;

  /// No description provided for @detailLayoutAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get detailLayoutAutomatic;

  /// No description provided for @detailLayoutAutomaticDescription.
  ///
  /// In en, this message translates to:
  /// **'Adapts to your text size and available space.'**
  String get detailLayoutAutomaticDescription;

  /// No description provided for @detailLayoutStacked.
  ///
  /// In en, this message translates to:
  /// **'Question above answer'**
  String get detailLayoutStacked;

  /// No description provided for @detailLayoutStackedDescription.
  ///
  /// In en, this message translates to:
  /// **'Always show each question above its answer, using the full width.'**
  String get detailLayoutStackedDescription;

  /// No description provided for @detailLayoutDeviceNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to saved answers for all profiles on this device.'**
  String get detailLayoutDeviceNote;

  /// No description provided for @detailLayoutSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load or save this preference. Select an option to try again.'**
  String get detailLayoutSaveError;

  /// No description provided for @detailAnswerSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get detailAnswerSelected;

  /// No description provided for @detailAnswerUndetermined.
  ///
  /// In en, this message translates to:
  /// **'Undetermined'**
  String get detailAnswerUndetermined;

  /// No description provided for @historyEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get historyEditEntry;

  /// No description provided for @recordSelectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select categories'**
  String get recordSelectCategories;

  /// No description provided for @recordSelectHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose everything you want to record. You will review all entries before saving.'**
  String get recordSelectHelp;

  /// No description provided for @recordDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get recordDateAndTime;

  /// No description provided for @recordDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get recordDetails;

  /// No description provided for @recordReviewAndSave.
  ///
  /// In en, this message translates to:
  /// **'Review and save'**
  String get recordReviewAndSave;

  /// No description provided for @recordToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get recordToday;

  /// No description provided for @recordYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get recordYesterday;

  /// No description provided for @recordEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get recordEarlier;

  /// No description provided for @recordSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time for all'**
  String get recordSameTime;

  /// No description provided for @recordSeparateTimes.
  ///
  /// In en, this message translates to:
  /// **'Separate times'**
  String get recordSeparateTimes;

  /// No description provided for @recordSharedTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'This time applies to every selected category.'**
  String get recordSharedTimeHelp;

  /// No description provided for @recordSeparateTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Each category keeps its own time and precision.'**
  String get recordSeparateTimeHelp;

  /// No description provided for @recordExactTime.
  ///
  /// In en, this message translates to:
  /// **'Exact time'**
  String get recordExactTime;

  /// No description provided for @recordTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get recordTimeOfDay;

  /// No description provided for @recordNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get recordNotSure;

  /// No description provided for @recordTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Time not known'**
  String get recordTimeUnknown;

  /// No description provided for @recordChoosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose a time of day'**
  String get recordChoosePeriod;

  /// No description provided for @recordEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning'**
  String get recordEarlyMorning;

  /// No description provided for @recordMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get recordMorning;

  /// No description provided for @recordAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get recordAfternoon;

  /// No description provided for @recordEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get recordEvening;

  /// No description provided for @recordNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get recordNight;

  /// No description provided for @recordUnknownTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Only the date will be recorded. You do not need to guess a time.'**
  String get recordUnknownTimeHelp;

  /// No description provided for @recordStudyExactTime.
  ///
  /// In en, this message translates to:
  /// **'This study entry needs an exact time. Choose separate times to use approximate timing for other categories.'**
  String get recordStudyExactTime;

  /// No description provided for @recordInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid time for each category. Entries cannot be in the future.'**
  String get recordInvalidTime;

  /// No description provided for @recordReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the date, times and answers before saving.'**
  String get recordReviewHelp;

  /// No description provided for @recordSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save entries'**
  String get recordSaveAll;

  /// No description provided for @recordReturnToReview.
  ///
  /// In en, this message translates to:
  /// **'Return to review'**
  String get recordReturnToReview;

  /// No description provided for @recordNotes.
  ///
  /// In en, this message translates to:
  /// **'Anything else to add?'**
  String get recordNotes;

  /// No description provided for @recordPainLevelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine pain level'**
  String get recordPainLevelUnknown;

  /// No description provided for @recordEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get recordEdit;

  /// No description provided for @recordBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get recordBack;

  /// No description provided for @recordRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get recordRetry;

  /// No description provided for @recordLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the recording flow.'**
  String get recordLoadError;

  /// No description provided for @recordNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No recording categories are available for this profile.'**
  String get recordNoCategories;

  /// No description provided for @recordProfileChanged.
  ///
  /// In en, this message translates to:
  /// **'The active profile changed. Return to the original profile to continue this draft.'**
  String get recordProfileChanged;

  /// No description provided for @recordRequiredAnswers.
  ///
  /// In en, this message translates to:
  /// **'Complete the required questions before continuing.'**
  String get recordRequiredAnswers;

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'Your entries have been saved.'**
  String get recordSaved;

  /// No description provided for @recordSaveError.
  ///
  /// In en, this message translates to:
  /// **'Your entries could not all be saved. Your draft is still here; try again.'**
  String get recordSaveError;

  /// No description provided for @recordStudyUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Your entries are saved, but the study could not be updated. Try again to finish updating the study.'**
  String get recordStudyUpdateError;

  /// No description provided for @recordSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get recordSaving;

  /// No description provided for @recordStart.
  ///
  /// In en, this message translates to:
  /// **'Record an entry'**
  String get recordStart;

  /// No description provided for @recordMultipleHint.
  ///
  /// In en, this message translates to:
  /// **'Record one or more categories together'**
  String get recordMultipleHint;

  /// No description provided for @recordSelectionRetained.
  ///
  /// In en, this message translates to:
  /// **'Answers are kept if you deselect and reselect a category. Only selected categories will be saved.'**
  String get recordSelectionRetained;

  /// No description provided for @recordStudyChanged.
  ///
  /// In en, this message translates to:
  /// **'The study has changed since this draft started. Start a new entry to use the current study questions.'**
  String get recordStudyChanged;

  /// No description provided for @recordPartialSaveError.
  ///
  /// In en, this message translates to:
  /// **'Some entries may already be saved. Retry to finish this recording without duplicates. Leaving keeps saved entries in History.'**
  String get recordPartialSaveError;

  /// No description provided for @recordLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave recording'**
  String get recordLeave;

  /// No description provided for @recordCategoryMealHint.
  ///
  /// In en, this message translates to:
  /// **'Breakfast, lunch, dinner or snacks'**
  String get recordCategoryMealHint;

  /// No description provided for @recordCategoryPainHint.
  ///
  /// In en, this message translates to:
  /// **'Signs of pain, location and intensity'**
  String get recordCategoryPainHint;

  /// No description provided for @recordCategoryBowelHint.
  ///
  /// In en, this message translates to:
  /// **'Stool type, straining, gas or bloating'**
  String get recordCategoryBowelHint;

  /// No description provided for @recordCategoryGiHint.
  ///
  /// In en, this message translates to:
  /// **'Gagging, vomiting or trouble eating'**
  String get recordCategoryGiHint;

  /// No description provided for @recordCategorySleepHint.
  ///
  /// In en, this message translates to:
  /// **'Sleep difficulties, mood or behavior changes'**
  String get recordCategorySleepHint;

  /// No description provided for @recordStudyExactTimeOnly.
  ///
  /// In en, this message translates to:
  /// **'This study entry needs an exact time.'**
  String get recordStudyExactTimeOnly;

  /// No description provided for @recordPageCount.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String recordPageCount(int current, int total);

  /// No description provided for @recordFollowUpAdded.
  ///
  /// In en, this message translates to:
  /// **'Your answer added a follow-up page.'**
  String get recordFollowUpAdded;

  /// No description provided for @recordFollowUpPage.
  ///
  /// In en, this message translates to:
  /// **'Follow-up questions'**
  String get recordFollowUpPage;

  /// No description provided for @recordQuestionRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get recordQuestionRequired;

  /// No description provided for @recordQuestionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check this answer before continuing.'**
  String get recordQuestionInvalid;

  /// No description provided for @recordNextCategory.
  ///
  /// In en, this message translates to:
  /// **'Next: {category}'**
  String recordNextCategory(String category);

  /// No description provided for @recordCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'Category {current} of {total}'**
  String recordCategoryCount(int current, int total);

  /// No description provided for @recordViewFollowUps.
  ///
  /// In en, this message translates to:
  /// **'View added questions'**
  String get recordViewFollowUps;

  /// No description provided for @recordFollowUpsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added based on your answer'**
  String get recordFollowUpsAdded;

  /// No description provided for @painIntensityNone.
  ///
  /// In en, this message translates to:
  /// **'No pain'**
  String get painIntensityNone;

  /// No description provided for @painIntensityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get painIntensityModerate;

  /// No description provided for @painIntensityWorst.
  ///
  /// In en, this message translates to:
  /// **'Worst possible'**
  String get painIntensityWorst;

  /// No description provided for @painIntensityNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get painIntensityNotSure;

  /// No description provided for @historySummaryDays.
  ///
  /// In en, this message translates to:
  /// **'{entries} across {days, plural, =1{1 day} other{{days} days}}'**
  String historySummaryDays(String entries, int days);

  /// No description provided for @historyMoreCategories.
  ///
  /// In en, this message translates to:
  /// **'+{count} more categories'**
  String historyMoreCategories(int count);

  /// No description provided for @historyListView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get historyListView;

  /// No description provided for @historyGraphView.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get historyGraphView;

  /// No description provided for @historyActiveFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter} other{{count} filters}}'**
  String historyActiveFilterCount(int count);

  /// No description provided for @historyMoreFilterCount.
  ///
  /// In en, this message translates to:
  /// **'+{count, plural, =1{1 filter} other{{count} filters}}'**
  String historyMoreFilterCount(int count);

  /// No description provided for @historyRemoveFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove filter: {label}'**
  String historyRemoveFilter(String label);

  /// No description provided for @historyTestBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get historyTestBlue;

  /// No description provided for @historyTestNoBlue.
  ///
  /// In en, this message translates to:
  /// **'No blue'**
  String get historyTestNoBlue;

  /// No description provided for @historyTestBlueDescription.
  ///
  /// In en, this message translates to:
  /// **'Blue color recorded'**
  String get historyTestBlueDescription;

  /// No description provided for @historyTestNoBlueDescription.
  ///
  /// In en, this message translates to:
  /// **'No blue color recorded'**
  String get historyTestNoBlueDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
