import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// Service for generating PDF summary reports from recorded data
class ReportGenerator {
  /// Generate a PDF report from the given responses within the date range
  static Future<Uint8List> generatePdf({
    required List<Response> responses,
    required DateTimeRange dateRange,
    String? patientName,
  }) async {
    final pdf = pw.Document();

    // Calculate stats
    final stats = _calculateStats(responses);
    final blueDyeResults = _extractBlueDyeResults(responses);

    // Load a font that supports unicode
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) => _buildHeader(
          dateRange: dateRange,
          patientName: patientName,
          fontBold: fontBold,
        ),
        footer: (context) => _buildFooter(context, font),
        build: (context) => [
          // Summary Section
          _buildSectionTitle('Summary', fontBold),
          pw.SizedBox(height: 8),
          _buildSummaryCards(stats),
          pw.SizedBox(height: 20),

          // Entries by Category
          _buildSectionTitle('Entries by Category', fontBold),
          pw.SizedBox(height: 8),
          _buildCategoryTable(stats.entriesByType, stats.totalEntries),
          pw.SizedBox(height: 20),

          // Blue Dye Test Results (if any)
          if (blueDyeResults.isNotEmpty) ...[
            _buildSectionTitle('Blue Dye Test Results', fontBold),
            pw.SizedBox(height: 8),
            _buildBlueDyeTable(blueDyeResults),
            pw.SizedBox(height: 20),
          ],

          // Response Details by Category
          _buildSectionTitle('Response Details', fontBold),
          pw.SizedBox(height: 8),
          ..._buildResponseDetails(responses, stats),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required DateTimeRange dateRange,
    String? patientName,
    required pw.Font fontBold,
  }) {
    final dateFormat = DateFormat.yMMMd();
    final rangeString =
        '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary Report',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: PdfColors.blueGrey800,
                ),
              ),
              if (patientName != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  patientName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Report Period',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                rangeString,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    final now = DateTime.now();
    final dateFormat = DateFormat.yMMMd().add_jm();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${dateFormat.format(now)}',
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: fontBold,
        fontSize: 16,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  static pw.Widget _buildSummaryCards(_ReportStats stats) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        _buildStatCard('Total Entries', stats.totalEntries.toString()),
        pw.SizedBox(width: 20),
        _buildStatCard('Days with Data', stats.uniqueDays.toString()),
        pw.SizedBox(width: 20),
        _buildStatCard('Categories', stats.categoryCount.toString()),
        pw.SizedBox(width: 20),
        _buildStatCard('Avg/Day', stats.averagePerDay.toStringAsFixed(1)),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryTable(
      Map<String, int> entriesByType, int total) {
    final sortedEntries = entriesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Category', isHeader: true),
            _tableCell('Count', isHeader: true),
            _tableCell('Percentage', isHeader: true),
          ],
        ),
        // Data rows
        ...sortedEntries.map((entry) {
          final percentage =
              total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
          return pw.TableRow(
            children: [
              _tableCell(entry.key),
              _tableCell(entry.value.toString()),
              _tableCell('$percentage%'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blueGrey800 : PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildBlueDyeTable(List<_BlueDyeResult> results) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Test Date', isHeader: true),
            _tableCell('Meal Duration', isHeader: true),
            _tableCell('Transit Time', isHeader: true),
            _tableCell('Lag Phase', isHeader: true),
          ],
        ),
        // Data rows
        ...results.map((result) {
          final dateFormat = DateFormat.yMMMd();
          return pw.TableRow(
            children: [
              _tableCell(dateFormat.format(result.testDate)),
              _tableCell(_formatDuration(result.mealDuration)),
              _tableCell(_formatDuration(result.transitTime)),
              _tableCell(_formatDuration(result.lagPhase)),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _buildResponseDetails(
      List<Response> responses, _ReportStats stats) {
    final List<pw.Widget> widgets = [];

    // Group responses by type and analyze
    final Map<String, List<Response>> byType = {};
    for (final response in responses) {
      if (response is DetailResponse) {
        for (final r in response.responses) {
          final type = r.type;
          byType.putIfAbsent(type, () => []).add(r);
        }
      }
    }

    for (final entry in byType.entries) {
      final type = entry.key;
      final typeResponses = entry.value;

      // Analyze based on response type
      final firstResponse = typeResponses.first;

      if (firstResponse is NumericResponse) {
        final numericResponses =
            typeResponses.whereType<NumericResponse>().toList();
        if (numericResponses.isNotEmpty) {
          final values = numericResponses.map((r) => r.response).toList();
          final avg = values.reduce((a, b) => a + b) / values.length;
          final min = values.reduce((a, b) => a < b ? a : b);
          final max = values.reduce((a, b) => a > b ? a : b);

          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    type,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      _buildMiniStat(
                          'Count', numericResponses.length.toString()),
                      pw.SizedBox(width: 20),
                      _buildMiniStat('Average', avg.toStringAsFixed(1)),
                      pw.SizedBox(width: 20),
                      _buildMiniStat('Min', min.toStringAsFixed(1)),
                      pw.SizedBox(width: 20),
                      _buildMiniStat('Max', max.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      } else if (firstResponse is MultiResponse) {
        // Count choices
        final Map<String, int> choiceCounts = {};
        for (final r in typeResponses.whereType<MultiResponse>()) {
          if (r.index < r.question.choices.length) {
            final choice = r.question.choices[r.index];
            choiceCounts[choice] = (choiceCounts[choice] ?? 0) + 1;
          }
        }

        if (choiceCounts.isNotEmpty) {
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    type,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...choiceCounts.entries.map((e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                e.key,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Text(
                              e.value.toString(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  static pw.Widget _buildMiniStat(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static _ReportStats _calculateStats(List<Response> responses) {
    final Map<String, int> entriesByType = {};
    final Set<DateTime> uniqueDates = {};

    for (final response in responses) {
      entriesByType[response.type] = (entriesByType[response.type] ?? 0) + 1;

      final date = dateFromStamp(response.stamp);
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }

    final avgPerDay =
        uniqueDates.isNotEmpty ? responses.length / uniqueDates.length : 0.0;

    return _ReportStats(
      totalEntries: responses.length,
      uniqueDays: uniqueDates.length,
      categoryCount: entriesByType.length,
      entriesByType: entriesByType,
      averagePerDay: avgPerDay,
    );
  }

  static List<_BlueDyeResult> _extractBlueDyeResults(List<Response> responses) {
    final List<_BlueDyeResult> results = [];

    for (final response in responses) {
      if (response is BlueDyeResp) {
        results.add(_BlueDyeResult(
          testDate: response.startEating,
          mealDuration: response.eatingDuration,
          transitTime: response.firstBlue.difference(
            response.startEating.add(response.eatingDuration),
          ),
          lagPhase: response.lastBlue.difference(response.firstBlue),
        ));
      }
    }

    return results;
  }

  /// Share the generated PDF using share_plus
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles([XFile(file.path)]);

    // Clean up temp file after sharing
    await file.delete();
  }
}

class _ReportStats {
  final int totalEntries;
  final int uniqueDays;
  final int categoryCount;
  final Map<String, int> entriesByType;
  final double averagePerDay;

  const _ReportStats({
    required this.totalEntries,
    required this.uniqueDays,
    required this.categoryCount,
    required this.entriesByType,
    required this.averagePerDay,
  });
}

class _BlueDyeResult {
  final DateTime testDate;
  final Duration mealDuration;
  final Duration transitTime;
  final Duration lagPhase;

  const _BlueDyeResult({
    required this.testDate,
    required this.mealDuration,
    required this.transitTime,
    required this.lagPhase,
  });
}
