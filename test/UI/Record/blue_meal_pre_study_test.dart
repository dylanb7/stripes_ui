import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final onboardingTerms in [false, true]) {
    testWidgets(
      '${onboardingTerms ? 'beta' : 'legacy'} study entry requires its own acknowledgement',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var starts = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              configProvider.overrideWith(
                (ref) => StripesConfig(
                  hasLogging: true,
                  allowsSummaryReport: true,
                  profileType: ProfileType.username,
                  betaUi: onboardingTerms
                      ? const BetaUiConfig.enabled()
                      : const BetaUiConfig.disabled(),
                ),
              ),
              authStream.overrideWith(
                (ref) => Stream.value(const AuthUser.uid(uid: 'account')),
              ),
              testProvider.overrideWith((ref) async => null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BlueMealPreStudy(
                  onClick: () => starts++,
                  isLoading: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (!onboardingTerms) {
          expect(find.byType(AppTos), findsOneWidget);
          expect(find.byType(PreStudyInfo), findsNothing);
          final continueButton = find.widgetWithText(FilledButton, 'Continue');
          expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
          await tester.ensureVisible(find.byType(Checkbox));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Checkbox));
          await tester.pumpAndSettle();
          await tester.tap(continueButton);
          await tester.pumpAndSettle();
        }

        expect(find.byType(AppTos), findsNothing);
        expect(find.byType(PreStudyInfo), findsOneWidget);
        expect(starts, 0);
        final startButton = find.widgetWithText(FilledButton, 'Start step one');
        expect(tester.widget<FilledButton>(startButton).onPressed, isNull);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(
          find.text(
            'I have read and understand the Blue Meal study process. I agree to start the test',
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(starts, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
