import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/Services/report_generator.dart';
import 'package:stripes_ui/Util/paddings.dart';

/// Report configuration and preview sheet
/// This sheet allows users to configure and generate a PDF summary report
class ReportSheet extends ConsumerStatefulWidget {
  final List<Response> responses;
  final ScrollController scrollController;

  const ReportSheet({
    required this.responses,
    required this.scrollController,
    super.key,
  });

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Calculate basic stats for preview
    final reportStats = _calculateStats();

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
                    Icons.assessment_outlined,
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
                        l10n.reportTitle,
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
                _SectionHeader(title: l10n.reportPreview),
                const SizedBox(height: AppPadding.medium),

                // Stats cards
                Wrap(
                  spacing: AppPadding.medium,
                  runSpacing: AppPadding.medium,
                  children: [
                    _StatCard(
                      icon: Icons.note_alt_outlined,
                      label: l10n.reportTotalEntries,
                      value: reportStats.totalEntries.toString(),
                      color: colors.primary,
                    ),
                    _StatCard(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.reportDaysWithData,
                      value: reportStats.uniqueDays.toString(),
                      color: colors.secondary,
                    ),
                    _StatCard(
                      icon: Icons.category_outlined,
                      label: l10n.reportCategories,
                      value: reportStats.categoryCount.toString(),
                      color: colors.tertiary,
                    ),
                  ],
                ),

                const SizedBox(height: AppPadding.xl),

                // Categories breakdown
                _SectionHeader(title: l10n.reportEntriesByCategory),
                const SizedBox(height: AppPadding.medium),

                ...reportStats.entriesByType.entries.map(
                  (entry) => _CategoryRow(
                    category: entry.key,
                    count: entry.value,
                    total: reportStats.totalEntries,
                  ),
                ),

                const SizedBox(height: AppPadding.xl),

                // Report will include note
                Container(
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
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppPadding.small),
                          Text(
                            l10n.reportContents,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.small),
                      Text(
                        l10n.reportContentsDesc,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.xl),
              ],
            ),
          ),

          // Generate button
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
                onPressed:
                    _isGenerating ? null : () => _generateReport(context),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_isGenerating
                    ? l10n.reportGenerating
                    : l10n.reportGeneratePdf),
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

  _ReportStats _calculateStats() {
    final Map<String, int> entriesByType = {};
    final Set<DateTime> uniqueDates = {};

    for (final response in widget.responses) {
      // Count by type
      final type = response.type;
      entriesByType[type] = (entriesByType[type] ?? 0) + 1;

      // Track unique days
      final date = dateFromStamp(response.stamp);
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }

    return _ReportStats(
      totalEntries: widget.responses.length,
      uniqueDays: uniqueDates.length,
      categoryCount: entriesByType.length,
      entriesByType: entriesByType,
    );
  }

  Future<void> _generateReport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGenerating = true);

    try {
      final DisplayDataSettings settings = ref.read(displayDataProvider);

      // Generate the PDF
      final pdfBytes = await ReportGenerator.generatePdf(
        responses: widget.responses,
        dateRange: settings.range,
      );

      if (!mounted) return;

      // Share the PDF
      final dateFormat = DateFormat('yyyy-MM-dd');
      final filename =
          'report_${dateFormat.format(settings.range.start)}_to_${dateFormat.format(settings.range.end)}.pdf';

      await ReportGenerator.sharePdf(pdfBytes, filename);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportGenerationFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

class _ReportStats {
  final int totalEntries;
  final int uniqueDays;
  final int categoryCount;
  final Map<String, int> entriesByType;

  const _ReportStats({
    required this.totalEntries,
    required this.uniqueDays,
    required this.categoryCount,
    required this.entriesByType,
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

class _CategoryRow extends StatelessWidget {
  final String category;
  final int count;
  final int total;

  const _CategoryRow({
    required this.category,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppPadding.medium),
          SizedBox(
            width: 40,
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
