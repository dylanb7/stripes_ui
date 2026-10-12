import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Providers/terms_acceptance_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer createContainer({SharedService? service}) {
    final container = ProviderContainer(
      overrides: [
        sharedSeviceProvider.overrideWithValue(service ?? SharedService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'accepted version and UTC timestamp survive a recreated container',
    () async {
      final container = createContainer();
      final provider = termsAcceptanceProvider('account');
      expect(await container.read(provider.future), isNull);
      final before = DateTime.now().toUtc();
      await container.read(provider.notifier).accept();
      final after = DateTime.now().toUtc();
      final accepted = container.read(provider).requireValue!;
      expect(accepted.version, stripesTermsVersion);
      expect(accepted.acceptedAt.isUtc, isTrue);
      expect(accepted.acceptedAt.isBefore(before), isFalse);
      expect(accepted.acceptedAt.isAfter(after), isFalse);

      final reopened = createContainer(service: SharedService());
      final restored = (await reopened.read(provider.future))!;
      expect(restored.version, accepted.version);
      expect(restored.acceptedAt, accepted.acceptedAt);
      expect(restored.acceptedAt.isUtc, isTrue);
    },
  );

  test('stored receipt normalizes an offset timestamp to UTC', () async {
    final acceptance = TermsAcceptance(
      version: stripesTermsVersion,
      acceptedAt: DateTime.parse('2026-10-12T14:30:00-04:00'),
    );
    await SharedService().setTermsAcceptance('account', acceptance);
    final restored = (await SharedService().getTermsAcceptance('account'))!;
    expect(restored.acceptedAt, DateTime.utc(2026, 10, 12, 18, 30));
    expect(restored.acceptedAt.isUtc, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(prefs.getKeys().single), contains('18:30:00.000Z'));
  });

  test('acceptance is isolated between accounts', () async {
    final container = createContainer();
    final first = termsAcceptanceProvider('first:account');
    final second = termsAcceptanceProvider('second:"account"');
    await container.read(first.notifier).accept();
    final firstReceipt = container.read(first).requireValue!;
    expect(await container.read(second.future), isNull);
    expect(
      await SharedService().getTermsAcceptance('second:"account"'),
      isNull,
    );

    await container.read(second.notifier).accept();
    expect(container.read(second).requireValue!.version, stripesTermsVersion);
    expect(
      container.read(first).requireValue!.acceptedAt,
      firstReceipt.acceptedAt,
    );
    expect(
      (await SharedService().getTermsAcceptance('first:account'))!.acceptedAt,
      firstReceipt.acceptedAt,
    );
  });

  for (final malformed in [
    'not-json',
    'null',
    '[]',
    '{}',
    '{"version":4,"acceptedAt":"2026-10-12T00:00:00Z"}',
    '{"version":"$stripesTermsVersion"}',
    '{"version":"$stripesTermsVersion","acceptedAt":"invalid-date"}',
  ]) {
    test('malformed receipt is not accepted: $malformed', () async {
      final service = SharedService();
      await service.setTermsAcceptance(
        'account',
        TermsAcceptance(
          version: stripesTermsVersion,
          acceptedAt: DateTime.utc(2026),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefs.getKeys().single, malformed);
      expect(await service.getTermsAcceptance('account'), isNull);
      final container = createContainer();
      expect(
        await container.read(termsAcceptanceProvider('account').future),
        isNull,
      );
    });
  }

  test(
    'a wrong-type stored preference prompts again and can be replaced',
    () async {
      final service = SharedService();
      await service.setTermsAcceptance(
        'account',
        TermsAcceptance(
          version: stripesTermsVersion,
          acceptedAt: DateTime.utc(2026),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefs.getKeys().single, 42);
      expect(await service.getTermsAcceptance('account'), isNull);

      final container = createContainer();
      final provider = termsAcceptanceProvider('account');
      expect(await container.read(provider.future), isNull);
      await container.read(provider.notifier).accept();
      expect(
        container.read(provider).requireValue!.version,
        stripesTermsVersion,
      );
      expect(
        (await SharedService().getTermsAcceptance('account'))!.version,
        stripesTermsVersion,
      );
    },
  );

  test('failed writes do not publish acceptance and allow retry', () async {
    final service = _FailingService();
    final container = createContainer(service: service);
    final provider = termsAcceptanceProvider('account');
    expect(await container.read(provider.future), isNull);

    await expectLater(
      container.read(provider.notifier).accept(),
      throwsStateError,
    );
    expect(container.read(provider).requireValue, isNull);
    expect(await SharedService().getTermsAcceptance('account'), isNull);
    service.fail = false;
    await container.read(provider.notifier).accept();
    expect(service.attempts, 2);
    expect(container.read(provider).requireValue!.version, stripesTermsVersion);
    expect(
      (await SharedService().getTermsAcceptance('account'))!.version,
      stripesTermsVersion,
    );
  });

  test(
    'a pending write stays with its account when the active listener changes',
    () async {
      final service = _DeferredService();
      final container = createContainer(service: service);
      final first = termsAcceptanceProvider('first');
      final second = termsAcceptanceProvider('second');
      final firstListener = container.listen(first, (_, _) {});
      await container.read(first.future);
      final pending = container.read(first.notifier).accept();
      await service.started.future;
      expect(container.read(first).requireValue, isNull);

      firstListener.close();
      container.listen(second, (_, _) {});
      expect(await container.read(second.future), isNull);
      service.release.complete();
      await pending;
      expect(service.savedAccount, 'first');
      expect(container.read(first).requireValue!.version, stripesTermsVersion);
      expect(container.read(second).requireValue, isNull);
      expect(await SharedService().getTermsAcceptance('second'), isNull);
      expect(
        (await SharedService().getTermsAcceptance('first'))!.version,
        stripesTermsVersion,
      );
    },
  );

  test('an empty account cannot record acceptance', () async {
    final container = createContainer();
    final provider = termsAcceptanceProvider('');
    await expectLater(
      container.read(provider.notifier).accept(),
      throwsStateError,
    );
    expect(await container.read(provider.future), isNull);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}

class _FailingService extends SharedService {
  bool fail = true;
  int attempts = 0;

  @override
  Future<void> setTermsAcceptance(
    String accountId,
    TermsAcceptance acceptance,
  ) async {
    attempts++;
    if (fail) throw StateError('Write failed');
    await super.setTermsAcceptance(accountId, acceptance);
  }
}

class _DeferredService extends SharedService {
  final started = Completer<void>();
  final release = Completer<void>();
  String? savedAccount;

  @override
  Future<void> setTermsAcceptance(
    String accountId,
    TermsAcceptance acceptance,
  ) async {
    savedAccount = accountId;
    started.complete();
    await release.future;
    await super.setTermsAcceptance(accountId, acceptance);
  }
}
