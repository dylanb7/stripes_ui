import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_persistence.dart';

void main() {
  final questions = <Question>[
    const Check(id: 'q1', prompt: 'First', type: 'Daily', userCreated: true),
    const Check(id: 'q2', prompt: 'Second', type: 'Daily', userCreated: true),
  ];
  final path = RecordPath(
    name: 'Daily',
    pages: [
      PageLayout(questionIds: const ['q1', 'q2']),
    ],
    userCreated: true,
  );

  test('writes questions before committing the complete record flow', () async {
    final repo = _FakeQuestionRepo();

    expect(
      await persistNewRecordFlow(repo: repo, path: path, questions: questions),
      isTrue,
    );
    expect(repo.operations, ['add:q1', 'add:q2', 'path:Daily']);
    expect(repo.savedPath?.pages.single.questionIds, ['q1', 'q2']);
  });

  test(
    'rolls back questions when the final path cannot be committed',
    () async {
      final repo = _FakeQuestionRepo(pathSucceeds: false);

      expect(
        await persistNewRecordFlow(
          repo: repo,
          path: path,
          questions: questions,
        ),
        isFalse,
      );
      expect(repo.operations, [
        'add:q1',
        'add:q2',
        'path:Daily',
        'remove:q2',
        'remove:q1',
      ]);
    },
  );

  test('rolls back earlier questions when a question write throws', () async {
    final repo = _FakeQuestionRepo(throwOnQuestionId: 'q2');

    expect(
      await persistNewRecordFlow(repo: repo, path: path, questions: questions),
      isFalse,
    );
    expect(repo.operations, ['add:q1', 'add:q2', 'remove:q1']);
  });
}

class _FakeQuestionRepo extends TestQuestionRepo {
  final bool pathSucceeds;
  final String? throwOnQuestionId;
  final List<String> operations = [];
  RecordPath? savedPath;

  _FakeQuestionRepo({this.pathSucceeds = true, this.throwOnQuestionId})
    : super(subUser: SubUser.empty());

  @override
  Future<bool> addQuestion(Question question) async {
    operations.add('add:${question.id}');
    if (question.id == throwOnQuestionId) throw StateError('write failed');
    return true;
  }

  @override
  Future<bool> removeQuestion(Question question) async {
    operations.add('remove:${question.id}');
    return true;
  }

  @override
  Future<bool> addRecordPath(RecordPath path) async {
    operations.add('path:${path.name}');
    savedPath = path;
    return pathSucceeds;
  }

  @override
  Future<bool> removeRecordPath(RecordPath path) async {
    operations.add('removePath:${path.name}');
    return true;
  }
}
