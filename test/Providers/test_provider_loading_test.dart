import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/repo_package.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

const _protocol = ActiveTestProtocol(
  id: 'active',
  testId: 'test',
  currentStageId: 'recording',
);
const _regular = FreeResponse(id: 'regular', prompt: 'Regular', type: 'record');
const _injected = FreeResponse(
  id: 'injected',
  prompt: 'Injected',
  type: 'record',
);
final _definition = TestDefinition(
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
final _profile = SubUser(
  id: 'profile',
  name: 'Sam',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

class _Source implements ActiveTestProtocolSource {
  var load = Completer<List<ActiveTestProtocol>>();
  int loadCalls = 0;

  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() {
    loadCalls++;
    return load.future;
  }

  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {}
}

class _Package extends LocalRepoPackage {
  final ModularTestsRepo repo;
  _Package(this.repo);

  @override
  ModularTestsRepo test({required AuthUser user, required SubUser subUser}) =>
      repo;
}

class _ProfileNotifier extends SubNotifier {
  @override
  SubState build() => SubState(subUsers: [_profile], selected: _profile);
}

class _QuestionHome extends QuestionHome {
  _QuestionHome() {
    all = const {'regular': _regular, 'injected': _injected};
  }

  @override
  Map<String, List<Question>> byType() => const {};
}

ModularTestsRepo _repo(_Source source) => ModularTestsRepo(
  source: source,
  engine: DefaultTestEngine(
    testDefinitions: [_definition],
    registry: TriggerRegistry(const {}),
  ),
  definitions: [_definition],
);

ProviderContainer _container(ModularTestsRepo repo) {
  final home = _QuestionHome();
  final graph = QuestionGraphBuilder.build(
    home: home,
    recordPaths: [
      RecordPath(
        name: 'record',
        pages: [
          PageLayout(questionIds: const ['regular']),
        ],
      ),
    ],
  );
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      reposProvider.overrideWithValue(_Package(repo)),
      authStream.overrideWith(
        (ref) => Stream.value(const AuthUser.uid(uid: 'account')),
      ),
      subHolderProvider.overrideWith(_ProfileNotifier.new),
      questionGraphProvider.overrideWith((ref) async => graph),
      questionHomeProvider.overrideWith((ref) => Stream.value(home)),
      baselinesStreamProvider.overrideWith((ref) => Stream.value(const [])),
    ],
  );
}

void main() {
  test('record session waits for persisted protocols before snapshotting injections', () async {
    final source = _Source();
    final repo = _repo(source);
    addTearDown(repo.dispose);
    final container = _container(repo);
    addTearDown(container.dispose);
    const args = RecordSessionArgs(recordPathName: 'record');
    final subscription = container.listen(
      recordSessionProvider(args),
      (_, _) {},
    );
    addTearDown(subscription.close);
    var completed = false;
    final pending = container.read(recordSessionProvider(args).future).then((
      value,
    ) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(completed, isFalse);
    expect(container.read(testProvider).isLoading, isTrue);

    source.load.complete([_protocol]);
    final session = await pending;
    expect(session.submitQuestions.map((question) => question.id), [
      'injected',
    ]);
    expect(session.sessionGraph.allPages.single.questionIds, ['regular']);
    expect(source.loadCalls, 1);
  });

  test(
    'invalidating a failed test provider retries the cached repository',
    () async {
      final source = _Source();
      final repo = _repo(source);
      addTearDown(repo.dispose);
      final container = _container(repo);
      addTearDown(container.dispose);
      final subscription = container.listen(testProvider, (_, _) {});
      addTearDown(subscription.close);
      final pending = container.read(testProvider.future);
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      final error = StateError('offline');
      final failure = expectLater(pending, throwsA(same(error)));
      source.load.completeError(error);
      await failure;
      expect(container.read(testProvider).hasError, isTrue);

      source.load = Completer<List<ActiveTestProtocol>>();
      container.invalidate(testProvider);
      final retry = container.read(testProvider.future);
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(source.loadCalls, 2);
      expect(container.read(testProvider).isLoading, isTrue);
      source.load.complete([_protocol]);
      expect(await retry, same(repo));
      expect(container.read(testProvider).hasError, isFalse);
      expect(
        repo.getInjectedQuestionIds(
          'record',
          placement: TestQuestionPlacement.review,
        ),
        ['injected'],
      );
    },
  );
}
