import 'dart:io' if (dart.library.html) 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

// Web-specific import for downloads
import 'package:stripes_ui/Services/web_download_stub.dart'
    if (dart.library.html) 'package:stripes_ui/Services/web_download.dart'
    as web_download;

class CsvPreviewSheet extends ConsumerStatefulWidget {
  final List<Response> responses;
  final ScrollController scrollController;

  const CsvPreviewSheet({
    required this.responses,
    required this.scrollController,
    super.key,
  });

  @override
  ConsumerState<CsvPreviewSheet> createState() => _CsvPreviewSheetState();
}

class _CsvPreviewSheetState extends ConsumerState<CsvPreviewSheet> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final csvStats = _calculateStats();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRounding.medium),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRounding.tiny),
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.csvExportTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        settings.getRangeString(context),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppPadding.large),
              children: [
                // Stats Preview Section
                _SectionHeader(title: l10n.csvExportPreview),
                const SizedBox(height: AppPadding.medium),

                // Stats cards - wrapped in IntrinsicHeight for equal heights
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.table_rows_outlined,
                          label: l10n.csvTotalRows,
                          value: csvStats.totalRows.toString(),
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppPadding.medium),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.note_alt_outlined,
                          label: l10n.csvDetailEntries,
                          value: csvStats.detailCount.toString(),
                          color: colors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppPadding.medium),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.science_outlined,
                          label: l10n.csvBlueDyeTests,
                          value: csvStats.blueDyeCount.toString(),
                          color: colors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.xl),

                // Files to be generated
                _SectionHeader(title: l10n.csvFilesToGenerate),
                const SizedBox(height: AppPadding.medium),

                if (csvStats.detailCount > 0)
                  _FileInfoTile(
                    icon: Icons.description_outlined,
                    filename: 'responses.csv',
                    description: l10n.csvEntriesWithRows(
                        csvStats.detailCount, csvStats.totalDetailRows),
                    columns: const [
                      'id',
                      'date',
                      'group',
                      'type',
                      'prompt',
                      'response',
                      'description'
                    ],
                  ),

                if (csvStats.blueDyeCount > 0) ...[
                  const SizedBox(height: AppPadding.medium),
                  _FileInfoTile(
                    icon: Icons.science_outlined,
                    filename: 'transit_responses.csv',
                    description:
                        l10n.csvBlueDyeTestResults(csvStats.blueDyeCount),
                    columns: const [
                      'ID',
                      'Transit Start',
                      'Transit Duration',
                      'Lag Phase',
                      'BM Date',
                      'Is Blue',
                      '...'
                    ],
                  ),
                ],

                const SizedBox(height: AppPadding.xl),

                // Sample data preview
                if (csvStats.totalRows > 0) ...[
                  _SectionHeader(title: l10n.csvSampleData),
                  const SizedBox(height: AppPadding.medium),
                  _buildSampleTable(l10n),
                ],

                const SizedBox(height: AppPadding.xl),
              ],
            ),
          ),

          // Export button
          Container(
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : () => _exportCsv(context),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(
                    _isExporting ? l10n.csvExporting : l10n.csvExportButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleTable(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get first few detail responses for preview
    final detailResponses =
        widget.responses.whereType<DetailResponse>().take(3).toList();

    if (detailResponses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        child: Text(
          l10n.csvNoDetailEntries,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRounding.small),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.small,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRounding.small),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.tableHeaderDate,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.tableHeaderType,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.tableHeaderResponse,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ...detailResponses.expand((detail) {
            final questionsL10n = QuestionsLocalizations.of(context);
            final date = dateFromStamp(detail.stamp);
            final dateStr = '${date.month}/${date.day}/${date.year}';
            return detail.responses.take(2).map((r) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.medium,
                    vertical: AppPadding.small,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          dateStr,
                          style: textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          questionsL10n?.value(r.type) ?? r.type,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatResponse(r, questionsL10n),
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ));
          }).take(5),
        ],
      ),
    );
  }

  String _formatResponse(Response response,
      [QuestionsLocalizations? questionsL10n]) {
    String localize(String key) => questionsL10n?.value(key) ?? key;

    if (response is NumericResponse) {
      return '${response.response}';
    }
    if (response is OpenResponse) {
      return response.response;
    }
    if (response is MultiResponse) {
      if (response.index < response.question.choices.length) {
        return localize(response.question.choices[response.index]);
      }
      return 'Unknown';
    }
    if (response is AllResponse) {
      return response.choices.map((c) => localize(c)).join(', ');
    }
    return 'Selected';
  }

  _CsvStats _calculateStats() {
    final detailResponses =
        widget.responses.whereType<DetailResponse>().toList();
    final blueDyeResponses = widget.responses.whereType<BlueDyeResp>().toList();

    int totalDetailRows = 0;
    for (final detail in detailResponses) {
      totalDetailRows += detail.responses.length;
    }

    return _CsvStats(
      totalRows: totalDetailRows + blueDyeResponses.length,
      detailCount: detailResponses.length,
      blueDyeCount: blueDyeResponses.length,
      totalDetailRows: totalDetailRows,
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final questionsL10n = QuestionsLocalizations.of(context);
    setState(() => _isExporting = true);

    try {
      final detailResponses =
          widget.responses.whereType<DetailResponse>().toList();
      String? detailCsv;
      if (detailResponses.isNotEmpty) {
        detailCsv = _generateDetailCsv(detailResponses, questionsL10n);
      }

      final blueDyeResponses =
          widget.responses.whereType<BlueDyeResp>().toList();
      String? blueDyeCsv;
      if (blueDyeResponses.isNotEmpty) {
        blueDyeCsv =
            _generateBlueDyeCsv(blueDyeResponses, questionsL10n: questionsL10n);
      }

      if (kIsWeb) {
        if (detailCsv != null) {
          web_download.downloadFile(detailCsv, 'responses.csv', 'text/csv');
        }
        if (blueDyeCsv != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          web_download.downloadFile(
              blueDyeCsv, 'transit_responses.csv', 'text/csv');
        }
      } else {
        // Native: Use share dialog
        final List<XFile> files = [];
        final Directory tempDir = await getTemporaryDirectory();

        if (detailCsv != null) {
          final detailFile = File('${tempDir.path}/responses.csv');
          await detailFile.writeAsString(detailCsv);
          files.add(XFile(detailFile.path));
        }

        if (blueDyeCsv != null) {
          final blueDyeFile = File('${tempDir.path}/transit_responses.csv');
          await blueDyeFile.writeAsString(blueDyeCsv);
          files.add(XFile(blueDyeFile.path));
        }

        if (files.isNotEmpty && context.mounted) {
          // Get share position for iPad
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          final Rect? sharePositionOrigin =
              box != null ? box.localToGlobal(Offset.zero) & box.size : null;

          await Share.shareXFiles(
            files,
            sharePositionOrigin: sharePositionOrigin,
          );
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.csvExportFailed(e.toString())),
            duration: const Duration(seconds: 4),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _generateDetailCsv(
      List<DetailResponse> responses, QuestionsLocalizations? questionsL10n) {
    const headers = [
      'id',
      'date',
      'group',
      'category',
      'prompt',
      'response',
      'description'
    ];
    final rows = <List<dynamic>>[headers];

    String localize(String key) => questionsL10n?.value(key) ?? key;

    for (final detail in responses) {
      final date = dateFromStamp(detail.stamp);
      final dateStr = date.toIso8601String();
      for (final r in detail.responses) {
        rows.add([
          detail.id ?? '',
          dateStr,
          detail.group != null ? localize(detail.group!) : '',
          localize(r.type),
          localize(r.question.prompt),
          _formatResponse(r, questionsL10n),
          detail.description ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _generateBlueDyeCsv(List<BlueDyeResp> responses,
      {QuestionsLocalizations? questionsL10n}) {
    const headers = [
      'ID',
      'Amount Consumed',
      'Test Start',
      'Eating Duration',
      'Finished Eating',
      'Transit Duration',
      'Lag Phase',
      'BM Date',
      'BMID',
      'Description',
      'Is Blue',
      'Prompt',
      'Response'
    ];
    final rows = <List<dynamic>>[headers];

    String localize(String key) => questionsL10n?.value(key) ?? key;

    for (final resp in responses) {
      // Correct calculations:
      // Transit Duration = time from START of eating to first blue BM
      final transitDuration = resp.firstBlue.difference(resp.startEating);
      // Lag Phase = time from first blue BM to last blue BM
      final lagPhase = resp.lastBlue.difference(resp.firstBlue);

      final finishedEatingTime =
          resp.finishedEatingTime ?? resp.startEating.add(resp.eatingDuration);

      // One row per response within each BM log (nested: Test -> Log -> Response)
      for (final log in resp.logs) {
        final bmDate = dateFromStamp(log.stamp);

        for (final logResponse in log.response.responses) {
          String prompt = localize(logResponse.question.prompt);
          String responseValue = '';

          if (logResponse is NumericResponse) {
            responseValue = '${logResponse.response}';
          } else if (logResponse is OpenResponse) {
            responseValue = logResponse.response;
          } else if (logResponse is MultiResponse &&
              logResponse.index < logResponse.question.choices.length) {
            responseValue =
                localize(logResponse.question.choices[logResponse.index]);
          } else if (logResponse is AllResponse) {
            responseValue =
                logResponse.choices.map((c) => localize(c)).join(', ');
          }

          rows.add([
            resp.id ?? '',
            resp.amountConsumed.name,
            resp.startEating.toIso8601String(),
            resp.eatingDuration.inMinutes,
            finishedEatingTime.toIso8601String(),
            transitDuration.inMinutes,
            lagPhase.inMinutes,
            bmDate.toIso8601String(),
            log.id ?? '',
            log.response.description ?? '',
            log.isBlue ? 'true' : 'false',
            prompt,
            responseValue,
          ]);
        }
      }
    }

    return const ListToCsvConverter().convert(rows);
  }
}

class _CsvStats {
  final int totalRows;
  final int detailCount;
  final int blueDyeCount;
  final int totalDetailRows;

  const _CsvStats({
    required this.totalRows,
    required this.detailCount,
    required this.blueDyeCount,
    required this.totalDetailRows,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRounding.small),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppPadding.tiny),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FileInfoTile extends StatelessWidget {
  final IconData icon;
  final String filename;
  final String description;
  final List<String> columns;

  const _FileInfoTile({
    required this.icon,
    required this.filename,
    required this.description,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRounding.small),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  filename,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.tiny),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          Wrap(
            spacing: AppPadding.tiny,
            runSpacing: AppPadding.tiny,
            children: columns
                .map((col) => Chip(
                      label: Text(col),
                      labelStyle: textTheme.labelSmall,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
