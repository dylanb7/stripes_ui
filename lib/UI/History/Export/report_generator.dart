import 'dart:io' if (dart.library.html) 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

// Web-specific import for downloads
import 'package:stripes_ui/Services/web_download_stub.dart'
    if (dart.library.html) 'package:stripes_ui/Services/web_download.dart'
    as web_download;
import 'package:stripes_ui/Util/Helpers/stats.dart';

class ReportGenerator {
  static Future<Uint8List> generatePdf({
    required List<Response> responses,
    required DateTimeRange dateRange,
    required Map<String, String> localizedStrings,
    String? patientName,
  }) async {
    final pdf = pw.Document();

    final stats = _calculateStats(responses);
    final blueDyeResults = _extractBlueDyeResults(responses);
    final insights = _calculateInsights(responses, dateRange);
    final questionBreakdown = _buildQuestionBreakdown(responses);

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    String localize(String key) => localizedStrings[key] ?? key;

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
          _buildSectionTitle('Summary', fontBold),
          pw.SizedBox(height: 8),
          _buildSummaryCards(stats),
          pw.SizedBox(height: 20),
          if (insights.isNotEmpty) ...[
            _buildSectionTitle('Insights', fontBold),
            pw.SizedBox(height: 8),
            _buildInsightsSection(insights),
            pw.SizedBox(height: 20),
          ],
          _buildSectionTitle('Entries by Category', fontBold),
          pw.SizedBox(height: 8),
          _buildCategoryTable(
              stats.entriesByType, stats.totalEntries, localize),
          pw.SizedBox(height: 20),
          if (blueDyeResults.isNotEmpty) ...[
            _buildSectionTitle('Blue Dye Test Results', fontBold),
            pw.SizedBox(height: 8),
            _buildBlueDyeTable(blueDyeResults),
            pw.SizedBox(height: 20),
          ],
          _buildSectionTitle('Detailed Breakdown', fontBold),
          pw.SizedBox(height: 8),
          ..._buildDetailedBreakdown(questionBreakdown, localize, fontBold),
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
                  style: const pw.TextStyle(
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
                style: const pw.TextStyle(
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

  static pw.Widget _buildInsightsSection(List<_Insight> insights) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue100),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: insights
            .map((insight) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${insight.title}: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        pw.TextSpan(
                          text: insight.description,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _buildCategoryTable(Map<String, int> entriesByType,
      int total, String Function(String) localize) {
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
              _tableCell(localize(entry.key)),
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

  /// Build detailed breakdown: Category → Question → Response counts
  /// Uses Partitions to allow content to split across pages gracefully
  static List<pw.Widget> _buildDetailedBreakdown(
    Map<String, _CategoryBreakdown> breakdown,
    String Function(String) localize,
    pw.Font fontBold,
  ) {
    final List<pw.Widget> widgets = [];

    for (final entry in breakdown.entries) {
      final category = entry.key;
      final categoryData = entry.value;
      final questionEntries = categoryData.questions.entries.toList();

      // Category header - kept together as a unit
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  localize(category),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.Text(
                  '${categoryData.totalCount} entries',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blueGrey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Each question as a separate widget that can break across pages
      for (int i = 0; i < questionEntries.length; i++) {
        final qEntry = questionEntries[i];
        final questionData = qEntry.value;
        final isLast = i == questionEntries.length - 1;

        widgets.add(
          pw.Container(
            margin: pw.EdgeInsets.only(
              left: 12,
              right: 12,
              top: i == 0 ? 12 : 0,
              bottom: isLast ? 16 : 10,
            ),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: isLast
                ? null
                : const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                  ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Question prompt
                pw.Text(
                  localize(questionData.prompt),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                // Response breakdown
                if (questionData.isNumeric) ...[
                  pw.Row(
                    children: [
                      _buildMiniStat('Count', questionData.count.toString()),
                      pw.SizedBox(width: 16),
                      _buildMiniStat('Avg',
                          questionData.average?.toStringAsFixed(1) ?? '-'),
                      pw.SizedBox(width: 16),
                      _buildMiniStat(
                          'Min', questionData.min?.toStringAsFixed(1) ?? '-'),
                      pw.SizedBox(width: 16),
                      _buildMiniStat(
                          'Max', questionData.max?.toStringAsFixed(1) ?? '-'),
                    ],
                  ),
                ] else if (questionData.openResponses.isNotEmpty) ...[
                  pw.Text(
                    '${questionData.count} responses',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ] else ...[
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: questionData.choiceCounts.entries
                        .map(
                          (cEntry) => pw.Text(
                            '${localize(cEntry.key)}: ${cEntry.value}',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
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
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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

  // ============= STATS CALCULATION =============

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

  static List<_Insight> _calculateInsights(
      List<Response> responses, DateTimeRange range) {
    final List<_Insight> insights = [];
    if (responses.isEmpty) return insights;

    // Calculate time of day distribution
    final Map<int, int> hourCounts = {};
    final Map<int, int> dayCounts = {}; // 1=Monday, 7=Sunday
    final Map<DateTime, int> dailyCounts = {};

    for (final response in responses) {
      final date = dateFromStamp(response.stamp);
      final hour = date.hour;
      final dayOfWeek = date.weekday;
      final dayOnly = DateTime(date.year, date.month, date.day);

      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayCounts[dayOfWeek] = (dayCounts[dayOfWeek] ?? 0) + 1;
      dailyCounts[dayOnly] = (dailyCounts[dayOnly] ?? 0) + 1;
    }

    // Peak hours - use Kadane's algorithm to find optimal contiguous window
    if (hourCounts.isNotEmpty) {
      final List<int> hourlyList = List.generate(24, (h) => hourCounts[h] ?? 0);
      final PeakWindow peak = findPeakWindow(hourlyList);

      if (peak.count > 0) {
        final int percentage = (peak.count / responses.length * 100).round();
        final double expectedCount = responses.length * peak.duration / 24;
        final double timesExpected =
            expectedCount > 0 ? peak.count / expectedCount : 1.0;

        String hourRange =
            '${_formatHour(peak.startHour)} - ${_formatHour(peak.endHour + 1)}';
        insights.add(_Insight(
          title: 'Peak Activity',
          description:
              '$hourRange ($percentage% of entries, ${timesExpected.toStringAsFixed(1)}× expected)',
        ));
      }
    }

    if (dayCounts.isNotEmpty) {
      final List<MapEntry<int, int>> sortedDays = dayCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final int peakDay = sortedDays.first.key;
      final String peakDayName = _dayName(peakDay);
      final int peakDayCount = sortedDays.first.value;
      final int dayPercentage = (peakDayCount / responses.length * 100).round();
      final double expectedDayCount = responses.length / 7;
      final double timesExpected =
          expectedDayCount > 0 ? peakDayCount / expectedDayCount : 1.0;

      insights.add(_Insight(
        title: 'Most Active Day',
        description:
            '$peakDayName ($dayPercentage% of entries, ${timesExpected.toStringAsFixed(1)}× expected)',
      ));
    }

    if (dailyCounts.isNotEmpty) {
      final List<DateTime> sortedDates = dailyCounts.keys.toList()..sort();
      int maxStreak = 1;
      int currentStreak = 1;

      for (int i = 1; i < sortedDates.length; i++) {
        final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
          if (currentStreak > maxStreak) maxStreak = currentStreak;
        } else {
          currentStreak = 1;
        }
      }

      if (maxStreak > 1) {
        insights.add(_Insight(
          title: 'Longest Streak',
          description: '$maxStreak consecutive days',
        ));
      }
    }

    // Weekend vs Weekday pattern
    if (dayCounts.isNotEmpty) {
      int weekdayCount = 0;
      int weekendCount = 0;
      for (final entry in dayCounts.entries) {
        if (entry.key >= 6) {
          weekendCount += entry.value;
        } else {
          weekdayCount += entry.value;
        }
      }
      final double weekdayAvg = weekdayCount / 5;
      final double weekendAvg = weekendCount / 2;

      if (weekdayAvg > 0 || weekendAvg > 0) {
        final bool moreOnWeekend = weekendAvg > weekdayAvg;
        final double higher = moreOnWeekend ? weekendAvg : weekdayAvg;
        final double lower = moreOnWeekend ? weekdayAvg : weekendAvg;
        final double ratio = lower > 0 ? higher / lower : 1.0;

        if (ratio >= 1.3) {
          insights.add(_Insight(
            title: 'Weekly Pattern',
            description:
                '${ratio.toStringAsFixed(1)}× more active on ${moreOnWeekend ? "weekends" : "weekdays"}',
          ));
        }
      }
    }

    // Trend direction
    if (dailyCounts.length >= 3) {
      final List<DateTime> sortedDates = dailyCounts.keys.toList()..sort();
      final DateTime firstDay = sortedDates.first;

      final List<double> xValues = sortedDates
          .map((d) => d.difference(firstDay).inDays.toDouble())
          .toList();
      final List<double> yValues =
          sortedDates.map((d) => dailyCounts[d]!.toDouble()).toList();

      final LinearRegressionResult? regression =
          linearRegression(xValues, yValues);
      if (regression != null && regression.percentChangePerUnit.abs() >= 10) {
        final String direction =
            regression.slope > 0 ? 'increasing' : 'decreasing';
        insights.add(_Insight(
          title: 'Activity Trend',
          description:
              '${direction.substring(0, 1).toUpperCase()}${direction.substring(1)} ~${regression.percentChangePerUnit.abs().toStringAsFixed(0)}% per day',
        ));
      }
    }

    // Category co-occurrence
    if (responses.length >= 10) {
      final Map<DateTime, Set<String>> categoriesByDay = {};
      for (final response in responses) {
        if (response is DetailResponse) {
          final DateTime date = dateFromStamp(response.stamp);
          final DateTime dayOnly = DateTime(date.year, date.month, date.day);
          categoriesByDay.putIfAbsent(dayOnly, () => {}).add(response.type);
        }
      }

      final CoOccurrenceResult? coOccurrence =
          findTopCoOccurrence(categoriesByDay);
      if (coOccurrence != null &&
          coOccurrence.occurrences >= 3 &&
          coOccurrence.percentage >= 30) {
        insights.add(_Insight(
          title: 'Common Pairing',
          description:
              '${coOccurrence.item1} + ${coOccurrence.item2} appear together ${coOccurrence.percentage.round()}% of days',
        ));
      }
    }

    // Symptom correlation (Spearman) - find related numeric symptoms
    if (responses.length >= 10) {
      // Group numeric values by symptom (question prompt) per day
      final Map<DateTime, Map<String, List<double>>> symptomsByDay = {};

      for (final response in responses) {
        if (response is DetailResponse) {
          final DateTime date = dateFromStamp(response.stamp);
          final DateTime dayOnly = DateTime(date.year, date.month, date.day);
          symptomsByDay.putIfAbsent(dayOnly, () => {});

          for (final r in response.responses) {
            if (r is NumericResponse) {
              // Use question prompt as symptom identifier
              final String symptom = r.question.prompt.isNotEmpty
                  ? r.question.prompt
                  : r.question.id;
              symptomsByDay[dayOnly]!
                  .putIfAbsent(symptom, () => [])
                  .add(r.response.toDouble());
            }
          }
        }
      }

      // Average values per day per symptom
      final Map<String, List<double>> symptomDailyAvgs = {};
      final List<DateTime> sortedDays = symptomsByDay.keys.toList()..sort();

      for (final day in sortedDays) {
        final dayData = symptomsByDay[day]!;
        for (final symptom in dayData.keys) {
          final values = dayData[symptom]!;
          final avg = values.reduce((a, b) => a + b) / values.length;
          symptomDailyAvgs.putIfAbsent(symptom, () => []).add(avg);
        }
      }

      // Find strongest correlation between symptom pairs
      SpearmanResult? bestCorrelation;
      String? bestPair;

      final symptoms = symptomDailyAvgs.keys.toList();
      for (int i = 0; i < symptoms.length - 1; i++) {
        for (int j = i + 1; j < symptoms.length; j++) {
          final symptom1 = symptoms[i];
          final symptom2 = symptoms[j];
          final vals1 = symptomDailyAvgs[symptom1]!;
          final vals2 = symptomDailyAvgs[symptom2]!;

          // Need matching lengths - use minimum
          final minLen =
              vals1.length < vals2.length ? vals1.length : vals2.length;
          if (minLen < 5) continue;

          final result = spearmanCorrelation(
            vals1.sublist(0, minLen),
            vals2.sublist(0, minLen),
          );

          if (result != null && result.isMeaningful) {
            if (bestCorrelation == null ||
                result.rho.abs() > bestCorrelation.rho.abs()) {
              bestCorrelation = result;
              bestPair = '$symptom1 & $symptom2';
            }
          }
        }
      }

      if (bestCorrelation != null &&
          bestPair != null &&
          bestCorrelation.rho.abs() >= 0.4) {
        // Only show moderate+ correlations
        final String linkType = bestCorrelation.rho > 0
            ? 'tend to increase together'
            : 'move in opposite directions';
        insights.add(_Insight(
          title: 'Symptom Link',
          description: '$bestPair $linkType (${bestCorrelation.strength})',
        ));
      }
    }

    return insights;
  }

  static String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12am';
    if (hour == 12) return '12pm';
    if (hour < 12) return '${hour}am';
    return '${hour - 12}pm';
  }

  static String _dayName(int weekday) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday];
  }

  static Map<String, _CategoryBreakdown> _buildQuestionBreakdown(
      List<Response> responses) {
    final Map<String, _CategoryBreakdown> breakdown = {};

    for (final response in responses) {
      switch (response) {
        case DetailResponse():
          final category = response.type;
          breakdown.putIfAbsent(category, () => _CategoryBreakdown());
          breakdown[category]!.totalCount++;

          for (final r in response.responses) {
            _processResponse(r, breakdown[category]!);
          }

        case BlueDyeResp():
          const category = 'Blue Dye Test';
          breakdown.putIfAbsent(category, () => _CategoryBreakdown());
          breakdown[category]!.totalCount++;

          // Add transit time as a numeric breakdown
          final transitTime = response.firstBlue.difference(
            response.startEating.add(response.eatingDuration),
          );
          breakdown[category]!.questions.putIfAbsent(
                'transit_time',
                () => _QuestionBreakdown(prompt: 'Transit Time (hours)'),
              );
          final transitBreakdown =
              breakdown[category]!.questions['transit_time']!;
          transitBreakdown.count++;
          transitBreakdown.isNumeric = true;
          transitBreakdown.numericValues.add(transitTime.inMinutes / 60.0);

          // Add lag phase as a numeric breakdown
          final lagPhase = response.lastBlue.difference(response.firstBlue);
          breakdown[category]!.questions.putIfAbsent(
                'lag_phase',
                () => _QuestionBreakdown(prompt: 'Lag Phase (hours)'),
              );
          final lagBreakdown = breakdown[category]!.questions['lag_phase']!;
          lagBreakdown.count++;
          lagBreakdown.isNumeric = true;
          lagBreakdown.numericValues.add(lagPhase.inMinutes / 60.0);

        default:
          // Handle standalone responses (not wrapped in DetailResponse)
          final category = response.type;
          breakdown.putIfAbsent(category, () => _CategoryBreakdown());
          breakdown[category]!.totalCount++;
          _processResponse(response, breakdown[category]!);
      }
    }

    // Calculate numeric stats
    for (final cat in breakdown.values) {
      for (final q in cat.questions.values) {
        if (q.numericValues.isNotEmpty) {
          q.average =
              q.numericValues.reduce((a, b) => a + b) / q.numericValues.length;
          q.min = q.numericValues.reduce((a, b) => a < b ? a : b);
          q.max = q.numericValues.reduce((a, b) => a > b ? a : b);
        }
      }
    }

    return breakdown;
  }

  /// Process an individual response and update the category breakdown
  static void _processResponse(Response r, _CategoryBreakdown categoryData) {
    final questionId = r.question.id;
    final prompt = r.question.prompt.isNotEmpty ? r.question.prompt : r.type;

    categoryData.questions.putIfAbsent(
      questionId,
      () => _QuestionBreakdown(prompt: prompt),
    );

    final qBreakdown = categoryData.questions[questionId]!;
    qBreakdown.count++;

    switch (r) {
      case NumericResponse():
        qBreakdown.isNumeric = true;
        qBreakdown.numericValues.add(r.response.toDouble());

      case MultiResponse():
        if (r.index < r.question.choices.length) {
          final choice = r.question.choices[r.index];
          qBreakdown.choiceCounts[choice] =
              (qBreakdown.choiceCounts[choice] ?? 0) + 1;
        }

      case AllResponse():
        // Handle "all that apply" responses
        for (final index in r.responses) {
          if (index < r.question.choices.length) {
            final choice = r.question.choices[index];
            qBreakdown.choiceCounts[choice] =
                (qBreakdown.choiceCounts[choice] ?? 0) + 1;
          }
        }

      case OpenResponse():
        qBreakdown.openResponses.add(r.response);

      case Selected():
        qBreakdown.choiceCounts['Selected'] =
            (qBreakdown.choiceCounts['Selected'] ?? 0) + 1;

      default:
        // For any other response types, just count them
        break;
    }
  }

  // ============= BLUE DYE EXTRACTION =============

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

  /// Share the generated PDF using share_plus (or download on web)
  ///
  /// [sharePositionOrigin] is required on iPad for the share popup anchor.
  static Future<void> sharePdf(
    Uint8List pdfBytes,
    String filename, {
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb) {
      // Web: Download directly to browser
      web_download.downloadBytes(
          pdfBytes.toList(), filename, 'application/pdf');
    } else {
      // Native: Use share dialog
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: sharePositionOrigin,
      );

      // Clean up temp file after sharing
      await file.delete();
    }
  }
}

// ============= DATA CLASSES =============

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

class _Insight {
  final String title;
  final String description;

  const _Insight({
    required this.title,
    required this.description,
  });
}

class _CategoryBreakdown {
  int totalCount = 0;
  final Map<String, _QuestionBreakdown> questions = {};
}

class _QuestionBreakdown {
  final String prompt;
  int count = 0;
  bool isNumeric = false;
  final List<double> numericValues = [];
  final Map<String, int> choiceCounts = {};
  final List<String> openResponses = [];
  double? average;
  double? min;
  double? max;

  _QuestionBreakdown({required this.prompt});
}
