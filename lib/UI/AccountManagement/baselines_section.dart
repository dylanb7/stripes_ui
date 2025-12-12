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
                  _SectionHeader(
                    title: 'Completed',
                    count: stamps.length,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ...stamps.map((stamp) => _CompletedBaselineTile(
                        stamp: stamp,
                      )),
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime date = dateFromStamp(widget.stamp.stamp);
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
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRounding.tiny),
                ),
                child: Icon(
                  Icons.check,
                  color: colors.primary,
                ),
              ),
              title: Text(title),
              subtitle: Text(
                'Completed ${dateToMDY(date, context)}',
                style: TextStyle(color: colors.primary),
              ),
              trailing: IconButton(
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
            if (_expanded) ...[
              // Version selector
              versionsAsync.when(
                data: (versions) {
                  if (versions.length <= 1) {
                    return const SizedBox.shrink();
                  }

                  final int effectiveVersion =
                      effectiveVersionAsync.valueOrNull ??
                          versions.first.version;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.large,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Active Version:',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: AppPadding.small),
                        DropdownButton<int>(
                          value: effectiveVersion,
                          items: versions.map((v) {
                            final versionDate = dateFromStamp(v.stamp);
                            return DropdownMenuItem(
                              value: v.version,
                              child: Text(
                                'v${v.version} (${dateToMDY(versionDate, context)})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                          onChanged: (newVersion) {
                            if (newVersion != null) {
                              ref
                                  .read(baselineVersionPreferenceProvider
                                      .notifier)
                                  .setVersion(widget.stamp.type, newVersion);
                            }
                          },
                          underline: const SizedBox.shrink(),
                          isDense: true,
                        ),
                        const Spacer(),
                        if (ref
                                .read(baselineVersionPreferenceProvider)
                                .valueOrNull
                                ?.containsKey(widget.stamp.type) ==
                            true)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(baselineVersionPreferenceProvider
                                      .notifier)
                                  .clearVersion(widget.stamp.type);
                            },
                            child: Text(
                              'Use Latest',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: colors.primary),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.large,
                  right: AppPadding.large,
                  bottom: AppPadding.medium,
                ),
                child: _buildStampContent(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStampContent(BuildContext context) {
    if (widget.stamp case DetailResponse detail) {
      return DetailDisplay(detail: detail);
    } else if (widget.stamp is Response) {
      return ResponseDisplay(res: widget.stamp as Response);
    }

    return Text(
      'Baseline recorded',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
