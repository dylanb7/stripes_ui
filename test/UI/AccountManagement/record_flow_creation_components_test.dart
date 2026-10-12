import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_build_step.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_draft.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('build step delegates section and question actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final first = DraftRecordFlowSection(
      id: 'first',
      questions: [
        const Check(id: 'q1', prompt: 'First question', type: 'Test'),
      ],
    );
    final second = DraftRecordFlowSection(id: 'second');
    var addedSection = false;
    String? addedQuestionSection;
    DraftRecordFlowSection? renamedSection;
    DraftRecordFlowSection? dependencySection;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecordFlowBuildStep(
            sections: [first, second],
            sectionLabel: (_, index) => 'Section ${index + 1}',
            sectionRuleSummary: (_) => 'Always shown',
            onAddSection: () => addedSection = true,
            onAddQuestion: (id) => addedQuestionSection = id,
            onRenameSection: (section, _) => renamedSection = section,
            onEditSectionDependency: (section, _) =>
                dependencySection = section,
            onMoveSection: (_, _) {},
            onRemoveSection: (_) {},
            onReorderQuestion: (_, _, _) {},
            onMoveQuestion: (_, _, _) {},
            onDeleteQuestion: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.byType(DraftRecordFlowSectionCard), findsNWidgets(2));
    expect(find.byType(DraftRecordFlowQuestionTile), findsOneWidget);

    await tester.tap(find.text('Add section'));
    expect(addedSection, isTrue);

    await tester.tap(find.text('Add question to this section').first);
    expect(addedQuestionSection, 'first');

    await tester.tap(find.byTooltip('Name your section').first);
    expect(renamedSection, same(first));

    await tester.tap(find.text('Add rule'));
    expect(dependencySection, same(second));
    expect(tester.takeException(), isNull);
  });
}
