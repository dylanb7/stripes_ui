import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';

final questionSplitProvider =
    Provider.family<Map<String, List<Question>>, PageProps>((ref, props) {
  final AsyncValue<QuestionRepo> repo = ref.watch(questionsProvider);
  AsyncValue<QuestionHome> home = ref.watch(questionHomeProvider);
  if (!repo.hasValue || !home.hasValue) return {};

  Map<String, List<Question>> questions = {};
  for (Question question in home.value!.all.values) {
    final String type = question.type;
    if (questions.containsKey(type)) {
      questions[type]!.add(question);
    } else {
      questions[type] = [question];
    }
  }
  for (final layout in repo.value!
      .getLayouts(
          context: props.context, questionListener: props.questionListener)
      .entries) {
    if (!questions.containsKey(layout.key)) {
      questions[layout.key] = [];
    }
  }
  return questions;
});

final pagePaths =
    Provider.family<Map<String, RecordPath>, PageProps>((ref, props) {
  final Map<String, RecordPath>? pageOverrides = ref.watch(
    questionsProvider.select(
      (questions) => questions.valueOrNull?.getLayouts(
          context: props.context, questionListener: props.questionListener),
    ),
  );

  final Map<String, List<Question>> split =
      ref.watch(questionSplitProvider(props));
  final Map<String, QuestionEntry> questionOverrides =
      ref.watch(questionsProvider).valueOrNull?.entryOverrides ?? {};

  return getAllPaths(pageOverrides, questionOverrides, split);
});

final _pageSplitProvider = Provider.family<PageSplit, PageProps>((ref, props) {
  final Map<String, RecordPath> allPaths = ref.watch(pagePaths(props));

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

final recordProvider =
    Provider.family<Map<String, RecordPath>, PageProps>((ref, props) {
  final Map<String, RecordPath> recordPaths =
      ref.watch(_pageSplitProvider(props).select((value) => value.recordPaths));
  return recordPaths;
});

final checkinProvider =
    Provider.family<Map<Period, List<CheckinItem>>, CheckInProps>((ref, props) {
  final Map<Period, Map<String, RecordPath>> checkIns = ref.watch(
      _pageSplitProvider(props.pageProps())
          .select((value) => value.checkinPaths));

  final DateTime searchTime = props.period ?? DateTime.now();
  final List<Stamp> stamps = ref.watch(stampHolderProvider).valueOrNull ?? [];
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
class PageProps {
  final BuildContext context;
  final QuestionsListener? questionListener;
  const PageProps({required this.context, this.questionListener});
}

@immutable
class CheckInProps {
  final BuildContext context;
  final QuestionsListener? questionListener;
  final DateTime? period;
  const CheckInProps(
      {required this.context, this.questionListener, this.period});

  PageProps pageProps() =>
      PageProps(context: context, questionListener: questionListener);
}

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
