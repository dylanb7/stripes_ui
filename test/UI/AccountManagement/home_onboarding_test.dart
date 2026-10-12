import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_onboarding_wizard.dart';
import 'package:stripes_ui/UI/AccountManagement/terms_onboarding_gate.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final beta in [false, true]) {
    testWidgets('first-profile setup reaches overview with beta terms $beta', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _ProfileRepo();
      final service = _DeferredSelectionService();
      addTearDown(repo.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWith(
              (ref) => StripesConfig(
                betaUi: beta
                    ? const BetaUiConfig.enabled()
                    : const BetaUiConfig.disabled(),
                hasLogging: true,
                allowsSummaryReport: true,
                profileType: ProfileType.username,
              ),
            ),
            authStream.overrideWith(
              (ref) => Stream.value(const AuthUser.uid(uid: 'account')),
            ),
            subProvider.overrideWith((ref) async => repo),
            sharedSeviceProvider.overrideWithValue(service),
            questionsProvider.overrideWith((ref) async {
              final selected = await ref.watch(
                subHolderProvider.selectAsync((state) => state.selected),
              );
              return selected == null
                  ? null
                  : TestQuestionRepo(subUser: selected);
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TermsOnboardingGate(
              child: Scaffold(body: Home(selected: TabOption.record)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (beta) {
        expect(find.text('Terms and privacy'), findsOneWidget);
        expect(find.byType(ProfileOnboardingWizard), findsNothing);
        expect(find.text('Step 1'), findsOneWidget);
        final agree = find.byType(Checkbox);
        await tester.ensureVisible(agree);
        await tester.tap(agree);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Agree and continue'));
        await tester.pumpAndSettle();
        expect(
          (await service.getTermsAcceptance('account'))?.version,
          stripesTermsVersion,
        );
      }
      final wizard = find.byType(ProfileOnboardingWizard);
      final originalState = tester.state(wizard);
      final profileProgress = tester.widget<OnboardingProgressBar>(
        find.byType(OnboardingProgressBar),
      );
      expect(profileProgress.currentStep, beta ? 1 : 0);
      expect(profileProgress.totalSteps, beta ? 3 : 2);
      final container = ProviderScope.containerOf(tester.element(wizard));
      await tester.enterText(find.byType(TextFormField), 'Alex');
      await tester.tap(find.widgetWithText(FilledButton, 'Create profile'));
      await tester.pump();
      await tester.pump();

      expect(container.read(subHolderProvider).isReloading, isTrue);
      expect(wizard, findsOneWidget);
      expect(tester.state(wizard), same(originalState));
      expect(container.read(onboardingCompleteProvider).value, isFalse);

      service.release.complete();
      await tester.pumpAndSettle();
      expect(tester.state(wizard), same(originalState));
      expect(find.text("You're all set!"), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Continue to Home'),
        findsOneWidget,
      );
      expect(container.read(onboardingCompleteProvider).value, isFalse);
      expect(repo.createCalls, 1);
      expect(find.text('Help and resources'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      final overviewProgress = tester.widget<OnboardingProgressBar>(
        find.byType(OnboardingProgressBar),
      );
      expect(overviewProgress.currentStep, beta ? 2 : 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _DeferredSelectionService extends SharedService {
  final release = Completer<void>();

  @override
  Future<String?> getCurrentUser() async {
    await release.future;
    return super.getCurrentUser();
  }
}

class _ProfileRepo extends SubUserRepo {
  _ProfileRepo() : super(authUser: const AuthUser.uid(uid: 'account'));

  List<SubUser> _users = [];
  final _changes = StreamController<List<SubUser>>.broadcast();
  int createCalls = 0;

  @override
  Stream<List<SubUser>> get users => Stream.multi((controller) {
    controller.add(_users);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<RepoResult<SubUser?>> addSubUser(SubUser user) async {
    createCalls++;
    _users = [..._users, user];
    _changes.add(_users);
    return Success(user);
  }

  @override
  Future<RepoResult<void>> deleteSubUser(SubUser user) =>
      throw UnimplementedError();

  @override
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user) =>
      throw UnimplementedError();

  @override
  Future<void> refresh() async {}

  Future<void> close() => _changes.close();
}
