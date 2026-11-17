import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/GraphView/chart_entries.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_models.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_preparer.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_view_screen.dart';
import 'package:stripes_ui/UI/History/GraphView/ChartRendering/history_chart.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../accessibility/audit_harness.dart' show loadAuditFonts;

const _captureKey = ValueKey('chart-entry-capture');
Future<void> capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('CHART_ENTRIES_CAPTURE');
  if (directory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    Directory(directory).createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$directory/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

const question = Numeric(
  id: 'pain',
  prompt: 'Pain intensity',
  type: 'Pain',
  min: 0,
  max: 10,
);
const categoryKey = GraphKey(
  title: 'Other measure',
  type: 'Pain',
  qid: 'other',
  isCategory: false,
);
const graphKey = GraphKey(
  title: 'Pain intensity',
  qid: 'pain',
  type: 'Pain',
  isCategory: false,
);
DetailResponse record(String? id, int day) => DetailResponse(
  id: id,
  detailType: 'Pain',
  stamp: dateToStamp(DateTime(2026, 10, day, 9)),
  responses: [
    NumericResponse(
      question: question,
      response: 4,
      stamp: dateToStamp(DateTime(2026, 10, day, 9)),
    ),
  ],
);

class Settings extends DisplayDataProvider {
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(
      TimeCycle.month,
      anchor: DateTime(2026, 10, 14),
    ),
    axis: GraphYAxis.number,
  );
}

Future<void> pump(
  WidgetTester tester,
  List<DetailResponse> entries,
  Widget child, {
  bool beta = true,
  double scale = 1,
}) async {
  await tester.runAsync(loadAuditFonts);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  for (final entry in entries) {
    attachRecordIdentity(entry);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(historyOverview: beta),
          ),
        ),
        displayDataProvider.overrideWith(Settings.new),
        stampsStreamProvider.overrideWith((ref) => Stream.value(entries)),
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
        graphStampsProvider.overrideWith(
          (ref) async => {
            categoryKey: entries.expand((entry) => entry.responses).toList(),
            graphKey: entries.expand((entry) => entry.responses).toList(),
          },
        ),
        reviewPathsByTypeProvider.overrideWith((ref) async => {}),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter', colorSchemeSeed: Colors.blue),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: _captureKey,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('source resolution deduplicates answers and preserves same-time legacy records', () {
    final first = record(null, 5);
    final second = record(null, 5);
    final unrelated = record('other', 6);
    expect(
      chartSourceEntries(
        [first, ...first.responses, ...second.responses],
        [first, second, unrelated],
      ),
      unorderedEquals([first, second]),
    );
    expect(chartSourceEntries(first.responses, [first, second]), [first]);
    expect(chartSourceEntries(first.responses, [second]), isEmpty);
  });

  test('a single stacked series retains its measure title', () {
    final entry = record('one', 5);
    final graph = GraphPreparer.prepare(
      responses: {graphKey: entry.responses},
      settings: Settings().build(),
      comparison: GraphComparison.stacked,
      colorResolver: (_) => Colors.blue,
    );
    expect(graph.lanes.single.label, 'Pain intensity');
  });

  for (final beta in [false, true]) {
    testWidgets('full chart defaults and source section honor beta $beta', (
      tester,
    ) async {
      await pump(
        tester,
        [record('one', 5)],
        const GraphViewScreen(
          graphKey: graphKey,
          initialAdditions: [categoryKey],
        ),
        beta: beta,
      );
      final chart = tester.widget<HistoryChart>(
        find.byType(HistoryChart).first,
      );
      expect(
        chart.graph.query.comparison,
        beta ? GraphComparison.separate : GraphComparison.stacked,
      );
      expect(find.byType(ChartEntries), beta ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
      if (beta) {
        await capture(tester, 'comparison');
        await tester.ensureVisible(find.text('Entries behind this chart'));
        await tester.pumpAndSettle();
        await capture(tester, 'comparison-entries');
      }
    });
  }

  for (final scale in [1.0, 3.0]) {
    testWidgets('selection and all entries preserve context at ${scale}x', (
      tester,
    ) async {
      final entries = [for (var i = 5; i < 9; i++) record('$i', i)];
      final selection = GraphSelectionController();
      addTearDown(selection.dispose);
      await pump(
        tester,
        entries,
        SingleChildScrollView(
          child: ChartEntries(
            keysForGraph: const [graphKey],
            selectionController: selection,
          ),
        ),
        scale: scale,
      );
      expect(find.byType(EntryDisplay), findsNWidgets(3));
      await capture(tester, 'entries-${scale}x');
      await tester.ensureVisible(find.text('View all 4'));
      await tester.tap(find.text('View all 4'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(selection.value.isEmpty, isTrue);
      final graph = GraphPreparer.prepare(
        responses: {graphKey: entries.expand((e) => e.responses).toList()},
        settings: Settings().build(),
        comparison: GraphComparison.separate,
        colorResolver: (_) => Colors.blue,
      );
      final series = graph.series.first;
      final datum = series.data.firstWhere((d) => d.evidence.isNotEmpty);
      selection.select(
        bin: datum.bin,
        items: [GraphSelectionItem(series: series, datum: datum)],
      );
      await tester.pumpAndSettle();
      expect(find.text('Entries in this selection'), findsOneWidget);
      expect(find.byType(EntryDisplay), findsOneWidget);
      selection.clear();
      await tester.pumpAndSettle();
      expect(find.byType(EntryDisplay), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }
}
