import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

class _QuestionHome extends QuestionHome {
  _QuestionHome(Map<String, Question> questions) {
    all = questions;
  }

  @override
  Map<String, List<Question>> byType() => const {};
}

class _ActiveProtocolSource implements ActiveTestProtocolSource {
  final List<ActiveTestProtocol> protocols;

  const _ActiveProtocolSource(this.protocols);

  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() async => protocols;

  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {}
}

void main() {
  test('review test questions are injected on submit only', () async {
    const regular = FreeResponse(
      id: 'regular',
      prompt: 'Regular',
      type: 'record',
    );
    const injected = MultipleChoice(
      id: 'injected',
      prompt: 'Injected',
      type: 'record',
      choices: ['yes', 'no'],
      isRequired: true,
    );
    final graph = QuestionGraphBuilder.build(
      home: _QuestionHome(const {'regular': regular, 'injected': injected}),
      recordPaths: [
        RecordPath(
          name: 'record',
          pages: [
            PageLayout(questionIds: const ['regular']),
          ],
        ),
      ],
    );
    const protocol = ActiveTestProtocol(
      id: 'active',
      testId: 'test',
      currentStageId: 'recording',
    );
    final definition = TestDefinition(
      id: 'test',
      nameKey: 'Test',
      listensTo: const {'record'},
      stages: const [
        TestStage(
          id: 'recording',
          injection: StageInjection(
            targetRecordPath: 'record',
            placement: TestQuestionPlacement.review,
            pageIndex: 0,
            questionIds: ['injected'],
          ),
          triggers: [],
        ),
      ],
    );
    final repo = ModularTestsRepo(
      source: const _ActiveProtocolSource([protocol]),
      engine: DefaultTestEngine(
        testDefinitions: [definition],
        registry: TriggerRegistry(const {}),
      ),
      definitions: [definition],
      initialProtocols: const [protocol],
    );
    addTearDown(repo.dispose);

    final session = TestAwareSessionFactory(
      graph: graph,
      tests: repo,
    ).create(recordPathName: 'record');

    expect(session.sessionGraph.allPages.single.questionIds, ['regular']);
    expect(session.submitQuestions.map((question) => question.id), [
      'injected',
    ]);
    expect(session.sessionGraph.isQuestionValid(injected), isFalse);
  });

  test('page test questions are added to the declared page only', () async {
    const regular = FreeResponse(
      id: 'regular',
      prompt: 'Regular',
      type: 'record',
    );
    const injected = FreeResponse(
      id: 'injected',
      prompt: 'Injected',
      type: 'record',
    );
    final graph = QuestionGraphBuilder.build(
      home: _QuestionHome(const {'regular': regular, 'injected': injected}),
      recordPaths: [
        RecordPath(
          name: 'record',
          pages: [
            PageLayout(questionIds: const ['regular']),
          ],
        ),
      ],
    );
    const protocol = ActiveTestProtocol(
      id: 'active',
      testId: 'test',
      currentStageId: 'recording',
    );
    final definition = TestDefinition(
      id: 'test',
      nameKey: 'Test',
      listensTo: const {'record'},
      stages: const [
        TestStage(
          id: 'recording',
          injection: StageInjection(
            targetRecordPath: 'record',
            placement: TestQuestionPlacement.page,
            pageIndex: 0,
            questionIds: ['injected'],
          ),
          triggers: [],
        ),
      ],
    );
    final repo = ModularTestsRepo(
      source: const _ActiveProtocolSource([protocol]),
      engine: DefaultTestEngine(
        testDefinitions: [definition],
        registry: TriggerRegistry(const {}),
      ),
      definitions: [definition],
      initialProtocols: const [protocol],
    );
    addTearDown(repo.dispose);

    final session = TestAwareSessionFactory(
      graph: graph,
      tests: repo,
    ).create(recordPathName: 'record');

    expect(session.sessionGraph.allPages.single.questionIds, [
      'regular',
      'injected',
    ]);
    expect(session.submitQuestions, isEmpty);
  });

  test(
    'session provider publishes validation changes after a failed attempt',
    () async {
      const question = FreeResponse(
        id: 'required',
        prompt: 'Required',
        type: 'record',
        isRequired: true,
      );
      final path = RecordPath(
        name: 'record',
        pages: [
          PageLayout(questionIds: const ['required']),
        ],
      );
      final graph = QuestionGraphBuilder.build(
        home: _QuestionHome(const {'required': question}),
        recordPaths: [path],
      );
      final container = ProviderContainer(
        overrides: [
          questionGraphProvider.overrideWith((ref) async => graph),
          questionHomeProvider.overrideWith(
            (ref) => Stream.value(_QuestionHome(const {'required': question})),
          ),
          baselinesStreamProvider.overrideWith((ref) => Stream.value(const [])),
          testProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      const args = RecordSessionArgs(recordPathName: 'record');
      var publicationCount = 0;
      final subscription = container.listen(
        recordSessionProvider(args),
        (_, _) => publicationCount++,
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final session = await container.read(recordSessionProvider(args).future);
      session.sessionGraph.tried = true;
      final afterFailedAttempt = publicationCount;

      session.sessionGraph.setResponse(
        question,
        response: OpenResponse(
          question: question,
          stamp: 1,
          response: 'answer',
        ),
      );

      expect(publicationCount, greaterThan(afterFailedAttempt));
      expect(session.sessionGraph.validatePage(0)?.canProceed, isTrue);
    },
  );
}
