import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

const String types = "types";
const String groups = "groups";

final setsProvider = FutureProvider.autoDispose((ref) async {
  final List<Response> stamps = (await ref.watch(stampHolderProvider.future))
      .whereType<Response>()
      .toList();

  final Map<String, Set<String>> values = {types: {}, groups: {}};

  for (Response res in stamps) {
    values[types]!.add(res.type);
    if (res.group != null) {
      values[groups]!.add(res.group!);
    }
  }

  return values;
});

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _FilterSheetState();
  }
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  final Set<String> selectedTypes = {};

  @override
  void initState() {
    final DisplayDataSettings filters = ref.read(displayDataProvider);
    selectedTypes.addAll(filters.filters.map((filter) => filter.name).toList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<String, Set<String>>> availible =
        ref.watch(setsProvider);

    if (availible.isLoading) {
      return const LoadingWidget();
    }

    final Set<String> availibleTypes =
        (availible.valueOrNull ?? {})[types] ?? {};

    final Set<String> availibleGroups =
        (availible.valueOrNull ?? {})[groups] ?? {};

    void apply() {
      final List<LabeledFilter> typeFilters = selectedTypes.map((type) {
        if (availibleTypes.contains(type)) {
          return LabeledFilter(
              name: type,
              filter: (stamp) => stamp.type == type,
              filterClass: type);
        }
        return LabeledFilter(
            name: type,
            filter: (stamp) => stamp.group == type,
            filterClass: groups);
      }).toList();

      ref.read(displayDataProvider.notifier).updateFilters(typeFilters);
      Navigator.of(context).pop();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium, vertical: AppPadding.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: AppPadding.small),
                  FilledButton(
                    onPressed: () {
                      apply();
                    },
                    child: const Text("Apply"),
                  ),
                ],
              )
            ],
          ),
          const Divider(),
          const SizedBox(
            height: AppPadding.tiny,
          ),
          if (availibleTypes.length > 1) ...[
            Text(
              context.translate.eventFilterTypesTag,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: AppPadding.tiny,
            ),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: AppPadding.tiny,
              runSpacing: AppPadding.tiny,
              children: availibleTypes.map((type) {
                final bool selected = selectedTypes.contains(type);
                return ChoiceChip(
                  padding: const EdgeInsets.all(AppPadding.tiny),
                  label: Text(
                    type,
                  ),
                  showCheckmark: false,
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedTypes.add(type);
                      } else {
                        selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(
              height: AppPadding.tiny,
            ),
            if (availibleGroups.isNotEmpty) ...[
              Text(
                "Study",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: AppPadding.tiny,
              ),
              Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: AppPadding.tiny,
                runSpacing: AppPadding.tiny,
                children: availibleGroups.map((type) {
                  final bool selected = selectedTypes.contains(type);
                  return ChoiceChip(
                    padding: const EdgeInsets.all(AppPadding.tiny),
                    label: Text(
                      type,
                    ),
                    showCheckmark: false,
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
