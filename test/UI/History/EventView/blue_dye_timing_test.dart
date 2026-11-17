import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/CommonWidgets/detail_field.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final legacy in [false, true]) {
    testWidgets(
      '${legacy ? 'legacy' : 'active'} history measures transit from meal start to first blue BM',
      (tester) async {
        // The meal estimate, recorded finish, and last blue BM deliberately
        // differ so none can silently replace the two transit endpoints.
        final response = BlueDyeResp(
          id: 'oral-transit',
          startEating: DateTime.utc(2026, 1, 21, 10),
          eatingDuration: const Duration(minutes: 22, seconds: 30),
          finishedEatingTime: DateTime.utc(2026, 1, 21, 10, 25),
          normalBowelMovements: 0,
          blueBowelMovements: 2,
          logs: const [],
          amountConsumed: AmountConsumed.half,
          firstBlue: DateTime.utc(2026, 1, 21, 13),
          lastBlue: DateTime.utc(2026, 1, 21, 14),
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: legacy
                      ? BlueDyeDisplay(resp: response)
                      : BlueDyeVisualDisplay(resp: response),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final threeHours = prettyDuration(
          const Duration(hours: 3),
          delimiter: ' ',
          abbreviated: true,
        );
        expect(find.text(threeHours), findsOneWidget);
        if (legacy) {
          expect(find.text('Transit Duration:'), findsOneWidget);
          expect(find.text('Eating Duration:'), findsOneWidget);
          expect(
            find.text(
              prettyDuration(
                const Duration(minutes: 22, seconds: 30),
                abbreviated: true,
              ),
            ),
            findsOneWidget,
          );
        } else {
          final fields = {
            for (final field in tester.widgetList<DetailField>(
              find.byType(DetailField),
            ))
              field.question: field.answerText,
          };
          expect(fields['Transit time'], threeHours);
          expect(fields['Eating Duration'], '15 to 30 minutes');
          expect(
            fields['Lag phase'],
            prettyDuration(
              const Duration(hours: 1),
              delimiter: ' ',
              abbreviated: true,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
