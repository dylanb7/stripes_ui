import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);
  testWidgets('navigation adapts to live text sizing and keeps named actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scale = ValueNotifier(1.0);
    addTearDown(scale.dispose);
    String? route;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWith(
            (ref) => const StripesConfig(
              profileType: ProfileType.username,
              hasLogging: true,
              allowsSummaryReport: true,
              betaUi: BetaUiConfig.enabled(),
            ),
          ),
          hasTestsProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ValueListenableBuilder(
            valueListenable: scale,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(value)),
              child: child!,
            ),
          ),
          home: Scaffold(
            bottomNavigationBar: SmallLayout(
              selected: TabOption.history,
              customSelect: (value) => route = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nav = find.byType(SmallLayout);
    final labels = find.descendant(of: nav, matching: find.byType(Text));
    expect(labels, findsNWidgets(3));
    for (final value in [1.5, 2.0, 3.0, 4.0]) {
      scale.value = value;
      await tester.pumpAndSettle();
      for (final label
          in find
              .descendant(of: nav, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (label.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);
    }
    expect(labels, findsNothing);
    final icons = find.descendant(of: nav, matching: find.byType(Icon));
    for (final icon in icons.evaluate()) {
      expect(tester.getSize(find.byWidget(icon.widget)).width, greaterThan(25));
    }
    final history = find.bySemanticsLabel('History');
    expect(
      tester.getSemantics(history),
      matchesSemantics(
        label: 'History',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('bottom-nav-Home')));
    await tester.pumpAndSettle();
    expect(route, Routes.HOME);
    // More width brings the full labels back at the requested text size.
    tester.view.physicalSize = const Size(1200, 568);
    await tester.pumpAndSettle();
    expect(labels, findsNWidgets(3));
    expect(tester.getSize(nav).height, greaterThan(76));
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy navigation remains available by request', (tester) async {
    String? route;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWith(
            (ref) => const StripesConfig.sandbox(
              display: StripesDisplayConfig(useLegacyNavigation: true),
            ),
          ),
          hasTestsProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: SmallLayout(
              selected: TabOption.record,
              customSelect: (value) => route = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('legacy-bottom-nav-Record')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bottom-nav-Home')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('legacy-bottom-nav-History')));
    expect(route, Routes.HISTORY);
  });

  testWidgets('new navigation is the default without the dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWith((ref) => const StripesConfig.sandbox()),
          hasTestsProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            bottomNavigationBar: SmallLayout(selected: TabOption.record),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bottom-nav-Record')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-Home')), findsNothing);
    expect(
      find.byKey(const ValueKey('legacy-bottom-nav-Record')),
      findsNothing,
    );
  });
}
