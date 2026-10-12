import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Navigation/route_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/multi_record_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/record_screen.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  for (final betaEnabled in [false, true]) {
    testWidgets('beta $betaEnabled gates the launcher and direct route', (
      tester,
    ) async {
      final harness = await _pumpFlow(
        tester,
        betaEnabled: betaEnabled,
        showOptions: true,
      );
      final launcher = find.byKey(const ValueKey('start-multi-record'));
      expect(launcher, betaEnabled ? findsOneWidget : findsNothing);
      expect(
        find.byType(RecordButton),
        betaEnabled ? findsNothing : findsNWidgets(2),
      );

      // Exercise the actual production page factory without building the
      // unrelated dashboard and account-provider tree around that route.
      final productionRouter = harness.container.read(routeProvider);
      addTearDown(productionRouter.dispose);
      final route = _allGoRoutes(productionRouter.configuration.routes)
          .singleWhere((route) => route.path == Routes.MULTI_RECORD);
      final context = tester.element(find.byType(Options));
      final page = route.pageBuilder!(context, GoRouterState.of(context));
      if (betaEnabled) {
        expect(page, isA<FadeIn>());
        expect((page as FadeIn).child, isA<MultiRecordScreen>());
        await _tap(tester, launcher);
        expect(find.text('Launched multi-record'), findsOneWidget);
      } else {
        expect(page, isA<NoTransitionPage>());
        expect((page as NoTransitionPage).child, isA<Home>());
      }
      expect(tester.takeException(), isNull);
    });
  }

  if (const bool.fromEnvironment('RECORD_FLOW_SCREENSHOTS')) {
    testWidgets('capture multi-record preview screens', (tester) async {
      await _pumpFlow(tester, includeAllCategories: true);
      expect(find.byType(SvgPicture), findsNWidgets(5));
      for (final label in _categoryLabels.values) {
        expect(find.text(label), findsOneWidget);
      }
      await _tapKey(tester, 'select-category-category.PAIN');
      await _tapKey(tester, 'select-category-category.BM');
      await _capture(tester, 'selection');
      await _continue(tester);
      await _tapKey(tester, 'record-yesterday');
      await _tapKey(tester, 'precision-dayPart');
      await _tapKey(tester, 'period-earlyMorning');
      await _capture(tester, 'time');
      await tester.drag(
        find.byKey(const ValueKey('multi-record-scroll')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'collapsed', resetScroll: false);
      await _continue(tester);
      await _capture(tester, 'details');
      await _tapKey(tester, 'bowel-existing-pain-choice-0');
      await _continue(tester);
      await _tapKey(tester, 'bowel-existing-bowel-choice-1');
      await _continue(tester);
      await _capture(tester, 'review');
    });
  }
  testWidgets('tablet form aligns notes and footer and separates next cue', (
    tester,
  ) async {
    await _pumpFlow(tester, size: const Size(1200, 1000));
    await _tapKey(tester, 'select-category-category.PAIN');
    await _tapKey(tester, 'select-category-category.BM');
    await _continue(tester);
    await _tapKey(tester, 'record-yesterday');
    await _continue(tester);

    final form = find.byKey(const ValueKey('category-details-category.PAIN'));
    final notes = find.descendant(
      of: find.byType(LongTextEntry),
      matching: find.byType(InkWell),
    );
    final button = find.byKey(const ValueKey('multi-record-continue'));
    final nextCue = find.byKey(const ValueKey('record-next-destination'));
    final bounds = tester.getRect(form);
    for (final field in [notes, button, nextCue]) {
      final rect = tester.getRect(field);
      expect(rect.left, closeTo(bounds.left, 0.1));
      expect(rect.right, closeTo(bounds.right, 0.1));
    }
    expect(
      tester.getSize(find.byKey(const ValueKey('multi-record-header'))).width,
      1200,
    );
    expect(bounds.width, lessThan(800));
    expect(find.text('Anything else to add?'), findsOneWidget);
    expect(find.text('Description'), findsNothing);
    expect(
      find.descendant(of: button, matching: find.text('Continue')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: button, matching: find.text('Next: Bowel Movement')),
      findsNothing,
    );
    expect(
      find.descendant(of: nextCue, matching: find.text('Next: Bowel Movement')),
      findsOneWidget,
    );
    expect(
      tester.getRect(nextCue).top,
      greaterThan(tester.getRect(notes).bottom),
    );
    if (const bool.fromEnvironment('RECORD_FLOW_SCREENSHOTS')) {
      await _capture(tester, 'tablet-details');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ordinary answers rebuild details without rebuilding the flow shell',
    (tester) async {
      await _pumpFlow(tester);
      await _tapKey(tester, 'select-category-category.PAIN');
      await _continue(tester);
      await _continue(tester);
      final header = tester.widget(find.byType(SliverPersistentHeader));
      final action = tester.widget(
        find.byKey(const ValueKey('multi-record-continue')),
      );
      await _tapKey(tester, 'bowel-existing-pain-choice-0');
      expect(tester.widget(find.byType(SliverPersistentHeader)), same(header));
      expect(
        tester.widget(find.byKey(const ValueKey('multi-record-continue'))),
        same(action),
      );
      await _continue(tester);
      expect(
        find.byKey(const ValueKey('review-category-category.PAIN')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a non-Blue-Meal listener requires exact time and can save', (
    tester,
  ) async {
    const protocol = ActiveTestProtocol(
      id: 'pain-study',
      testId: 'pain-test',
      currentStageId: 'recording',
    );
    final definition = TestDefinition(
      id: 'pain-test',
      nameKey: 'Pain study',
      listensTo: const {'category.PAIN'},
      stages: const [TestStage(id: 'recording', triggers: [])],
    );
    final tests = ModularTestsRepo(
      source: const _ProtocolSource([protocol]),
      engine: DefaultTestEngine(
        testDefinitions: [definition],
        registry: TriggerRegistry(const {}),
      ),
      definitions: [definition],
      initialProtocols: const [protocol],
    );
    addTearDown(tests.dispose);
    final harness = await _pumpFlow(tester, tests: tests);
    await _tapKey(tester, 'select-category-category.PAIN');
    await _continue(tester);
    expect(
      tester
          .widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(const ValueKey('precision-unknown')),
              matching: find.byType(ChoiceChip),
            ),
          )
          .onSelected,
      isNull,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(const ValueKey('precision-dayPart')),
              matching: find.byType(ChoiceChip),
            ),
          )
          .onSelected,
      isNull,
    );
    await _tapKey(tester, 'record-yesterday');
    await _continue(tester);
    await _tapKey(tester, 'bowel-existing-pain-choice-0');
    await _continue(tester);
    await _continue(tester);
    expect(find.byKey(const ValueKey('record-home')), findsOneWidget);
    final entry = harness.writer.attempts.single.entries.single;
    expect(entry.timeOfDay, TimeOfDayEntry.exact);
    expect(entry.sessionId, isNull);
  });

  testWidgets(
    'multi-record review edits retain answers and retry one stable batch',
    (tester) async {
      final harness = await _pumpFlow(
        tester,
        textScale: 1.5,
        failFirstSave: true,
      );
      final continueFinder = find.byKey(
        const ValueKey('multi-record-continue'),
      );
      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);
      await _tapKey(tester, 'select-category-category.PAIN');
      await _tapKey(tester, 'select-category-category.BM');
      await _tapKey(tester, 'select-category-category.PAIN');
      expect(find.text('1 Entry'), findsOneWidget);
      await _tapKey(tester, 'select-category-category.PAIN');
      expect(find.text('2 Entries'), findsOneWidget);
      await _continue(tester);

      await _tapKey(tester, 'record-yesterday');
      await _tapKey(tester, 'precision-dayPart');
      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);
      await _tapKey(tester, 'period-earlyMorning');
      await _continue(tester);

      expect(
        find.byKey(const ValueKey('category-details-category.PAIN')),
        findsOneWidget,
      );
      expect(find.text(_pain.prompt), findsOneWidget);
      expect(find.text('Next: Bowel Movement'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
      await _continue(tester);
      expect(
        find.text('Complete the required questions before continuing.'),
        findsOneWidget,
      );
      await _tapKey(tester, 'bowel-existing-pain-choice-1');
      await _enterNotes(tester, 'category.PAIN', 'First pain note');
      await _continue(tester);

      expect(
        find.byKey(const ValueKey('category-details-category.BM')),
        findsOneWidget,
      );
      expect(find.text(_bowel.prompt), findsOneWidget);
      await _tapKey(tester, 'bowel-existing-bowel-choice-0');
      await _tapKey(tester, 'bowel-existing-bowel-choice-2');
      await _enterNotes(tester, 'category.BM', 'Bowel note');
      await _continue(tester);

      expect(
        find.byKey(const ValueKey('review-category-category.PAIN')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('review-category-category.BM')),
        findsOneWidget,
      );
      await _tapKey(tester, 'review-edit-category.PAIN');
      expect(find.text('First pain note'), findsOneWidget);
      await _tapKey(tester, 'bowel-existing-pain-choice-0');
      await _enterNotes(tester, 'category.PAIN', 'Edited pain note');
      await _continue(tester);
      expect(
        find.byKey(const ValueKey('review-category-category.BM')),
        findsOneWidget,
      );

      await _tapKey(tester, 'review-edit-time');
      await _tapKey(tester, 'record-separate-times');
      await _tapWithin(
        tester,
        'record-time-category.PAIN',
        'precision-unknown',
      );
      await _continue(tester);
      expect(
        find.byKey(const ValueKey('review-category-category.PAIN')),
        findsOneWidget,
      );
      expect(find.text('Edited pain note'), findsOneWidget);
      await _continue(tester);

      expect(harness.writer.attempts, hasLength(1));
      expect(
        find.text(
          'Your entries could not all be saved. Your draft is still here; try again.',
        ),
        findsOneWidget,
      );
      final first = harness.writer.attempts.single;
      expect(first.preserveEntrySessionIds, isTrue);
      expect(first.entries.map((entry) => entry.subtype), [
        'category.PAIN',
        'category.BM',
      ]);
      expect(
        first.entries.map((entry) => entry.subUserId),
        everyElement(_profile.uid),
      );
      expect(first.entries.first.timeOfDay, TimeOfDayEntry.notSure);
      expect(
        RecordTime.fromEntry(first.entries.last).dayPart,
        RecordDayPart.earlyMorning,
      );
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        first.entries.map((entry) => DateUtils.dateOnly(entry.stamp.toLocal())),
        everyElement(DateUtils.dateOnly(yesterday)),
      );
      final pain = entryToDetailResponse(first.entries.first, harness.home);
      final bowel = entryToDetailResponse(first.entries.last, harness.home);
      expect(pain.description, 'Edited pain note');
      expect((pain.responses.single as MultiResponse).index, 0);
      expect(bowel.description, 'Bowel note');
      expect((bowel.responses.single as AllResponse).responses, [0, 2]);
      expect(pain.responses.single.question, _pain);
      expect(bowel.responses.single.question, _bowel);

      await _continue(tester);
      expect(harness.writer.attempts, hasLength(2));
      final retry = harness.writer.attempts.last;
      expect(retry.batchId, first.batchId);
      expect(retry.entries, first.entries);
      expect(find.byKey(const ValueKey('record-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'partial saves stay frozen when a later retry cannot read storage',
    (tester) async {
      final harness = await _pumpFlow(tester);
      harness.writer.failures.addAll([
        Failure(
          message: 'Partial save',
          error: RecordSessionWriteRecovery(
            cause: const Failure(message: 'Rollback failed'),
            remainingEntryIds: ['saved-entry'],
          ),
        ),
        const Failure(message: 'Read unavailable'),
      ]);
      await _tapKey(tester, 'select-category-category.PAIN');
      await _continue(tester);
      await _tapKey(tester, 'precision-unknown');
      await _continue(tester);
      await _tapKey(tester, 'bowel-existing-pain-choice-0');
      await _continue(tester);
      await _continue(tester);
      await _continue(tester);

      expect(harness.writer.attempts, hasLength(2));
      expect(
        tester
            .widget<AbsorbPointer>(
              find.byKey(const ValueKey('multi-record-content')),
            )
            .absorbing,
        isTrue,
      );
      expect(find.text('Review and save'), findsOneWidget);
      await _continue(tester);
      expect(harness.writer.attempts, hasLength(3));
      final first = harness.writer.attempts.first;
      for (final retry in harness.writer.attempts.skip(1)) {
        expect(retry.batchId, first.batchId);
        expect(retry.entries, first.entries);
      }
      expect(find.byKey(const ValueKey('record-home')), findsOneWidget);
    },
  );

  testWidgets(
    'all flow stages fit a 375 pixel phone at twice normal text size',
    (tester) async {
      await _pumpFlow(tester, textScale: 2);
      await _tapKey(tester, 'select-category-category.PAIN');
      await _tapKey(tester, 'select-category-category.BM');
      await _continue(tester);
      await _tapKey(tester, 'record-yesterday');
      await _tapKey(tester, 'precision-dayPart');
      // Reach each option, including periods below the fold at larger text sizes.
      for (final part in RecordDayPart.values) {
        await _tapKey(tester, 'period-${part.name}');
        expect(tester.takeException(), isNull);
      }
      await _continue(tester);
      await _tapKey(tester, 'bowel-existing-pain-choice-0');
      await _continue(tester);
      await _tapKey(tester, 'bowel-existing-bowel-choice-1');
      await _continue(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('review-category-category.BM')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('review-category-category.PAIN')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('review-category-category.BM')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a profile change blocks save until the original profile returns',
    (tester) async {
      final harness = await _pumpFlow(tester);
      await _tapKey(tester, 'select-category-category.PAIN');
      await _continue(tester);
      await _tapKey(tester, 'precision-unknown');
      await _continue(tester);
      await _tapKey(tester, 'bowel-existing-pain-choice-1');
      await _continue(tester);
      final notifier =
          harness.container.read(subHolderProvider.notifier) as _Profile;
      notifier.select(
        SubUser(
          id: 'another-profile',
          name: 'Someone else',
          gender: '',
          birthYear: 2000,
          isControl: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The active profile changed. Return to the original profile to continue this draft.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('multi-record-continue')),
            )
            .onPressed,
        isNull,
      );
      expect(harness.writer.attempts, isEmpty);
      notifier.select(_profile);
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(
        harness.writer.attempts.single.entries.single.subUserId,
        _profile.uid,
      );
      expect(find.byKey(const ValueKey('record-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _pain = MultipleChoice(
  id: 'existing-pain',
  prompt: 'How much pain did you experience?',
  type: 'category.PAIN',
  choices: ['Mild', 'Severe'],
  isRequired: true,
);
const _bowel = AllThatApply(
  id: 'existing-bowel',
  prompt: 'Which bowel symptoms occurred?',
  type: 'category.BM',
  choices: ['Straining', 'Bloating', 'Urgency'],
  isRequired: true,
);
final _profile = SubUser(
  id: 'record-profile',
  name: 'Alex',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

const _categoryLabels = {
  'category.PAIN': 'Pain',
  'category.BM': 'Bowel Movement',
  'category.Meal-Time': 'Meal',
  'category.REFLUX': 'GI Symptoms',
  'category.NB': 'Sleep',
};

class _QuestionBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(utf8.encode(jsonEncode(_categoryLabels))),
  );
}

Iterable<GoRoute> _allGoRoutes(Iterable<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route;
    yield* _allGoRoutes(route.routes);
  }
}

Future<_Harness> _pumpFlow(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double textScale = 1,
  bool failFirstSave = false,
  bool includeAllCategories = false,
  bool betaEnabled = true,
  bool showOptions = false,
  ModularTestsRepo? tests,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final home = _QuestionHome({_pain.id: _pain, _bowel.id: _bowel});
  final paths = [
    RecordPath(
      name: 'category.PAIN',
      pages: [
        PageLayout(questionIds: [_pain.id]),
      ],
    ),
    RecordPath(
      name: 'category.BM',
      pages: [
        PageLayout(questionIds: [_bowel.id]),
      ],
    ),
    if (includeAllCategories)
      for (final category in [
        'category.Meal-Time',
        'category.REFLUX',
        'category.NB',
      ])
        RecordPath(
          name: category,
          pages: [
            PageLayout(questionIds: [_pain.id]),
          ],
        ),
  ];
  final graph = QuestionGraphBuilder.build(home: home, recordPaths: paths);
  final data = MultiRecordContext(
    authUserId: 'auth-user',
    profile: _profile,
    categories: [for (final path in paths) RecordItem(path: path)],
    graph: graph,
    tests: tests,
  );
  final writer = _Writer(failFirstSave: failFirstSave);
  final container = ProviderContainer(
    overrides: [
      configProvider.overrideWith(
        (ref) => StripesConfig.sandbox(
          betaUi: BetaUiConfig.disabled(
            multiSessionFlow: betaEnabled,
            useCategoryTheme: true,
          ),
        ),
      ),
      authStream.overrideWith(
        (ref) => Stream.value(const AuthUser.uid(uid: 'auth-user')),
      ),
      subHolderProvider.overrideWith(_Profile.new),
      recordSessionWriterProvider.overrideWith((ref) async => writer),
      stampProvider.overrideWith((ref) async => null),
      entryRepoProvider.overrideWith((ref) async => null),
      baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
      availableRecordPaths.overrideWith((ref) async => data.categories),
      reviewPaths.overrideWith((ref, _) async => []),
    ],
  );
  final router = GoRouter(
    initialLocation: '/multi',
    routes: [
      GoRoute(
        path: '/multi',
        builder: (_, _) => showOptions
            ? const Scaffold(body: SingleChildScrollView(child: Options()))
            : MultiRecordFlow(data: data),
      ),
      GoRoute(
        path: '/launched',
        name: RouteName.MULTI_RECORD,
        builder: (_, _) => const Scaffold(body: Text('Launched multi-record')),
      ),
      GoRoute(
        path: Routes.HOME,
        builder: (_, _) =>
            const Scaffold(body: Text('Home', key: ValueKey('record-home'))),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    container.dispose();
    graph.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: light,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          QuestionsLocalizationsDelegate(
            path: 'test-questions',
            assetBundle: _QuestionBundle(),
          ),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(
            key: const ValueKey('record-flow-preview'),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return _Harness(container, writer, home);
}

Future<void> _continue(WidgetTester tester) =>
    _tapKey(tester, 'multi-record-continue');

Future<void> _capture(
  WidgetTester tester,
  String stage, {
  bool resetScroll = true,
}) async {
  if (resetScroll) {
    tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('multi-record-scroll')),
        )
        .controller!
        .jumpTo(0);
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('record-flow-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/private/tmp/stripes-multi-record-$stage.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await _tap(tester, find.byKey(ValueKey(key)));
}

Future<void> _tapWithin(WidgetTester tester, String parent, String key) async {
  await _tap(
    tester,
    find.descendant(
      of: find.byKey(ValueKey(parent)),
      matching: find.byKey(ValueKey(key)),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _enterNotes(
  WidgetTester tester,
  String category,
  String text,
) async {
  await _tap(
    tester,
    find.descendant(
      of: find.byKey(ValueKey('category-notes-$category')),
      matching: find.byType(InkWell),
    ),
  );
  final field = find.byType(TextField);
  expect(field, findsOneWidget);
  await tester.enterText(field, text);
  await _tap(tester, find.text('Done'));
}

class _Harness {
  final ProviderContainer container;
  final _Writer writer;
  final _QuestionHome home;
  const _Harness(this.container, this.writer, this.home);
}

class _QuestionHome extends QuestionHome {
  _QuestionHome(Map<String, Question> questions) {
    all = questions;
  }
  @override
  Map<String, List<Question>> byType() => const {};
}

class _Profile extends SubNotifier {
  @override
  SubState build() => SubState(subUsers: [_profile], selected: _profile);
  void select(SubUser profile) => state = AsyncData(
    SubState(subUsers: [_profile, profile], selected: profile),
  );
}

class _SaveAttempt {
  final String batchId;
  final List<Entry> entries;
  final bool preserveEntrySessionIds;
  const _SaveAttempt(this.batchId, this.entries, this.preserveEntrySessionIds);
}

class _Writer implements RecordSessionWriter {
  final bool failFirstSave;
  final List<_SaveAttempt> attempts = [];
  final List<Failure<List<Entry>>> failures = [];
  _Writer({this.failFirstSave = false});

  @override
  Future<RepoResult<List<Entry>>> createSession({
    required String sessionId,
    required List<Entry> entries,
    bool preserveEntrySessionIds = false,
  }) async {
    attempts.add(
      _SaveAttempt(sessionId, List.of(entries), preserveEntrySessionIds),
    );
    if (failures.isNotEmpty) return failures.removeAt(0);
    if (failFirstSave && attempts.length == 1) {
      return const Failure(message: 'Test save failure');
    }
    return Success(entries);
  }

  @override
  Future<RepoResult<List<Entry>>> updateSession({
    required List<Entry> entries,
  }) async => throw UnimplementedError();
  @override
  Future<RepoResult<void>> removeEntries({
    required List<Entry> entries,
  }) async => throw UnimplementedError();
}

class _ProtocolSource implements ActiveTestProtocolSource {
  final List<ActiveTestProtocol> protocols;
  const _ProtocolSource(this.protocols);
  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() async => protocols;
  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {}
}
