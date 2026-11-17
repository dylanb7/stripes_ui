import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/History/Export/csv_export_data.dart';
import 'package:stripes_ui/UI/History/Export/csv_preview_sheet.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  test('detail CSV retains its category, timestamp, answers and notes', () {
    final detail = _detail();
    final rows = _rows(CsvExportData.generateDetailCsv([detail], null));

    expect(rows.first, CsvExportData.detailColumns);
    expect(rows.singleWhere((row) => row.first == 'bm-entry'), [
      'bm-entry',
      '2026-01-21T13:00:00.000Z',
      'study',
      'category.BM',
      'Average BM type (1-7)',
      '4',
      'A note, with "quotes"',
    ]);
  });

  for (final fixture in [
    (
      'oral with recorded finish',
      const Duration(minutes: 22, seconds: 30),
      DateTime.utc(2026, 1, 21, 10, 25),
      AmountConsumed.half,
      '22.5',
    ),
    (
      'oral without recorded finish',
      const Duration(minutes: 20),
      null,
      AmountConsumed.half,
      '20',
    ),
    ('tube start only', Duration.zero, null, AmountConsumed.undetermined, ''),
    (
      'legacy tube with recorded finish',
      Duration.zero,
      DateTime.utc(2026, 1, 21, 10, 25),
      AmountConsumed.undetermined,
      '',
    ),
  ]) {
    test('${fixture.$1} preserves raw timing without inventing an end', () {
      final transit = _transit(
        duration: fixture.$2,
        finished: fixture.$3,
        amount: fixture.$4,
      );
      final rows = _rows(CsvExportData.generateBlueDyeCsv([transit]));
      expect(rows.first, CsvExportData.transitColumns);
      final values = Map<String, dynamic>.fromIterables(
        rows.first.cast<String>(),
        rows[1],
      );

      expect(values['Test Start'], '2026-01-21T10:00:00.000Z');
      expect(values['Eating Duration'], fixture.$5);
      expect(
        values['Finished Eating'],
        fixture.$3?.toUtc().toIso8601String() ?? '',
      );
      expect(values['Transit Duration'], '180');
      expect(values['Lag Phase'], '60');
      expect(values['BM Date'], '2026-01-21T13:00:00.000Z');
      expect(values['Amount Consumed'], fixture.$4.name);
    });
  }

  testWidgets('preview shows every exact heading written to both CSV files', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final detail = _detail();
    final transit = _transit();
    final headings = [
      ..._rows(CsvExportData.generateDetailCsv([detail], null)).first,
      ..._rows(CsvExportData.generateBlueDyeCsv([transit])).first,
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CsvPreviewSheet(
              responses: [detail, transit],
              scrollController: scroll,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<Chip>(find.byType(Chip))
          .map((chip) => (chip.label as Text).data),
      headings,
    );
    expect(tester.takeException(), isNull);
  });
}

List<List<dynamic>> _rows(String csv) =>
    const CsvToListConverter(shouldParseNumbers: false).convert(csv);

DetailResponse _detail() {
  final stamp = dateToStamp(DateTime.utc(2026, 1, 21, 13));
  return DetailResponse(
    id: 'bm-entry',
    group: 'study',
    stamp: stamp,
    detailType: 'category.BM',
    description: 'A note, with "quotes"',
    responses: [
      NumericResponse(
        question: const Numeric(
          id: 'q4',
          prompt: 'Average BM type (1-7)',
          type: 'category.BM',
        ),
        stamp: stamp,
        response: 4,
      ),
    ],
  );
}

BlueDyeResp _transit({
  Duration duration = const Duration(minutes: 20),
  DateTime? finished,
  AmountConsumed amount = AmountConsumed.half,
}) => BlueDyeResp(
  id: 'transit-1',
  startEating: DateTime.utc(2026, 1, 21, 10),
  eatingDuration: duration,
  finishedEatingTime: finished,
  normalBowelMovements: 0,
  blueBowelMovements: 1,
  logs: [BMTestLog(id: 'bm-log', response: _detail(), isBlue: true)],
  amountConsumed: amount,
  firstBlue: DateTime.utc(2026, 1, 21, 13),
  lastBlue: DateTime.utc(2026, 1, 21, 14),
);
