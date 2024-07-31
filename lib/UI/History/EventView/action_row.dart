import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'add_event.dart';
import 'export.dart';

class ActionRow extends ConsumerWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int results = ref.watch(availibleStampsProvider
        .select((value) => value.valueOrNull?.filteredVisible.length ?? 0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.eventFilterResults(results),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Row(children: [
                AddEvent(),
                Export(
                  type: ExportType.perPage,
                ),
              ])
            ],
          ),
          Divider(
            thickness: 1.5,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}
