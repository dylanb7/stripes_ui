import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/record_timing_step.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('one category keeps date and time choices without timing modes', (
    tester,
  ) async {
    final fixture = _Fixture();
    fixture.draft.toggle(fixture.items.first);
    await _pump(tester, fixture.draft);

    expect(find.byKey(const ValueKey('record-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-yesterday')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-shared-time')), findsNothing);
    expect(find.byKey(const ValueKey('record-separate-times')), findsNothing);
    expect(
      find.text('This time applies to every selected category.'),
      findsNothing,
    );
    expect(find.byType(RecordTimeCard), findsOneWidget);

    await _tap(tester, 'precision-unknown');
    expect(
      fixture.draft.timeFor('Pain').precision,
      RecordTimePrecision.unknown,
    );
    expect(fixture.draft.sharedTime.precision, RecordTimePrecision.unknown);
    expect(fixture.draft.separateTimes, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'one remaining category edits its own time and retains the other',
    (tester) async {
      final fixture = _Fixture();
      final draft = fixture.draft;
      draft.toggle(fixture.items.first);
      draft.toggle(fixture.items.last);
      draft.setSeparateTimes(true);
      const painTime = RecordTime(
        exactTime: TimeOfDay(hour: 9, minute: 0),
        precision: RecordTimePrecision.dayPart,
        dayPart: RecordDayPart.morning,
      );
      const bowelTime = RecordTime(exactTime: TimeOfDay(hour: 14, minute: 15));
      draft.setTime(painTime, type: 'Pain');
      draft.setTime(bowelTime, type: 'Bowel Movement');
      final sharedTime = draft.sharedTime;
      draft.toggle(fixture.items.last);
      await _pump(tester, draft);

      expect(find.byKey(const ValueKey('record-separate-times')), findsNothing);
      expect(
        tester.widget<RecordTimeCard>(find.byType(RecordTimeCard)).value,
        same(painTime),
      );
      await _tap(tester, 'precision-unknown');
      expect(draft.timeFor('Pain').precision, RecordTimePrecision.unknown);
      expect(draft.sharedTime, same(sharedTime));
      expect(draft.separateTimes, isTrue);

      draft.toggle(fixture.items.last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('record-separate-times')),
        findsOneWidget,
      );
      expect(find.byType(RecordTimeCard), findsNWidgets(2));
      expect(draft.timeFor('Bowel Movement'), same(bowelTime));
      expect(draft.timeFor('Pain').precision, RecordTimePrecision.unknown);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single study entry does not suggest unavailable separate times',
    (tester) async {
      await tester.pumpWidget(
        _app(
          RecordTimeCard(
            value: const RecordTime(exactTime: TimeOfDay(hour: 10, minute: 0)),
            date: DateTime(2020, 1, 1),
            heading: const Text('Bowel Movement'),
            requiresExact: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This study entry needs an exact time.'),
        findsOneWidget,
      );
      expect(find.textContaining('Choose separate times'), findsNothing);
      for (final key in ['precision-dayPart', 'precision-unknown']) {
        final choice = tester.widget<ChoiceChip>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(choice.onSelected, isNull);
      }
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _pump(WidgetTester tester, MultiRecordDraft draft) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith((ref) => StripesConfig.sandbox()),
      ],
      child: _app(
        ListenableBuilder(
          listenable: draft,
          builder: (context, _) => RecordTimingStep(draft: draft),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _Fixture {
  late final List<RecordItem> items;
  late final MultiRecordDraft draft;

  _Fixture() {
    const question = FreeResponse(id: 'note', prompt: 'Notes', type: 'Notes');
    items = [
      for (final name in ['Pain', 'Bowel Movement'])
        RecordItem(
          path: RecordPath(
            name: name,
            pages: [
              PageLayout(questionIds: [question.id]),
            ],
          ),
        ),
    ];
    final graph = QuestionGraphBuilder.build(
      home: _QuestionHome({question.id: question}),
      recordPaths: items.map((item) => item.path).toList(),
    );
    draft = MultiRecordDraft(
      now: DateTime(2020, 1, 1, 16, 30),
      context: MultiRecordContext(
        authUserId: 'auth-user',
        profile: SubUser(
          id: 'profile',
          name: 'Profile',
          gender: '',
          birthYear: 2000,
          isControl: false,
        ),
        categories: items,
        graph: graph,
      ),
    );
    addTearDown(() {
      draft.dispose();
      graph.dispose();
    });
  }
}

class _QuestionHome extends QuestionHome {
  _QuestionHome(Map<String, Question> questions) {
    all = questions;
  }

  @override
  Map<String, List<Question>> byType() => const {};
}
