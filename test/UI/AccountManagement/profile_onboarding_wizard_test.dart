import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/UI/AccountManagement/terms_onboarding_gate.dart';
import 'package:stripes_ui/UI/Resources/resource_sheet.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/add_first_profile.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_onboarding_wizard.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_harness.dart';
import '../../accessibility/audit_fixtures.dart' show auditShell;

class _Profiles extends SubNotifier {
  @override
  SubState build() => SubState.empty();

  void add(SubUser user) => state = AsyncData(
    SubState(subUsers: [...state.requireValue.subUsers, user], selected: user),
  );

  @override
  Future<bool> changeCurrent(SubUser user) async => true;
}

class _ProfileRepo extends SubUserRepo {
  _ProfileRepo() : super(authUser: const AuthUser.uid(uid: 'account'));

  bool fail = false;
  int createCalls = 0;
  SubUser? created;
  void Function(SubUser)? onAdded;

  @override
  Future<RepoResult<SubUser?>> addSubUser(SubUser user) async {
    createCalls++;
    if (fail) return const Failure(message: 'Unavailable');
    created = user;
    onAdded?.call(user);
    return Success(user);
  }

  @override
  Stream<List<SubUser>> get users => const Stream.empty();

  @override
  Future<RepoResult<void>> deleteSubUser(SubUser user) =>
      throw UnimplementedError();

  @override
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user) =>
      throw UnimplementedError();

  @override
  Future<void> refresh() async {}
}

Future<ProviderContainer> _pumpWizard(
  WidgetTester tester, {
  required _ProfileRepo repo,
  ProfileType profileType = ProfileType.username,
  double scale = 1,
  Size size = const Size(390, 844),
  bool Function()? failSetup,
  VoidCallback? onFinished,
  bool firstProfile = false,
  bool fullShell = false,
  bool beta = false,
  bool withTermsGate = false,
  bool hasStudy = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (fullShell && size.width < 600) {
    final insets = FakeViewPadding(top: size.width < 375 ? 20 : 50, bottom: 34);
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig(
            hasLogging: true,
            allowsSummaryReport: true,
            profileType: profileType,
            betaUi: beta
                ? const BetaUiConfig.enabled()
                : const BetaUiConfig.disabled(),
          ),
        ),
        authStream.overrideWith(
          (ref) => Stream.value(const AuthUser.uid(uid: 'account')),
        ),
        subProvider.overrideWith((ref) async => repo),
        subHolderProvider.overrideWith(_Profiles.new),
        questionsProvider.overrideWith((ref) async => null),
        hasTestsProvider.overrideWith((ref) async => hasStudy),
        incompleteBaselinesProvider.overrideWith((ref) async {
          if (failSetup?.call() ?? false) throw StateError('Unavailable');
          return [];
        }),
      ],
      child: MaterialApp(
        theme: light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            final body = firstProfile
                ? const CreatePatient()
                : Scaffold(
                    body: ProfileOnboardingWizard(
                      title: 'Care recipient details',
                      subtitle:
                          'Create a profile for the person whose symptoms '
                          'you will track.',
                      showTour: true,
                      onFinished: onFinished,
                    ),
                  );
            final shell = fullShell
                ? auditShell(body, tab: TabOption.record)
                : body;
            return withTermsGate ? TermsOnboardingGate(child: shell) : shell;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ProfileOnboardingWizard)),
  );
  repo.onAdded = (user) =>
      (container.read(subHolderProvider.notifier) as _Profiles).add(user);
  return container;
}

Future<void> _submit(
  WidgetTester tester, [
  String label = 'Create profile',
]) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuditFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final type in ProfileType.values) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('$type setup is readable on a small phone at ${scale}x', (
        tester,
      ) async {
        await _pumpWizard(
          tester,
          repo: _ProfileRepo(),
          profileType: type,
          scale: scale,
          size: const Size(320, 568),
          firstProfile: true,
          fullShell: true,
          beta: true,
        );
        expect(find.text('Care recipient details'), findsOneWidget);
        expect(tester.testTextInput.isVisible, isFalse);
        final fields = find.byType(TextFormField);
        expect(fields, findsNWidgets(type == ProfileType.name ? 2 : 1));
        if (type == ProfileType.name) {
          expect(find.text('First name'), findsWidgets);
          expect(find.text('Last name'), findsWidgets);
        }
        final button = find.widgetWithText(FilledButton, 'Create profile');
        expect(button.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(button).bottom,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(SmallLayout)).dy),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('whitespace is rejected without creating a profile', (
    tester,
  ) async {
    final repo = _ProfileRepo();
    await _pumpWizard(tester, repo: repo);
    await tester.enterText(find.byType(TextFormField), '   ');
    await _submit(tester);
    expect(find.text('Please enter a username'), findsOneWidget);
    expect(repo.createCalls, 0);
  });

  testWidgets('creation failure retains input and allows retry', (
    tester,
  ) async {
    final repo = _ProfileRepo()..fail = true;
    await _pumpWizard(tester, repo: repo);
    await tester.enterText(find.byType(TextFormField), ' Alex ');
    await _submit(tester);
    expect(
      find.text('We could not create your profile. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      ' Alex ',
    );
    repo.fail = false;
    await _submit(tester);
    expect(find.text("You're all set!"), findsOneWidget);
    expect(repo.created!.name, 'Alex');
    expect(repo.created!.birthYear, 0);
    expect(repo.created!.gender, '');
    expect(repo.createCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup retry reuses the created profile and waits for Continue', (
    tester,
  ) async {
    final repo = _ProfileRepo();
    var failSetup = true;
    var finished = false;
    await _pumpWizard(
      tester,
      repo: repo,
      failSetup: () => failSetup,
      onFinished: () => finished = true,
    );
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await _submit(tester);
    expect(find.textContaining('Your profile was created'), findsOneWidget);
    expect(repo.createCalls, 1);
    expect(finished, isFalse);

    failSetup = false;
    await _submit(tester, 'Continue setup');
    expect(find.text("You're all set!"), findsOneWidget);
    expect(repo.createCalls, 1);
    expect(finished, isFalse);
    await _submit(tester, 'Continue to Home');
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('name, birth year, and condition survive a failed creation', (
    tester,
  ) async {
    final repo = _ProfileRepo()..fail = true;
    await _pumpWizard(tester, repo: repo, profileType: ProfileType.name);
    await tester.enterText(find.byType(TextFormField).first, ' Mary Ann ');
    await tester.enterText(find.byType(TextFormField).last, ' van der Berg ');
    await tester.tap(find.byType(BirthYearSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2000'));
    await tester.pumpAndSettle();
    final condition = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(condition);
    await tester.tap(condition);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not Sure').last);
    await tester.pumpAndSettle();

    await _submit(tester);
    expect(repo.createCalls, 1);
    expect(find.text('2000'), findsOneWidget);
    repo.fail = false;
    await _submit(tester);
    expect(repo.created!.name, 'Mary Ann van der Berg');
    expect(repo.created!.birthYear, 2000);
    expect(repo.created!.gender, '');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileOnboardingWizard)),
    );
    expect(
      await container.read(profileConditionProvider(repo.created!.uid).future),
      const ProfileCondition('Not Sure'),
    );
    expect(find.text("You're all set!"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard leaves the create action reachable', (tester) async {
    await _pumpWizard(
      tester,
      repo: _ProfileRepo(),
      fullShell: true,
      firstProfile: true,
      beta: true,
    );
    await tester.enterText(find.byType(TextFormField), 'Alex');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Create profile');
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(544));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(375, 812), const Size(1200, 900)]) {
    testWidgets('restart keeps consent and allows reviewing terms at $size', (
      tester,
    ) async {
      final acceptance = TermsAcceptance(
        version: stripesTermsVersion,
        acceptedAt: DateTime.utc(2026, 10, 12, 14, 2),
      );
      final service = SharedService();
      await service.setTermsAcceptance('account', acceptance);
      final container = await _pumpWizard(
        tester,
        repo: _ProfileRepo(),
        profileType: ProfileType.name,
        firstProfile: true,
        fullShell: true,
        beta: true,
        withTermsGate: true,
        size: size,
      );
      // Like LocalEntry, profiles start empty while account consent persists.
      expect(find.text('Agree and continue'), findsNothing);
      expect(
        tester
            .widget<OnboardingProgressBar>(find.byType(OnboardingProgressBar))
            .currentStep,
        1,
      );
      final button = find.widgetWithText(FilledButton, 'Create profile');
      expect(button.hitTestable(), findsOneWidget);
      final buttonRect = tester.getRect(button);
      await tester.enterText(find.byType(TextFormField).first, 'Alex');
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      final details = find.byType(TextFormField).last;
      await tester.ensureVisible(details);
      await tester.enterText(details, 'Example condition');
      expect(tester.getRect(button), buttonRect);
      final conditionDecorations = tester
          .widgetList<InputDecorator>(
            find.descendant(
              of: find.byType(ProfileOnboardingWizard),
              matching: find.byType(InputDecorator),
            ),
          )
          .where(
            (widget) => [
              'Condition',
              'Specify condition',
            ].contains(widget.decoration.labelText),
          );
      expect(conditionDecorations.length, 2);
      expect(
        conditionDecorations.every(
          (widget) => widget.decoration.border is OutlineInputBorder,
        ),
        isTrue,
      );

      final review = find.byTooltip('Review terms and privacy');
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(container.read(isSheetOpenProvider), isTrue);
      expect(find.byType(ResourceSheetBody), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(
        find.byType(Dialog),
        size.width > 1000 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(DraggableScrollableSheet),
        size.width > 1000 ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close resources'));
      await tester.pumpAndSettle();
      expect(container.read(isSheetOpenProvider), isFalse);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Alex',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        'Example condition',
      );
      expect(
        (await service.getTermsAcceptance('account'))?.toJson(),
        acceptance.toJson(),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('name form stays usable above the keyboard at larger text', (
    tester,
  ) async {
    await _pumpWizard(
      tester,
      repo: _ProfileRepo(),
      profileType: ProfileType.name,
      scale: 2,
      size: const Size(375, 812),
      firstProfile: true,
      fullShell: true,
      beta: true,
    );
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    final choice = find.text('GRIN2A gene disorder').last;
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    final selectedText = find.descendant(
      of: dropdown,
      matching: find.text('GRIN2A gene disorder'),
    );
    expect(
      tester.getRect(dropdown).contains(tester.getBottomRight(selectedText)),
      isTrue,
    );
    final firstName = find.byType(TextFormField).first;
    await tester.ensureVisible(firstName);
    await tester.enterText(firstName, 'Alex');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 50);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Create profile');
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(512));
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(375, 812), 1.0),
    (const Size(320, 568), 3.0),
  ]) {
    testWidgets(
      'completion action stays above navigation at $size and ${scale}x',
      (tester) async {
        final container = await _pumpWizard(
          tester,
          repo: _ProfileRepo(),
          scale: scale,
          size: size,
          firstProfile: true,
          fullShell: true,
          beta: true,
          hasStudy: true,
        );
        final completion = container.listen(
          onboardingCompleteProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(completion.close);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Alex');
        await _submit(tester);
        expect(find.text("You're all set!"), findsOneWidget);
        final overviewScroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(overviewScroll.controller!.offset, 0);
        expect(
          tester.getTopLeft(find.byIcon(Icons.check_circle_outline)).dy,
          greaterThan(
            tester.getBottomLeft(find.byType(OnboardingProgressBar)).dy,
          ),
        );
        final button = find.widgetWithText(FilledButton, 'Continue to Home');
        // No ensureVisible: the action must be usable before any scrolling.
        expect(button.hitTestable(), findsOneWidget);
        final actionRect = tester.getRect(button);
        expect(
          actionRect.bottom,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(SmallLayout)).dy),
        );
        overviewScroll.controller!.jumpTo(
          overviewScroll.controller!.position.maxScrollExtent,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Help and resources'));
        await tester.pumpAndSettle();
        expect(find.text('Help and resources').hitTestable(), findsOneWidget);
        expect(tester.getRect(button), actionRect);
        overviewScroll.controller!.jumpTo(0);
        await tester.pumpAndSettle();
        expect(container.read(onboardingCompleteProvider).value, isFalse);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(container.read(onboardingCompleteProvider).value, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
