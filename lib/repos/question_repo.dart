import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/blue_dye_entry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bristol_entry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_numeric.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/vertical_pain_numeric.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/repos/blue_dye_test_repo.dart';

const mealTimeType = "Meal Time";

const seizureEntry = "Seizure Status";

class Questions extends QuestionRepo {
  Questions({required super.authUser});

  @override
  QuestionHome get questions => Home();

  @override
  Map<String, RecordPath> getLayouts(
      {required BuildContext context, QuestionsListener? questionListener}) {
    return {
      "Meal Time": const RecordPath(pages: []),
      Symptoms.PAIN: RecordPath(pages: [
        const PageLayout(questionIds: [q1, q14, q18, q27, q28]),
        if (questionListener != null &&
            (hasId(questionListener, q1) || hasId(questionListener, q18)))
          PageLayout(
              questionIds: const [location],
              header: AppLocalizations.of(context)!.painLocation),
        PageLayout(
            questionIds: const [rating],
            header: AppLocalizations.of(context)!.painLevel),
      ]),
      Symptoms.BM: RecordPath(pages: [
        PageLayout(
            questionIds: const [q4],
            header: AppLocalizations.of(context)!.bristolLevel),
        PageLayout(
            questionIds: const [q6],
            header: AppLocalizations.of(context)!.painLevelBM),
        const PageLayout(questionIds: [q7, q8, q9, q29, q30]),
      ]),
      Symptoms.REFLUX: const RecordPath(pages: [
        PageLayout(questionIds: [q10, q12, q19, q20]),
        PageLayout(questionIds: [q2, q11, q13])
      ]),
      Symptoms.NB: const RecordPath(pages: [
        PageLayout(questionIds: [q21, q22, q23]),
        PageLayout(questionIds: [q24, q25, q26]),
      ])
    };
  }

  @override
  Map<String, QuestionEntry>? get entryOverrides => {
        q4: QuestionEntry(
            isSeparateScreen: true,
            entryBuilder: (listener, context, question) {
              return BMSlider(
                listener: listener,
                question: question as Numeric,
              );
            }),
        location: QuestionEntry(
            isSeparateScreen: true,
            entryBuilder: (listener, context, question) {
              return PainAreaWidget(
                  questionsListener: listener,
                  question: question as MultipleChoice);
            }),
        rating: QuestionEntry(
            isSeparateScreen: true,
            entryBuilder: (listener, context, question) {
              return VerticalPainFaces(
                  questionsListener: listener, question: question as Numeric);
            }),
        q6: QuestionEntry(
            isSeparateScreen: true,
            entryBuilder: (listener, context, question) {
              return VerticalPainFaces(
                  questionsListener: listener, question: question as Numeric);
            }),
        blueQuestionId: QuestionEntry(
            isSeparateScreen: true,
            entryBuilder: (listener, context, question) {
              return BlueDyeEntry(
                  listener: listener, question: question as MultipleChoice);
            })
      };

  @override
  Map<String, DisplayBuilder<Response<Question>>>? get displayOverrides => {
        q4: <Numeric>(context, numeric) => SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: BMRow(response: numeric)),
        rating: <Numeric>(context, numeric) =>
            PainSliderDisplay(response: numeric),
        q6: <Numeric>(context, numeric) => PainSliderDisplay(response: numeric),
      };
}

bool hasId(QuestionsListener listener, String id) {
  return listener.questions.keys
      .where((question) => question.id == id)
      .isNotEmpty;
}

const rating = "Pain-Rating";

const location = "Pain-Location";

class Home extends QuestionHome {
  @override
  Map<String, Question> get all => {
        ...QuestionHomeInst().all,
        rating: const Numeric(
            id: rating,
            prompt: "Pain Level",
            type: Symptoms.PAIN,
            isRequired: true),
        location: const MultipleChoice(
            id: location,
            choices: [
              "Unable to determine pain location",
              "Upper Left",
              "Top",
              "Upper Right",
              "Left",
              "Center",
              "Right",
              "Bottom Left",
              "Bottom",
              "Bottom Right"
            ],
            prompt: "Pain Location",
            type: Symptoms.PAIN,
            isRequired: true)
      };

  @override
  Map<String, Question> get additons => {
        blueQuestionId: const MultipleChoice(
            id: blueQuestionId,
            isRequired: true,
            prompt: "Did this bowel movement contain any blue color?",
            type: Symptoms.BM,
            choices: ['Yes', 'No'])
      };
}
