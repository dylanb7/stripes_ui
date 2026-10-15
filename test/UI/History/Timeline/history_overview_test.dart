import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/History/EventView/date_header.dart';
import 'package:stripes_ui/UI/History/Export/export.dart';
import 'package:stripes_ui/UI/History/Export/export_options_sheet.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../../accessibility/audit_harness.dart';

const _summaryKey = ValueKey('history-period-summary');
const _controlsKey = ValueKey('history-presentation-controls');
const _captureKey = ValueKey('history-overview-capture');

class _OverviewSettings extends DisplayDataProvider {
  final List<LabeledFilter> initialFilters;

  _OverviewSettings(this.initialFilters);

  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.month, anchor: DateTime(2024, 9)),
    axis: GraphYAxis.number,
    filters: initialFilters,
  );
}

class _OverviewProfile extends SubNotifier {
  @override
  SubState build() {
    final profile = SubUser(
      name: 'Sam',
      gender: '',
      birthYear: 2000,
      isControl: false,
      id: 'sam',
    );
    return SubState(subUsers: [profile], selected: profile);
  }
}

List<Response> _records() {
  DetailResponse record(
    String id,
    String category,
    DateTime date,
    int answers,
  ) {
    final stamp = dateToStamp(date);
    return DetailResponse(
      id: id,
      detailType: category,
      stamp: stamp,
      responses: [
        for (var i = 0; i < answers; i++)
          NumericResponse(
            id: '$id-answer-$i',
            question: Numeric(
              id: '$id-question-$i',
              prompt: i == 0 ? 'Intensity' : 'Duration',
              type: category,
            ),
            stamp: stamp,
            response: i + 3,
          ),
      ],
    );
  }

  return [
    record('pain-evening', 'Pain', DateTime(2024, 9, 23, 18, 30), 2),
    record('pain-morning', 'Pain', DateTime(2024, 9, 23, 8, 15), 2),
    record('sleep', 'Sleep & Mood', DateTime(2024, 9, 22, 7), 1),
  ];
}

LabeledFilter _categoryFilter(String category) => LabeledFilter(
  name: category,
  filterType: FilterType.category,
  filter: (response) => response.type == category,
);

Future<void> _unusedExport(
  BuildContext context,
  List<Response> responses,
  ExportType type,
) async {}

Future<ProviderContainer> _pumpOverview(
  WidgetTester tester, {
  List<Response>? records,
  List<LabeledFilter> filters = const [],
  bool betaUi = true,
  bool overviewEnabled = true,
  bool hasGraphing = true,
  bool exportEnabled = true,
  double width = 390,
  double textScale = 1,
  bool reducedMotion = false,
  bool darkMode = false,
  ValueNotifier<bool>? visible,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = records ?? _records();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayDataProvider.overrideWith(() => _OverviewSettings(filters)),
        configProvider.overrideWith(
          (ref) => StripesConfig(
            profileType: ProfileType.username,
            hasLogging: true,
            allowsSummaryReport: true,
            export: exportEnabled ? _unusedExport : null,
            betaUi: betaUi
                ? BetaUiConfig.enabled(
                    historyOverview: overviewEnabled,
                    hasGraphing: hasGraphing,
                  )
                : BetaUiConfig.disabled(hasGraphing: hasGraphing),
          ),
        ),
        subHolderProvider.overrideWith(_OverviewProfile.new),
        authStream.overrideWith((ref) => Stream.value(const AuthUser.empty())),
        stampProvider.overrideWith((ref) async => null),
        stampsStreamProvider.overrideWith((ref) => Stream.value(data)),
        hasTestsProvider.overrideWith((ref) async => true),
        // Keep the production availableStampsProvider so the summary and export
        // exercise the same real filtering logic, with no backend dependencies.
        inRangeProvider.overrideWith((ref) async => data),
        graphStampsProvider.overrideWith((ref) async => {}),
        reviewPaths.overrideWith((ref, args) async => []),
        reviewPathsByTypeProvider.overrideWith((ref) async => {}),
        hasAvailableFiltersProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp(
        theme: (darkMode ? dark : light).copyWith(
          platform: TargetPlatform.iOS,
          // Use the bundled audit font in both themes; the widget-test default
          // for an unloaded system font is Ahem, which changes label widths.
          textTheme: (darkMode ? dark : light).textTheme.apply(
            fontFamily: 'Inter',
          ),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('STRiPES')),
          bottomNavigationBar: const SmallLayout(selected: TabOption.history),
          body: visible == null
              ? const EventsView()
              : ValueListenableBuilder<bool>(
                  valueListenable: visible,
                  builder: (context, show, _) =>
                      show ? const EventsView() : const SizedBox(),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(EventsView)));
}

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

Finder _viewChoice(String label) => find.byKey(
  ValueKey('history-presentation-${label == 'List' ? 'events' : 'graph'}'),
);

Finder _exportButton() => find.descendant(
  of: find.byKey(_controlsKey),
  matching: find.widgetWithText(TextButton, 'Export'),
);

Future<void> _showPresentationControls(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final scroll = container.read(historyScrollControllerProvider);
  for (
    var attempt = 0;
    find.byKey(_controlsKey).evaluate().isEmpty && attempt < 10;
    attempt++
  ) {
    scroll.jumpTo(
      (scroll.offset + scroll.position.viewportDimension / 2).clamp(
        0,
        scroll.position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.byKey(_controlsKey));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAuditFonts();
  });

  for (final width in [390.0, 1200.0]) {
    testWidgets('beta history separates scope and presentation at ${width}px', (
      tester,
    ) async {
      await _pumpOverview(tester, width: width);
      final date = find.byType(DateRangeButton);
      final summary = find.byKey(_summaryKey);
      final controls = find.byKey(_controlsKey);
      expect(date, findsOneWidget);
      expect(summary, findsOneWidget);
      expect(controls, findsOneWidget);
      expect(
        tester.getRect(date).bottom,
        lessThanOrEqualTo(tester.getRect(summary).top),
      );
      expect(
        tester.getRect(summary).bottom,
        lessThanOrEqualTo(tester.getRect(controls).top),
      );
      expect(find.byTooltip('History view: List'), findsNothing);
      expect(_viewChoice('List'), findsOneWidget);
      expect(_viewChoice('Graph'), findsOneWidget);
      expect(
        find.descendant(of: controls, matching: find.byType(Export)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, 'overview-${width.toInt()}px');
    });
  }

  testWidgets('summary counts recordings instead of nested prompt answers', (
    tester,
  ) async {
    await _pumpOverview(tester);
    expect(find.text('3 entries across 2 days'), findsOneWidget);
    final summary = find.byKey(_summaryKey);
    expect(
      find.descendant(of: summary, matching: find.textContaining('Pain 2')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.textContaining('Sleep & Mood 1'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('5 entries'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('view switching preserves dates, filters, and the summary', (
    tester,
  ) async {
    final container = await _pumpOverview(
      tester,
      filters: [_categoryFilter('Pain')],
    );
    final initialSettings = container.read(displayDataProvider);
    expect(find.text('2 entries across 1 day'), findsOneWidget);
    await tester.tap(_viewChoice('Graph'));
    await tester.pumpAndSettle();
    expect(container.read(viewModeProvider), ViewMode.graph);
    expect(container.read(displayDataProvider), initialSettings);
    expect(find.text('2 entries across 1 day'), findsOneWidget);
    expect(
      tester.widget<Semantics>(_viewChoice('Graph')).properties.selected,
      isTrue,
    );
    expect(_exportButton(), findsOneWidget);
    await tester.tap(_viewChoice('List'));
    await tester.pumpAndSettle();
    expect(container.read(viewModeProvider), ViewMode.events);
    expect(container.read(displayDataProvider), initialSettings);
    expect(
      tester.widget<Semantics>(_viewChoice('List')).properties.selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary and day grouping honor an approximate saved date', (
    tester,
  ) async {
    // The stored timestamp can land on the preceding day in a viewing zone;
    // date-only recordings must retain the calendar date the user chose.
    final storedDate = DateTime(2024, 9, 22, 21);
    final approximate = TimedDetailResponse(
      response: DetailResponse(
        id: 'unknown-time',
        detailType: 'Pain',
        stamp: dateToStamp(storedDate),
        responses: const [],
      ),
      entry: Entry(
        id: 'unknown-time',
        subUserId: 'sam',
        stamp: storedDate,
        entityType: InputCategory.event.name,
        timeOfDay: TimeOfDayEntry.notSure,
        data: const {
          recordTimeField: {'localDate': '2024-09-23'},
        },
      ),
    );
    await _pumpOverview(tester, records: [_records().first, approximate]);
    expect(find.text('2 entries across 1 day'), findsOneWidget);
    final dayHeaders = tester
        .widgetList<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
        .map((header) => header.delegate)
        .whereType<DateHeaderDelegate>()
        .toList();
    expect(dayHeaders, hasLength(1));
    expect(dayHeaders.single.date, DateTime(2024, 9, 23));
    expect(dayHeaders.single.eventCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content export receives the selected subset of recordings', (
    tester,
  ) async {
    final records = _records();
    await _pumpOverview(
      tester,
      records: records,
      filters: [_categoryFilter('Sleep & Mood')],
    );
    expect(find.text('1 entry across 1 day'), findsOneWidget);
    expect(tester.widget<TextButton>(_exportButton()).onPressed, isNotNull);
    await tester.tap(_exportButton());
    await tester.pumpAndSettle();
    final sheet = tester.widget<ExportOptionsSheet>(
      find.byType(ExportOptionsSheet),
    );
    expect(sheet.responses, [records.last]);
    expect(sheet.responses.single, isA<DetailResponse>());
    expect(tester.takeException(), isNull);
    await _capture(tester, 'export-selected-records');
  });

  testWidgets(
    'content export remains disabled when embedding export is absent',
    (tester) async {
      await _pumpOverview(tester, exportEnabled: false);
      expect(tester.widget<TextButton>(_exportButton()).onPressed, isNull);
      expect(find.byType(ExportOptionsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('export options and close remain reachable at 320px and 3x', (
    tester,
  ) async {
    final container = await _pumpOverview(tester, width: 320, textScale: 3);
    await _showPresentationControls(tester, container);
    await tester.ensureVisible(_exportButton());
    await tester.tap(_exportButton());
    await tester.pumpAndSettle();
    final sheet = find.byType(ExportOptionsSheet);
    expect(sheet, findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'export-320px-3.0x-top');
    for (final label in ['CSV Export', 'Summary Report']) {
      final option = find.descendant(of: sheet, matching: find.text(label));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      expect(option.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await _capture(tester, 'export-320px-3.0x-options');
    final close = find.descendant(
      of: sheet,
      matching: find.widgetWithIcon(IconButton, Icons.close),
    );
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    expect(close.hitTestable(), findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final betaUi in [false, true]) {
    testWidgets('overview off retains legacy History controls; beta $betaUi', (
      tester,
    ) async {
      await _pumpOverview(tester, betaUi: betaUi, overviewEnabled: false);
      expect(find.byKey(_summaryKey), findsNothing);
      expect(find.byKey(_controlsKey), findsNothing);
      expect(find.byTooltip('History view: List'), findsOneWidget);
      expect(find.byType(EventGridHeader), findsOneWidget);
      expect(_viewChoice('List'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('overview remains useful when graphing is unavailable', (
    tester,
  ) async {
    await _pumpOverview(tester, hasGraphing: false);
    expect(find.text('3 entries across 2 days'), findsOneWidget);
    expect(_viewChoice('Graph'), findsNothing);
    expect(_exportButton(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('beta overview preserves History position when returning', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final records = [
      for (var i = 0; i < 30; i++)
        NumericResponse(
          id: 'scroll-record-$i',
          question: const Numeric(
            id: 'intensity',
            prompt: 'Intensity',
            type: 'Pain',
          ),
          response: i % 10,
          stamp: dateToStamp(DateTime(2024, 9, 23 - i ~/ 10, 18, 30 - i % 10)),
        ),
    ];
    final container = await _pumpOverview(
      tester,
      records: records,
      visible: visible,
    );
    expect(find.text('30 entries across 3 days'), findsOneWidget);
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(700);
    await tester.pumpAndSettle();
    scroll.jumpTo(620);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-floating-date')), findsOneWidget);
    final position = scroll.offset;
    visible.value = false;
    await tester.pumpAndSettle();
    expect(scroll.hasClients, isFalse);
    visible.value = true;
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(position, 0.01));
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.byKey(_controlsKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 3.0]) {
    testWidgets('overview controls remain readable at 320px and ${scale}x', (
      tester,
    ) async {
      final container = await _pumpOverview(
        tester,
        width: 320,
        textScale: scale,
      );
      expect(find.text('3 entries across 2 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'overview-320px-${scale}x-top');
      await _showPresentationControls(tester, container);
      for (final label in ['List', 'Graph']) {
        final choice = _viewChoice(label);
        expect(choice, findsOneWidget);
        final bounds = tester.getRect(choice);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(320));
        expect(bounds.height, greaterThanOrEqualTo(48));
      }
      expect(_exportButton(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'overview-320px-${scale}x-controls');
      await tester.ensureVisible(_viewChoice('Graph'));
      await tester.tap(_viewChoice('Graph'));
      await tester.pumpAndSettle();
      expect(container.read(viewModeProvider), ViewMode.graph);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'presentation switch exposes selection and supports the keyboard',
    (tester) async {
      final handle = tester.ensureSemantics();
      final container = await _pumpOverview(tester);
      expect(
        tester.getSemantics(_viewChoice('List')).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      final graphButton = find.descendant(
        of: _viewChoice('Graph'),
        matching: find.byType(TextButton),
      );
      final focus = Focus.of(
        tester.element(
          find.descendant(of: graphButton, matching: find.text('Graph')),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(container.read(viewModeProvider), ViewMode.graph);
      expect(
        tester.getSemantics(_viewChoice('Graph')).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_viewChoice('List')).flagsCollection.isSelected,
        ui.Tristate.isFalse,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('presentation switch respects reduced motion', (tester) async {
    final container = await _pumpOverview(tester, reducedMotion: true);
    final indicator = find.byKey(
      const ValueKey('history-presentation-indicator'),
    );
    expect(tester.widget<AnimatedAlign>(indicator).duration, Duration.zero);
    await tester.tap(_viewChoice('Graph'));
    await tester.pump();
    expect(container.read(viewModeProvider), ViewMode.graph);
    expect(
      tester.widget<AnimatedAlign>(indicator).alignment,
      AlignmentDirectional.centerEnd,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentation switch and export remain distinct in dark mode', (
    tester,
  ) async {
    await _pumpOverview(tester, darkMode: true);
    final switcher = find.byKey(const ValueKey('history-presentation-switch'));
    final bounds = tester.getRect(switcher);
    final exportBounds = tester.getRect(_exportButton());
    expect(
      bounds.right < exportBounds.left || bounds.bottom <= exportBounds.top,
      isTrue,
    );
    await _capture(tester, 'overview-dark-390px');
    expect(tester.takeException(), isNull);
  });
}
