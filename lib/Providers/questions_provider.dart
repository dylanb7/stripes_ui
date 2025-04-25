import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/entry.dart';

final questionsProvider = FutureProvider<QuestionRepo>((ref) async {
  AuthUser user = await ref.watch(authStream.future);
  return ref.watch(reposProvider).questions(user: user);
});

final questionHomeProvider = StreamProvider<QuestionHome>((ref) {
  return ref.watch(questionsProvider).map(
      data: (data) => data.value.questions,
      error: (_) => const Stream.empty(),
      loading: (_) => const Stream.empty());
});

final questionsByType =
    FutureProvider.family<Map<String, List<Question>>, BuildContext>(
        (ref, context) async {
  final QuestionHome home = await ref.watch(questionHomeProvider.future);
  final QuestionRepo repo = await ref.watch(questionsProvider.future);
  final Map<String, List<Question>> byCategory = {};

  final Map<String, Question> allQuestions = home.additions..addAll(home.all);
  for (final Question val in allQuestions.values) {
    if (byCategory.containsKey(val.type)) {
      byCategory[val.type]!.add(val);
    } else {
      byCategory[val.type] = [val];
    }
  }
  if (context.mounted) {
    List<RecordPath> paths = repo.getLayouts(context: context);
    for (final RecordPath path in paths) {
      if (!byCategory.containsKey(path.name)) {
        byCategory[path.name] = [];
      }
    }
  }
  return byCategory;
});
