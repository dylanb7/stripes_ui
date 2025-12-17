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

// Web-specific import for downloads
import 'package:stripes_ui/Services/web_download_stub.dart'
    if (dart.library.html) 'package:stripes_ui/Services/web_download.dart'
    as web_download;

/// CSV export preview sheet
/// Shows a preview of the data to be exported and allows sharing
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

    // Calculate stats for preview
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

                // Stats cards
                Wrap(
                  spacing: AppPadding.medium,
                  runSpacing: AppPadding.medium,
                  children: [
                    _StatCard(
                      icon: Icons.table_rows_outlined,
                      label: l10n.csvTotalRows,
                      value: csvStats.totalRows.toString(),
                      color: colors.primary,
                    ),
                    _StatCard(
                      icon: Icons.note_alt_outlined,
                      label: l10n.csvDetailEntries,
                      value: csvStats.detailCount.toString(),
                      color: colors.secondary,
                    ),
                    _StatCard(
                      icon: Icons.science_outlined,
                      label: l10n.csvBlueDyeTests,
                      value: csvStats.blueDyeCount.toString(),
                      color: colors.tertiary,
                    ),
                  ],
                ),

                const SizedBox(height: AppPadding.xl),

                // Files to be generated
                _SectionHeader(title: l10n.csvFilesToGenerate),
                const SizedBox(height: AppPadding.medium),

                if (csvStats.detailCount > 0)
                  _FileInfoTile(
                    icon: Icons.description_outlined,
                    filename: 'detail_responses.csv',
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
                    filename: 'test_responses.csv',
                    description:
                        l10n.csvBlueDyeTestResults(csvStats.blueDyeCount),
                    columns: const [
                      'id',
                      'meal start',
                      'meal duration',
                      'brown bms',
                      'blue bms',
                      'transit time',
                      'lag phase'
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

    // Build simple list-based preview instead of DataTable for better display
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
                          r.type,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatResponse(r),
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

  String _formatResponse(Response response) {
    if (response is NumericResponse) {
      return '${response.response}';
    }
    if (response is OpenResponse) {
      return response.response;
    }
    if (response is MultiResponse) {
      if (response.index < response.question.choices.length) {
        return response.question.choices[response.index];
      }
      return 'Unknown';
    }
    if (response is AllResponse) {
      return response.choices.join(', ');
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
    setState(() => _isExporting = true);

    try {
      // Generate detail responses CSV
      final detailResponses =
          widget.responses.whereType<DetailResponse>().toList();
      String? detailCsv;
      if (detailResponses.isNotEmpty) {
        detailCsv = _generateDetailCsv(detailResponses);
      }

      // Generate blue dye responses CSV
      final blueDyeResponses =
          widget.responses.whereType<BlueDyeResp>().toList();
      String? blueDyeCsv;
      if (blueDyeResponses.isNotEmpty) {
        blueDyeCsv = _generateBlueDyeCsv(blueDyeResponses);
      }

      if (kIsWeb) {
        // Web: Download files directly to browser
        if (detailCsv != null) {
          web_download.downloadFile(
              detailCsv, 'detail_responses.csv', 'text/csv');
        }
        if (blueDyeCsv != null) {
          // Small delay to avoid browser blocking multiple downloads
          await Future.delayed(const Duration(milliseconds: 500));
          web_download.downloadFile(
              blueDyeCsv, 'test_responses.csv', 'text/csv');
        }
      } else {
        // Native: Use share dialog
        final List<XFile> files = [];
        final Directory tempDir = await getTemporaryDirectory();

        if (detailCsv != null) {
          final detailFile = File('${tempDir.path}/detail_responses.csv');
          await detailFile.writeAsString(detailCsv);
          files.add(XFile(detailFile.path));
        }

        if (blueDyeCsv != null) {
          final blueDyeFile = File('${tempDir.path}/test_responses.csv');
          await blueDyeFile.writeAsString(blueDyeCsv);
          files.add(XFile(blueDyeFile.path));
        }

        if (files.isNotEmpty) {
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

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.csvExportFailed(e.toString())),
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

  String _generateDetailCsv(List<DetailResponse> responses) {
    const headers = [
      'id',
      'date',
      'group',
      'type',
      'prompt',
      'response',
      'description'
    ];
    final rows = <List<dynamic>>[headers];

    for (final detail in responses) {
      final date = dateFromStamp(detail.stamp);
      final dateStr = date.toIso8601String();
      for (final r in detail.responses) {
        rows.add([
          detail.id ?? '',
          dateStr,
          detail.group,
          r.type,
          r.question.prompt,
          _formatResponse(r),
          detail.description ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _generateBlueDyeCsv(List<BlueDyeResp> responses) {
    const headers = [
      'id',
      'meal start',
      'meal duration',
      'brown bms',
      'blue bms',
      'transit time',
      'lag phase'
    ];
    final rows = <List<dynamic>>[headers];

    for (final resp in responses) {
      final transitTime = resp.firstBlue.difference(
        resp.startEating.add(resp.eatingDuration),
      );
      final lagPhase = resp.lastBlue.difference(resp.firstBlue);

      rows.add([
        resp.id ?? '',
        resp.startEating.toIso8601String(),
        resp.eatingDuration.inMinutes,
        resp.normalBowelMovements,
        resp.blueBowelMovements,
        transitTime.inMinutes,
        lagPhase.inMinutes,
      ]);
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
      width: 100,
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
