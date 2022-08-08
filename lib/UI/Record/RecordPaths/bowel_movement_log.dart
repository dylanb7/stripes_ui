import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_ui/UI/Record/RecordPaths/question_splitter.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/screen_manager.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';

class BowelMovementLog extends ConsumerWidget {
  final QuestionsListener listener = QuestionsListener();

  final SymptomRecordData data;

  final bool test;

  BowelMovementLog({required this.data, this.test = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, List<Question>> questions = ref.watch(questionSplitProvider);
    final QuestionsListener questionsListener = data.listener ?? listener;
    final Question specialCase = QuestionHomeInst().bm1.first;
    return BaseScreen(
      type: Symptoms.BM,
      screen: ScreenController([
        QuestionScreen(
            header: 'Use slider to select bowel movement consistency.',
            questions: [specialCase],
            questionsListener: questionsListener),
        QuestionScreen(
            header: 'Select all behaviors associated with bowel movement(BM)',
            questions: questions[Symptoms.BM] ?? []
              ..remove(specialCase),
            questionsListener: questionsListener),
        SubmitScreen(
          questionsListener: questionsListener,
          type: Symptoms.BM,
          submitTime: data.submitTime,
          desc: data.initialDesc,
          isEdit: data.isEditing ?? false,
          isTest: test,
        )
      ]),
      listener: questionsListener,
    );
  }
}
