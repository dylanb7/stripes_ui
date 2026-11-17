import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_intensity_selector.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/severity_slider.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  for (final id in ['Pain-Rating', 'q6']) {
    final question = Numeric(
      id: id,
      prompt: 'Pain level',
      type: 'Pain',
      isRequired: true,
    );

    testWidgets('$id uses faces in base UI and retains answers when edited', (
      tester,
    ) async {
      final session = _session(question);
      await _pump(tester, session, question);
      expect(find.byType(PainSlider), findsOneWidget);
      expect(find.byType(PainIntensitySelector), findsNothing);
      expect(session.fromQuestion(question), isNull);
      expect(find.text('Select Level'), findsOneWidget);

      final faces = find.descendant(
        of: find.byType(PainSlider),
        matching: find.byType(InkResponse),
      );
      expect(faces, findsNWidgets(6));
      await tester.tap(faces.first);
      await tester.pumpAndSettle();
      expect((session.fromQuestion(question) as NumericResponse).response, 0);

      final notSure = find.byKey(const ValueKey('pain-intensity-not-sure'));
      await tester.tap(notSure);
      await tester.pumpAndSettle();
      expect((session.fromQuestion(question) as NumericResponse).response, -1);
      expect(find.text('Select Level'), findsOneWidget);
      await tester.tap(notSure);
      await tester.pumpAndSettle();
      expect(session.fromQuestion(question), isNull);

      final saved = NumericResponse(
        question: question,
        stamp: 12345,
        response: 7,
        id: 'saved-pain',
        group: 'recording',
      );
      session.setResponse(question, response: saved);
      await tester.pumpAndSettle();
      expect(session.fromQuestion(question), same(saved));
      expect(tester.widget<Slider>(find.byType(Slider)).value, 7);

      for (var index = 0; index < 6; index++) {
        await tester.tap(faces.at(index));
        await tester.pumpAndSettle();
        final changed = session.fromQuestion(question) as NumericResponse;
        expect(changed.response, index * 2);
        expect(changed.id, saved.id);
        expect(changed.group, saved.group);
        expect(changed.stamp, saved.stamp);
      }
      await tester.tap(notSure);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 0);
      expect(find.text('Select Level'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$id keeps the numbered range selector in beta UI', (
      tester,
    ) async {
      final session = _session(question);
      await _pump(
        tester,
        session,
        question,
        betaUi: const BetaUiConfig.enabled(),
      );
      expect(find.byType(PainSlider), findsNothing);
      expect(find.byType(PainIntensitySelector), findsOneWidget);
      expect(session.fromQuestion(question), isNull);
      await tester.tap(find.byKey(const ValueKey('pain-band-moderate')));
      await tester.pumpAndSettle();
      expect((session.fromQuestion(question) as NumericResponse).response, 5);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  SessionGraph session,
  Numeric question, {
  BetaUiConfig betaUi = const BetaUiConfig.disabled(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(betaUi: betaUi),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, _) => ref
                  .watch(questionUIRegistryProvider)
                  .entryForQuestion(question)!
                  .entryBuilder(session, context, question),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SessionGraph _session(Numeric question) {
  final graph = QuestionGraphBuilder.build(
    home: _QuestionHome(question),
    recordPaths: [
      RecordPath(
        name: 'Pain',
        pages: [
          PageLayout(questionIds: [question.id]),
        ],
      ),
    ],
  );
  final session = graph.createSession(recordPathName: 'Pain');
  addTearDown(() {
    session.dispose();
    graph.dispose();
  });
  return session;
}

class _QuestionHome extends QuestionHome {
  _QuestionHome(Numeric question) {
    all = {question.id: question};
  }

  @override
  Map<String, List<Question>> byType() => const {};
}
