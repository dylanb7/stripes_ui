import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_ui/UI/Record/base_screen.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/screen_manager.dart';
import 'package:stripes_ui/UI/Record/submit_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';

import 'question_splitter.dart';

class NeurologicalBehaviorsLog extends ConsumerWidget {
  final QuestionsListener listener = QuestionsListener();

  final SymptomRecordData data;

  NeurologicalBehaviorsLog({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, List<Question>> questions = ref.watch(questionSplitProvider);
    final QuestionsListener questionsListener = data.listener ?? listener;
    return BaseScreen(
      type: Symptoms.NB,
      screen: ScreenController([
        QuestionScreen(
            header: 'Select all associated with neurological behaviors',
            questions: questions[Symptoms.NB] ?? [],
            questionsListener: questionsListener),
        SubmitScreen(
          questionsListener: questionsListener,
          type: Symptoms.NB,
          desc: data.initialDesc,
          isEdit: data.isEditing ?? false,
          submitTime: data.submitTime,
        )
      ]),
      listener: questionsListener,
    );
  }
}
