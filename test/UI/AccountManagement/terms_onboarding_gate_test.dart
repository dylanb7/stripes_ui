import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Navigation/route_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/UI/AccountManagement/terms_onboarding_gate.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('legacy UI does not read or request onboarding terms', (
    tester,
  ) async {
    final service = _FailingService()..failRead = true;
    await _pump(tester, beta: false, service: service);
    expect(find.text('Protected app'), findsOneWidget);
    expect(find.text('Terms and privacy'), findsNothing);
    expect(service.reads, 0);
  });

  for (final scale in [1.0, 3.0]) {
    testWidgets('terms require an explicit agreement at ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, scale: scale);
      final action = find.widgetWithText(FilledButton, 'Agree and continue');
      expect(find.text('Protected app'), findsNothing);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.text('Read Privacy Policy'), findsOneWidget);
      expect(
        tester.getSize(find.byType(SingleChildScrollView)).height,
        greaterThan(200),
      );
      await _agree(tester);
      expect(action.hitTestable(), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Protected app'), findsOneWidget);
      final stored = await SharedService().getTermsAcceptance('account');
      expect(stored?.version, stripesTermsVersion);
      expect(tester.takeException(), isNull);

      // Remount with a fresh provider container, as after an app restart.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, scale: scale);
      expect(find.text('Protected app'), findsOneWidget);
      expect(find.text('Terms and privacy'), findsNothing);
    });
  }

  testWidgets('switching accounts resets the unchecked agreement', (
    tester,
  ) async {
    final accounts = StreamController<AuthUser>();
    addTearDown(accounts.close);
    await _pump(tester, accounts: accounts.stream, settle: false);
    accounts.add(const AuthUser.uid(uid: 'first'));
    await tester.pumpAndSettle();
    await _agree(tester);
    accounts.add(const AuthUser.uid(uid: 'second'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await _agree(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Agree and continue'));
    await tester.pumpAndSettle();
    expect(find.text('Protected app'), findsOneWidget);
    expect(await SharedService().getTermsAcceptance('first'), isNull);
    expect(await SharedService().getTermsAcceptance('second'), isNotNull);
    accounts.add(const AuthUser.uid(uid: 'first'));
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('outdated terms prompt again', (tester) async {
    await SharedService().setTermsAcceptance(
      'account',
      TermsAcceptance(version: 'older-terms', acceptedAt: DateTime.utc(2024)),
    );
    await _pump(tester);
    expect(find.text('Terms and privacy'), findsOneWidget);
    expect(find.text('Protected app'), findsNothing);
  });

  testWidgets('failed read stays gated and can retry', (tester) async {
    final service = _FailingService()..failRead = true;
    await _pump(tester, service: service);
    expect(find.text('Unable to check your terms agreement.'), findsOneWidget);
    expect(find.text('Protected app'), findsNothing);
    service.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
  });

  testWidgets('failed save retains agreement and never opens the app', (
    tester,
  ) async {
    final service = _FailingService()..failWrite = true;
    await _pump(tester, service: service);
    await _agree(tester);
    final action = find.widgetWithText(FilledButton, 'Agree and continue');
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Protected app'), findsNothing);
    expect(
      find.text('We couldn’t save your agreement. Please try again.'),
      findsOneWidget,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    service.failWrite = false;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Protected app'), findsOneWidget);
  });

  testWidgets('production study and profile deep links cannot bypass terms', (
    tester,
  ) async {
    final container = _container();
    final router = container.read(routeProvider);
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    router.goNamed(RouteName.TEST);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
    router.goNamed(RouteName.USERS);
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

ProviderContainer _container({
  bool beta = true,
  SharedService? service,
  Stream<AuthUser>? accounts,
}) => ProviderContainer(
  overrides: [
    configProvider.overrideWithValue(
      StripesConfig.sandbox(
        betaUi: beta
            ? const BetaUiConfig.enabled()
            : const BetaUiConfig.disabled(),
      ),
    ),
    subHolderProvider.overrideWith(_NoProfiles.new),
    authStream.overrideWith(
      (ref) => accounts ?? Stream.value(const AuthUser.uid(uid: 'account')),
    ),
    if (service != null) sharedSeviceProvider.overrideWithValue(service),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  bool beta = true,
  SharedService? service,
  double scale = 1,
  Stream<AuthUser>? accounts,
  bool settle = true,
}) async {
  final container = _container(
    beta: beta,
    service: service,
    accounts: accounts,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const TermsOnboardingGate(
          child: Scaffold(body: Text('Protected app')),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _agree(WidgetTester tester) async {
  final checkbox = find.byType(Checkbox);
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
}

class _FailingService extends SharedService {
  bool failRead = false;
  bool failWrite = false;
  int reads = 0;

  @override
  Future<TermsAcceptance?> getTermsAcceptance(String accountId) {
    reads++;
    if (failRead) throw StateError('Read failed');
    return super.getTermsAcceptance(accountId);
  }

  @override
  Future<void> setTermsAcceptance(
    String accountId,
    TermsAcceptance acceptance,
  ) {
    if (failWrite) throw StateError('Write failed');
    return super.setTermsAcceptance(accountId, acceptance);
  }
}

class _NoProfiles extends SubNotifier {
  @override
  SubState build() => SubState.empty();
}
