import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

@immutable
class RecordSessionArgs extends Equatable {
  final String recordPathName;
  final SessionData initialData;
  final Set<String>? whiteList;
  final List<String> submitQuestionIds;

  const RecordSessionArgs({
    required this.recordPathName,
    this.initialData = const SessionData(),
    this.whiteList,
    this.submitQuestionIds = const [],
  });

  @override
  List<Object?> get props => [
    recordPathName,
    initialData,
    whiteList == null ? null : (whiteList!.toList()..sort()),
    submitQuestionIds,
  ];
}

class TestAwareSession {
  final SessionGraph sessionGraph;
  final List<Question> submitQuestions;
  final bool requiresExactTime;

  const TestAwareSession({
    required this.sessionGraph,
    this.submitQuestions = const [],
    this.requiresExactTime = false,
  });
}

class TestAwareSessionFactory {
  final QuestionGraph graph;
  final ModularTestsRepo? tests;

  const TestAwareSessionFactory({required this.graph, this.tests});

  TestAwareSession create({
    required String recordPathName,
    SessionData? initialData,
    List<Stamp> baselines = const [],
    Set<String>? whiteList,
    List<String> submitQuestionIds = const [],
  }) {
    final pages = graph.pagesForPath(recordPathName);
    final augmentedPages = [
      for (var index = 0; index < pages.length; index++)
        pages[index].copyWith(
          questionIds: _mergeIds(
            pages[index].questionIds,
            tests?.getInjectedQuestionIds(
                  recordPathName,
                  placement: TestQuestionPlacement.page,
                  pageIndex: index,
                ) ??
                const [],
          ),
        ),
    ];

    final allSubmitIds = _mergeIds(
      submitQuestionIds,
      tests?.getInjectedQuestionIds(
            recordPathName,
            placement: TestQuestionPlacement.review,
          ) ??
          const [],
    );
    final questions = allSubmitIds
        .map((id) => graph.node(id)?.question)
        .whereType<Question>()
        .toList(growable: false);

    return TestAwareSession(
      sessionGraph: SessionGraph(
        graph: graph,
        pages: augmentedPages,
        initialData: initialData,
        baselines: baselines,
        whiteList: whiteList,
      ),
      submitQuestions: questions,
      requiresExactTime: _hasActiveListener(recordPathName),
    );
  }

  // Match the engine's category filtering, including its empty-set wildcard.
  // A session snapshots this policy alongside its injected questions. The
  // multi-record flow rejects saving if the active protocols change mid-draft.
  bool _hasActiveListener(String recordPathName) {
    final repo = tests;
    if (repo == null) return false;
    return repo.currentProtocols.any((protocol) {
      if (protocol.isCompleted) return false;
      return repo.definitions.any(
        (definition) =>
            definition.id == protocol.testId &&
            (definition.listensTo.isEmpty ||
                definition.listensTo.contains(recordPathName)),
      );
    });
  }

  static List<String> _mergeIds(
    Iterable<String> first,
    Iterable<String> second,
  ) {
    return {...first, ...second}.toList(growable: false);
  }
}

@immutable
class RecordSessionState {
  final SessionData original;
  final SessionGraph sessionGraph;
  final List<Question> submitQuestions;
  final bool hasChanged;

  const RecordSessionState({
    required this.original,
    required this.sessionGraph,
    this.submitQuestions = const [],
    this.hasChanged = false,
  });

  RecordSessionState copyWith({bool? hasChanged}) {
    return RecordSessionState(
      original: original,
      sessionGraph: sessionGraph,
      submitQuestions: submitQuestions,
      hasChanged: hasChanged ?? this.hasChanged,
    );
  }
}

final recordSessionProvider = AsyncNotifierProvider.autoDispose
    .family<RecordSessionNotifier, RecordSessionState, RecordSessionArgs>(
      RecordSessionNotifier.new,
    );

class RecordSessionNotifier extends AsyncNotifier<RecordSessionState> {
  final RecordSessionArgs args;

  RecordSessionNotifier(this.args);

  @override
  Future<RecordSessionState> build() async {
    final graph = await ref.watch(questionGraphProvider.future);
    final home = await ref.watch(questionHomeProvider.future);
    final initialData = args.initialData.resolveQuestions(home);
    final baselines = await ref.watch(baselinesStreamProvider.future);
    final tests = await ref.watch(testProvider.future);
    final session = TestAwareSessionFactory(graph: graph, tests: tests).create(
      recordPathName: args.recordPathName,
      initialData: initialData,
      baselines: baselines,
      whiteList: args.whiteList,
      submitQuestionIds: args.submitQuestionIds,
    );
    final sessionGraph = session.sessionGraph;

    void onChanged() {
      final current = state.value;
      if (current == null) return;
      final changed = current.original != sessionGraph.data;
      // SessionGraph owns validation and conditional-page state. Publish every
      // graph change so controls and visible pages do not retain stale values
      // after `hasChanged` has already become true.
      state = AsyncData(current.copyWith(hasChanged: changed));
    }

    sessionGraph.addListener(onChanged);
    ref.onDispose(() {
      sessionGraph.removeListener(onChanged);
      sessionGraph.dispose();
    });

    return RecordSessionState(
      original: initialData,
      sessionGraph: sessionGraph,
      submitQuestions: session.submitQuestions,
    );
  }

  void acceptChanges() {
    final current = state.value;
    if (current != null && current.hasChanged) {
      state = AsyncData(current.copyWith(hasChanged: false));
    }
  }
}
