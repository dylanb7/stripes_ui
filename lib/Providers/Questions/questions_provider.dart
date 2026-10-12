import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

export 'package:stripes_backend_helper/stripes_backend_helper.dart'
    show PathProviderType, PagesData, RecordItem, ReviewItem;

final questionsProvider = FutureProvider<QuestionRepo?>((ref) async {
  final AuthUser user = await ref.watch(authStream.future);
  final SubUser? sub = await ref.watch(
    subHolderProvider.selectAsync((value) => value.selected),
  );
  final bool subEmpty = sub == null || SubUser.isEmpty(sub);
  if (subEmpty) return null;
  return ref.watch(reposProvider).questions(user: user, subUser: sub);
});

final questionHomeProvider = StreamProvider<QuestionHome>((ref) {
  return ref
      .watch(questionsProvider)
      .map(
        data: (data) {
          final QuestionRepo<QuestionHome>? repo = data.value;
          if (repo == null) return const Stream.empty();
          return repo.questions;
        },
        error: (_) => const Stream.empty(),
        loading: (_) => const Stream.empty(),
      );
});

final questionLayoutProvider = StreamProvider<List<RecordPath>>((ref) {
  return ref
      .watch(questionsProvider)
      .map(
        data: (data) {
          final QuestionRepo<QuestionHome>? repo = data.value;
          if (repo == null) return const Stream.empty();
          return repo.layouts;
        },
        error: (_) => const Stream.empty(),
        loading: (_) => const Stream.empty(),
      );
});

/// Exposes baseline layouts from repos that mix in BaselineRecordPathMixin.
final baselineLayoutProvider = StreamProvider<List<RecordPath>>((ref) {
  return ref
      .watch(questionsProvider)
      .map(
        data: (data) {
          final repo = data.value;
          if (repo == null) return const Stream.empty();
          if (repo is BaselineRecordPathMixin) {
            return repo.baselineRecordPaths;
          }
          return Stream.value(const <RecordPath>[]);
        },
        error: (_) => const Stream.empty(),
        loading: (_) => const Stream.empty(),
      );
});

final questionGraphProvider = FutureProvider<QuestionGraph>((ref) async {
  final QuestionHome home = await ref.watch(questionHomeProvider.future);
  final List<RecordPath> layouts = await ref.watch(
    questionLayoutProvider.future,
  );
  final List<RecordPath> baselineLayouts = await ref
      .watch(baselineLayoutProvider.future)
      .catchError((_) => <RecordPath>[]);

  final allLayouts = [...layouts, ...baselineLayouts];

  return QuestionGraphBuilder.build(home: home, recordPaths: allLayouts);
});

final questionsByType = FutureProvider<Map<String, List<Question>>>((
  ref,
) async {
  final graph = await ref.watch(questionGraphProvider.future);
  return graph.questionsByType();
});

@immutable
class PagesByPathProps extends Equatable {
  final String? pathName;
  final bool filterEnabled;
  const PagesByPathProps({required this.pathName, this.filterEnabled = false});

  @override
  List<Object?> get props => [pathName, filterEnabled];
}

final pagesByPath = FutureProvider.autoDispose
    .family<PagesData, PagesByPathProps>((ref, props) async {
      final graph = await ref.watch(questionGraphProvider.future);
      final List<Stamp> baselines = await ref.watch(
        baselinesStreamProvider.future,
      );
      return graph.pagesDataForPath(
            props.pathName,
            filterEnabled: props.filterEnabled,
            baselines: baselines,
          ) ??
          const PagesData();
    });

@immutable
class RecordPathProps extends Equatable {
  final bool filterEnabled;
  final PathProviderType type;
  const RecordPathProps({required this.filterEnabled, required this.type});
  @override
  List<Object?> get props => [filterEnabled, type];
}

final recordPaths = FutureProvider.family<List<RecordPath>, RecordPathProps>((
  ref,
  props,
) async {
  final graph = await ref.watch(questionGraphProvider.future);
  return graph
      .allRecordPaths(filterEnabled: props.filterEnabled, type: props.type)
      .where((path) => !path.isBaseline)
      .toList(growable: false);
});

class ReviewPathsProps {
  final DateTime? searchDate;
  const ReviewPathsProps({this.searchDate});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReviewPathsProps) return false;
    final a = searchDate;
    final b = other.searchDate;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  int get hashCode {
    final d = searchDate;
    if (d == null) return 0;
    return Object.hash(d.year, d.month, d.day);
  }
}

final reviewPaths = FutureProvider.autoDispose
    .family<List<ReviewItem>, ReviewPathsProps>((ref, props) async {
      final graph = await ref.watch(questionGraphProvider.future);
      final List<Stamp> baselines = await ref.watch(
        baselinesStreamProvider.future,
      );
      final List<Stamp> stamps = await ref.watch(stampsStreamProvider.future);
      return graph.reviewPaths(
        searchDate: props.searchDate,
        stamps: stamps,
        baselines: baselines,
      );
    });

final reviewPathsByTypeProvider =
    FutureProvider.autoDispose<Map<String, RecordPath>>((ref) async {
      final graph = await ref.watch(questionGraphProvider.future);
      return graph.reviewPathsByType();
    });

@immutable
class ReviewPeriodsProps extends Equatable {
  final DateTime start;
  final DateTime end;

  const ReviewPeriodsProps({required this.start, required this.end});

  DateTimeRange get range => DateTimeRange(start: start, end: end);

  @override
  List<Object> get props => [start, end];
}

/// Review periods currently visible in the history display range.
final reviewPeriodsProvider = FutureProvider.autoDispose
    .family<List<ReviewPeriod>, ReviewPeriodsProps>((ref, props) async {
      final graph = await ref.watch(questionGraphProvider.future);
      final List<Stamp> stamps = await ref.watch(stampsStreamProvider.future);
      return graph.reviewPeriods(stamps: stamps, displayRange: props.range);
    });

final availableRecordPaths = FutureProvider<List<RecordItem>>((ref) async {
  final graph = await ref.watch(questionGraphProvider.future);
  final List<Stamp> baselines = await ref.watch(baselinesStreamProvider.future);
  return graph
      .availableRecordPaths(baselines)
      .where((item) => !item.path.isBaseline)
      .toList(growable: false);
});
