import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_harness.dart';

final _profiles = [
  SubUser(
    name: 'Alexandratheodora Baker',
    gender: '',
    birthYear: 2000,
    isControl: false,
    id: 'first',
  ),
  SubUser(
    name: 'Sam',
    gender: '',
    birthYear: 2000,
    isControl: false,
    id: 'second',
  ),
];

class _Profiles extends SubNotifier {
  @override
  SubState build() => SubState(subUsers: _profiles, selected: _profiles.first);

  @override
  Future<bool> changeCurrent(SubUser newUser) async {
    state = AsyncData(state.requireValue.copyWith(selected: newUser));
    return true;
  }
}

void main() {
  setUpAll(loadAuditFonts);

  for (final scale in [1.0, 3.0]) {
    testWidgets('profile name opens full-row choices at ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subHolderProvider.overrideWith(_Profiles.new),
            configProvider.overrideWith(
              (ref) => StripesConfig(
                hasLogging: true,
                allowsSummaryReport: true,
                profileType: ProfileType.username,
                betaUi: const BetaUiConfig.enabled(),
              ),
            ),
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
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(child: PatientChanger()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final name = find.text(_profiles.first.name);
      expect(name, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PatientChanger),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(PatientChanger)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Recording for ${_profiles.first.name}. Change profile',
          ),
        ),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          label: 'Recording for ${_profiles.first.name}. Change profile',
        ),
      );

      await tester.tap(name);
      await tester.pumpAndSettle();
      expect(find.byType(UserSelect), findsOneWidget);

      final choice = find.byKey(const ValueKey('select-profile-second'));
      await tester.scrollUntilVisible(
        choice,
        100,
        scrollable: find.descendant(
          of: find.byType(UserSelect),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.getRect(choice);
      expect(row.height, greaterThanOrEqualTo(48));
      // Blank trailing space should select just as reliably as the label.
      await tester.tapAt(Offset(row.right - 16, row.center.dy));
      await tester.pumpAndSettle();
      expect(find.byType(UserSelect), findsNothing);
      expect(find.text('Sam'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PatientChanger)),
      );
      expect(
        container.read(subHolderProvider).requireValue.selected?.uid,
        'second',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
