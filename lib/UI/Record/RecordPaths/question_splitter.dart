import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';

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

final pageProvider = Provider.family<List<List<Question>>, String>((ref, type) {
  final Map<String, List<Question>> split = ref.watch(questionSplitProvider);
  final Map<String, QuestionEntry> overrides = ref.watch(questionEntryOverides);
  final List<Question> typedQuestions = split[type] ?? [];
  final List<List<Question>> pages = [[]];
  for (Question question in typedQuestions) {
    if (question.prompt == type || question.prompt.isEmpty) continue;
    if (overrides.containsKey(question.id) &&
        (overrides[question.id]?.isSeparateScreen ?? false)) {
      pages.insert(0, [question]);
    } else {
      pages[pages.length - 1].add(question);
    }
  }
  pages.removeWhere((element) => element.isEmpty);
  return pages;
});
