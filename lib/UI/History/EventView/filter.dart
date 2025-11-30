import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/display_data_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';

import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

class FilterView extends ConsumerWidget {
  const FilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DisplayDataSettings filters = ref.watch(displayDataProvider);
    final String range = filters.getRangeString(context);
    return Wrap(
      spacing: AppPadding.tiny,
      runSpacing: AppPadding.tiny,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        FilledButton(
          onPressed: () {
            ref.read(overlayProvider.notifier).state = CurrentOverlay(
              widget: _PopUpStyle(
                child: _FilterPopUp(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate.filterEventsButton,
              ),
              const SizedBox(
                width: AppPadding.tiny,
              ),
              const Icon(
                Icons.filter_list,
              ),
            ],
          ),
        ),
        if (false && range.isNotEmpty)
          RemoveChip(
              onPressed: () {
                // Range clearing logic if needed, but range is managed by DisplayDataProvider
              },
              text: range),
        ...filters.filters.map(
          (filter) => RemoveChip(
            onPressed: () {
              ref.read(displayDataProvider.notifier).updateFilters(
                  filters.filters.where((f) => f != filter).toList());
            },
            text: filter.name,
          ),
        )
      ],
    );
  }
}

class RemoveChip extends StatelessWidget {
  final VoidCallback onPressed;

  final String text;

  const RemoveChip({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      label: Text(text),
      icon: const Icon(Icons.close),
      style: Theme.of(context).filledButtonTheme.style?.copyWith(
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppPadding.tiny))),
      iconAlignment: IconAlignment.end,
    );
  }
}

class _FilterPopUp extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FilterPopUpState();
}

class _FilterPopUpState extends ConsumerState<_FilterPopUp> {
  Set<String> selectedTypes = {};

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
      return const _PopUpStyle(child: LoadingWidget());
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
      ref.read(overlayProvider.notifier).state = closedOverlay;
    }

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: AppPadding.xl,
              ),
              Text(
                context.translate.eventFilterHeader,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                  onPressed: () {
                    ref.read(overlayProvider.notifier).state = closedOverlay;
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 35,
                  ))
            ],
          ),
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
              height: AppPadding.small,
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
                height: AppPadding.small,
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
            /*
              Text(
                AppLocalizations.of(context)!.eventFiltersFromTag,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(
                height: 6.0,
              ),
              DateRangePicker(
                onSelection: (dateRange) {
                  if (dateRange != null) {
                    setState(() {
                      newRange = dateRange;
                    });
                  }
                },
                initialStart: newRange?.start,
                initialEnd: newRange?.end,
              ),*/
            const SizedBox(
              height: AppPadding.medium,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedTypes = {};
                      });
                    },
                    child: Text(
                      context.translate.eventFilterReset,
                    ),
                  ),
                ),
                const SizedBox(
                  width: AppPadding.medium,
                ),
                Expanded(
                  child: FilledButton(
                    child: Text(context.translate.eventFiltersApply),
                    onPressed: () {
                      apply();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: AppPadding.tiny,
            ),
          ],
        ]);
  }
}

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

class _PopUpStyle extends StatelessWidget {
  final Widget child;

  const _PopUpStyle({required this.child});

  @override
  Widget build(BuildContext context) {
    return OverlayBackdrop(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
          child: SingleChildScrollView(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRounding.small))),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppPadding.small,
                          horizontal: AppPadding.large),
                      child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
