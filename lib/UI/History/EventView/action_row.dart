import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/config.dart';

import 'add_event.dart';
import '../Export/export.dart';

class ActionRow extends ConsumerWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final DisplayDataSettings filters = ref.watch(displayDataProvider);
    final int results = ref.watch(availableStampsProvider
        .select((available) => available.valueOrNull?.length ?? 0));
    ;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.translate.eventFilterResults(results),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
            const Row(children: [
              AddEvent(),
              Export(),
            ])
          ],
        ),
        /*Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              filters.getRangeString(context),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            ChoiceChip(
              label: Icon(
                Icons.layers,
                color: filters.groupSymptoms
                    ? Theme.of(context).canvasColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              selected: filters.groupSymptoms,
              showCheckmark: false,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (value) {
                ref
                    .read(displayDataProvider.notifier)
                    .updateGroupSymptoms(value);
              },
            )
          ],
        ),*/
        Divider(
          thickness: 1.5,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }
}
