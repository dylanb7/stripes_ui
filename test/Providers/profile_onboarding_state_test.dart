import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

void main() {
  late _Replay<AuthUser> auth;
  late Map<String, _Replay<List<SubUser>>> profiles;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Replay(const AuthUser.uid(uid: 'new-account'));
    profiles = {
      'new-account': _Replay([]),
      'returning-account': _Replay([_profile('existing')]),
      '': _Replay([]),
    };
    container = ProviderContainer(
      overrides: [
        authStream.overrideWith((ref) => auth.stream),
        subStream.overrideWith((ref) async* {
          final user = await ref.watch(authStream.future);
          yield* profiles[user.uid]!.stream;
        }),
      ],
    );
    container.listen(onboardingCompleteProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await auth.close();
    for (final values in profiles.values) {
      await values.close();
    }
  });

  Future<bool> isComplete() async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    return container.read(onboardingCompleteProvider.future);
  }

  test('first profile stays in onboarding until explicitly completed', () async {
    expect(await isComplete(), isFalse);
    profiles['new-account']!.add([_profile('first')]);
    expect(await isComplete(), isFalse);
    expect((await container.read(subHolderProvider.future)).selected?.uid, 'first');

    container.read(onboardingCompleteProvider.notifier).complete();
    expect(await isComplete(), isTrue);
  });

  test('an account with an existing profile bypasses onboarding', () async {
    auth.add(const AuthUser.uid(uid: 'returning-account'));
    expect(await isComplete(), isTrue);
  });

  test('auth updates for the same account keep first setup active', () async {
    expect(await isComplete(), isFalse);
    profiles['new-account']!.add([_profile('first')]);
    expect(await isComplete(), isFalse);
    auth.add(const AuthUser(uid: 'new-account', attributes: {'name': 'Updated'}));
    expect(await isComplete(), isFalse);
  });

  test('completed onboarding survives profile changes and refreshes', () async {
    expect(await isComplete(), isFalse);
    profiles['new-account']!.add([_profile('first'), _profile('second')]);
    await isComplete();
    container.read(onboardingCompleteProvider.notifier).complete();
    final second = (await container.read(subHolderProvider.future)).subUsers.last;
    await container.read(subHolderProvider.notifier).changeCurrent(second);
    expect(await isComplete(), isTrue);
    container.invalidate(subHolderProvider);
    expect(await isComplete(), isTrue);
  });

  test('reset keeps onboarding active across profile updates', () async {
    auth.add(const AuthUser.uid(uid: 'returning-account'));
    expect(await isComplete(), isTrue);
    container.read(onboardingCompleteProvider.notifier).reset();
    profiles['returning-account']!.add([_profile('existing', name: 'Updated')]);
    expect(await isComplete(), isFalse);
  });

  test('removing the last profile requires completing the next setup', () async {
    auth.add(const AuthUser.uid(uid: 'returning-account'));
    expect(await isComplete(), isTrue);
    profiles['returning-account']!.add([]);
    expect(await isComplete(), isFalse);
    profiles['returning-account']!.add([_profile('replacement')]);
    expect(await isComplete(), isFalse);
  });

  test('onboarding state is initialized again when accounts change', () async {
    expect(await isComplete(), isFalse);
    profiles['new-account']!.add([_profile('first')]);
    expect(await isComplete(), isFalse);
    auth.add(const AuthUser.uid(uid: 'returning-account'));
    expect(await isComplete(), isTrue);
    auth.add(const AuthUser.empty());
    expect(await isComplete(), isFalse);
    auth.add(const AuthUser.uid(uid: 'returning-account'));
    expect(await isComplete(), isTrue);
  });
}

SubUser _profile(String id, {String name = 'Sam'}) => SubUser(
  id: id,
  name: name,
  gender: '',
  birthYear: 2000,
  isControl: false,
);

class _Replay<T> {
  T value;
  final _changes = StreamController<T>.broadcast();

  _Replay(this.value);

  Stream<T> get stream => Stream<T>.multi((controller) {
    controller.add(value);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  void add(T value) {
    this.value = value;
    _changes.add(value);
  }

  Future<void> close() => _changes.close();
}
