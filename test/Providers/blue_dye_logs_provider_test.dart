import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_entry_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';

const _protocol = ActiveTestProtocol(
  id: 'protocol',
  testId: 'blue_dye_transit_test',
  currentStageId: 'awaiting_transit',
  testContext: {blueDyeActiveRunSessionKey: 'active-run'},
);
const _dyeQuestion = MultipleChoice(
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

class _QuestionHome extends QuestionHome {
  _QuestionHome() {
    all = {_dyeQuestion.id: _dyeQuestion};
  }
  @override
  Map<String, List<Question>> byType() => {
    'category.BM': [_dyeQuestion],
  };
}

class _AllDatesRepo extends TestEntryRepo {
  int subtypeRequests = 0;
  _AllDatesRepo() : super(const AuthUser.uid(uid: 'account'), _profile);

  // Mirrors a repository whose visible timeline starts in October.
  @override
  Stream<List<Entry>> get entries => super.entries.map(
    (entries) => entries
        .where((entry) => !entry.stamp.isBefore(DateTime.utc(2026, 10)))
        .toList(),
  );

  @override
  Stream<List<Entry>> entriesBySubtype(String subtype) {
    subtypeRequests++;
    return super.entries.map(
      (entries) => entries.where((entry) => entry.subtype == subtype).toList(),
    );
  }
}

Entry _bm(
  String id,
  DateTime stamp, {
  int selected = 0,
  String sessionId = 'active-run',
}) => DetailResponse(
  id: id,
  stamp: dateToStamp(stamp),
  detailType: 'category.BM',
  linkingId: sessionId,
  responses: [
    MultiResponse(
      question: _dyeQuestion,
      stamp: dateToStamp(stamp),
      index: selected,
    ),
  ],
).toEntry(_profile.uid);

void main() {
  late _AllDatesRepo repository;
  late ProviderContainer container;
  setUp(() {
    repository = _AllDatesRepo();
    container = ProviderContainer(
      overrides: [
        activeProtocolProvider.overrideWith((_) async => _protocol),
        entryRepoProvider.overrideWith((_) async => repository),
        questionHomeProvider.overrideWith((_) => Stream.value(_QuestionHome())),
      ],
    );
    container.listen(blueDyeBmTestLogsProvider, (_, _) {});
  });
  tearDown(() {
    container.dispose();
    repository.dispose();
  });

  Future<List<BMTestLog>> logs() async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    return container.read(blueDyeBmTestLogsProvider.future);
  }

  test('active run includes prior-month BMs excluded from History', () async {
    await repository.addEntry(
      _bm('september-blue', DateTime.utc(2026, 9, 30, 23)),
    );
    await repository.addEntry(
      _bm('october-brown', DateTime.utc(2026, 10, 1), selected: 1),
    );
    await repository.addEntry(
      _bm('other-run', DateTime.utc(2026, 9, 29), sessionId: 'other'),
    );
    expect((await repository.entries.first).map((entry) => entry.id), [
      'october-brown',
    ]);

    final result = await logs();
    expect(result.map((log) => log.id), ['september-blue', 'october-brown']);
    expect(result.map((log) => log.isBlue), [true, false]);
    expect(repository.subtypeRequests, 1);
  });

  test('older BM edits and removals update logs without another subtype subscription', () async {
    final blue = _bm('prior-month', DateTime.utc(2026, 9, 30));
    await repository.addEntry(blue);
    expect((await logs()).single.isBlue, isTrue);

    await repository.updateEntry(_bm('prior-month', blue.stamp, selected: 1));
    expect((await logs()).single.isBlue, isFalse);
    await repository.removeEntry('prior-month');
    expect(await logs(), isEmpty);
    expect(repository.subtypeRequests, 1);
  });
}
