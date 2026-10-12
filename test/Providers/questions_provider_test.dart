import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

class _QuestionHome extends QuestionHome {
  _QuestionHome(Map<String, Question> questions) {
    all = questions;
  }

  @override
  Map<String, List<Question>> byType() => const {};
}

void main() {
  test('entry path providers exclude baseline-only paths', () async {
    const question = Check(id: 'q1', prompt: 'prompt', type: 'type');
    final recordPath = RecordPath(
      name: 'record',
      pages: [
        PageLayout(questionIds: const ['q1']),
      ],
    );
    final baselinePath = RecordPath(
      name: 'baseline',
      pages: [
        PageLayout(questionIds: const ['q1']),
      ],
      isBaseline: true,
    );
    final graph = QuestionGraphBuilder.build(
      home: _QuestionHome(const {'q1': question}),
      recordPaths: [recordPath, baselinePath],
    );
    final container = ProviderContainer(
      overrides: [
        questionGraphProvider.overrideWith((ref) async => graph),
        baselinesStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);

    final paths = await container.read(
      recordPaths(
        const RecordPathProps(filterEnabled: true, type: PathProviderType.both),
      ).future,
    );
    final available = await container.read(availableRecordPaths.future);

    expect(paths.map((path) => path.name), ['record']);
    expect(available.map((item) => item.path.name), ['record']);
  });
}
