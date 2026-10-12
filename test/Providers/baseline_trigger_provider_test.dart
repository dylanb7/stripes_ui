import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

void main() {
  test(
    'a repository without baseline support completes setup without stamps',
    () async {
      final repo = TestQuestionRepo(subUser: SubUser.marker());
      var stampsRequested = false;
      final container = ProviderContainer(
        overrides: [
          questionsProvider.overrideWith((ref) async => repo),
          baselinesStreamProvider.overrideWith((ref) {
            stampsRequested = true;
            return const Stream.empty();
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(incompleteBaselinesProvider, (_, _) {});

      final triggers = await container
          .read(incompleteBaselinesProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(triggers, isEmpty);
      expect(stampsRequested, isFalse);
    },
  );

  test(
    'empty baseline layouts do not wait on an unavailable stamp stream',
    () async {
      var stampsRequested = false;
      final container = ProviderContainer(
        overrides: [
          baselineLayoutProvider.overrideWith((ref) => Stream.value(const [])),
          baselinesStreamProvider.overrideWith((ref) {
            stampsRequested = true;
            return const Stream.empty();
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(incompleteBaselinesProvider, (_, _) {});

      final triggers = await container
          .read(incompleteBaselinesProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(triggers, isEmpty);
      expect(stampsRequested, isFalse);
    },
  );

  test(
    'configured baselines still read stamps and return required setup',
    () async {
      var stampsRequested = false;
      final container = ProviderContainer(
        overrides: [
          baselineLayoutProvider.overrideWith(
            (ref) => Stream.value([
              RecordPath(
                name: 'Initial questionnaire',
                pages: const [],
                isBaseline: true,
              ),
            ]),
          ),
          baselinesStreamProvider.overrideWith((ref) {
            stampsRequested = true;
            return Stream.value(const []);
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(incompleteBaselinesProvider, (_, _) {});

      final triggers = await container
          .read(incompleteBaselinesProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(stampsRequested, isTrue);
      expect(triggers.single.baselineType, 'Initial questionnaire');
    },
  );
}
