import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/CommonWidgets/detail_field.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final colored in [false, true]) {
    testWidgets('category icons with color accents $colored', (tester) async {
      final response = DetailResponse(
        id: 'record',
        stamp: DateTime(2026, 10, 1, 9).millisecondsSinceEpoch,
        detailType: 'category.BM',
        description: 'Example note',
        responses: [
          NumericResponse(
            question: const Numeric(
              id: 'q4',
              type: 'category.BM',
              prompt: 'Average BM type (1–7)',
              min: 1,
              max: 7,
            ),
            stamp: 0,
            response: 2,
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWith(
              (ref) => StripesConfig.sandbox(
                betaUi: BetaUiConfig.disabled(
                  useCategoryTheme: true,
                  useCategoryColors: colored,
                ),
              ),
            ),
            baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: EntryDisplay(event: response, hasControls: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CategoryIcon), findsOneWidget);
      tester
          .state<EntryDisplayState>(find.byType(EntryDisplay))
          .controller
          .expand();
      await tester.pumpAndSettle();
      final field = find.byType(DetailField);
      expect(field, findsOneWidget);
      final fieldContext = tester.element(field);
      final appContext = tester.element(find.byType(Scaffold));
      expect(
        Theme.of(fieldContext).colorScheme.primary,
        colored
            ? CategoryTheme.resolve('category.BM').color
            : Theme.of(appContext).colorScheme.primary,
      );
      final decorations = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(EntryDisplay),
          matching: find.byType(DecoratedBox),
        ),
      );
      final rails = decorations.where((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration &&
            decoration.border != null &&
            !decoration.border!.isUniform;
      });
      expect(rails.length, colored ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }
}
