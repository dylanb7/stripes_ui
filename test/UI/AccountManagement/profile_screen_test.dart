import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/edit_profile.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/profile_avatar.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/profile_screen.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';

import '../../accessibility/audit_harness.dart';

final _first = SubUser(
  id: 'first',
  name: 'Robert Campbell',
  birthYear: 1990,
  gender: 'Male',
  isControl: true,
);
final _second = SubUser(
  id: 'second',
  name: 'Emma van der Berg',
  birthYear: 2000,
  gender: 'Female',
  isControl: false,
);

class _Profiles extends SubNotifier {
  final List<SubUser> profiles;
  _Profiles(this.profiles);

  @override
  SubState build() => SubState(subUsers: profiles, selected: profiles.first);

  @override
  Future<bool> changeCurrent(SubUser newUser) async {
    state = AsyncData(state.requireValue.copyWith(selected: newUser));
    return true;
  }
}

class _Repo extends SubUserRepo {
  _Repo()
    : super(
        authUser: const AuthUser(uid: 'account', attributes: {}),
      );

  final List<SubUser> updates = [];
  final List<SubUser> deletions = [];
  String? updateError;
  String? deleteError;

  @override
  Stream<List<SubUser>> get users => const Stream.empty();

  @override
  Future<RepoResult<SubUser?>> addSubUser(SubUser user) async => Success(user);

  @override
  Future<RepoResult<void>> deleteSubUser(SubUser user) async {
    deletions.add(user);
    return deleteError == null
        ? const Success(null)
        : Failure(message: deleteError!);
  }

  @override
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user) async {
    updates.add(user);
    return updateError == null ? Success(user) : Failure(message: updateError!);
  }

  @override
  Future<void> refresh() async {}
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Repo repo, {
  ProfileType type = ProfileType.username,
  List<SubUser>? profiles,
  Size size = const Size(390, 844),
  double scale = 1,
  double keyboard = 0,
  SharedService? service,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (service != null) sharedSeviceProvider.overrideWithValue(service),
        configProvider.overrideWith(
          (ref) => StripesConfig(
            profileType: type,
            hasLogging: true,
            allowsSummaryReport: true,
          ),
        ),
        subHolderProvider.overrideWith(
          () => _Profiles(profiles ?? [_first, _second]),
        ),
        subProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: const Scaffold(body: PatientScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(PatientScreen)));
}

Future<void> _edit(WidgetTester tester, String id) async {
  final edit = find.byKey(ValueKey('edit-profile-$id'));
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
}

Future<void> _tapEditorText(WidgetTester tester, String text) async {
  await tester.pump();
  final target = find.descendant(
    of: find.byType(EditUserWidget),
    matching: find.text(text),
  );
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuditFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('condition-only edits persist locally and replace gender', (
    tester,
  ) async {
    final repo = _Repo();
    final container = await _pump(tester, repo, type: ProfileType.name);
    expect(find.textContaining('Male'), findsNothing);
    expect(find.textContaining('Female'), findsNothing);
    await _edit(tester, 'first');
    expect(find.text('Gender'), findsNothing);
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('GRIN2B gene disorder').last);
    await tester.pumpAndSettle();
    await _tapEditorText(tester, 'Save');
    expect(repo.updates, isEmpty);
    expect(
      await container.read(profileConditionProvider('first').future),
      const ProfileCondition('GRIN2B gene disorder'),
    );
    expect(find.textContaining('GRIN2B gene disorder'), findsWidgets);

    await _edit(tester, 'first');
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not Sure').last);
    await tester.pumpAndSettle();
    await _tapEditorText(tester, 'Cancel');
    expect(
      await container.read(profileConditionProvider('first').future),
      const ProfileCondition('GRIN2B gene disorder'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other requires details and restores them in the editor', (
    tester,
  ) async {
    final repo = _Repo();
    final container = await _pump(tester, repo, type: ProfileType.name);
    await _edit(tester, 'first');
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await _tapEditorText(tester, 'Save');
    expect(find.text('Please specify the condition'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).last,
      'Example condition',
    );
    await _tapEditorText(tester, 'Save');
    expect(
      await container.read(profileConditionProvider('first').future),
      const ProfileCondition('Other', details: 'Example condition'),
    );
    expect(repo.updates, isEmpty);
    await _edit(tester, 'first');
    expect(find.text('Example condition'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local storage failure keeps the condition draft for retry', (
    tester,
  ) async {
    final repo = _Repo();
    final service = _FailingConditionService();
    final container = await _pump(
      tester,
      repo,
      type: ProfileType.name,
      service: service,
    );
    await _edit(tester, 'first');
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not Sure').last);
    await tester.pumpAndSettle();
    await _tapEditorText(tester, 'Save');
    expect(find.byType(EditUserWidget), findsOneWidget);
    expect(
      find.text('Unable to save this profile. Please try again.'),
      findsOneWidget,
    );
    service.fail = false;
    await _tapEditorText(tester, 'Save');
    expect(
      await container.read(profileConditionProvider('first').future),
      const ProfileCondition('Not Sure'),
    );
    expect(repo.updates, isEmpty);
  });

  test('initials handle blank, single and multi-part names', () {
    expect(profileInitials('  '), '');
    expect(profileInitials('  Sam  '), 'S');
    expect(profileInitials('Emma van der Berg'), 'EB');
    expect(profileInitials('Émile Zola'), 'ÉZ');
  });

  testWidgets('full row switches the current profile; Edit does not', (
    tester,
  ) async {
    final repo = _Repo();
    final container = await _pump(tester, repo);
    final banner = find.byKey(const ValueKey('current-profile-banner'));
    expect(
      find.descendant(of: banner, matching: find.text(_first.name)),
      findsOneWidget,
    );
    final row = find.byKey(const ValueKey('profile-row-second'));
    final bounds = tester.getRect(row);
    await tester.tapAt(Offset(bounds.right - 4, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(
      container.read(subHolderProvider).requireValue.selected?.uid,
      'second',
    );
    expect(
      find.descendant(of: banner, matching: find.text(_second.name)),
      findsOneWidget,
    );
    expect(find.text('Current profile'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Add Profile')).dy,
      greaterThan(tester.getBottomLeft(row).dy),
    );

    await _edit(tester, 'first');
    expect(
      container.read(subHolderProvider).requireValue.selected?.uid,
      'second',
    );
    expect(container.read(isSheetOpenProvider), isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('profile-first-name')),
      'Changed',
    );
    await _tapEditorText(tester, 'Cancel');
    expect(find.byType(EditUserWidget), findsNothing);
    expect(repo.updates, isEmpty);
    expect(container.read(isSheetOpenProvider), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('outside dismissal discards edits', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo);
    await _edit(tester, 'first');
    await tester.enterText(
      find.byKey(const ValueKey('profile-first-name')),
      'Unsaved',
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(EditUserWidget), findsNothing);
    expect(repo.updates, isEmpty);
  });

  testWidgets('username save preserves demographics and control flag', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo);
    await _edit(tester, 'first');
    await tester.enterText(
      find.byKey(const ValueKey('profile-first-name')),
      '  New Username  ',
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(EditUserWidget),
        matching: find.text('NU'),
      ),
      findsOneWidget,
    );
    await _tapEditorText(tester, 'Save');
    expect(find.byType(EditUserWidget), findsNothing);
    expect(repo.updates, hasLength(1));
    final updated = repo.updates.single;
    expect(updated.name, 'New Username');
    expect(updated.uid, _first.uid);
    expect(updated.birthYear, _first.birthYear);
    expect(updated.gender, _first.gender);
    expect(updated.isControl, isTrue);
  });

  testWidgets('validation and repository errors keep the editor usable', (
    tester,
  ) async {
    final repo = _Repo()..updateError = 'Unable to sync profile';
    await _pump(tester, repo);
    await _edit(tester, 'first');
    final input = find.byKey(const ValueKey('profile-first-name'));
    await tester.enterText(input, '   ');
    await _tapEditorText(tester, 'Save');
    expect(find.text('Enter a name'), findsOneWidget);
    expect(repo.updates, isEmpty);
    await tester.enterText(input, 'Updated');
    await _tapEditorText(tester, 'Save');
    expect(find.byType(EditUserWidget), findsOneWidget);
    expect(find.text('Unable to sync profile'), findsOneWidget);
    repo.updateError = null;
    await _tapEditorText(tester, 'Save');
    expect(find.byType(EditUserWidget), findsNothing);
    expect(repo.updates, hasLength(2));
  });

  testWidgets('name editor retains multi-part family names and live initials', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo, type: ProfileType.name);
    await _edit(tester, 'second');
    final family = tester.widget<TextFormField>(
      find.byKey(const ValueKey('profile-last-name')),
    );
    expect(family.controller?.text, 'van der Berg');
    await tester.enterText(
      find.byKey(const ValueKey('profile-first-name')),
      'Alex',
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(EditUserWidget),
        matching: find.text('AB'),
      ),
      findsOneWidget,
    );
    await _tapEditorText(tester, 'Save');
    expect(repo.updates.single.name, 'Alex van der Berg');
    expect(repo.updates.single.birthYear, 2000);
    expect(repo.updates.single.gender, 'Female');
  });

  testWidgets('one-word name profiles can still be edited', (tester) async {
    final repo = _Repo();
    final user = SubUser(
      id: 'single',
      name: 'Sam',
      birthYear: 2000,
      gender: 'Other',
      isControl: true,
    );
    await _pump(tester, repo, type: ProfileType.name, profiles: [user]);
    await _edit(tester, 'single');
    await tester.enterText(
      find.byKey(const ValueKey('profile-first-name')),
      'Alex',
    );
    await _tapEditorText(tester, 'Save');
    expect(repo.updates.single.name, 'Alex');
    expect(repo.updates.single.isControl, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete requires confirmation and retains errors until success', (
    tester,
  ) async {
    final repo = _Repo()..deleteError = 'Unable to remove profile';
    final container = await _pump(tester, repo);
    await container
        .read(profileConditionProvider('first').notifier)
        .save(const ProfileCondition('Not Sure'));
    await _edit(tester, 'first');
    await _tapEditorText(tester, 'Delete this profile');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.deletions, isEmpty);
    expect(find.byType(EditUserWidget), findsOneWidget);
    await _tapEditorText(tester, 'Delete this profile');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repo.deletions.single.uid, _first.uid);
    expect(find.text('Unable to remove profile'), findsOneWidget);
    expect(
      await container.read(profileConditionProvider('first').future),
      const ProfileCondition('Not Sure'),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    repo.deleteError = null;
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(EditUserWidget), findsNothing);
    expect(repo.deletions, hasLength(2));
    expect(
      await container.read(profileConditionProvider('first').future),
      isNull,
    );
  });

  testWidgets('profile fields and Save remain reachable above the keyboard', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo, type: ProfileType.name, keyboard: 300);
    await _edit(tester, 'first');
    final family = find.byKey(const ValueKey('profile-last-name'));
    await tester.ensureVisible(family);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(family).dy, lessThanOrEqualTo(544));
    await tester.enterText(family, 'van der Campbell');
    await _tapEditorText(tester, 'Save');
    expect(repo.updates.single.name, 'Robert van der Campbell');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(1500, 900)]) {
    testWidgets(
      'adaptive profile editor fits ${size.width} wide at large text',
      (tester) async {
        final repo = _Repo();
        await _pump(tester, repo, size: size, scale: 3, type: ProfileType.name);
        expect(tester.takeException(), isNull);
        await _edit(tester, 'first');
        expect(find.byType(Dialog), findsOneWidget);
        final condition = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(condition);
        await tester.tap(condition);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final choice = find.text('GRIN2B gene disorder');
        await tester.scrollUntilVisible(
          choice,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(
          tester.element(choice.last),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        expect(choice.last.hitTestable(), findsOneWidget);
        await tester.tap(choice.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final name = find.byKey(const ValueKey('profile-first-name'));
        await tester.ensureVisible(name);
        await tester.enterText(name, 'Alex');
        await tester.pumpAndSettle();
        await _tapEditorText(tester, 'Save');
        expect(repo.updates.single.name, 'Alex Campbell');
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _FailingConditionService extends SharedService {
  bool fail = true;

  @override
  Future<void> setProfileCondition({
    required String accountId,
    required String profileId,
    required ProfileCondition? condition,
  }) async {
    if (fail) throw StateError('Storage unavailable');
    await super.setProfileCondition(
      accountId: accountId,
      profileId: profileId,
      condition: condition,
    );
  }
}
