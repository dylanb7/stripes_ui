import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/dependency_editor.dart';
import 'package:stripes_ui/UI/CommonWidgets/Conditions/rule_summary.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  const question = MultipleChoice(
    id: 'which',
    prompt: 'Which',
    type: 'Custom',
    choices: ['a', 'b', 'c'],
  );

  testWidgets('choice labels survive saving and reopening a rule', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DependsOn? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DependencyEditor(
            initialDependency: const DependsOn([
              ConditionGroup(
                conditions: [EqualsExact('which', 1)],
                op: GroupOp.all,
              ),
            ]),
            availableQuestions: const [question],
            onSave: (value) => saved = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('b'), findsWidgets);
    await tester.tap(find.text('Save rule'));
    expect((saved!.groups.single.conditions.single as EqualsExact).expected, 1);
    final context = tester.element(find.byType(DependencyEditor));
    expect(
      localizedRuleSummary(context, saved!, (_) => question),
      'Which — Equals b',
    );
    await tester.tap(find.text('Add condition'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save rule'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
