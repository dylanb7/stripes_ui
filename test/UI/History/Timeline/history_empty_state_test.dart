import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/history_empty_state_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Timeline/history_empty_state.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../../accessibility/audit_harness.dart';

const _captureKey = ValueKey('history-empty-state-capture');

Future<void> _capture(WidgetTester tester, String name) async {
  const configuredDirectory = String.fromEnvironment(
    'HISTORY_OVERVIEW_CAPTURE',
  );
  if (configuredDirectory.isEmpty || configuredDirectory == 'false') return;
  final directory = configuredDirectory == 'true'
      ? 'build/history_overview'
      : configuredDirectory;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    Directory(directory).createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$directory/$name.png').writeAsBytesSync(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAuditFonts();
  });

  Future<ProviderContainer> pumpEmpty(
    WidgetTester tester, {
    HistoryEmptyDetails details = const HistoryEmptyDetails(
      kind: HistoryEmptyKind.noEntries,
    ),
    List<LabeledFilter> filters = const [],
    bool hasLogging = true,
    Future<HistoryEmptyDetails> Function()? load,
    Stream<List<Stamp>>? historyStream,
    double textScale = 1,
    Size viewport = const Size(390, 844),
    bool historyShell = false,
    Completer<List<ReviewItem>>? pendingReviews,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWith(
            (_) => StripesConfig(
              profileType: ProfileType.username,
              hasLogging: hasLogging,
              allowsSummaryReport: true,
              betaUi: const BetaUiConfig.enabled(),
            ),
          ),
          displayDataProvider.overrideWith(() => _Settings(filters)),
          if (historyShell) ...[
            authStream.overrideWith(
              (_) => Stream.value(const AuthUser.empty()),
            ),
            subHolderProvider.overrideWith(_HistoryProfile.new),
            hasTestsProvider.overrideWith((_) async => true),
            availableStampsProvider.overrideWith((_) async => []),
            inRangeProvider.overrideWith((_) async => []),
            graphStampsProvider.overrideWith((_) async => {}),
            reviewPaths.overrideWith(
              (_, _) => pendingReviews?.future ?? Future.value([]),
            ),
            reviewPathsByTypeProvider.overrideWith((_) async => {}),
            hasAvailableFiltersProvider.overrideWith((_) async => true),
          ],
          stampProvider.overrideWith((_) async => null),
          stampsStreamProvider.overrideWith(
            (_) =>
                historyStream ??
                Stream.value([
                  if (details.closestEntry != null) details.closestEntry!,
                ]),
          ),
          baselinesStreamProvider.overrideWith((_) => Stream.value([])),
          historyEmptyDetailsProvider.overrideWith(
            (_) async => load == null ? details : await load(),
          ),
        ],
        child: MaterialApp(
          theme: light.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: RepaintBoundary(key: _captureKey, child: child!),
          ),
          home: Scaffold(
            appBar: historyShell ? AppBar(title: const Text('STRiPES')) : null,
            bottomNavigationBar: historyShell
                ? const SmallLayout(selected: TabOption.history)
                : null,
            body: historyShell
                ? const EventsView()
                : const SingleChildScrollView(child: HistoryEmptyState()),
          ),
        ),
      ),
    );
    await tester.pump();
    if (historyShell) await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(HistoryEmptyState)),
    );
  }

  testWidgets('first-entry invitation respects logging availability', (
    tester,
  ) async {
    await pumpEmpty(tester);
    expect(find.text('No entries available yet'), findsOneWidget);
    expect(find.text('Record an entry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpEmpty(tester, hasLogging: false);
    expect(find.text('Record an entry'), findsNothing);
  });

  testWidgets('clearing filters is explicit and leaves the period unchanged', (
    tester,
  ) async {
    final filters = const CategoryContext().createFilters(
      CategoryState(selectedItems: {'Pain'}),
    );
    final container = await pumpEmpty(
      tester,
      filters: filters,
      details: const HistoryEmptyDetails(
        kind: HistoryEmptyKind.noMatchingEntries,
        unfilteredPeriodCount: 2,
      ),
    );
    final before = container.read(displayDataProvider).range;
    expect(
      find.text('2 entries are available in this period without filters.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    expect(container.read(displayDataProvider).filters, isEmpty);
    expect(container.read(displayDataProvider).range, before);
  });

  testWidgets(
    'closest opens the actual expanded entry without changing current scope',
    (tester) async {
      final filters = const CategoryContext().createFilters(
        CategoryState(selectedItems: {'Pain'}),
      );
      final entry = DetailResponse(
        id: 'entry',
        detailType: 'Pain',
        description: 'After the late meal',
        stamp: dateToStamp(DateTime(2026, 10, 11, 17)),
        responses: const [],
      );
      final container = await pumpEmpty(
        tester,
        filters: filters,
        details: HistoryEmptyDetails(
          kind: HistoryEmptyKind.noMatchingEntries,
          closestEntry: entry,
        ),
      );
      container.read(viewModeProvider.notifier).setMode(ViewMode.graph);
      final original = container.read(displayDataProvider);
      expect(find.textContaining('Pain · Oct 11, 2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Entry details'), findsOneWidget);
      expect(find.text('After the late meal'), findsOneWidget);
      final display = tester.widget<EntryDisplay>(find.byType(EntryDisplay));
      expect(display.event, same(entry));
      expect(
        tester
            .state<EntryDisplayState>(find.byType(EntryDisplay))
            .controller
            .isExpanded,
        isTrue,
      );
      expect(container.read(displayDataProvider), original);
      expect(container.read(viewModeProvider), ViewMode.graph);

      await tester.tap(find.text('View this day'));
      await tester.pumpAndSettle();
      final settings = container.read(displayDataProvider);
      expect(settings.cycle, TimeCycle.day);
      expect(settings.range.start, DateTime(2026, 10, 11));
      expect(settings.filters, filters);
      expect(container.read(viewModeProvider), ViewMode.events);
      expect(find.text('Entry details'), findsNothing);
    },
  );

  testWidgets('unknown recording time is labeled honestly in recovery link', (
    tester,
  ) async {
    final response = DetailResponse(
      id: 'entry',
      detailType: 'Pain',
      stamp: dateToStamp(DateTime(2026, 10, 11)),
      responses: const [],
    );
    final entry = TimedDetailResponse(
      response: response,
      entry: detailResponseToEntry(response, 'profile').copyWith(
        timeOfDay: TimeOfDayEntry.notSure,
        data: {
          recordTimeField: const RecordTime(
            precision: RecordTimePrecision.unknown,
            exactTime: TimeOfDay(hour: 0, minute: 0),
          ).toJson(DateTime(2026, 10, 10)),
        },
      ),
    );
    final container = await pumpEmpty(
      tester,
      details: HistoryEmptyDetails(
        kind: HistoryEmptyKind.noEntriesInPeriod,
        closestEntry: entry,
      ),
    );
    expect(find.text('Time not known'), findsOneWidget);
    expect(find.textContaining('12:00'), findsNothing);
    expect(find.textContaining('Oct 10, 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View this day'));
    await tester.pumpAndSettle();
    expect(
      container.read(displayDataProvider).range.start,
      DateTime(2026, 10, 10),
    );
  });

  testWidgets(
    'review recovery shows its period and opens review details without an exact time',
    (tester) async {
      final path = RecordPath(
        name: 'Monthly check-in',
        pages: const [],
        period: Period.month,
      );
      final review = DetailResponse(
        id: 'review',
        detailType: path.name,
        stamp: dateToStamp(DateTime(2026, 9, 1)),
        description: 'Monthly observations',
        responses: const [],
      );
      final container = await pumpEmpty(
        tester,
        details: HistoryEmptyDetails(
          kind: HistoryEmptyKind.noEntriesInPeriod,
          closestEntry: review,
          closestReviewPath: path,
        ),
      );
      final original = container.read(displayDataProvider);
      expect(find.text('Monthly check-in · Sep 2026'), findsOneWidget);
      expect(find.textContaining('12:00'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
      await tester.pumpAndSettle();
      final display = tester.widget<EntryDisplay>(find.byType(EntryDisplay));
      expect(display.isReview, isTrue);
      expect(display.dateLabel, 'Sep 2026');
      expect(
        tester
            .state<EntryDisplayState>(find.byType(EntryDisplay))
            .controller
            .isExpanded,
        isTrue,
      );
      expect(find.text('Monthly observations'), findsOneWidget);
      expect(find.textContaining('12:00'), findsNothing);
      expect(container.read(displayDataProvider), original);
      await tester.tap(find.text('View this period'));
      await tester.pumpAndSettle();
      expect(
        container.read(displayDataProvider).range,
        DateTimeRange(start: DateTime(2026, 9), end: DateTime(2026, 10)),
      );
    },
  );

  testWidgets('loading does not claim history is globally empty', (
    tester,
  ) async {
    final pending = Completer<HistoryEmptyDetails>();
    await pumpEmpty(tester, load: () => pending.future);
    expect(find.text('Looking for entries near this period…'), findsOneWidget);
    expect(find.text('No entries available yet'), findsNothing);
    expect(find.text('Record an entry'), findsNothing);
    expect(find.text('Choose dates'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'open closest details follows edits and stops displaying a removed entry',
    (tester) async {
      final entry = DetailResponse(
        id: 'entry',
        detailType: 'Pain',
        stamp: dateToStamp(DateTime(2026, 10, 11, 17)),
        description: 'Original note',
        responses: const [],
      );
      final updates = StreamController<List<Stamp>>();
      Stream<List<Stamp>> history() async* {
        yield [entry];
        yield* updates.stream;
      }

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await updates.close();
      });
      await pumpEmpty(
        tester,
        historyStream: history(),
        details: HistoryEmptyDetails(
          kind: HistoryEmptyKind.noEntriesInPeriod,
          closestEntry: entry,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Original note'), findsOneWidget);
      updates.add([
        DetailResponse(
          id: entry.id,
          detailType: entry.type,
          stamp: entry.stamp,
          description: 'Updated note',
          responses: const [],
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Updated note'), findsOneWidget);
      expect(find.text('Original note'), findsNothing);
      updates.add([]);
      await tester.pumpAndSettle();
      expect(find.text('This entry is no longer available.'), findsOneWidget);
      expect(find.byType(EntryDisplay), findsNothing);
    },
  );

  testWidgets(
    'failed lookup offers retry without claiming there are no records',
    (tester) async {
      var calls = 0;
      await pumpEmpty(
        tester,
        load: () async {
          calls++;
          throw StateError('unavailable');
        },
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('No entries available yet'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(calls, 2);
    },
  );

  testWidgets('recovery action wraps at large text sizes', (tester) async {
    final entry = DetailResponse(
      id: 'entry',
      detailType: 'A category with a long accessible name',
      stamp: dateToStamp(DateTime(2026, 10, 11, 17)),
      responses: const [],
    );
    await pumpEmpty(
      tester,
      details: HistoryEmptyDetails(
        kind: HistoryEmptyKind.noEntriesInPeriod,
        closestEntry: entry,
      ),
      textScale: 2.5,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('history-closest-entry')),
    );
    await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'confirmed empty history offers nearest recovery while reviews are still loading',
    (tester) async {
      final pendingReviews = Completer<List<ReviewItem>>();
      final entry = _visualEntry();
      await pumpEmpty(
        tester,
        historyShell: true,
        pendingReviews: pendingReviews,
        details: HistoryEmptyDetails(
          kind: HistoryEmptyKind.noEntriesInPeriod,
          closestEntry: entry,
        ),
      );
      expect(find.text('No entries in this period'), findsOneWidget);
      expect(pendingReviews.isCompleted, isFalse);
      await tester.ensureVisible(
        find.byKey(const ValueKey('history-closest-entry')),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'empty-390px-closest');
      await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
      await tester.pumpAndSettle();
      expect(find.text('After lunch, lower abdominal pain.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'empty-390px-entry-sheet');
      pendingReviews.complete([]);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'closest detail sheet remains readable and operable at 320px and 3x',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final entry = _visualEntry();
      await pumpEmpty(
        tester,
        viewport: const Size(320, 568),
        textScale: 3,
        details: HistoryEmptyDetails(
          kind: HistoryEmptyKind.noEntriesInPeriod,
          closestEntry: entry,
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('history-closest-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-closest-entry')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Entry details'), findsOneWidget);
      await _capture(tester, 'empty-320px-3.0x-sheet-top');
      final note = find.text('After lunch, lower abdominal pain.');
      await tester.ensureVisible(note);
      await tester.pumpAndSettle();
      expect(note.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'empty-320px-3.0x-sheet-note');
      final edit = find.widgetWithIcon(IconButton, Icons.edit);
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      expect(edit.hitTestable(), findsOneWidget);
      await _capture(tester, 'empty-320px-3.0x-sheet-controls');
      await tester.ensureVisible(find.text('View this day'));
      await tester.pumpAndSettle();
      expect(find.text('View this day').hitTestable(), findsOneWidget);
      await _capture(tester, 'empty-320px-3.0x-sheet-context');
      final close = find.widgetWithText(TextButton, 'Close');
      expect(close.hitTestable(), findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Entry details'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

DetailResponse _visualEntry() {
  final stamp = dateToStamp(DateTime(2026, 10, 11, 17));
  return DetailResponse(
    id: 'pain-closest',
    detailType: 'Pain',
    description: 'After lunch, lower abdominal pain.',
    stamp: stamp,
    responses: [
      NumericResponse(
        question: const Numeric(
          id: 'pain-intensity',
          prompt: 'Pain intensity',
          type: 'Pain',
          min: 0,
          max: 10,
        ),
        response: 6,
        stamp: stamp,
      ),
    ],
  );
}

class _HistoryProfile extends SubNotifier {
  @override
  SubState build() {
    final profile = SubUser(
      id: 'sam',
      name: 'Sam',
      gender: '',
      birthYear: 2000,
      isControl: false,
    );
    return SubState(subUsers: [profile], selected: profile);
  }
}

class _Settings extends DisplayDataProvider {
  final List<LabeledFilter> filters;
  _Settings(this.filters);
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.day, anchor: DateTime(2026, 10, 12)),
    axis: GraphYAxis.number,
    filters: filters,
  );
}
