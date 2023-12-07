import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';

final questionSplitProvider = Provider<Map<String, List<Question>>>((ref) {
  final QuestionNotifier repo = ref.watch(questionHomeProvider);
  QuestionRepo? home = repo.home;
  if (home == null) return {};
  Map<String, List<Question>> questions = {};
  for (Question question in home.questions.all.values) {
    final String type = question.type;
    if (questions.containsKey(type)) {
      questions[type]!.add(question);
    } else {
      questions[type] = [question];
    }
  }
  for (final layout in home.getLayouts().entries) {
    if (!questions.containsKey(layout.key)) {
      questions[layout.key] = [];
    }
  }
  return questions;
});

final pageProvider = Provider<Map<String, RecordPath>>((ref) {
  Map<String, RecordPath>? pageOverrides =
      ref.watch(questionHomeProvider).home?.getLayouts();
  final Map<String, List<Question>> split = ref.watch(questionSplitProvider);
  final Map<String, RecordPath> recordPaths = {};
  for (String type in split.keys) {
    if (pageOverrides?.containsKey(type) ?? false) {
      recordPaths[type] = pageOverrides![type]!;
      continue;
    }
    final Map<String, QuestionEntry> overrides =
        ref.watch(questionEntryOverides);
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
    recordPaths[type] = RecordPath(
        pages: pages
            .map((pageQuestions) => PageLayout(questions: pageQuestions))
            .toList());
  }
  return recordPaths;
});
