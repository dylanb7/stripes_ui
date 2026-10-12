import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/animated_segmented_progress.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/multi_record_screen.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  testWidgets('compound follow-ups keep one prompt per control', (
    tester,
  ) async {
    const location = AllThatApply(
      id: 'Pain-Location',
      prompt: 'Select the location of the pain',
      type: 'category.PAIN',
      isRequired: true,
      choices: [
        'Unable to determine pain location',
        'Upper left',
        'Top',
        'Upper right',
        'Left',
        'Center',
        'Right',
        'Lower left',
        'Bottom',
        'Lower right',
      ],
    );
    const level = Numeric(
      id: 'Pain-Rating',
      prompt: 'Rate the pain level',
      type: 'category.PAIN',
      isRequired: true,
    );
    await _pumpFlow(
      tester,
      questions: [_source, location, level],
      pages: [
        PageLayout(uid: 'first-page', questionIds: [_source.id]),
        PageLayout(
          uid: 'pain-details',
          header: location.prompt,
          questionIds: [location.id, level.id],
          dependsOn: DependsOn([
            ConditionGroup(
              conditions: [EqualsExact(_source.id, 0)],
              op: GroupOp.all,
            ),
          ]),
        ),
      ],
    );
    await _openDetails(tester);
    await _choose(tester, _source.id, 0);
    expect(find.text(location.prompt), findsOneWidget);
    expect(find.text(level.prompt), findsOneWidget);
    expect(find.text('Follow-up questions'), findsOneWidget);
    final group = find.byKey(const ValueKey('follow-ups-pain-details'));
    for (final key in [
      'compact-pain-location-unknown',
      'compact-pain-level-unknown',
    ]) {
      expect(
        find.descendant(of: group, matching: find.byKey(ValueKey(key))),
        findsOneWidget,
      );
    }
    await _next(tester);
    expect(_review, findsNothing);
    await _tapKey(tester, 'compact-pain-location-unknown');
    await _tapKey(tester, 'compact-pain-level-unknown');
    await _next(tester);
    expect(_review, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'inline follow-ups preserve context and review edits require new answers',
    (tester) async {
      final harness = await _pumpFlow(tester);
      await _openDetails(tester);
      expect(find.byKey(const ValueKey('details-page-progress')), findsNothing);
      expect(find.byType(AnimatedSegmentedProgress), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(_question(_source.id), findsOneWidget);
      expect(_question(_last.id), findsOneWidget);
      expect(_question(_followUp.id), findsNothing);
      expect(
        find.byKey(const ValueKey('category-notes-category.PAIN')),
        findsOneWidget,
      );
      await _next(tester);
      expect(_review, findsNothing);
      final sourceChoice = find.byKey(ValueKey('bowel-${_source.id}-choice-0'));
      await tester.ensureVisible(sourceChoice);
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      final beforeReveal = scroll.offset;
      await tester.tap(sourceChoice);
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(beforeReveal, 0.5));
      expect(_question(_source.id), findsOneWidget);
      expect(_question(_followUp.id), findsOneWidget);
      expect(
        find.byKey(const ValueKey('view-added-questions')),
        findsOneWidget,
      );
      await _tapKey(tester, 'view-added-questions');
      expect(find.byKey(const ValueKey('view-added-questions')), findsNothing);
      await _choose(tester, _followUp.id, 1);
      await _choose(tester, _source.id, 1);
      expect(_question(_followUp.id), findsNothing);
      await _choose(tester, _last.id, 0);
      await _next(tester);
      expect(_review, findsOneWidget);
      await _tapKey(tester, 'review-edit-category.PAIN');
      await _choose(tester, _source.id, 0);
      expect(
        tester
            .widget<BowelMovementChoiceButton>(
              find.byKey(ValueKey('bowel-${_followUp.id}-choice-1')),
            )
            .selected,
        isFalse,
      );
      await _next(tester);
      expect(_review, findsNothing);
      expect(_question(_followUp.id), findsOneWidget);
      await _choose(tester, _followUp.id, 0);
      await _next(tester);
      expect(_review, findsOneWidget);
      await _next(tester);
      final response = entryToDetailResponse(
        harness.writer.saved.single,
        harness.home,
      );
      expect(
        response.responses.map((r) => r.question.id),
        containsAll([_source.id, _followUp.id, _last.id]),
      );
    },
  );

  testWidgets('page requirements gate Next even when questions are optional', (
    tester,
  ) async {
    const optional = MultipleChoice(
      id: 'page-required-answer',
      prompt: 'Select an answer to complete this page.',
      type: 'category.PAIN',
      choices: ['Yes', 'No'],
    );
    await _pumpFlow(
      tester,
      questions: [optional, _last],
      pages: [
        PageLayout(
          uid: 'requirement-page',
          questionIds: [optional.id],
          requirement: Requirement.exists(optional.id),
        ),
        PageLayout(uid: 'last-page', questionIds: [_last.id]),
      ],
    );
    await _openDetails(tester);
    await _next(tester);
    expect(_question(optional.id), findsOneWidget);
    expect(_question(_last.id), findsOneWidget);
    expect(_review, findsNothing);
    await _choose(tester, optional.id, 0);
    await _next(tester);
    expect(_question(_last.id), findsOneWidget);
    expect(_review, findsNothing);
  });

  testWidgets(
    'required study additions remain reachable after ordinary pages',
    (tester) async {
      const studyQuestion = MultipleChoice(
        id: 'BlueDyeQuestion',
        prompt: 'Did this happen during your study?',
        type: 'category.PAIN',
        choices: ['Yes', 'No'],
        isRequired: true,
        isAddition: true,
      );
      const protocol = ActiveTestProtocol(
        id: 'active-study',
        testId: 'test',
        currentStageId: 'recording',
      );
      final definition = TestDefinition(
        id: 'test',
        nameKey: 'Test',
        listensTo: const {'category.PAIN'},
        stages: const [
          TestStage(
            id: 'recording',
            injection: StageInjection(
              targetRecordPath: 'category.PAIN',
              placement: TestQuestionPlacement.review,
              pageIndex: 0,
              questionIds: ['BlueDyeQuestion'],
            ),
            triggers: [],
          ),
        ],
      );
      final studies = ModularTestsRepo(
        source: const _Protocols([protocol]),
        engine: DefaultTestEngine(
          testDefinitions: [definition],
          registry: TriggerRegistry(const {}),
        ),
        definitions: [definition],
        initialProtocols: const [protocol],
      );
      addTearDown(studies.dispose);
      await _pumpFlow(
        tester,
        questions: [_last, studyQuestion],
        pages: [
          PageLayout(uid: 'ordinary-page', questionIds: [_last.id]),
        ],
        studies: studies,
      );
      await _tapKey(tester, 'select-category-category.PAIN');
      await _next(tester);
      for (final precision in ['dayPart', 'unknown']) {
        final chip = find.descendant(
          of: find.byKey(ValueKey('precision-$precision')),
          matching: find.byType(ChoiceChip),
        );
        expect(tester.widget<ChoiceChip>(chip).onSelected, isNull);
      }
      await _tapKey(tester, 'record-yesterday');
      await _next(tester);
      expect(_question(studyQuestion.id), findsOneWidget);
      await _choose(tester, _last.id, 0);
      await _next(tester);
      expect(_question(studyQuestion.id), findsOneWidget);
      expect(_review, findsNothing);
      await _next(tester);
      expect(_question(studyQuestion.id), findsOneWidget);
      expect(_review, findsNothing);
      await _tap(tester, find.widgetWithText(ChoiceChip, 'No'));
      await _next(tester);
      expect(_review, findsOneWidget);
    },
  );

  testWidgets(
    'same-page dependent question is announced and remains required',
    (tester) async {
      final followUp = MultipleChoice(
        id: 'inline-follow-up',
        prompt: 'Which symptom followed the meal?',
        type: 'category.PAIN',
        choices: const ['Pain', 'Discomfort'],
        isRequired: true,
        dependsOn: DependsOn([
          ConditionGroup(
            conditions: [EqualsExact(_source.id, 0)],
            op: GroupOp.all,
          ),
        ]),
      );
      await _pumpFlow(
        tester,
        questions: [_source, followUp],
        pages: [
          PageLayout(
            uid: 'inline-page',
            questionIds: [_source.id, followUp.id],
          ),
        ],
      );
      await _openDetails(tester);
      expect(_question(followUp.id), findsNothing);
      expect(find.text('Follow-up questions'), findsNothing);
      await _choose(tester, _source.id, 0);
      expect(_question(_source.id), findsOneWidget);
      expect(_question(followUp.id), findsOneWidget);
      final announcement = find.text('View added questions');
      expect(announcement, findsOneWidget);
      expect(
        tester
            .widgetList<Semantics>(
              find.ancestor(of: announcement, matching: find.byType(Semantics)),
            )
            .any((semantics) => semantics.properties.liveRegion == true),
        isTrue,
      );
      await _next(tester);
      expect(_review, findsNothing);
      expect(_question(followUp.id), findsOneWidget);
      await _choose(tester, followUp.id, 1);
      await _next(tester);
      expect(_review, findsOneWidget);
    },
  );

  testWidgets(
    'invalid long page scrolls the missing required question into view',
    (tester) async {
      final optionalQuestions = [
        for (var i = 0; i < 8; i++)
          MultipleChoice(
            id: 'optional-$i',
            prompt: 'Optional symptom question ${i + 1}',
            type: 'category.PAIN',
            choices: const ['Yes', 'No'],
          ),
      ];
      await _pumpFlow(
        tester,
        questions: [...optionalQuestions, _last],
        pages: [
          PageLayout(
            uid: 'long-page',
            questionIds: [
              for (final question in optionalQuestions) question.id,
              _last.id,
            ],
          ),
        ],
      );
      await _openDetails(tester);
      expect(tester.getTopLeft(_question(_last.id)).dy, greaterThan(812));
      await _next(tester);
      final header = tester.getRect(
        find.byKey(const ValueKey('multi-record-header')),
      );
      final requiredQuestion = tester.getRect(_question(_last.id));
      final button = tester.getRect(
        find.byKey(const ValueKey('multi-record-continue')),
      );
      expect(requiredQuestion.top, greaterThanOrEqualTo(header.bottom));
      expect(requiredQuestion.top, lessThan(button.top));
      expect(
        find.text('Complete the required questions before continuing.'),
        findsOneWidget,
      );
    },
  );

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'header collapses alongside compact progress at ${textScale}x text',
      (tester) async {
        final questions = [
          for (var i = 0; i < 8; i++)
            MultipleChoice(
              id: 'long-$i',
              prompt: 'How did symptom ${i + 1} affect your day?',
              type: 'category.PAIN',
              choices: const ['Mild', 'Moderate', 'Severe'],
            ),
        ];
        await _pumpFlow(
          tester,
          textScale: textScale,
          questions: questions,
          pages: [
            PageLayout(
              uid: 'scrolling-page',
              questionIds: questions.map((question) => question.id).toList(),
            ),
          ],
        );
        final selectionHeader = tester
            .widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
            .delegate;
        expect(selectionHeader.minExtent, selectionHeader.maxExtent);
        await _openDetails(tester);
        final header = find.byKey(const ValueKey('multi-record-header'));
        final before = tester.getSize(header).height;
        expect(find.byKey(const ValueKey('record-step-label')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('record-step-progress')),
          findsOneWidget,
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.getSize(header).height, lessThan(before));
        final label = tester.getRect(
          find.byKey(const ValueKey('record-step-label')),
        );
        final progress = tester.getRect(
          find.byKey(const ValueKey('record-step-progress')),
        );
        expect(progress.left, greaterThanOrEqualTo(label.right));
        expect(progress.center.dy, closeTo(label.center.dy, 0.5));
        expect(label.center.dy, closeTo(tester.getRect(header).center.dy, 0.5));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

const _source = MultipleChoice(
  id: 'branch-source',
  prompt: 'Did you have pain after a meal?',
  type: 'category.PAIN',
  choices: ['Yes', 'No'],
  isRequired: true,
);
const _followUp = MultipleChoice(
  id: 'branch-follow-up',
  prompt: 'How soon after the meal did pain start?',
  type: 'category.PAIN',
  choices: ['Immediately', 'Later'],
  isRequired: true,
);
const _last = MultipleChoice(
  id: 'last-question',
  prompt: 'How long did the pain last?',
  type: 'category.PAIN',
  choices: ['Briefly', 'A long time'],
  isRequired: true,
);
final _profile = SubUser(
  id: 'navigation-profile',
  name: 'Alex',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

Finder _question(String id) => find.byKey(ValueKey('detail-question-$id'));
Finder get _review =>
    find.byKey(const ValueKey('review-category-category.PAIN'));
Future<void> _openDetails(WidgetTester tester) async {
  await _tapKey(tester, 'select-category-category.PAIN');
  await _next(tester);
  await _tapKey(tester, 'record-yesterday');
  await _next(tester);
}

Future<void> _next(WidgetTester tester) =>
    _tapKey(tester, 'multi-record-continue');
Future<void> _choose(WidgetTester tester, String questionId, int index) =>
    _tapKey(tester, 'bowel-$questionId-choice-$index');

Future<void> _tapKey(WidgetTester tester, String key) =>
    _tap(tester, find.byKey(ValueKey(key)));
Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<_Harness> _pumpFlow(
  WidgetTester tester, {
  List<Question> questions = const [_source, _followUp, _last],
  List<PageLayout>? pages,
  double textScale = 1,
  ModularTestsRepo? studies,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final home = _QuestionHome({
    for (final question in questions) question.id: question,
  });
  final path = RecordPath(
    name: 'category.PAIN',
    pages:
        pages ??
        [
          PageLayout(uid: 'first-page', questionIds: [_source.id]),
          PageLayout(
            uid: 'conditional-page',
            questionIds: [_followUp.id],
            dependsOn: DependsOn([
              ConditionGroup(
                conditions: [EqualsExact(_source.id, 0)],
                op: GroupOp.all,
              ),
            ]),
          ),
          PageLayout(uid: 'last-page', questionIds: [_last.id]),
        ],
  );
  final graph = QuestionGraphBuilder.build(home: home, recordPaths: [path]);
  final data = MultiRecordContext(
    authUserId: 'auth-user',
    profile: _profile,
    categories: [RecordItem(path: path)],
    graph: graph,
    tests: studies,
  );
  final writer = _Writer();
  final container = ProviderContainer(
    overrides: [
      configProvider.overrideWith(
        (ref) => const StripesConfig.sandbox(
          betaUi: BetaUiConfig.disabled(
            multiSessionFlow: true,
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
    ],
  );
  final router = GoRouter(
    initialLocation: '/multi',
    routes: [
      GoRoute(
        path: '/multi',
        builder: (_, _) => MultiRecordFlow(data: data),
      ),
      GoRoute(
        path: Routes.HOME,
        builder: (_, _) => const Scaffold(body: Text('Saved')),
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
            path: 'navigation-questions',
            assetBundle: _QuestionBundle(),
          ),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return _Harness(home, writer);
}

class _QuestionBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(utf8.encode('{"category.PAIN":"Pain"}')),
  );
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
}

class _Harness {
  final _QuestionHome home;
  final _Writer writer;
  const _Harness(this.home, this.writer);
}

class _Protocols implements ActiveTestProtocolSource {
  final List<ActiveTestProtocol> protocols;
  const _Protocols(this.protocols);
  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() async => protocols;
  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {}
}

class _Writer implements RecordSessionWriter {
  List<Entry> saved = [];
  @override
  Future<RepoResult<List<Entry>>> createSession({
    required String sessionId,
    required List<Entry> entries,
    bool preserveEntrySessionIds = false,
  }) async {
    saved = entries;
    return Success(entries);
  }

  @override
  Future<RepoResult<List<Entry>>> updateSession({
    required List<Entry> entries,
  }) => throw UnimplementedError();
  @override
  Future<RepoResult<void>> removeEntries({required List<Entry> entries}) =>
      throw UnimplementedError();
}
