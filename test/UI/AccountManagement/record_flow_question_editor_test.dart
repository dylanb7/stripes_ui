import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('draft editor preserves identity, range and placement on save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    QuestionDraftResult? result;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open editor'),
                onPressed: () async {
                  result = await Navigator.of(context)
                      .push<QuestionDraftResult>(
                        MaterialPageRoute(
                          builder: (_) => const AddQuestionPage(
                            type: 'Sleep',
                            saveToRepository: false,
                            initialQuestion: Numeric(
                              id: 'existing',
                              prompt: 'Sleep quality',
                              type: 'Sleep',
                              min: 0,
                              max: 10,
                              userCreated: true,
                            ),
                            initialSectionId: 'section',
                            sections: [
                              QuestionSectionOption(
                                id: 'section',
                                label: 'Evening',
                              ),
                            ],
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(find.text('Sleep quality'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sleep quality'),
      'How well did you sleep?',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(result?.sectionId, 'section');
    final question = result!.question as Numeric;
    expect(question.id, 'existing');
    expect(question.prompt, 'How well did you sleep?');
    expect(question.min, 0);
    expect(question.max, 10);
    expect(tester.takeException(), isNull);
  });
}
