import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Insights/insights.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/CommonWidgets/control_bar.dart';
import 'package:stripes_ui/UI/History/EventView/date_header.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../../accessibility/audit_harness.dart';

class _DisplayData extends DisplayDataProvider {
  final bool grouped;
  _DisplayData({this.grouped = false});

  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.month, anchor: DateTime(2024, 9)),
    axis: GraphYAxis.number,
    groupSymptoms: grouped,
  );
}

class _Profile extends SubNotifier {
  @override
  SubState build() {
    final user = SubUser(
      name: 'Sam',
      gender: '',
      birthYear: 2000,
      isControl: false,
      id: 'sam',
    );
    return SubState(subUsers: [user], selected: user);
  }
}

Future<ProviderContainer> _pumpHistory(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ValueNotifier<double>? liveTextScale,
  bool grouped = false,
  TargetPlatform? platform,
  ValueNotifier<bool>? visible,
  bool insightsEnabled = false,
  void Function()? onFindingsLoad,
  bool betaUi = true,
  bool historyOverview = false,
  bool hasGraphing = true,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final entries = [
    for (var i = 0; i < 30; i++)
      NumericResponse(
        id: 'entry-$i',
        question: Numeric(
          id: 'q-$i',
          prompt: 'Duration',
          type: i == 0 ? 'Bowel Movement' : 'Entry $i',
        ),
        stamp: dateToStamp(DateTime(2024, 9, 23 - i ~/ 10, 18, 30 - i % 10)),
        response: 10 + i,
      ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayDataProvider.overrideWith(() => _DisplayData(grouped: grouped)),
        configProvider.overrideWith(
          (ref) => StripesConfig(
            profileType: ProfileType.username,
            hasLogging: true,
            allowsSummaryReport: true,
            betaUi: betaUi
                ? BetaUiConfig.enabled(
                    hasGraphing: hasGraphing,
                    historyOverview: historyOverview,
                  )
                : BetaUiConfig.disabled(hasGraphing: hasGraphing),
            display: StripesDisplayConfig(insightsEnabled: insightsEnabled),
          ),
        ),
        subHolderProvider.overrideWith(_Profile.new),
        authStream.overrideWith((ref) => Stream.value(const AuthUser.empty())),
        stampProvider.overrideWith((ref) async => null),
        hasTestsProvider.overrideWith((ref) async => true),
        availableStampsProvider.overrideWith((ref) async => entries),
        graphStampsProvider.overrideWith((ref) async => {}),
        inRangeProvider.overrideWith(
          (ref) async => [
            for (final response in entries)
              DetailResponse(
                description: null,
                responses: [response],
                stamp: response.stamp,
                detailType: response.type,
              ),
          ],
        ),
        reviewPaths.overrideWith((ref, arg) async => []),
        hasAvailableFiltersProvider.overrideWith((ref) async => true),
        historyFindingsProvider.overrideWith((ref) async {
          onFindingsLoad?.call();
          return FindingFeed(
            run: runFindingsFromResponses(
              responses: [],
              windows: findingWindowsForHistoryRange(
                DateTimeRange(
                  start: DateTime(2024, 9),
                  end: DateTime(2024, 10),
                ),
              ),
              catalog: const InsightAnalysisCatalog.empty(),
              rules: [],
            ),
            ranked: [],
          );
        }),
      ],
      child: MaterialApp(
        theme: platform == null ? light : light.copyWith(platform: platform),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          Widget scaled(double scale) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
          return liveTextScale == null
              ? scaled(textScale)
              : ValueListenableBuilder(
                  valueListenable: liveTextScale,
                  builder: (context, scale, _) => scaled(scale),
                );
        },
        home: RepaintBoundary(
          key: const ValueKey('preview'),
          // Use the shared shell's geometry without starting Rive's native
          // logo renderer; these tests exercise History's scroll interactions.
          child: Scaffold(
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
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(EventsView)));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAuditFonts();
  });

  testWidgets('history loads insights only when enabled', (tester) async {
    var loads = 0;
    await _pumpHistory(tester, onFindingsLoad: () => loads++);
    expect(loads, 0);
    await tester.pumpWidget(const SizedBox());
    await _pumpHistory(
      tester,
      insightsEnabled: true,
      onFindingsLoad: () => loads++,
    );
    expect(loads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy History keeps cards instead of compact rows', (
    tester,
  ) async {
    await _pumpHistory(tester, width: 375, textScale: 1.5, betaUi: false);
    expect(find.byKey(const ValueKey('compact-entry-surface')), findsNothing);
    expect(find.byType(EntryDisplay), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('graphing can be enabled separately from the redesign', (
    tester,
  ) async {
    await _pumpHistory(tester, betaUi: false, hasGraphing: false);
    expect(find.text('List'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await _pumpHistory(tester, betaUi: false, hasGraphing: true);
    expect(find.text('List'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'date navigation floats within thumb reach and only pinned headings have dividers',
    (tester) async {
      final container = await _pumpHistory(tester);
      final appBar = find.byType(AppBar);
      final headers = find.byWidgetPredicate(
        (widget) =>
            widget is SliverPersistentHeader &&
            widget.delegate is DateHeaderDelegate,
      );

      void expectDateDividers({required bool hasPinnedHeader}) {
        var pinnedCount = 0;
        for (final header in headers.evaluate()) {
          final headerFinder = find.byWidget(header.widget);
          final bounds = tester.getRect(
            find
                .descendant(of: headerFinder, matching: find.byType(ClipRect))
                .first,
          );
          final isPinned =
              (bounds.top - tester.getRect(appBar).bottom).abs() < 2;
          final surface = tester.widget<Container>(
            find
                .descendant(of: headerFinder, matching: find.byType(Container))
                .first,
          );
          final border =
              (surface.decoration! as BoxDecoration).border as Border?;
          if (isPinned) {
            pinnedCount++;
            expect(border, isNotNull);
            expect(border!.bottom.color.a, 1);
            expect(border.bottom.width, greaterThan(0));
          } else {
            expect(border, isNull);
          }
        }
        expect(pinnedCount, hasPinnedHeader ? 1 : 0);
      }

      expectDateDividers(hasPinnedHeader: false);
      expect(find.text("Sam's History"), findsOneWidget);
      final scroll = container.read(historyScrollControllerProvider);
      final floatingDate = find.byKey(const ValueKey('history-floating-date'));
      expect(floatingDate, findsNothing);
      scroll.jumpTo(700);
      await tester.pumpAndSettle();
      expect(floatingDate, findsNothing);
      scroll.jumpTo(620);
      await tester.pumpAndSettle();
      expect(floatingDate, findsOneWidget);
      expect(tester.getRect(floatingDate).top, greaterThan(600));
      expect(
        tester.getRect(floatingDate).bottom,
        closeTo(tester.getRect(find.byType(SmallLayout)).top, 0.01),
      );

      expectDateDividers(hasPinnedHeader: true);
      scroll.jumpTo(750);
      await tester.pumpAndSettle();
      expect(floatingDate, findsNothing);
      scroll.jumpTo(650);
      await tester.pumpAndSettle();
      expect(floatingDate, findsOneWidget);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expectDateDividers(hasPinnedHeader: false);
      expect(floatingDate, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'floating date animation keeps the scroll viewport and position stable',
    (tester) async {
      final container = await _pumpHistory(
        tester,
        platform: TargetPlatform.iOS,
      );
      final scroll = container.read(historyScrollControllerProvider);
      scroll.jumpTo(700);
      await tester.pumpAndSettle();
      final viewportHeight = scroll.position.viewportDimension;
      for (final target in [620.0, 700.0, 640.0, 720.0]) {
        scroll.jumpTo(target);
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(scroll.position.viewportDimension, viewportHeight);
          expect(scroll.offset, closeTo(target, 0.01));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bottom overscroll rebound does not reopen the date row', (
    tester,
  ) async {
    final container = await _pumpHistory(tester, platform: TargetPlatform.iOS);
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final bottom = scroll.position.maxScrollExtent;
    scroll.jumpTo(bottom - 40);
    await tester.pumpAndSettle();
    expect(container.read(historyCalendarNavVisibleProvider), isTrue);
    final lastEntry = find.ancestor(
      of: find.text('Entry 29'),
      matching: find.byType(EntryDisplay),
    );
    expect(
      tester.getRect(lastEntry).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('history-floating-date'))).top,
      ),
    );
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -300),
      1200,
    );
    await tester.pumpAndSettle();
    expect(container.read(historyCalendarNavVisibleProvider), isFalse);
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expansion keeps its heading anchored and survives recycling', (
    tester,
  ) async {
    final container = await _pumpHistory(tester);
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(60);
    await tester.pumpAndSettle();
    final heading = find.text('Bowel Movement');
    final initialTop = tester.getTopLeft(heading);
    final offset = scroll.offset;
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(scroll.offset, offset);
    expect(tester.getTopLeft(heading), initialTop);
    final entry = find.ancestor(
      of: heading,
      matching: find.byType(EntryDisplay),
    );
    expect(
      tester.state<EntryDisplayState>(entry).controller.isExpanded,
      isTrue,
    );
    final rotation = tester.widget<RotationTransition>(
      find.descendant(of: entry, matching: find.byType(RotationTransition)),
    );
    expect(rotation.turns.value, 0.5);
    expect(find.text('Delete'), findsNothing);
    // The chevron is the last header element; actions live in the body.
    final chevron = find.descendant(
      of: entry,
      matching: find.byType(RotationTransition),
    );
    final headerRow = find
        .ancestor(of: chevron, matching: find.byType(Row))
        .first;
    expect(
      tester.widget<Row>(headerRow).children.last,
      isA<RotationTransition>(),
    );

    scroll.jumpTo(1600);
    await tester.pumpAndSettle();
    expect(heading, findsNothing);
    scroll.jumpTo(offset);
    await tester.pumpAndSettle();
    expect(
      tester.state<EntryDisplayState>(entry).controller.isExpanded,
      isTrue,
    );
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(heading), initialTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating date navigation stays within reach when switching months',
    (tester) async {
      final container = await _pumpHistory(tester);
      final scroll = container.read(historyScrollControllerProvider);
      scroll.jumpTo(700);
      await tester.pumpAndSettle();
      scroll.jumpTo(600);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('history-floating-date')),
          matching: find.byTooltip('Previous'),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, 600);
      expect(
        container.read(displayDataProvider).range.start,
        DateTime(2024, 8),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('history-floating-date')),
          matching: find.text('Aug 2024'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('history-floating-date')),
          matching: find.byTooltip('Previous'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('history-floating-date')),
          matching: find.text('Jul 2024'),
        ),
        findsOneWidget,
      );
      expect(scroll.offset, 600);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('returning to History restores scroll and expansion', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final container = await _pumpHistory(tester, visible: visible);
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(150);
    await tester.pumpAndSettle();
    final heading = find.text('Entry 2');
    await tester.tap(heading);
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    visible.value = false;
    await tester.pumpAndSettle();
    expect(scroll.hasClients, isFalse);
    visible.value = true;
    await tester.pumpAndSettle();
    expect(scroll.offset, offset);
    final entry = find.ancestor(
      of: heading,
      matching: find.byType(EntryDisplay),
    );
    expect(
      tester.state<EntryDisplayState>(entry).controller.isExpanded,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct delete button retains confirmation', (tester) async {
    await _pumpHistory(tester);
    expect(find.byTooltip('Delete'), findsNothing);
    await tester.tap(find.text('Bowel Movement'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.byType(DeleteErrorPrevention), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('filter badge stays with history controls at ${width}px', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pumpHistory(tester, width: width);
      final toolbar = find.byType(ControlBar);
      final initialHeight = tester.getSize(toolbar).height;
      expect(find.byTooltip('Filters'), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      container.read(displayDataProvider.notifier).updateFilters([
        LabeledFilter(
          name: 'Bowel Movement',
          filterType: FilterType.category,
          filter: (_) => true,
        ),
        LabeledFilter(
          name: 'Entry 1',
          filterType: FilterType.category,
          filter: (_) => true,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNothing);
      expect(tester.getSize(toolbar).height, initialHeight);
      expect(find.byTooltip('Filters (2 active)'), findsOneWidget);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isTrue);
      expect((badge.label! as Text).data, '2');
      final button = find.byTooltip('Filters (2 active)');
      final historyView = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'History view',
      );
      final timeRange = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Time range',
      );
      expect(tester.getCenter(button).dy, tester.getCenter(historyView).dy);
      expect(tester.getCenter(button).dy, tester.getCenter(timeRange).dy);
      expect(
        tester.getRect(button).right,
        lessThan(tester.getRect(timeRange).left),
      );
      expect(
        tester.getRect(timeRange).right,
        lessThan(tester.getRect(historyView).left),
      );
      expect(
        find.descendant(of: toolbar, matching: button),
        width >= 1200 ? findsOneWidget : findsNothing,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(FilterSheet), findsOneWidget);
      expect(
        find.byType(Dialog),
        width >= 1200 ? findsOneWidget : findsNothing,
      );
      expect(find.widgetWithText(ChoiceChip, 'Bowel Movement'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(container.read(displayDataProvider).filters, isEmpty);
      expect(find.byType(FilterSheet), findsNothing);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets(
    'large-text filter badge reserves space without squeezing the date',
    (tester) async {
      final container = await _pumpHistory(tester, width: 320, textScale: 3);
      container.read(displayDataProvider.notifier).updateFilters([
        LabeledFilter(
          name: 'Bowel Movement',
          filterType: FilterType.category,
          filter: (_) => true,
        ),
        LabeledFilter(
          name: 'Entry 1',
          filterType: FilterType.category,
          filter: (_) => true,
        ),
      ]);
      await tester.pumpAndSettle();
      final badge = tester.getRect(find.byType(Badge));
      final icon = tester.getRect(find.byIcon(Icons.filter_list));
      final date = tester.getRect(find.byTooltip('Previous'));
      expect(badge.left, greaterThanOrEqualTo(icon.right));
      expect(badge.right, lessThanOrEqualTo(320));
      expect(badge.bottom, lessThan(date.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history dropdown labels collapse together and restore without resetting selections',
    (tester) async {
      final textScale = ValueNotifier(1.0);
      addTearDown(textScale.dispose);
      final container = await _pumpHistory(
        tester,
        width: 390,
        liveTextScale: textScale,
      );
      expect(find.byType(SegmentedButton<TimeCycle>), findsNothing);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);

      textScale.value = 3;
      await tester.pumpAndSettle();
      final timeRange = find.byTooltip('Time range: Month');
      final historyView = find.byTooltip('History view: List');
      final filter = find.byTooltip('Filters');
      expect(timeRange.hitTestable(), findsOneWidget);
      expect(historyView.hitTestable(), findsOneWidget);
      expect(find.text('Month'), findsNothing);
      expect(find.text('List'), findsNothing);
      expect(tester.getCenter(filter).dy, tester.getCenter(timeRange).dy);
      expect(tester.getCenter(filter).dy, tester.getCenter(historyView).dy);
      for (final control in [filter, timeRange, historyView]) {
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }
      final semantics = tester.ensureSemantics();
      await tester.pump();
      final timeRangeSemantics = tester.getSemantics(
        find.bySemanticsLabel('Time range'),
      );
      expect(timeRangeSemantics.value, 'Month');
      semantics.dispose();

      await tester.tap(timeRange);
      await tester.pumpAndSettle();
      final week = find.widgetWithText(ListTile, 'Week');
      await tester.ensureVisible(week);
      await tester.tap(week);
      await tester.pumpAndSettle();
      expect(container.read(displayDataProvider).cycle, TimeCycle.week);
      expect(find.byTooltip('Time range: Week'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_week), findsOneWidget);

      await tester.tap(historyView);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Graph'));
      await tester.pumpAndSettle();
      expect(container.read(viewModeProvider), ViewMode.graph);
      expect(find.byTooltip('History view: Graph'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byTooltip('History view: Graph'),
          matching: find.byIcon(Icons.bar_chart),
        ),
        findsOneWidget,
      );

      // Widening the available space restores labels even at larger text.
      tester.view.physicalSize = const Size(1200, 844);
      await tester.pumpAndSettle();
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Graph'), findsOneWidget);
      expect(container.read(displayDataProvider).cycle, TimeCycle.week);
      expect(container.read(viewModeProvider), ViewMode.graph);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [700.0, 1500.0]) {
    testWidgets(
      'desktop history uses dropdowns for range, view, and graph measure at $width',
      (tester) async {
        final container = await _pumpHistory(tester, width: width);
        expect(find.byType(SegmentedButton<TimeCycle>), findsNothing);
        expect(find.byTooltip('Time range: Month'), findsOneWidget);
        await tester.tap(find.byTooltip('History view: List'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Graph'));
        await tester.pumpAndSettle();
        expect(find.byType(SegmentedButton<GraphYAxis>), findsNothing);
        final measure = find.byTooltip(
          'Graph measure: ${GraphYAxis.number.label}',
        );
        expect(measure, findsOneWidget);
        await tester.tap(measure);
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(ListTile, GraphYAxis.average.label),
        );
        await tester.pumpAndSettle();
        expect(container.read(displayDataProvider).axis, GraphYAxis.average);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('narrow screen with large text fits history controls', (
    tester,
  ) async {
    final container = await _pumpHistory(tester, width: 320, textScale: 1.6);

    expect(find.byTooltip('Previous'), findsOneWidget);
    expect(find.byTooltip('Filters'), findsOneWidget);
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(700);
    await tester.pumpAndSettle();
    scroll.jumpTo(620);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-floating-date')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mini keeps cards at normal text and adapts live without losing expansion',
    (tester) async {
      final scale = ValueNotifier(1.0);
      addTearDown(scale.dispose);
      await _pumpHistory(tester, width: 375, liveTextScale: scale);
      final heading = find.text('Bowel Movement');
      final entry = find.ancestor(
        of: heading,
        matching: find.byType(EntryDisplay),
      );
      final expander = find.descendant(
        of: entry,
        matching: find.byType(Expansible),
      );
      final boundary = find.descendant(
        of: entry,
        matching: find.byKey(const ValueKey('compact-entry-surface')),
      );
      BoxDecoration card() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: expander,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(boundary, findsNothing);
      expect(card().border, isNotNull);
      await tester.tap(heading);
      await tester.pumpAndSettle();
      final state = tester.state<EntryDisplayState>(entry);
      for (final (width, factor, compact) in [
        (375.0, 1.5, true),
        (650.0, 1.5, false),
        (375.0, 2.0, true),
        (375.0, 1.0, false),
      ]) {
        tester.view.physicalSize = Size(width, 844);
        scale.value = factor;
        await tester.pumpAndSettle();
        expect(state.controller.isExpanded, isTrue);
        expect(boundary, compact ? findsOneWidget : findsNothing);
        final arrow = find.descendant(
          of: entry,
          matching: find.byType(RotationTransition),
        );
        final header = find
            .descendant(of: entry, matching: find.byType(InkWell))
            .first;
        expect(
          tester.getCenter(arrow).dy,
          closeTo(tester.getCenter(header).dy, 0.1),
        );
      }
      expect(card().border, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact symptom groups expand with an arrow', (tester) async {
    final container = await _pumpHistory(
      tester,
      width: 320,
      textScale: 3,
      grouped: true,
    );
    final scroll = container.read(historyScrollControllerProvider);
    scroll.jumpTo(300);
    await tester.pumpAndSettle();
    final group = find.byType(ExpandibleSymptomArea).first;
    await tester.ensureVisible(group);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: group, matching: find.byType(DecoratedBox)),
      findsNothing,
    );
    await tester.tap(
      find.descendant(of: group, matching: find.byIcon(Icons.expand_more)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: group, matching: find.byType(EntryDisplay)),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: group, matching: find.byIcon(Icons.expand_less)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: group, matching: find.byType(EntryDisplay)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('plain history rows stay usable at $width and 3x text', (
      tester,
    ) async {
      final container = await _pumpHistory(tester, width: width, textScale: 3);
      final scroll = container.read(historyScrollControllerProvider);
      scroll.jumpTo(300);
      await tester.pumpAndSettle();
      final heading = find.text('Bowel Movement');
      final entry = find.ancestor(
        of: heading,
        matching: find.byType(EntryDisplay),
      );
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      final expander = find.descendant(
        of: entry,
        matching: find.byType(Expansible),
      );
      final surface = tester.widget<DecoratedBox>(
        find.ancestor(of: expander, matching: find.byType(DecoratedBox)).first,
      );
      expect((surface.decoration as BoxDecoration).border, isNull);
      expect(tester.getRect(heading).left, 20);
      final chevron = find.descendant(
        of: entry,
        matching: find.byIcon(Icons.keyboard_arrow_down),
      );
      expect(tester.getSize(chevron).width, greaterThan(24));
      await tester.tap(chevron);
      await tester.pumpAndSettle();
      expect(
        tester.state<EntryDisplayState>(entry).controller.isExpanded,
        isTrue,
      );
      final boundary = find.descendant(
        of: entry,
        matching: find.byKey(const ValueKey('compact-entry-surface')),
      );
      final decoration =
          tester.widget<DecoratedBox>(boundary).decoration as BoxDecoration;
      expect(decoration.border, isNull);
      expect(
        decoration.color,
        Theme.of(tester.element(entry)).colorScheme.surfaceContainerLow,
      );
      expect(tester.getRect(boundary).left, 0);
      expect(tester.getRect(boundary).right, width);
      final controls = find.descendant(
        of: entry,
        matching: find.byKey(const ValueKey('entry-controls')),
      );
      expect(
        find.descendant(of: controls, matching: find.byTooltip('Delete')),
        findsOneWidget,
      );
      expect(
        tester.getRect(controls).bottom,
        lessThan(tester.getRect(boundary).bottom),
      );
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      final header = find
          .descendant(of: entry, matching: find.byType(InkWell))
          .first;
      expect(
        tester.getCenter(chevron).dy,
        closeTo(tester.getCenter(header).dy, 0.1),
      );

      final headers = find.byWidgetPredicate(
        (widget) =>
            widget is SliverPersistentHeader &&
            widget.delegate is DateHeaderDelegate,
      );
      for (final header in headers.evaluate()) {
        final text = find.descendant(
          of: find.byWidget(header.widget),
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        final bounds = tester.getRect(
          find
              .descendant(
                of: find.byWidget(header.widget),
                matching: find.byType(ClipRect),
              )
              .first,
        );
        expect(tester.getRect(text).bottom, lessThanOrEqualTo(bounds.bottom));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
