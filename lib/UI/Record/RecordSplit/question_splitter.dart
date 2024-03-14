import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';

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

final pagePaths = Provider<Map<String, RecordPath>>((ref) {
  final Map<String, RecordPath>? pageOverrides =
      ref.watch(questionHomeProvider).home?.getLayouts();
  final Map<String, List<Question>> split = ref.watch(questionSplitProvider);
  final Map<String, QuestionEntry> questionOverrides =
      ref.watch(questionsProvider).entryOverrides ?? {};

  return getAllPaths(pageOverrides, questionOverrides, split);
});

final _pageSplitProvider = Provider<PageSplit>((ref) {
  final Map<String, RecordPath> allPaths = ref.watch(pagePaths);

  final Map<String, RecordPath> recordPaths = {};
  final Map<Period, Map<String, RecordPath>> checkinPaths = {};
  for (final entry in allPaths.entries) {
    final Period? period = entry.value.period;
    if (period != null) {
      if (checkinPaths.containsKey(period)) {
        checkinPaths[period]![entry.key] = entry.value;
      } else {
        checkinPaths[period] = {entry.key: entry.value};
      }
    } else {
      recordPaths[entry.key] = entry.value;
    }
  }
  return PageSplit(recordPaths: recordPaths, checkinPaths: checkinPaths);
});

final recordProvider = Provider<Map<String, RecordPath>>((ref) {
  final Map<String, RecordPath> recordPaths =
      ref.watch(_pageSplitProvider.select((value) => value.recordPaths));
  return recordPaths;
});

final checkinProvider =
    Provider.family<Map<Period, List<CheckinItem>>, DateTime?>((ref, time) {
  final Map<Period, Map<String, RecordPath>> checkIns =
      ref.watch(_pageSplitProvider.select((value) => value.checkinPaths));

  final DateTime searchTime = time ?? DateTime.now();
  final List<Stamp> stamps = ref.watch(stampHolderProvider).stamps;
  final Map<Period, List<CheckinItem>> ret = {};

  for (final byPeriod in checkIns.entries) {
    final Period searchPeriod = byPeriod.key;
    if (!ret.containsKey(searchPeriod)) {
      ret[searchPeriod] = [];
    }
    for (final byType in byPeriod.value.entries) {
      final DateTimeRange range = searchPeriod.getRange(searchTime);

      final String searchType = byType.key;
      final List<Stamp> valid = stamps.where((element) {
        final DateTime stampTime = dateFromStamp(element.stamp);
        return element.type == searchType &&
            (stampTime.isBefore(range.end) || stampTime.isBefore(range.end)) &&
            (stampTime.isAfter(range.start) ||
                stampTime.isAtSameMomentAs(range.start));
      }).toList();

      ret[searchPeriod]!.add(CheckinItem(
          path: byType.value,
          type: byType.key,
          response: valid.isEmpty ? null : valid.first as DetailResponse));
    }
  }
  return ret;
});

@immutable
class CheckinItem {
  final RecordPath path;
  final String type;
  final DetailResponse? response;

  const CheckinItem(
      {required this.path, required this.type, required this.response});
}

@immutable
class PageSplit {
  final Map<String, RecordPath> recordPaths;
  final Map<Period, Map<String, RecordPath>> checkinPaths;

  const PageSplit({required this.recordPaths, required this.checkinPaths});
}

Map<String, RecordPath> getAllPaths(
    Map<String, RecordPath>? pageOverrides,
    Map<String, QuestionEntry> questionOverrides,
    Map<String, List<Question>> split) {
  final Map<String, RecordPath> recordPaths = {};
  for (String type in split.keys) {
    if (pageOverrides?.containsKey(type) ?? false) {
      recordPaths[type] = pageOverrides![type]!;
      continue;
    }

    final List<Question> typedQuestions = split[type] ?? [];
    final List<List<Question>> pages = [[]];
    for (Question question in typedQuestions) {
      if (question.prompt == type || question.prompt.isEmpty) continue;
      if (questionOverrides.containsKey(question.id) &&
          (questionOverrides[question.id]?.isSeparateScreen ?? false)) {
        pages.insert(0, [question]);
      } else {
        pages[pages.length - 1].add(question);
      }
    }
    pages.removeWhere((element) => element.isEmpty);
    recordPaths[type] = RecordPath(
        pages: pages
            .map((pageQuestions) => PageLayout(
                questionIds:
                    pageQuestions.map((question) => question.id).toList()))
            .toList());
  }
  return recordPaths;
}
