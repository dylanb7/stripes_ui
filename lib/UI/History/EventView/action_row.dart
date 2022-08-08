import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';

import 'add_event.dart';
import 'export.dart';
import 'filter.dart';

class ActionRow extends ConsumerWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    HistoryLocation location = ref.watch(historyLocationProvider);
    Filters filters = ref.watch(filtersProvider);
    final double size = MediaQuery.of(context).size.width;
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: min(450, size - 80.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              location.day == DayChoice.day ||
                      (location.day == DayChoice.month &&
                          filters.selectedDate != null)
                  ? const AddEvent()
                  : const FilterButton(),
              const Spacer(),
              const Export(),
            ],
          ),
        ),
      ),
    );
  }
}
