import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/Providers/sheet_provider.dart';
import 'package:stripes_ui/Util/paddings.dart';

import 'csv_preview_sheet.dart';
import 'report_sheet.dart';

/// Bottom sheet showing export format options (CSV or Report)
class ExportOptionsSheet extends ConsumerWidget {
  final List<Response> responses;

  const ExportOptionsSheet({required this.responses, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings settings = ref.watch(displayDataProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Text(
                l10n.exportDataTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.tiny),

          // Date range info
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.small,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: AppPadding.small),
                Text(
                  settings.getRangeString(context),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.entriesCount(responses.length),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),

          // Export options
          _ExportOptionTile(
            icon: Icons.table_chart_outlined,
            title: l10n.exportOptionCsv,
            description: l10n.exportOptionCsvDesc,
            onTap: () => _handleExport(context, ref, _ExportFormat.csv),
          ),
          _ExportOptionTile(
            icon: Icons.assessment_outlined,
            title: l10n.exportOptionReport,
            description: l10n.exportOptionReportDesc,
            onTap: () => _handleExport(context, ref, _ExportFormat.report),
          ),

          const SizedBox(height: AppPadding.medium),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context, WidgetRef ref, _ExportFormat type) {
    Navigator.of(context).pop();

    final sheetController = ref.read(sheetControllerProvider);

    switch (type) {
      case _ExportFormat.csv:
        sheetController.show(
          context: context,
          scrollControlled: true,
          sheetBuilder: (context, scrollController) => CsvPreviewSheet(
              responses: responses, scrollController: scrollController),
        );
        break;

      case _ExportFormat.report:
        sheetController.show(
          context: context,
          scrollControlled: true,
          sheetBuilder: (context, scrollController) => ReportSheet(
              responses: responses, scrollController: scrollController),
        );
        break;
    }
  }
}

enum _ExportFormat { csv, report }

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRounding.small),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRounding.small),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRounding.tiny),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
