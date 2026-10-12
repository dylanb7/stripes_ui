import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Record/record_study_processor.dart';

void main() {
  for (final commitsBeforeFailure in [false, true]) {
    test('retry updates each protocol once after partial processing '
        '(commit before failure: $commitsBeforeFailure)', () async {
      final source = _ProtocolSource([_protocol('first'), _protocol('second')]);
      source.failNext.add('second');
      source.commitsBeforeFailure = commitsBeforeFailure;
      final engine = _CountingEngine();
      final tests = _repo(source, engine);
      addTearDown(tests.dispose);
      await Future<void>.delayed(Duration.zero);
      final processor = RecordStudyProcessor();
      final entries = [_entry('entry')];

      await expectLater(
        processor.process(tests: tests, entries: entries, history: entries),
        throwsStateError,
      );
      expect(engine.evaluations, {'entry:first': 1, 'entry:second': 1});
      expect(source.protocols['first']!.currentStageId, 'second-stage');

      await processor.process(tests: tests, entries: entries, history: entries);
      expect(engine.evaluations, {'entry:first': 1, 'entry:second': 1});
      expect(source.updates['first'], hasLength(1));
      expect(source.updates['second'], hasLength(2));
      expect(source.updates['second']![1], same(source.updates['second']![0]));
      expect(
        tests.currentProtocols.map((protocol) => protocol.currentStageId),
        everyElement('second-stage'),
      );

      await processor.process(tests: tests, entries: entries, history: entries);
      expect(source.updates['first'], hasLength(1));
      expect(source.updates['second'], hasLength(2));
    });
  }

  test(
    'skips approximate events and history but accepts legacy exact entries',
    () async {
      final source = _ProtocolSource([_protocol('study')]);
      final engine = _CountingEngine();
      final tests = _repo(source, engine);
      addTearDown(tests.dispose);
      await Future<void>.delayed(Duration.zero);
      final exact = _entry('exact');
      final legacy = _entry('legacy', precision: null);
      final afternoon = _entry(
        'afternoon',
        precision: TimeOfDayEntry.afternoon,
      );
      final unknown = _entry('unknown', precision: TimeOfDayEntry.notSure);
      final unrelated = _entry('different-session', sessionId: 'other-session');

      await RecordStudyProcessor().process(
        tests: tests,
        entries: [afternoon, unknown, exact, legacy],
        history: [afternoon, unknown, exact, legacy, unrelated],
      );

      expect(engine.evaluations, {'exact:study': 1, 'legacy:study': 1});
      expect(engine.history['exact:study']!.map((entry) => entry.id), [
        'legacy',
      ]);
      expect(engine.history['legacy:study']!.map((entry) => entry.id), [
        'exact',
      ]);
      expect(source.updates['study'], hasLength(2));
    },
  );

  test(
    'non-transition evaluations are completed without a protocol write',
    () async {
      final source = _ProtocolSource([_protocol('study')]);
      final engine = _CountingEngine()..stageChanged = false;
      final tests = _repo(source, engine);
      addTearDown(tests.dispose);
      await Future<void>.delayed(Duration.zero);
      final processor = RecordStudyProcessor();
      final entries = [_entry('entry')];

      await processor.process(tests: tests, entries: entries, history: []);
      await processor.process(tests: tests, entries: entries, history: []);

      expect(engine.evaluations, {'entry:study': 1});
      expect(source.updates, isEmpty);
    },
  );

  test(
    'rejects entries without stable IDs before processing any protocol',
    () async {
      final source = _ProtocolSource([_protocol('study')]);
      final engine = _CountingEngine();
      final tests = _repo(source, engine);
      addTearDown(tests.dispose);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        RecordStudyProcessor().process(
          tests: tests,
          entries: [_entry('valid'), _entry(null)],
          history: [],
        ),
        throwsArgumentError,
      );
      expect(engine.evaluations, isEmpty);
      expect(source.updates, isEmpty);
    },
  );
}

ActiveTestProtocol _protocol(String id) =>
    ActiveTestProtocol(id: id, testId: 'test', currentStageId: 'first-stage');

Entry _entry(
  String? id, {
  TimeOfDayEntry? precision = TimeOfDayEntry.exact,
  String sessionId = 'study-run',
}) => Entry(
  id: id,
  subUserId: 'profile',
  stamp: DateTime.utc(2026, 10, 6, 12),
  entityType: InputCategory.event.name,
  data: {'type': 'category.BM'},
  timeOfDay: precision,
  sessionId: sessionId,
);

ModularTestsRepo _repo(_ProtocolSource source, TestEngine engine) =>
    ModularTestsRepo(
      source: source,
      engine: engine,
      definitions: const [],
      initialProtocols: source.protocols.values.toList(),
    );

class _ProtocolSource implements ActiveTestProtocolSource {
  final Map<String, ActiveTestProtocol> protocols;
  final Map<String, List<ActiveTestProtocol>> updates = {};
  final Set<String> failNext = {};
  bool commitsBeforeFailure = false;

  _ProtocolSource(List<ActiveTestProtocol> initial)
    : protocols = {for (final protocol in initial) protocol.id: protocol};

  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() async =>
      protocols.values.toList();

  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {
    updates.putIfAbsent(protocol.id, () => []).add(protocol);
    if (failNext.remove(protocol.id)) {
      if (commitsBeforeFailure) protocols[protocol.id] = protocol;
      throw StateError('Protocol update failed');
    }
    protocols[protocol.id] = protocol;
  }
}

class _CountingEngine extends TestEngine {
  final Map<String, int> evaluations = {};
  final Map<String, List<Entry>> history = {};
  bool stageChanged = true;

  @override
  Future<TestEvaluationResult> processEntry({
    required ActiveTestProtocol activeTest,
    required Entry currentResponse,
    List<Entry> historicalResponses = const [],
  }) async {
    final key = '${currentResponse.id}:${activeTest.id}';
    evaluations.update(key, (count) => count + 1, ifAbsent: () => 1);
    history[key] = historicalResponses;
    final nextStage = activeTest.currentStageId == 'first-stage'
        ? 'second-stage'
        : 'third-stage';
    return TestEvaluationResult(
      updatedTest: activeTest.copyWith(currentStageId: nextStage),
      stageChanged: stageChanged,
      previousStageId: activeTest.currentStageId,
      newStageId: nextStage,
    );
  }

  @override
  TestEvaluationResult advanceStage({
    required ActiveTestProtocol activeTest,
    String? targetStageId,
  }) => TestEvaluationResult(updatedTest: activeTest);

  @override
  List<String> getInjectedQuestionIds({
    required ActiveTestProtocol activeTest,
    required String flowType,
    TestQuestionPlacement placement = TestQuestionPlacement.page,
    int pageIndex = 0,
  }) => const [];
}
