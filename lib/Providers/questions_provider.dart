import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
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

  //add in empty paths
  for (final RecordPath path in paths) {
    if (!byCategory.containsKey(path.name)) {
      byCategory[path.name] = [];
    }
  }

  return byCategory;
});

@immutable
class PagesByPathProps extends Equatable {
  final String? pathName;
  final bool filterEnabled;
  const PagesByPathProps({required this.pathName, this.filterEnabled = false});

  @override
  List<Object?> get props => [pathName, filterEnabled];
}

@immutable
class PagesData extends Equatable {
  final List<LoadedPageLayout>? loadedLayouts;

  final RecordPath? path;

  const PagesData({this.path, this.loadedLayouts});

  @override
  List<Object?> get props => [path, loadedLayouts];
}

final pagesByPath = FutureProvider.autoDispose
    .family<PagesData, PagesByPathProps>((ref, props) async {
  final QuestionHome home = await ref.watch(questionHomeProvider.future);
  final List<RecordPath> paths = await ref.watch(questionLayoutProvider.future);
  final Iterable<RecordPath> withName =
      paths.where((path) => path.name == props.pathName);
  final RecordPath? matching = withName.isEmpty ? null : withName.first;
  if (matching == null) return const PagesData();
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
  return PagesData(path: matching, loadedLayouts: loadedLayouts);
});

enum PathProviderType {
  checkin,
  record,
  both;
}

@immutable
class RecordPathProps extends Equatable {
  final bool filterEnabled;
  final PathProviderType type;
  const RecordPathProps({required this.filterEnabled, required this.type});
  @override
  List<Object?> get props => [filterEnabled, type];
}

final recordPaths = FutureProvider.family<List<RecordPath>, RecordPathProps>(
    (ref, props) async {
  final List<RecordPath> layouts =
      await ref.watch(questionLayoutProvider.future);

  return layouts.where((layout) {
    if (props.filterEnabled && !layout.enabled) return false;
    if (props.type == PathProviderType.checkin && layout.period == null) {
      return false;
    }
    if (props.type == PathProviderType.record && layout.period != null) {
      return false;
    }
    return true;
  }).toList();
});

@immutable
class CheckinItem {
  final RecordPath path;
  final String type;
  final DetailResponse? response;

  const CheckinItem(
      {required this.path, required this.type, required this.response});
}

final checkInPaths = FutureProvider.family<List<CheckinItem>, DateTime?>(
    (ref, searchDate) async {
  List<CheckinItem> checkins = [];
  final DateTime date = searchDate ?? DateTime.now();
  final List<Stamp> stamps = await ref.watch(stampHolderProvider.future);

  const pathProps =
      RecordPathProps(filterEnabled: true, type: PathProviderType.checkin);

  final List<RecordPath> paths = await ref.watch(recordPaths(pathProps).future);

  for (final RecordPath recordPath in paths) {
    final DateTimeRange range = recordPath.period!.getRange(date);

    final String searchType = recordPath.name;

    final List<Stamp> valid = stamps.where((element) {
      final DateTime stampTime = dateFromStamp(element.stamp);
      return element.type == searchType &&
          (stampTime.isBefore(range.end) || stampTime.isBefore(range.end)) &&
          (stampTime.isAfter(range.start) ||
              stampTime.isAtSameMomentAs(range.start));
    }).toList();

    checkins.add(CheckinItem(
        path: recordPath,
        type: searchType,
        response: valid.isEmpty ? null : valid.first as DetailResponse));
  }
  return checkins
    ..sort((first, second) => first.response == null
        ? -1
        : second.response == null
            ? 1
            : 0);
});
