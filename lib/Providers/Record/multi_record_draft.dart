import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:uuid/uuid.dart';

class MultiRecordContext {
  final String authUserId;
  final SubUser profile;
  final List<RecordItem> categories;
  final QuestionGraph graph;
  final List<Stamp> baselines;
  final ModularTestsRepo? tests;

  const MultiRecordContext({
    required this.authUserId,
    required this.profile,
    required this.categories,
    required this.graph,
    this.baselines = const [],
    this.tests,
  });
}

final multiRecordContextProvider =
    FutureProvider.autoDispose<MultiRecordContext>((ref) async {
      final auth = await ref.watch(authStream.future);
      final profile = await ref.watch(
        subHolderProvider.selectAsync((state) => state.selected),
      );
      if (AuthUser.isEmpty(auth) ||
          profile == null ||
          SubUser.isEmpty(profile)) {
        throw StateError('Select a profile before recording.');
      }
      final graph = await ref.watch(questionGraphProvider.future);
      final categories = await ref.watch(availableRecordPaths.future);
      final baselines = await ref.watch(baselinesStreamProvider.future);
      final tests = await ref.watch(testProvider.future);
      // The repository can resolve before its initial protocol load. Snapshot
      // injected questions and timing requirements only once that load arrives.
      if (tests != null) await tests.activeProtocols.first;
      return MultiRecordContext(
        authUserId: auth.uid,
        profile: profile,
        categories: categories
            .where((item) => item.path.inputCategory == InputCategory.event)
            .toList(growable: false),
        graph: graph,
        baselines: baselines,
        tests: tests,
      );
    });

class MultiRecordCategory {
  final RecordItem item;
  final String entryId;
  final TestAwareSession session;

  MultiRecordCategory({required this.item, required this.session})
    : entryId = const Uuid().v4();

  SessionGraph get graph => session.sessionGraph;
  String get type => item.path.name;
  bool get requiresExactTime => session.requiresExactTime;

  /// Blue Meal linking is independent of the timing policy shared by all tests.
  bool get requiresBlueDyeSession =>
      session.submitQuestions.any(
        (question) => question.id == 'BlueDyeQuestion',
      ) ||
      graph.allPages.any(
        (page) => page.questionIds.contains('BlueDyeQuestion'),
      );
  bool get canSubmit =>
      graph.canSubmit &&
      session.submitQuestions.every(
        (question) =>
            graph.questionStateOf(question.id)?.value.valid ??
            graph.isQuestionValid(question),
      );
}

/// A draft owns one existing SessionGraph per category. Deselecting a category
/// keeps its unsaved answers so reselecting it does not erase the user's work.
class MultiRecordDraft extends ChangeNotifier {
  final MultiRecordContext context;
  final String batchId = const Uuid().v4();
  final DateTime createdAt;
  final Map<String, MultiRecordCategory> _categories = {};
  final Set<String> _selected = {};
  final Map<String, RecordTime> _individualTimes = {};
  late DateTime date;
  late RecordTime sharedTime;
  bool separateTimes = false;
  bool hasChanges = false;

  MultiRecordDraft({required this.context, DateTime? now})
    : createdAt = now ?? DateTime.now() {
    date = DateUtils.dateOnly(createdAt);
    sharedTime = RecordTime(exactTime: TimeOfDay.fromDateTime(createdAt));
  }

  List<MultiRecordCategory> get selected => [
    for (final item in context.categories)
      if (_selected.contains(item.path.name)) _categories[item.path.name]!,
  ];
  bool isSelected(String type) => _selected.contains(type);

  void toggle(RecordItem item) {
    final type = item.path.name;
    if (!_selected.remove(type)) {
      _selected.add(type);
      _categories.putIfAbsent(type, () {
        final category = MultiRecordCategory(
          item: item,
          session:
              TestAwareSessionFactory(
                graph: context.graph,
                tests: context.tests,
              ).create(
                recordPathName: type,
                baselines: context.baselines,
                initialData: SessionData(submitTime: createdAt),
              ),
        );
        category.graph.addListener(_changed);
        return category;
      });
      _individualTimes.putIfAbsent(type, () => sharedTime);
    }
    _changed();
  }

  RecordTime timeFor(String type) =>
      separateTimes ? _individualTimes[type] ?? sharedTime : sharedTime;

  void setDate(DateTime value) {
    date = DateUtils.dateOnly(value);
    _changed();
  }

  void setSeparateTimes(bool value) {
    if (separateTimes == value) return;
    separateTimes = value;
    _changed();
  }

  void setTime(RecordTime time, {String? type}) {
    if (type == null) {
      sharedTime = time;
      // Retain independently edited cards when switching modes.
      if (!separateTimes) {
        for (final category in selected) {
          _individualTimes[category.type] = time;
        }
      }
    } else {
      _individualTimes[type] = time;
    }
    _changed();
  }

  bool timesValid(DateTime now) =>
      selected.isNotEmpty &&
      selected.every(
        (category) => timeFor(category.type)
            .isValidFor(date, now, requiresExact: category.requiresExactTime),
      );

  bool get questionsValid =>
      selected.isNotEmpty && selected.every((category) => category.canSubmit);

  List<Entry> entries({String? blueDyeSessionId}) => selected
      .map((category) {
        final time = timeFor(category.type);
        category.graph.submitTime = time.stampOn(date);
        final response = category.graph.createDetailResponse(
          detailType: category.type,
          id: category.entryId,
        );
        final entry = detailResponseToEntry(
          response,
          context.profile.uid,
          category: category.item.path.inputCategory,
          sessionId: category.requiresBlueDyeSession ? blueDyeSessionId : null,
        );
        return entry.copyWith(
          timeOfDay: time.storagePrecision,
          data: {...entry.data, recordTimeField: time.toJson(date)},
          createdAt: createdAt,
        );
      })
      .toList(growable: false);

  void _changed() {
    hasChanges = true;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final category in _categories.values) {
      category.graph.removeListener(_changed);
      category.graph.dispose();
    }
    super.dispose();
  }
}
