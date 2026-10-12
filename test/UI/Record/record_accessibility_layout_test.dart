import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/CommonWidgets/discard_changes_sheet.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bristol_entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_fixtures.dart';
import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  testWidgets('Bristol descriptor grows with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixtures = AuditFixtures();
    final graph = SessionGraph(
      graph: fixtures.graph,
      pages: fixtures.path.pages,
      initialData: fixtures.session,
    );
    addTearDown(graph.dispose);
    addTearDown(fixtures.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BMSlider(
                  listener: graph,
                  question: auditQuestions.first as Numeric,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Like a sausage or snake, smooth and soft'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 812), const Size(1500, 900)]) {
    testWidgets('discard confirmation adapts at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? discarded;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(3),
              ),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => TextButton(
                    onPressed: () async =>
                        discarded = await showDiscardChangesSheet(context, ref),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscardChangesSheet), findsOneWidget);
      expect(
        find.byType(Dialog),
        size.width > 1200 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Discard changes'));
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(discarded, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeping an entry cancels discard', (tester) async {
    bool? discarded;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async =>
                    discarded = await showDiscardChangesSheet(context, ref),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(discarded, isFalse);
  });
}
