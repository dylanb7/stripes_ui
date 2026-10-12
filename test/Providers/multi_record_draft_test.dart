import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';

void main() {
  test(
    'deselecting and reselecting retains answers, time, and entry identity',
    () {
      final fixture = _Fixture();
      final draft = fixture.draft;
      draft.toggle(fixture.items.first);
      final category = draft.selected.single;
      category.graph.addResponse(_answer(_pain, 'Severe'));
      draft.setSeparateTimes(true);
      const time = RecordTime(
        exactTime: TimeOfDay(hour: 9, minute: 0),
        precision: RecordTimePrecision.dayPart,
        dayPart: RecordDayPart.morning,
      );
      draft.setTime(time, type: category.type);
      draft.toggle(fixture.items.first);

      expect(draft.selected, isEmpty);
      expect(draft.questionsValid, isFalse);
      expect(draft.timesValid(fixture.now), isFalse);
      draft.toggle(fixture.items.first);

      expect(draft.selected.single, same(category));
      expect(draft.selected.single.entryId, category.entryId);
      expect(category.graph.fromQuestion(_pain), _answer(_pain, 'Severe'));
      expect(draft.timeFor(category.type), same(time));
      expect(draft.questionsValid, isTrue);
    },
  );

  test('each category owns independent answers even for a shared question', () {
    final fixture = _Fixture();
    final draft = fixture.draft;
    // Reverse the click order to verify a stable configured category order.
    draft.toggle(fixture.items.last);
    draft.toggle(fixture.items.first);
    final categories = draft.selected;
    expect(categories.map((category) => category.type), [
      'Pain',
      'Bowel Movement',
    ]);
    categories.first.graph.addResponse(_answer(_pain, 'Mild pain'));
    categories.first.graph.addResponse(_answer(_note, 'After breakfast'));
    categories.last.graph.addResponse(_answer(_bowel, 'Normal'));
    categories.last.graph.addResponse(_answer(_note, 'After lunch'));

    final entries = draft.entries();
    final responses = entries
        .map((entry) => entryToDetailResponse(entry, fixture.home))
        .toList();
    expect(responses.first.responses.map((response) => response.question.id), [
      _pain.id,
      _note.id,
    ]);
    expect(responses.last.responses.map((response) => response.question.id), [
      _bowel.id,
      _note.id,
    ]);
    expect(
      (responses.first.responses.last as OpenResponse).response,
      'After breakfast',
    );
    expect(
      (responses.last.responses.last as OpenResponse).response,
      'After lunch',
    );
  });

  test('required existing questions gate the combined draft', () {
    final fixture = _Fixture();
    final draft = fixture.draft;
    draft.toggle(fixture.items.first);
    draft.toggle(fixture.items.last);

    expect(draft.questionsValid, isFalse);
    draft.selected.first.graph.addResponse(_answer(_pain, 'Mild'));
    expect(draft.questionsValid, isFalse);
    draft.selected.last.graph.addResponse(_answer(_bowel, 'Normal'));
    expect(draft.questionsValid, isTrue);
    draft.selected.first.graph.removeResponse(_pain);
    expect(draft.questionsValid, isFalse);
  });

  test('mixed category times share the chosen date and preserve precision', () {
    final fixture = _Fixture();
    final draft = fixture.draft;
    draft.toggle(fixture.items.first);
    draft.toggle(fixture.items.last);
    draft.setSeparateTimes(true);
    draft.setDate(DateTime(2026, 10, 3, 18, 42));
    draft.setTime(
      const RecordTime(exactTime: TimeOfDay(hour: 11, minute: 24)),
      type: 'Pain',
    );
    draft.setTime(
      const RecordTime(
        exactTime: TimeOfDay(hour: 8, minute: 0),
        precision: RecordTimePrecision.dayPart,
        dayPart: RecordDayPart.earlyMorning,
      ),
      type: 'Bowel Movement',
    );

    final entries = draft.entries();
    expect(draft.date, DateTime(2026, 10, 3));
    expect(entries.first.stamp.toLocal(), DateTime(2026, 10, 3, 11, 24));
    expect(entries.last.stamp.toLocal(), DateTime(2026, 10, 3));
    expect(entries.first.timeOfDay, TimeOfDayEntry.exact);
    expect(
      RecordTime.fromEntry(entries.last).dayPart,
      RecordDayPart.earlyMorning,
    );
    expect(draft.timesValid(fixture.now), isTrue);
  });

  test('switching timing modes retains independent values until shared time changes', () {
    final fixture = _Fixture();
    final draft = fixture.draft;
    draft.toggle(fixture.items.first);
    draft.toggle(fixture.items.last);
    final shared = draft.sharedTime;
    const first = RecordTime(exactTime: TimeOfDay(hour: 9, minute: 5));
    const second = RecordTime(
      exactTime: TimeOfDay(hour: 0, minute: 0),
      precision: RecordTimePrecision.unknown,
    );
    draft.setSeparateTimes(true);
    draft.setTime(first, type: 'Pain');
    draft.setTime(second, type: 'Bowel Movement');
    draft.setSeparateTimes(false);
    expect(draft.timeFor('Pain'), same(shared));
    expect(draft.timeFor('Bowel Movement'), same(shared));
    draft.setSeparateTimes(true);
    expect(draft.timeFor('Pain'), same(first));
    expect(draft.timeFor('Bowel Movement'), same(second));

    draft.setSeparateTimes(false);
    const replacement = RecordTime(exactTime: TimeOfDay(hour: 12, minute: 15));
    draft.setTime(replacement);
    draft.setSeparateTimes(true);
    expect(draft.timeFor('Pain'), same(replacement));
    expect(draft.timeFor('Bowel Movement'), same(replacement));
  });

  test(
    'snapshots retain stable entry IDs, creation time, and bound profile',
    () {
      final fixture = _Fixture();
      final draft = fixture.draft;
      draft.toggle(fixture.items.first);
      draft.toggle(fixture.items.last);
      final first = draft.entries();
      draft.selected.first.graph.addResponse(_answer(_pain, 'Updated answer'));
      final second = draft.entries();

      expect(second.map((entry) => entry.id), first.map((entry) => entry.id));
      expect(second.map((entry) => entry.id).toSet(), hasLength(2));
      expect(second.map((entry) => entry.subUserId), everyElement('profile-a'));
      expect(
        second.map((entry) => entry.createdAt),
        everyElement(fixture.now.toUtc()),
      );
      expect(draft.context.authUserId, 'auth-user');
      expect(draft.batchId, isNotEmpty);
      final other = _Fixture(profileId: 'profile-b');
      other.draft.toggle(other.items.first);
      expect(other.draft.entries().single.subUserId, 'profile-b');
      expect(draft.entries().first.subUserId, 'profile-a');
      expect(other.draft.batchId, isNot(draft.batchId));
    },
  );

  for (final (label, listensTo, completed, painExact, bowelExact) in [
    ('matching listener without injection', {'Pain'}, false, true, false),
    ('unrelated listener', {'Meal'}, false, false, false),
    ('completed listener', {'Pain'}, true, false, false),
    (
      'empty listener set matches all categories',
      <String>{},
      false,
      true,
      true,
    ),
  ]) {
    test(label, () {
      final fixture = _Fixture(
        listensTo: listensTo,
        completed: completed,
        unrelatedFirst: true,
      );
      fixture.draft.toggle(fixture.items.first);
      fixture.draft.toggle(fixture.items.last);
      final categories = fixture.draft.selected;
      expect(categories.first.requiresExactTime, painExact);
      expect(categories.last.requiresExactTime, bowelExact);
      expect(
        categories.every((category) => !category.requiresBlueDyeSession),
        isTrue,
      );
      const approximate = RecordTime(
        exactTime: TimeOfDay(hour: 10, minute: 0),
        precision: RecordTimePrecision.unknown,
      );
      fixture.draft.setTime(approximate);
      expect(fixture.draft.timesValid(fixture.now), !painExact && !bowelExact);
      fixture.draft.setSeparateTimes(true);
      for (final category in categories.where(
        (category) => category.requiresExactTime,
      )) {
        fixture.draft.setTime(
          const RecordTime(exactTime: TimeOfDay(hour: 10, minute: 0)),
          type: category.type,
        );
      }
      expect(fixture.draft.timesValid(fixture.now), isTrue);
      // Generic timing requirements must not assign a Blue Meal session ID.
      expect(
        fixture.draft
            .entries(blueDyeSessionId: 'blue-run')
            .map((entry) => entry.sessionId),
        everyElement(isNull),
      );
    });
  }

  for (final placement in TestQuestionPlacement.values) {
    test(
      '${placement.name} injected study questions keep validation and study linkage',
      () {
        final fixture = _Fixture(injection: placement);
        final draft = fixture.draft;
        draft.toggle(fixture.items.first);
        draft.toggle(fixture.items.last);
        final pain = draft.selected.first;
        final bowel = draft.selected.last;
        pain.graph.addResponse(_answer(_pain, 'Mild'));
        bowel.graph.addResponse(_answer(_bowel, 'Normal'));

        expect(draft.questionsValid, isFalse);
        expect(pain.requiresExactTime, isFalse);
        expect(bowel.requiresExactTime, isTrue);
        bowel.graph.addResponse(
          MultiResponse(question: _blueDye, stamp: 1, index: 0),
        );
        expect(draft.questionsValid, isTrue);
        final entries = draft.entries(blueDyeSessionId: 'study-run');
        expect(entries.first.sessionId, isNull);
        expect(entries.last.sessionId, 'study-run');
        expect(
          entryToDetailResponse(
            entries.last,
            fixture.home,
          ).responses.map((response) => response.question.id),
          contains(_blueDye.id),
        );
        draft.setTime(
          const RecordTime(
            exactTime: TimeOfDay(hour: 10, minute: 0),
            precision: RecordTimePrecision.unknown,
          ),
        );
        expect(draft.timesValid(fixture.now), isFalse);
        draft.setSeparateTimes(true);
        draft.setTime(
          const RecordTime(exactTime: TimeOfDay(hour: 10, minute: 0)),
          type: 'Bowel Movement',
        );
        expect(draft.timesValid(fixture.now), isTrue);
      },
    );
  }
}

const _pain = FreeResponse(
  id: 'pain',
  prompt: 'Describe pain',
  type: 'Pain',
  isRequired: true,
);
const _bowel = FreeResponse(
  id: 'bowel',
  prompt: 'Describe bowel movement',
  type: 'Bowel Movement',
  isRequired: true,
);
const _note = FreeResponse(id: 'note', prompt: 'Notes', type: 'Notes');
const _blueDye = MultipleChoice(
  id: 'BlueDyeQuestion',
  prompt: 'Was the stool blue?',
  type: 'Bowel Movement',
  choices: ['Yes', 'No'],
  isRequired: true,
);

OpenResponse _answer(FreeResponse question, String text) =>
    OpenResponse(question: question, stamp: 1, response: text);

class _Fixture {
  final now = DateTime(2026, 10, 7, 14, 30);
  final home = _QuestionHome({
    for (final question in [_pain, _bowel, _note, _blueDye])
      question.id: question,
  });
  late final List<RecordItem> items;
  late final MultiRecordDraft draft;

  _Fixture({
    String profileId = 'profile-a',
    TestQuestionPlacement? injection,
    Set<String>? listensTo,
    bool completed = false,
    bool unrelatedFirst = false,
  }) {
    items = [
      RecordItem(
        path: RecordPath(
          name: 'Pain',
          pages: [
            PageLayout(questionIds: [_pain.id, _note.id]),
          ],
        ),
      ),
      RecordItem(
        path: RecordPath(
          name: 'Bowel Movement',
          pages: [
            PageLayout(questionIds: [_bowel.id, _note.id]),
          ],
        ),
      ),
    ];
    final graph = QuestionGraphBuilder.build(
      home: home,
      recordPaths: items.map((item) => item.path).toList(),
    );
    ModularTestsRepo? tests;
    if (injection != null || listensTo != null) {
      final protocol = ActiveTestProtocol(
        id: 'study-run',
        isCompleted: completed,
        testId: 'test',
        currentStageId: 'recording',
      );
      final definition = TestDefinition(
        id: 'test',
        nameKey: 'Test',
        listensTo: listensTo ?? const {'Bowel Movement'},
        stages: [
          TestStage(
            id: 'recording',
            injection: injection == null
                ? null
                : StageInjection(
                    targetRecordPath: 'Bowel Movement',
                    placement: injection,
                    pageIndex: 0,
                    questionIds: const ['BlueDyeQuestion'],
                  ),
            triggers: const [],
          ),
        ],
      );
      final protocols = [
        if (unrelatedFirst)
          const ActiveTestProtocol(
            id: 'unrelated',
            testId: 'unknown-test',
            currentStageId: 'recording',
          ),
        protocol,
      ];
      tests = ModularTestsRepo(
        source: _ActiveProtocolSource(protocols),
        engine: DefaultTestEngine(
          testDefinitions: [definition],
          registry: TriggerRegistry(const {}),
        ),
        definitions: [definition],
        initialProtocols: protocols,
      );
    }
    draft = MultiRecordDraft(
      now: now,
      context: MultiRecordContext(
        authUserId: 'auth-user',
        profile: SubUser(
          id: profileId,
          name: 'Profile',
          gender: '',
          birthYear: 2000,
          isControl: false,
        ),
        categories: items,
        graph: graph,
        tests: tests,
      ),
    );
    addTearDown(() {
      draft.dispose();
      graph.dispose();
      tests?.dispose();
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

class _ActiveProtocolSource implements ActiveTestProtocolSource {
  final List<ActiveTestProtocol> protocols;
  const _ActiveProtocolSource(this.protocols);

  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() async => protocols;

  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {}
}
