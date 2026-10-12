import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/Demo/bowel_movement_full_view_demo.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';
import 'package:stripes_ui/UI/Record/Screens/record_screen.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';

void main() {
  testWidgets('category styling can opt in on its own', (tester) async {
    Widget app(BetaUiConfig betaUi) => ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(betaUi: betaUi),
        ),
      ],
      child: MaterialApp(
        theme: light,
        home: Scaffold(
          body: RecordButton(
            'Bowel Movement',
            (_) {},
            const [],
            categoryType: 'Bowel Movement',
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const BetaUiConfig.disabled()));
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      app(const BetaUiConfig.disabled(useCategoryTheme: true)),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Bowel Movement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every type preset and the Bristol ID escape hatch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp());
    await tester.pumpAndSettle();

    expect(find.byType(BowelMovementBristolEntry), findsOneWidget);
    expect(find.byType(BowelMovementNumericEntry), findsNothing);
    expect(find.byType(BowelMovementMultipleChoiceEntry), findsNWidgets(2));
    expect(find.byType(BowelMovementAllThatApplyEntry), findsNWidgets(3));
    expect(find.byType(BowelMovementCheckEntry), findsOneWidget);
    expect(find.byType(BowelMovementFreeResponseEntry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo controls write real responses and submit the session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DetailResponse? submitted;
    await tester.pumpWidget(
      _demoApp(onSubmit: (response) => submitted = response),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, const ValueKey('bristol-type-4'));
    await _tapVisible(
      tester,
      const ValueKey('bowel-demo-laxatives-taken-choice-0'),
    );
    await _tapVisible(
      tester,
      const ValueKey('bowel-demo-stool-symptoms-choice-1'),
    );
    await _tapVisible(
      tester,
      const ValueKey('bowel-demo-stool-symptoms-choice-2'),
    );
    await _tapVisible(tester, const ValueKey('bowel-demo-follow-up-check'));

    final textField = find.byKey(const ValueKey('bowel-free-response'));
    await tester.ensureVisible(textField);
    await tester.pumpAndSettle();
    await tester.enterText(textField, 'Felt better after resting.');
    await tester.pump();

    await _tapVisible(tester, const ValueKey('bowel-demo-submit'));

    expect(submitted, isNotNull);
    final responses = submitted!.responses;
    expect(responses.whereType<NumericResponse>().single.response, 4);
    expect(responses.whereType<MultiResponse>().single.index, 0);
    expect(responses.whereType<AllResponse>().single.responses, [1, 2]);
    expect(responses.whereType<Selected>(), hasLength(1));
    expect(
      responses.whereType<OpenResponse>().single.response,
      'Felt better after resting.',
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _demoApp({ValueChanged<DetailResponse>? onSubmit}) => ProviderScope(
  overrides: [
    configProvider.overrideWith(
      (ref) => const StripesConfig.sandbox(betaUi: BetaUiConfig.enabled()),
    ),
  ],
  child: MaterialApp(
    theme: light,
    home: BowelMovementFullViewDemo(onSubmit: onSubmit),
  ),
);

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
