import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/Questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/account_management_screen.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/config.dart';

class _Profiles extends SubNotifier {
  @override
  SubState build() => SubState.empty();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Menu hides Baselines until the set supplies baseline layouts', (
    tester,
  ) async {
    final layouts = StreamController<List<RecordPath>>();
    addTearDown(layouts.close);
    await _pumpMenu(tester, layouts: layouts.stream);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Baselines'), findsNothing);
    layouts.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Baselines'), findsNothing);
    layouts.add([
      RecordPath(
        name: 'Initial questionnaire',
        pages: const [],
        isBaseline: true,
      ),
    ]);
    await tester.pumpAndSettle();
    // Completed baselines remain accessible for review; only empty sets hide.
    expect(find.text('Baselines'), findsOneWidget);
    expect(find.textContaining('pending'), findsNothing);
    layouts.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Baselines'), findsNothing);
    expect(find.text('Help and resources'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (label, config, visible) in [
    ('base', const BetaUiConfig.disabled(), false),
    ('beta', const BetaUiConfig.enabled(), true),
    ('opt in', const BetaUiConfig.disabled(helpAndResources: true), true),
    ('opt out', const BetaUiConfig.enabled(helpAndResources: false), false),
  ]) {
    testWidgets('Menu resources follow their beta gate: $label', (
      tester,
    ) async {
      await _pumpMenu(tester, layouts: Stream.value([]), betaUi: config);
      expect(
        find.text('Help and resources'),
        visible ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Study guides and tracking tips'),
        visible ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('configured baselines retain their pending count', (
    tester,
  ) async {
    await _pumpMenu(
      tester,
      layouts: Stream.value([
        RecordPath(
          name: 'Initial questionnaire',
          pages: const [],
          isBaseline: true,
        ),
      ]),
      pending: const [
        BaselineTrigger(
          baselineType: 'Initial questionnaire',
          recordPath: 'Initial questionnaire',
          title: 'Initial questionnaire',
          description: '',
        ),
      ],
    );
    expect(find.text('Baselines'), findsOneWidget);
    expect(find.text('1 pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpMenu(
  WidgetTester tester, {
  required Stream<List<RecordPath>> layouts,
  List<BaselineTrigger> pending = const [],
  BetaUiConfig betaUi = const BetaUiConfig.disabled(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(betaUi: betaUi),
        ),
        subHolderProvider.overrideWith(_Profiles.new),
        baselineLayoutProvider.overrideWith((ref) => layouts),
        incompleteBaselinesProvider.overrideWith((ref) async => pending),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(actions: const [UserProfileButton(selected: false)]),
          body: const AccountManagementScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
