import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_entry_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/Test/blue_dye_study_records_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

const _dye = MultipleChoice(
  id: 'BlueDyeQuestion',
  type: 'category.BM',
  prompt: 'Blue?',
  choices: ['Yes', 'No'],
);
final _profile = SubUser(
  id: 'profile',
  name: 'Profile',
  gender: '',
  birthYear: 2000,
  isControl: false,
);

class _Home extends QuestionHome {
  _Home() {
    all = {_dye.id: _dye};
  }
  @override
  Map<String, List<Question>> byType() => {
    'category.BM': [_dye],
  };
}

class _Repo extends TestEntryRepo {
  _Repo() : super(const AuthUser.uid(uid: 'account'), _profile);
  int subscriptions = 0;
  @override
  Stream<List<Entry>> get entries => super.entries.map(
    (entries) => entries.where((e) => e.stamp.month >= 10).toList(),
  );
  @override
  Stream<List<Entry>> entriesBySubtype(String subtype) {
    subscriptions++;
    return super.entries.map(
      (entries) => entries.where((e) => e.subtype == subtype).toList(),
    );
  }
}

Entry _bm(String id, String session, {bool blue = true}) => DetailResponse(
  id: id,
  detailType: 'category.BM',
  linkingId: session,
  stamp: dateToStamp(DateTime.utc(2026, 9, 1)),
  responses: [
    MultiResponse(
      question: _dye,
      index: blue ? 0 : 1,
      stamp: dateToStamp(DateTime.utc(2026, 9, 1)),
    ),
  ],
).toEntry(_profile.uid);

void main() {
  test('archived and active records stay separated across dates, edits, and deletions', () async {
    final repository = _Repo();
    final firstMeal = BlueDyeMealState(
      startTime: DateTime.utc(2026, 9, 1),
      finishedEating: const Duration(minutes: 15),
      amountConsumed: AmountConsumed.all,
    );
    final secondMeal = BlueDyeMealState(
      startTime: DateTime.utc(2026, 10, 1),
      finishedEating: const Duration(minutes: 45),
      amountConsumed: AmountConsumed.half,
    );
    final protocol = ActiveTestProtocol(
      id: 'protocol',
      testId: 'blue',
      currentStageId: 'awaiting_transit_2',
      testContext: {
        ...secondMeal.toContext(),
        blueDyeActiveRunSessionKey: 'second',
        blueDyeCompletedRunsKey: [
          BlueDyeRunSnapshot(
            sessionId: 'first',
            mealState: firstMeal.copyWith(
              logs: [
                BlueDyeBmLog(
                  stamp: dateToStamp(DateTime.utc(2026, 9, 1)),
                  isBlue: true,
                ),
              ],
            ),
            finishTime: DateTime.utc(2026, 9, 2),
          ).toJson(),
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        activeProtocolProvider.overrideWith((ref) async => protocol),
        entryRepoProvider.overrideWith((ref) async => repository),
        questionHomeProvider.overrideWith((ref) => Stream.value(_Home())),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    container.listen(blueDyeStudyRecordsProvider, (_, _) {});
    Future<Map<int, BlueDyeStudyRunRecords>> records() async {
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      return container.read(blueDyeStudyRecordsProvider.future);
    }

    final first = _bm('bm-first', 'first');
    await repository.addEntry(first);
    await repository.addEntry(_bm('bm-second', 'second'));
    await repository.addEntry(_bm('unrelated', 'other-study'));
    expect(await repository.entries.first, isEmpty);
    var saved = await records();
    expect(saved[0]!.meal.amountConsumed, AmountConsumed.all);
    expect(saved[1]!.meal.amountConsumed, AmountConsumed.half);
    expect(saved[0]!.bowelMovements.map((e) => e.id), ['bm-first']);
    expect(saved[1]!.bowelMovements.map((e) => e.id), ['bm-second']);

    await repository.updateEntry(_bm('bm-first', 'first', blue: false));
    expect((await records())[0]!.bowelMovements.single.isBlue, isFalse);
    await repository.removeEntry('bm-first');
    saved = await records();
    expect(saved[0]!.hasMeal, isTrue);
    expect(saved[0]!.bowelMovements, isEmpty);
    expect(saved[1]!.bowelMovements.single.id, 'bm-second');
    expect(repository.subscriptions, 1);
  });

  test(
    'starting a study alone is not a recorded meal; no future run is invented',
    () async {
      final protocol = ActiveTestProtocol(
        id: 'protocol',
        testId: 'blue',
        currentStageId: 'eat_meal',
        testContext: BlueDyeMealState(startTime: DateTime.utc(2026, 1, 1))
            .toContext(),
      );
      final container = ProviderContainer(
        overrides: [
          activeProtocolProvider.overrideWith((ref) async => protocol),
          blueDyeRunLogsProvider.overrideWith((ref, session) async => []),
        ],
      );
      addTearDown(container.dispose);
      final records = await container.read(blueDyeStudyRecordsProvider.future);
      expect(records.keys, [0]);
      expect(records[0]!.hasMeal, isFalse);
    },
  );

  test(
    'missing first-run snapshot never relabels second-run data as first-run',
    () async {
      final state = const BlueDyeMealState().withTubeFeedingStart(
        DateTime.utc(2026, 1, 1),
      );
      final protocol = ActiveTestProtocol(
        id: 'protocol',
        testId: 'blue',
        currentStageId: 'completed',
        testContext: state.toContext(),
      );
      final container = ProviderContainer(
        overrides: [
          activeProtocolProvider.overrideWith((ref) async => protocol),
          blueDyeRunLogsProvider.overrideWith((ref, session) async => []),
        ],
      );
      addTearDown(container.dispose);
      final records = await container.read(blueDyeStudyRecordsProvider.future);
      expect(records.keys, [1]);
      expect(records[1]!.hasMeal, isTrue);
      expect(records[1]!.meal.finishedEatingTime, isNull);
    },
  );
}
