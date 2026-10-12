import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../accessibility/audit_harness.dart';

class _GraphSettings extends DisplayDataProvider {
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.week, anchor: DateTime(2026, 10, 7)),
    axis: GraphYAxis.number,
  );
}

const _category = GraphKey(
  title: 'Meal Time',
  type: 'Meal Time',
  isCategory: true,
);
const _questionKey = GraphKey(
  title: 'What meal type did you have?',
  type: 'Meal Time',
  qid: 'meal-type',
  isCategory: false,
);
const _question = MultipleChoice(
  id: 'meal-type',
  prompt: 'What meal type did you have?',
  type: 'Meal Time',
  choices: ['Breakfast', 'Lunch', 'Dinner'],
);
const _captureKey = ValueKey('history-graph-capture');

Future<void> _capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('HISTORY_GRAPH_CAPTURE_DIR');
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

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAuditFonts();
  });

  for (final scale in [1.0, 3.0]) {
    testWidgets('graph overview wraps at 320px and ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final answers = [
        for (var i = 0; i < 3; i++)
          MultiResponse(
            id: 'answer-$i',
            question: _question,
            stamp: dateToStamp(DateTime(2026, 10, 6 + i, 12)),
            index: i,
          ),
      ];
      final records = [
        for (var i = 0; i < 2; i++)
          DetailResponse(
            id: 'record-$i',
            detailType: 'Meal Time',
            stamp: answers[i].stamp,
            responses: [answers[i]],
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWith((ref) => const StripesConfig.sandbox()),
            displayDataProvider.overrideWith(_GraphSettings.new),
            graphStampsProvider.overrideWith(
              (ref) async => {_category: records, _questionKey: answers},
            ),
            reviewPathsByTypeProvider.overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: _captureKey,
              child: Scaffold(
                body: SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('History'),
                        ),
                      ),
                      const SliverToBoxAdapter(child: GraphHeader()),
                      const SliverToBoxAdapter(child: DateRangeButton()),
                      GraphSliverList(
                        onSelect: (_) {},
                        onCategorySelect: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2 events'), findsOneWidget);
      expect(find.text('3 answers'), findsOneWidget);
      final title = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.textContaining('What meal type did you have?'),
          matching: find.byType(RichText),
        ),
      );
      expect(title.didExceedMaxLines, isFalse);
      final trigger = find.widgetWithText(TextButton, 'Count');
      expect(tester.getSize(trigger).width, lessThan(scale == 1 ? 145 : 230));
      await _capture(tester, 'history-graph-${scale}x');
      if (scale > 1) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
        await _capture(tester, 'history-graph-${scale}x-scrolled');
        await tester.ensureVisible(trigger);
        await tester.pumpAndSettle();
      }
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(find.text('Graph measure'), findsOneWidget);
      expect(find.text('Time of Day'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Time of Day'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Time of Day'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
