import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_context_caption.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_symptom.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_hero.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_view_screen.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_with_keys.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../accessibility/audit_harness.dart' show loadAuditFonts;

const _question = Numeric(
  id: 'pain',
  prompt: 'Pain',
  type: 'GI',
  min: 0,
  max: 10,
);
const _key = GraphKey(
  title: 'Pain',
  qid: 'pain',
  type: 'GI',
  isCategory: false,
);

TimedDetailResponse _record(String id, int day, TimeOfDayEntry precision) {
  final date = DateTime(2026, 10, day, 9, 15);
  return TimedDetailResponse(
    response: DetailResponse(
      id: id,
      stamp: dateToStamp(date),
      detailType: 'GI',
      responses: [
        NumericResponse(
          question: _question,
          stamp: dateToStamp(date),
          response: 4,
        ),
      ],
    ),
    entry: Entry(
      id: id,
      subUserId: 'profile',
      stamp: date,
      entityType: InputCategory.event.name,
      timeOfDay: precision,
      data: {
        recordTimeField: {
          'localDate': '2026-10-${day.toString().padLeft(2, '0')}',
          'dayPart': 'morning',
        },
      },
    ),
  );
}

DisplayDataSettings _settings(GraphYAxis axis) => DisplayDataSettings(
  window: TimeWindow(
    range: DateTimeRange(
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 12),
    ),
    cycle: TimeCycle.week,
  ),
  axis: axis,
);

PreparedGraph _graph(GraphYAxis axis) => GraphPreparer.prepare(
  responses: {
    _key: [
      _record('exact-1', 5, TimeOfDayEntry.exact).responses.single,
      _record('exact-2', 7, TimeOfDayEntry.exact).responses.single,
      _record('morning', 8, TimeOfDayEntry.morning).responses.single,
      _record('unknown', 9, TimeOfDayEntry.notSure).responses.single,
    ],
  },
  settings: _settings(axis),
  comparison: GraphComparison.separate,
  colorResolver: (_) => Colors.blue,
);

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(fontFamily: 'Inter', colorSchemeSeed: Colors.blue),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SafeArea(child: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('unknown selections retain their timing and can be cleared', (
    tester,
  ) async {
    final graph = _graph(GraphYAxis.entrytime);
    final series = graph.series.firstWhere(
      (series) =>
          series.data.any((datum) => datum.timing == GraphTiming.unknown),
    );
    final datum = series.data.firstWhere(
      (datum) => datum.timing == GraphTiming.unknown,
    );
    final selection = GraphSelectionController()
      ..select(
        bin: datum.bin,
        items: [GraphSelectionItem(series: series, datum: datum)],
      );
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _app(
        ChartDataPanel(
          selectionController: selection,
          axis: GraphYAxis.entrytime,
        ),
        scale: 3,
      ),
    );
    expect(find.textContaining('Time not known'), findsWidgets);
    expect(find.textContaining('Check-in period'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(selection.value.isEmpty, isTrue);
  });

  testWidgets(
    'caption counts a recording once across category and answer series',
    (tester) async {
      final record = _record('morning', 8, TimeOfDayEntry.morning);
      final graph = GraphPreparer.prepare(
        responses: {
          _key: [record.responses.single],
          const GraphKey(title: 'GI', type: 'GI', isCategory: true): [record],
        },
        settings: _settings(GraphYAxis.entrytime),
        comparison: GraphComparison.separate,
        colorResolver: (_) => Colors.blue,
      );
      await tester.pumpWidget(_app(GraphContextCaption(graph: graph)));
      expect(find.textContaining('1 approximate'), findsOneWidget);
      expect(find.textContaining('2 approximate'), findsNothing);
    },
  );

  testWidgets('a point in a monthly bin identifies its occurrence day', (
    tester,
  ) async {
    final record = _record('exact', 6, TimeOfDayEntry.exact);
    final bin = GraphTimeBin(
      index: 0,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 11, 1),
      label: 'October',
    );
    const id = GraphSeriesId(
      title: 'Pain',
      questionId: 'pain',
      type: 'GI',
      isCategory: false,
      isReview: false,
    );
    final datum = PreparedDatum(
      id: const GraphDatumId(seriesId: id, binIndex: 0),
      bin: bin,
      xStart: DateTime(2026, 10, 6, 12),
      value: 9.25,
      evidence: [record],
    );
    final series = PreparedSeries(
      id: id,
      label: 'Pain',
      color: Colors.blue,
      mark: GraphMark.point,
      data: [datum],
    );
    final selection = GraphSelectionController()
      ..select(
        bin: bin,
        items: [GraphSelectionItem(series: series, datum: datum)],
      );
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _app(
        ChartDataPanel(
          selectionController: selection,
          axis: GraphYAxis.entrytime,
        ),
      ),
    );
    expect(find.text('Oct 6, 2026'), findsOneWidget);
    expect(find.textContaining('Oct 1, 2026'), findsNothing);
  });

  testWidgets('shared chart identifies its metric and full date range', (
    tester,
  ) async {
    final settings = _settings(GraphYAxis.number);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayDataProvider.overrideWith(() => _Settings(settings)),
        ],
        child: _app(
          GraphWithKeys(
            graph: _graph(GraphYAxis.number),
            chartWidget: const SizedBox(height: 100),
            colorKeys: null,
            responses: {
              _key: [
                _record('exact', 5, TimeOfDayEntry.exact).responses.single,
              ],
            },
          ),
          scale: 3,
        ),
      ),
    );
    expect(find.text('Count per day'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared partial-day range includes both time boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Text(
            graphExportRangeLabel(
              context,
              DateTimeRange(
                start: DateTime(2026, 10, 6, 9),
                end: DateTime(2026, 10, 6, 12),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Oct 6, 2026'), findsOneWidget);
    expect(find.textContaining('9:00 AM'), findsOneWidget);
    expect(find.textContaining('12:00 PM'), findsOneWidget);
  });

  testWidgets(
    'multiple count datasets open stacked with context outside Hero',
    (tester) async {
      const otherKey = GraphKey(
        title: 'Other',
        qid: 'other',
        type: 'GI',
        isCategory: false,
      );
      final response = _record(
        'exact',
        5,
        TimeOfDayEntry.exact,
      ).responses.single;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayDataProvider.overrideWith(
              () => _Settings(_settings(GraphYAxis.number)),
            ),
            graphStampsProvider.overrideWith(
              (ref) async => {
                _key: [response],
                otherKey: [response],
              },
            ),
            reviewPathsByTypeProvider.overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: GraphViewScreen(
                graphKey: _key,
                initialAdditions: [otherKey],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<HistoryChart>(
        find.byType(HistoryChart).first,
      );
      expect(chart.graph.query.comparison, GraphComparison.stacked);
      expect(find.byType(GraphContextCaption), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(GraphContextCaption),
          matching: find.byType(Hero),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byType(GraphContextCaption),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected and choice answers have quick-read badges', (
    tester,
  ) async {
    final day = DateTime(2026, 10, 5);
    const check = Check(id: 'check', prompt: 'Difficulty sleeping', type: 'GI');
    const choice = MultipleChoice(
      id: 'meal',
      prompt: 'Meal',
      type: 'GI',
      choices: ['Breakfast', 'Dinner'],
    );
    for (final answer in <Response>[
      Selected(question: check, stamp: dateToStamp(day)),
      MultiResponse(question: choice, index: 0, stamp: dateToStamp(day)),
    ]) {
      final graph = GraphPreparer.prepare(
        responses: {
          _key: [answer],
        },
        settings: _settings(GraphYAxis.number),
        comparison: GraphComparison.separate,
        colorResolver: (_) => Colors.blue,
      );
      final series = graph.series.single;
      final datum = series.data.firstWhere((d) => d.evidence.isNotEmpty);
      final selection = GraphSelectionController()
        ..select(
          bin: datum.bin,
          items: [GraphSelectionItem(series: series, datum: datum)],
        );
      await tester.pumpWidget(
        _app(
          ChartDataPanel(
            selectionController: selection,
            axis: GraphYAxis.number,
          ),
          scale: 3,
        ),
      );
      expect(
        find.text(answer is Selected ? 'Selected' : 'Breakfast · 1'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      selection.dispose();
    }
  });

  testWidgets('export contains chart context but no explanatory caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayDataProvider.overrideWith(
            () => _Settings(_settings(GraphYAxis.number)),
          ),
        ],
        child: _app(
          GraphSymptom(
            responses: {
              _key: [
                _record('exact', 5, TimeOfDayEntry.exact).responses.single,
              ],
            },
            isDetailed: true,
            forExport: true,
          ),
        ),
      ),
    );
    expect(find.byType(GraphContextCaption), findsNothing);
    expect(find.text('Count per day'), findsOneWidget);
    expect(find.byType(HistoryChart), findsOneWidget);
  });

  testWidgets('numeric answers show their value and scale at large text', (
    tester,
  ) async {
    final graph = _graph(GraphYAxis.number);
    final series = graph.series.first;
    final datum = series.data.firstWhere((d) => d.evidence.isNotEmpty);
    final selection = GraphSelectionController()
      ..select(
        bin: datum.bin,
        items: [GraphSelectionItem(series: series, datum: datum)],
      );
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _app(
        ChartDataPanel(selectionController: selection, axis: GraphYAxis.number),
        scale: 3,
      ),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.text('0–10 scale'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart Hero fits every frame on push and pop at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget chart(bool detailed) => Hero(
      tag: 'chart',
      flightShuttleBuilder: graphHeroShuttle,
      child: GraphSymptom(
        responses: {
          _key: [_record('exact', 5, TimeOfDayEntry.exact).responses.single],
        },
        isDetailed: detailed,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayDataProvider.overrideWith(
            () => _Settings(_settings(GraphYAxis.entrytime)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  chart(false),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: SingleChildScrollView(child: chart(true)),
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    final context = tester.element(find.byType(GraphSymptom).last);
    Navigator.of(context).pop();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('mixed timing chart remains usable at ${scale}x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadAuditFonts();
      final graph = _graph(GraphYAxis.entrytime);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pain · Event times',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 22),
                    ),
                    const Text('Oct 5–11, 2026'),
                    HistoryChart(graph: graph),
                    GraphContextCaption(graph: graph),
                  ],
                ),
              ),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('1 approximate'), findsOneWidget);
      const captureDir = String.fromEnvironment('GRAPH_CAPTURE_DIR');
      if (captureDir.isNotEmpty) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        await tester.runAsync(() async {
          await Directory(captureDir).create(recursive: true);
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('$captureDir/timing-${scale}x.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
    });
  }
}

class _Settings extends DisplayDataProvider {
  final DisplayDataSettings settings;
  _Settings(this.settings);
  @override
  DisplayDataSettings build() => settings;
}
