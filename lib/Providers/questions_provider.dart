import 'package:flutter/foundation.dart';
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

final questionLayoutProvider = StreamProvider<List<RecordPath>>((ref) {
  return ref.watch(questionsProvider).map(
      data: (data) => data.value.layouts,
      error: (_) => const Stream.empty(),
      loading: (_) => const Stream.empty());
});

final questionsByType =
    FutureProvider<Map<String, List<Question>>>((ref) async {
  final QuestionHome home = await ref.watch(questionHomeProvider.future);
  final List<RecordPath> paths = await ref.watch(questionLayoutProvider.future);
  final Map<String, List<Question>> byCategory = home.byType();

  for (final RecordPath path in paths) {
    if (!byCategory.containsKey(path.name)) {
      byCategory[path.name] = [];
    }
  }

  return byCategory;
});

@immutable
class PagesByPathProps {
  final String? pathName;
  final bool filterEnabled;
  const PagesByPathProps({required this.pathName, this.filterEnabled = false});
}

final pagesByPath =
    FutureProvider.family<List<LoadedPageLayout>?, PagesByPathProps>(
        (ref, props) async {
  final QuestionHome home = await ref.watch(questionHomeProvider.future);
  final List<RecordPath> paths = await ref.watch(questionLayoutProvider.future);
  final Iterable<RecordPath> withName =
      paths.where((path) => path.name == props.pathName);
  final RecordPath? matching = withName.isEmpty ? null : withName.first;
  if (matching == null) return null;
  print(matching.toJson());
  List<LoadedPageLayout> loadedLayouts = [];
  for (final PageLayout layout in matching.pages) {
    List<Question> questions = [];
    for (final String qid in layout.questionIds) {
      Question? question = home.fromBank(qid);
      if (question == null || (props.filterEnabled && !question.enabled)) {
        continue;
      }
      questions.add(question);
    }
    if (questions.isEmpty) continue;
    loadedLayouts.add(LoadedPageLayout(
        questions: questions,
        dependsOn: layout.dependsOn,
        header: layout.header));
  }
  for (final layout in loadedLayouts) {
    for (Question question in layout.questions) {
      print(question);
    }
  }
  return loadedLayouts;
});

final enabledRecordPaths = FutureProvider<List<RecordPath>>((ref) async {
  final List<RecordPath> layouts =
      await ref.watch(questionLayoutProvider.future);
  return layouts.where((layout) => layout.enabled).toList();
});
