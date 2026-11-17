import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Export/export_options_sheet.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final fixture in [
    ('base UI', true, const BetaUiConfig.disabled(), false),
    ('beta UI', true, const BetaUiConfig.enabled(), true),
    (
      'embedding app disables reports',
      false,
      const BetaUiConfig.enabled(),
      false,
    ),
    (
      'beta reports individually disabled',
      true,
      const BetaUiConfig.enabled(summaryReports: false),
      false,
    ),
  ]) {
    testWidgets('${fixture.$1} respects the summary report gate', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWithValue(
              StripesConfig(
                profileType: ProfileType.name,
                hasLogging: false,
                allowsSummaryReport: fixture.$2,
                betaUi: fixture.$3,
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ExportOptionsSheet(responses: [])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CSV Export'), findsOneWidget);
      expect(
        find.text('Summary Report'),
        fixture.$4 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
