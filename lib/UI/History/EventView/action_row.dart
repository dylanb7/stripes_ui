import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'add_event.dart';
import 'export.dart';
import 'filter.dart';

class ActionRow extends ConsumerWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Filters filters = ref.watch(filtersProvider);
    final int results = ref.watch(availibleStampsProvider
        .select((value) => value.valueOrNull?.filteredVisible.length ?? 0));
    final double size = MediaQuery.of(context).size.width;

    final String range = filters.toRange(context);
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: min(450, size - 80.0),
          child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (range.isNotEmpty)
                        Text(
                          range,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      Text(
                        AppLocalizations.of(context)!
                            .eventFilterResults(results),
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      filters.selectedDate != null
                          ? const AddEvent()
                          : const FilterButton(),
                      const Spacer(),
                      const Export(),
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
