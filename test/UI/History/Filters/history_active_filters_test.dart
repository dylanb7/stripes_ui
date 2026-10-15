import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Filters/history_active_filters.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../../accessibility/audit_harness.dart';

const _captureKey = ValueKey('history-active-filters-capture');

Future<void> _capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('HISTORY_FILTER_CAPTURE');
  if (directory.isEmpty) return;
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

class _FilterSettings extends DisplayDataProvider {
  final List<LabeledFilter> filters;
  _FilterSettings(this.filters);

  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.week, anchor: DateTime(2026, 10, 14)),
    filters: filters,
    axis: GraphYAxis.number,
    groupSymptoms: true,
    groupBars: true,
  );
}

LabeledFilter _filter(String name, [FilterType type = FilterType.category]) =>
    LabeledFilter(name: name, filterType: type, filter: (response) => true);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<LabeledFilter> filters = const [],
  bool beta = true,
  double width = 320,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig(
            profileType: ProfileType.username,
            hasLogging: true,
            allowsSummaryReport: true,
            betaUi: beta
                ? const BetaUiConfig.enabled()
                : const BetaUiConfig.disabled(),
          ),
        ),
        displayDataProvider.overrideWith(() => _FilterSettings(filters)),
        inRangeProvider.overrideWith(
          (ref) async => [
            DetailResponse(
              id: 'one',
              detailType: 'Pain',
              stamp: 3,
              responses: const [],
            ),
            DetailResponse(
              id: 'two',
              detailType: 'Sleep & Mood',
              stamp: 2,
              responses: const [],
            ),
            DetailResponse(
              id: 'three',
              detailType: 'Bowel Movement',
              stamp: 1,
              responses: const [],
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: const Scaffold(
          body: SafeArea(child: Column(children: [HistoryActiveFilters()])),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(HistoryActiveFilters)),
  );
}

void main() {
  setUpAll(loadAuditFonts);

  testWidgets('no active filters and beta off add no header space', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('history-active-filters')), findsNothing);
    await _pump(tester, filters: [_filter('Pain')], beta: false);
    expect(find.byKey(const ValueKey('history-active-filters')), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('a narrow row fits whole labels with an overflow count', (
    tester,
  ) async {
    await _pump(
      tester,
      filters: [
        _filter('Pain'),
        _filter('Sleep & Mood'),
        _filter('Bowel Movement'),
      ],
    );
    expect(find.text('Pain'), findsOneWidget);
    expect(find.text('+2 filters'), findsOneWidget);
    expect(find.text('Sleep & Mood'), findsNothing);
    final row = tester.getRect(
      find.byKey(const ValueKey('history-active-filters')),
    );
    expect(row.height, 48);
    for (final button in tester.widgetList<TextButton>(
      find.byType(TextButton),
    )) {
      final rect = tester.getRect(find.byWidget(button));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(row.left));
      expect(rect.right, lessThanOrEqualTo(row.right));
    }
    expect(tester.takeException(), isNull);
    await _capture(tester, 'filters-320px');
  });

  testWidgets('wide layouts cap visible chips at two', (tester) async {
    await _pump(
      tester,
      width: 1200,
      filters: [
        _filter('Pain'),
        _filter('Sleep & Mood'),
        _filter('Bowel Movement'),
      ],
    );
    expect(find.text('Pain'), findsOneWidget);
    expect(find.text('Sleep & Mood'), findsOneWidget);
    expect(find.text('+1 filter'), findsOneWidget);
    expect(find.text('Bowel Movement'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('history-active-filters')))
          .height,
      48,
    );
  });

  testWidgets(
    'removing one chip preserves the other filters and date settings',
    (tester) async {
      final pain = _filter('Pain');
      final morning = _filter('Morning', FilterType.timeOfDay);
      final container = await _pump(tester, filters: [pain, morning]);
      final before = container.read(displayDataProvider);
      await tester.tap(find.byKey(const ValueKey('history-remove-filter-0')));
      await tester.pumpAndSettle();
      final after = container.read(displayDataProvider);
      expect(after.filters, [morning]);
      expect(after.window, before.window);
      expect(after.axis, before.axis);
      expect(after.groupSymptoms, before.groupSymptoms);
      expect(after.groupBars, before.groupBars);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large text summarizes without clipping and opens the editor', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final filters = [
      _filter('Pain'),
      _filter('Sleep & Mood'),
      _filter('Bowel Movement'),
    ];
    await _pump(tester, filters: filters, textScale: 3);
    expect(find.text('3 filters'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-remove-filter-0')), findsNothing);
    expect(
      find.bySemanticsLabel('3 filters: Pain, Sleep & Mood, Bowel Movement'),
      findsOneWidget,
    );
    semantics.dispose();
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    await _capture(tester, 'filters-320px-3x');
    await tester.tap(find.byKey(const ValueKey('history-more-filters')));
    await tester.pumpAndSettle();
    expect(find.byType(FilterSheet), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Time of Day'), findsNothing);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'filter-editor-320px-3x');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.byType(FilterSheet), findsNothing);
  });

  testWidgets('long labels remain available in the summary semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const label = 'A study group with a particularly long | meaningful name';
    await _pump(tester, filters: [_filter(label, FilterType.group)]);
    expect(find.text('1 filter'), findsOneWidget);
    expect(find.bySemanticsLabel('1 filter: Group: $label'), findsOneWidget);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor preserves disabled existing filter types on Apply', (
    tester,
  ) async {
    final saved = _filter(
      'after lunch | before dinner',
      FilterType.description,
    );
    final container = await _pump(
      tester,
      filters: [_filter('Pain'), _filter('Sleep & Mood'), saved],
    );
    await tester.tap(find.byKey(const ValueKey('history-more-filters')));
    await tester.pumpAndSettle();
    expect(
      find.text('Description: after lunch | before dinner'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(container.read(displayDataProvider).filters, contains(saved));
    expect(container.read(displayDataProvider).filters, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text editor can remove a disabled filter without enabling its inputs',
    (tester) async {
      final saved = _filter('Morning', FilterType.timeOfDay);
      final container = await _pump(
        tester,
        textScale: 3,
        filters: [_filter('Pain'), _filter('Sleep & Mood'), saved],
      );
      await tester.tap(find.byKey(const ValueKey('history-more-filters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Time of Day: Morning'));
      await tester.tap(find.text('Time of Day: Morning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        container.read(displayDataProvider).filters,
        isNot(contains(saved)),
      );
      expect(container.read(displayDataProvider).filters, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}
