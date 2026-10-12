import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('section name editor returns a name without controller errors', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showSectionNameEditor(
                  context,
                  currentName: 'Section 1',
                  fallbackName: 'Section 1',
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Daily reflection');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(result, 'Daily reflection');
    expect(tester.takeException(), isNull);
  });
}
