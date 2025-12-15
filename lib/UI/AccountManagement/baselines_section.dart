import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/baseline_version_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/baseline_gate.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class BaselinesScreen extends ConsumerWidget {
  const BaselinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BaselineTrigger>> pendingTriggersAsync =
        ref.watch(incompleteBaselinesProvider);
    final AsyncValue<List<Stamp>> baselinesAsync =
        ref.watch(baselinesStreamProvider);

    return RefreshWidget(
      depth: RefreshDepth.subuser,
      scrollable: baselinesAsync.when(
        data: (stamps) {
          final List<BaselineTrigger> pending =
              pendingTriggersAsync.valueOrNull ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.large),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.keyboard_arrow_left),
                      ),
                      const SizedBox(width: AppPadding.small),
                      Text(
                        'Baselines',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Pending',
                    count: pending.length,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  ...pending.map((trigger) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.large,
                          vertical: AppPadding.tiny,
                        ),
                        child: BaselineTriggerTile(trigger: trigger),
                      )),
                  const SizedBox(height: AppPadding.medium),
                ],
                if (stamps.isNotEmpty) ...[
                  // Group stamps by baseline type, keeping only the latest version for display
                  ...(() {
                    final Map<String, Stamp> latestByType = {};
                    for (final stamp in stamps) {
                      final existing = latestByType[stamp.type];
                      if (existing == null || stamp.stamp > existing.stamp) {
                        latestByType[stamp.type] = stamp;
                      }
                    }
                    return [
                      _SectionHeader(
                        title: 'Completed',
                        count: latestByType.length,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ...latestByType.values
                          .map((stamp) => _CompletedBaselineTile(
                                stamp: stamp,
                              )),
                    ];
                  })(),
                ],
                if (pending.isEmpty && stamps.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.xl),
                      child: Text(
                        'No baselines configured',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading baselines')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.large,
        vertical: AppPadding.small,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: AppPadding.small),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: AppPadding.tiny,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRounding.small),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBaselineTile extends ConsumerStatefulWidget {
  final Stamp stamp;

  const _CompletedBaselineTile({
    required this.stamp,
  });

  @override
  ConsumerState<_CompletedBaselineTile> createState() =>
      _CompletedBaselineTileState();
}

class _CompletedBaselineTileState
    extends ConsumerState<_CompletedBaselineTile> {
  bool _isExpanded = true;

  void _showVersionPicker(
    BuildContext context,
    WidgetRef ref,
    List<({int version, int stamp})> versions,
    int currentVersion,
  ) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Text(
                'Select Version',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...versions.map((v) {
              final versionDate = dateFromStamp(v.stamp);
              final isSelected = v.version == currentVersion;
              return ListTile(
                leading: isSelected
                    ? Icon(Icons.check_circle, color: colors.primary)
                    : const Icon(Icons.circle_outlined),
                title: Text('Version ${v.version}'),
                subtitle: Text(dateToMDY(versionDate, context)),
                onTap: () {
                  ref
                      .read(baselineVersionPreferenceProvider.notifier)
                      .setVersion(widget.stamp.type, v.version);
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Always use latest'),
              onTap: () {
                ref
                    .read(baselineVersionPreferenceProvider.notifier)
                    .clearVersion(widget.stamp.type);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppPadding.small),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final String title =
        localizations?.value(widget.stamp.type) ?? widget.stamp.type;

    // Get available versions for this baseline type
    final AsyncValue<List<({int version, int stamp})>> versionsAsync =
        ref.watch(baselineVersionsProvider(widget.stamp.type));
    final AsyncValue<int> effectiveVersionAsync =
        ref.watch(effectiveBaselineVersionProvider(widget.stamp.type));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.large,
        vertical: AppPadding.tiny,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Section
            versionsAsync.when(
              data: (versions) {
                final int effectiveVersion =
                    effectiveVersionAsync.valueOrNull ??
                        (versions.isNotEmpty ? versions.first.version : 1);

                final currentVersionData = versions.firstWhere(
                  (v) => v.version == effectiveVersion,
                  orElse: () =>
                      (version: effectiveVersion, stamp: widget.stamp.stamp),
                );
                final versionDate = dateFromStamp(currentVersionData.stamp);

                return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color:
                            colors.surfaceContainerHigh.withValues(alpha: 0.5),
                        border: Border(
                          bottom: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.5),
                            width: _isExpanded ? 1.0 : 0.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_edu,
                              size: 20,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppPadding.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Version $effectiveVersion',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      ' • ${dateToMDY(versionDate, context)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (versions.length > 1)
                            TextButton.icon(
                              onPressed: () => _showVersionPicker(
                                context,
                                ref,
                                versions,
                                effectiveVersion,
                              ),
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: const Text('Switch'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          const SizedBox(width: AppPadding.small),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ));
              },
              loading: () => ListTile(title: Text(title)),
              error: (_, __) => ListTile(title: Text(title)),
            ),

            if (_isExpanded) ...[
              // Content Section
              Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: _buildStampContent(context, ref),
              ),

              // Footer Action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: AppPadding.medium,
                  right: AppPadding.medium,
                  bottom: AppPadding.medium,
                ),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.pushNamed(
                      RouteName.BASELINE_ENTRY,
                      pathParameters: {
                        'recordPath': Uri.encodeComponent(widget.stamp.type),
                      },
                    );
                    if (context.mounted) {
                      ref.invalidate(baselinesStreamProvider);
                    }
                  },
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Update Baseline'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStampContent(BuildContext context, WidgetRef ref) {
    // Watch the selected version's data
    final selectedDataAsync = ref.watch(baselineResponseProvider((
      baselineType: widget.stamp.type,
      version: null, // null means use effective version
    )));

    return selectedDataAsync.when(
      data: (detail) {
        if (detail != null) {
          return DetailDisplay(detail: detail);
        }
        // Fallback to widget.stamp if provider returns null
        if (widget.stamp case DetailResponse d) {
          return DetailDisplay(detail: d);
        } else if (widget.stamp is Response) {
          return ResponseDisplay(res: widget.stamp as Response);
        }
        return Text(
          'Baseline recorded',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppPadding.medium),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        // Fallback to widget.stamp on error
        if (widget.stamp case DetailResponse detail) {
          return DetailDisplay(detail: detail);
        } else if (widget.stamp is Response) {
          return ResponseDisplay(res: widget.stamp as Response);
        }
        return Text(
          'Error loading baseline',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}
