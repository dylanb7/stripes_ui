import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final (textScale, betaNotes) in [
    (1.0, false),
    (2.0, false),
    (1.0, true),
    (2.0, true),
  ]) {
    testWidgets(
      'description sheet stays above keyboard and retains notes at ${textScale}x text, beta $betaNotes',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        final controller = TextEditingController();
        final container = ProviderContainer();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LongTextEntry(
                      textController: controller,
                      hintText: 'Anything else to add?',
                      labelText: betaNotes ? 'Anything else to add?' : null,
                      expandToFill: betaNotes,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          controller.dispose();
          container.dispose();
        });

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
        expect(container.read(isSheetOpenProvider), isFalse);
        await tester.tap(find.text('Tap to type...'));
        await tester.pumpAndSettle();

        final input = find.byType(TextField);
        final done = find.widgetWithText(TextButton, 'Done');
        expect(container.read(isSheetOpenProvider), isTrue);
        expect(input, findsOneWidget);
        expect(tester.widget<TextField>(input).expands, isTrue);
        expect(tester.getSize(input).height, greaterThan(300));
        expect(tester.testTextInput.isVisible, isTrue);

        // A real view-inset change propagates through the production sheet
        // controller and its modal route, as it does when the keyboard opens.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        const keyboardTop = 512.0;
        for (final control in [
          input,
          done,
          find.text(betaNotes ? 'Anything else to add?' : 'Description').last,
        ]) {
          final bounds = tester.getRect(control);
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(keyboardTop));
        }
        expect(tester.getSize(input).height, greaterThan(120));
        expect(done.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        const note =
            'Felt better after lunch.\nWill keep track of this tomorrow.';
        await tester.enterText(input, note);
        await tester.tap(done);
        await tester.pumpAndSettle();

        expect(controller.text, note);
        expect(find.byType(TextField), findsNothing);
        expect(find.text(note), findsOneWidget);
        expect(container.read(isSheetOpenProvider), isFalse);

        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.tap(find.text(note));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, note);

        await tester.enterText(input, '$note\nNo other notes.');
        await tester.tap(done);
        await tester.pumpAndSettle();
        expect(controller.text, '$note\nNo other notes.');
        expect(container.read(isSheetOpenProvider), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
