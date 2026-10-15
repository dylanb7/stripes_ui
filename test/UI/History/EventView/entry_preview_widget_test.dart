import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final _entry = DetailResponse(
  id: 'pain-entry',
  stamp: dateToStamp(DateTime(2026, 10, 14, 7, 25)),
  detailType: 'Pain',
  description: 'After dinner',
  responses: [
    NumericResponse(
      question: const Numeric(
        id: 'intensity',
        type: 'Pain',
        prompt: 'Intensity',
      ),
      stamp: dateToStamp(DateTime(2026, 10, 14, 7, 25)),
      response: 6,
    ),
  ],
);

Future<ProviderContainer> _pumpEntry(
  WidgetTester tester, {
  bool beta = true,
  bool reduceMotion = false,
  bool review = false,
  bool initiallyExpanded = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(historyOverview: beta),
          ),
        ),
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: EntryDisplay(
              event: _entry,
              dateLabel: '7:25 AM',
              isReview: review,
              initiallyExpanded: initiallyExpanded,
              hasControls: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(EntryDisplay)));
}

void main() {
  testWidgets('beta entry shows category, preview, then timestamp', (
    tester,
  ) async {
    await _pumpEntry(tester);
    final title = find.text('Pain', findRichText: true);
    final preview = find.byKey(const ValueKey('entry-preview'));
    final timestamp = find.text('7:25 AM');
    expect(find.text('Intensity: 6 · “After dinner”'), findsOneWidget);
    expect(tester.widget<Text>(preview).maxLines, 2);
    expect(
      tester.getBottomLeft(title).dy,
      lessThan(tester.getTopLeft(preview).dy),
    );
    expect(
      tester.getBottomLeft(preview).dy,
      lessThan(tester.getTopLeft(timestamp).dy),
    );
  });

  testWidgets('preview fades and collapses while timestamp remains', (
    tester,
  ) async {
    await _pumpEntry(tester);
    final state = tester.state<EntryDisplayState>(find.byType(EntryDisplay));
    final timestampBefore = tester.getTopLeft(find.text('7:25 AM')).dy;
    await tester.tap(find.text('Pain', findRichText: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(state.controller.isExpanded, isTrue);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('entry-preview')),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, allOf(greaterThan(0), lessThan(1)));
    expect(
      tester.getTopLeft(find.text('7:25 AM')).dy,
      lessThan(timestampBefore),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('entry-preview')), findsNothing);
    expect(find.text('7:25 AM'), findsOneWidget);
    expect(find.text('After dinner'), findsOneWidget);
    await tester.tap(find.text('Pain', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('entry-preview')), findsOneWidget);
  });

  testWidgets('reduced motion immediately removes the preview', (tester) async {
    await _pumpEntry(tester, reduceMotion: true);
    tester
        .state<EntryDisplayState>(find.byType(EntryDisplay))
        .controller
        .expand();
    await tester.pump();
    expect(find.byKey(const ValueKey('entry-preview')), findsNothing);
    expect(find.text('7:25 AM'), findsOneWidget);
  });

  testWidgets('beta off keeps the original header', (tester) async {
    await _pumpEntry(tester, beta: false);
    expect(find.byKey(const ValueKey('entry-preview')), findsNothing);
    expect(find.text('7:25 AM'), findsOneWidget);
  });

  testWidgets('beta review entries also show saved-answer previews', (
    tester,
  ) async {
    await _pumpEntry(tester, review: true);
    expect(find.byKey(const ValueKey('entry-preview')), findsOneWidget);
    expect(find.text('7:25 AM'), findsOneWidget);
  });

  testWidgets('preview wraps at large text sizes', (tester) async {
    await _pumpEntry(tester, textScale: 3.2);
    final preview = tester.widget<Text>(
      find.byKey(const ValueKey('entry-preview')),
    );
    expect(preview.maxLines, isNull);
    expect(tester.takeException(), isNull);
    tester
        .state<EntryDisplayState>(find.byType(EntryDisplay))
        .controller
        .expand();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'header exposes its expanded state and avoids duplicate preview semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEntry(tester);
      final header = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.expanded != null,
      );
      expect(
        tester.getSemantics(header),
        isSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(header).getSemanticsData().label,
        contains('Intensity: 6'),
      );
      await tester.tap(find.text('Pain', findRichText: true));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(header), isSemantics(isExpanded: true));
      expect(
        tester.getSemantics(header).getSemanticsData().label,
        isNot(contains('Intensity: 6')),
      );
      semantics.dispose();
    },
  );

  testWidgets('detail sheet can start expanded and still collapse', (
    tester,
  ) async {
    await _pumpEntry(tester, initiallyExpanded: true);
    final state = tester.state<EntryDisplayState>(find.byType(EntryDisplay));
    expect(state.controller.isExpanded, isTrue);
    expect(find.byKey(const ValueKey('entry-preview')), findsNothing);
    await tester.tap(find.text('Pain', findRichText: true));
    await tester.pumpAndSettle();
    expect(state.controller.isExpanded, isFalse);
    expect(find.byKey(const ValueKey('entry-preview')), findsOneWidget);
  });
}
