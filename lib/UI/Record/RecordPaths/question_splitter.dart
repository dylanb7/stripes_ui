import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';

final questionSplitProvider = Provider<Map<String, List<Question>>>((ref) {
  QuestionHome? home = ref.watch(questionHomeProvider).home;
  if (home == null) return {};
  Map<String, List<Question>> questions = {};
  for (Question question in home.all.values) {
    final String type = question.type;
    if (questions.containsKey(type)) {
      questions[type]!.add(question);
    } else {
      questions[type] = [question];
    }
  }
  return questions;
});
