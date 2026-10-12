import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Dashboard/today_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/DashboardView/compact_entry_card.dart';
import 'package:stripes_ui/UI/History/DashboardView/today_section.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  for (final count in [0, 2]) {
    testWidgets('Today logging opens recording with $count previous entries', (
      tester,
    ) async {
      await _pump(tester, count: count);
      await tester.tap(find.byKey(const ValueKey('today-log-Pain')));
      await tester.pumpAndSettle();
      expect(find.text('Recording Pain'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Today review count toggles entries without opening recording', (
    tester,
  ) async {
    final router = await _pump(tester, count: 2);
    final review = find.byKey(const ValueKey('today-review-Pain'));
    expect(find.byType(CompactEntryCard), findsNothing);
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byKey(const ValueKey('today-log-Pain'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.byType(CompactEntryCard), findsNWidgets(2));
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.byType(CompactEntryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today actions fit a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, count: 2, textScale: 3);
    final record = find.byKey(const ValueKey('today-log-Pain'));
    final review = find.byKey(const ValueKey('today-review-Pain'));
    expect(
      tester.getTopLeft(review).dy,
      greaterThan(tester.getTopLeft(record).dy),
    );
    expect(tester.getSize(record).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.byType(CompactEntryCard), findsNWidgets(2));
    final entry = find.byType(CompactEntryCard).first;
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    final detail = find.text('How much pain?');
    expect(detail, findsOneWidget);
    expect(MediaQuery.textScalerOf(tester.element(detail)).scale(14), 42);
    expect(tester.takeException(), isNull);
  });
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required int count,
  double textScale = 1,
}) async {
  const question = Numeric(
    id: 'pain',
    prompt: 'How much pain?',
    type: 'Pain',
    min: 0,
    max: 10,
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: TodayActivitySection(),
          ),
        ),
      ),
      GoRoute(
        path: '/record',
        name: RouteName.MULTI_RECORD,
        builder: (_, state) => Scaffold(
          body: Text('Recording ${state.uri.queryParameters['category']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => const StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(multiSessionFlow: true),
          ),
        ),
        availableRecordPaths.overrideWith(
          (ref) async => [
            RecordItem(
              path: RecordPath(name: 'Pain', pages: []),
            ),
          ],
        ),
        todayCategoryCountsProvider.overrideWith(
          (ref) async => {'Pain': count},
        ),
        todayResponsesProvider.overrideWith(
          (ref) async => [
            for (var index = 0; index < count; index++)
              NumericResponse(
                question: question,
                stamp: dateToStamp(DateTime.now()) - index,
                response: 4,
              ),
          ],
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
