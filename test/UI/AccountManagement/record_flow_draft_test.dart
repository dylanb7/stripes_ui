import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_draft.dart';

void main() {
  test('draft owns section and question ordering', () {
    final draft = RecordFlowDraft();
    final first = draft.sections.single;
    final second = draft.addSection();
    const question = Check(id: 'q1', prompt: 'First', type: 'Draft');

    draft.addQuestion(first.id, question);
    draft.moveQuestion(question, first, second.id);

    expect(first.questions, isEmpty);
    expect(second.questions, [question]);
    draft.moveSection(1, 0);
    expect(draft.sections.first, same(second));
  });

  test('draft rejects dependencies moved before their source question', () {
    final draft = RecordFlowDraft();
    final section = draft.sections.single;
    const first = Check(id: 'q1', prompt: 'First', type: 'Draft');
    final dependent = Check(
      id: 'q2',
      prompt: 'Second',
      type: 'Draft',
      dependsOn: _dependsOn('q1'),
    );
    draft.addQuestion(section.id, first);
    draft.addQuestion(section.id, dependent);

    expect(draft.rulesFollowFlowOrder, isTrue);
    draft.reorderQuestion(section, 1, 0);
    expect(draft.rulesFollowFlowOrder, isFalse);
  });

  test('page layouts preserve section names and visibility rules', () {
    final draft = RecordFlowDraft();
    final first = draft.sections.single;
    first.header = 'Start';
    draft.addQuestion(
      first.id,
      const Check(id: 'q1', prompt: 'First', type: 'Draft'),
    );
    final second = draft.addSection();
    second.header = 'Follow-up';
    second.dependsOn = _dependsOn('q1');
    draft.addQuestion(
      second.id,
      const Check(id: 'q2', prompt: 'Second', type: 'Draft'),
    );

    final pages = draft.toPageLayouts();
    expect(pages.map((page) => page.header), ['Start', 'Follow-up']);
    expect(pages.last.dependsOn, second.dependsOn);
    expect(draft.rulesFollowFlowOrder, isTrue);
  });
}

DependsOn _dependsOn(String questionId) => DependsOn([
  ConditionGroup(conditions: [ExistsCondition(questionId)], op: GroupOp.all),
]);
