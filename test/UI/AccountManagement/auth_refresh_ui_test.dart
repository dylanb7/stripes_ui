import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_auth_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/terms_acceptance_provider.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/terms_onboarding_gate.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/config.dart';

class _Auth extends TestAuth {
  final events = StreamController<AuthUser>.broadcast();
  var refreshResult = Completer<void>();
  int refreshCalls = 0;
  int signOutCalls = 0;
  int userReads = 0;
  Object? signOutError;

  @override
  Stream<AuthUser> get user {
    userReads++;
    return events.stream;
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
    await refreshResult.future;
    events.add(
      const AuthUser(uid: 'account', attributes: {'storage': 'remote'}),
    );
  }

  @override
  Future<void> logOut() async {
    signOutCalls++;
    if (signOutError case final error?) throw error;
    events.add(const AuthUser.empty());
  }
}

class _AcceptedTerms extends TermsAcceptanceNotifier {
  _AcceptedTerms() : super('account');

  @override
  Future<TermsAcceptance?> build() async => TermsAcceptance(
    version: stripesTermsVersion,
    acceptedAt: DateTime.utc(2026),
  );
}

void main() {
  for (final termsEnabled in [false, true]) {
    testWidgets('unknown account can retry with terms $termsEnabled', (
      tester,
    ) async {
      final auth = _Auth();
      addTearDown(auth.events.close);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWithValue(auth),
          termsAcceptanceProvider('account').overrideWith(_AcceptedTerms.new),
          configProvider.overrideWithValue(
            StripesConfig.sandbox(
              betaUi: BetaUiConfig.disabled(onboardingTerms: termsEnabled),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TermsOnboardingGate(child: Text('App content')),
          ),
        ),
      );
      auth.events.addError(StateError('attributes unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('App content'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(auth.userReads, 1);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(auth.refreshCalls, 1);
      expect(find.text('Trying again…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      auth.refreshResult.completeError(StateError('still offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to refresh your account. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);

      auth.refreshResult = Completer<void>();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      auth.refreshResult.complete();
      await tester.pumpAndSettle();
      expect(auth.refreshCalls, 2);
      expect(auth.userReads, 1);
      expect(find.text('App content'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(container.read(authStream).value?.uid, 'account');
    });
  }

  testWidgets(
    'unknown account keeps sign out available during a pending retry',
    (tester) async {
      final auth = _Auth();
      addTearDown(auth.events.close);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWithValue(auth),
          configProvider.overrideWithValue(const StripesConfig.sandbox()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TermsOnboardingGate(child: Text('App content')),
          ),
        ),
      );
      auth.events.addError(StateError('unknown account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(container.read(authStream).value?.uid, isEmpty);
      // Fail the pending fetch after sign-out, as a canceled request might do.
      auth.refreshResult.completeError(StateError('session ended'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account refresh awaits the repository before refreshing profile data',
    (tester) async {
      final auth = _Auth();
      addTearDown(auth.events.close);
      var profileReads = 0;
      var stampReads = 0;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWithValue(auth),
          subProvider.overrideWith((ref) async {
            profileReads++;
            return null;
          }),
          stampProvider.overrideWith((ref) async {
            stampReads++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RefreshWidget(
                depth: RefreshDepth.authuser,
                scrollable: ListView(children: const [Text('Account')]),
              ),
            ),
          ),
        ),
      );
      var done = false;
      final pending = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh()
          .then((_) => done = true);
      await tester.pump();
      expect(auth.refreshCalls, 1);
      expect(done, isFalse);
      expect(profileReads, 0);
      expect(stampReads, 0);
      auth.refreshResult.complete();
      await tester.pump();
      await pending;
      expect(done, isTrue);
      expect(profileReads, 1);
      expect(stampReads, 1);
      expect(auth.userReads, 0);
    },
  );

  testWidgets('account refresh failure is handled and can be retried', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.events.close);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWithValue(auth),
        subProvider.overrideWith((ref) async => null),
        stampProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RefreshWidget(
              depth: RefreshDepth.authuser,
              scrollable: ListView(children: const [Text('Account')]),
            ),
          ),
        ),
      ),
    );
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh;
    final pending = refresh();
    auth.refreshResult.completeError(StateError('offline'));
    await tester.pump();
    await pending;
    expect(find.text('Unable to refresh. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.refreshResult = Completer<void>();
    final retry = refresh();
    auth.refreshResult.complete();
    await tester.pump();
    await retry;
    expect(auth.refreshCalls, 2);
    await tester.pumpAndSettle();
  });
}
