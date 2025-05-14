import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class EventGrid extends ConsumerWidget {
  final bool daysSeparated;

  const EventGrid({this.daysSeparated = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool symptomsGrouping =
        ref.watch(filtersProvider.select((filters) => filters.groupSymptoms));
    final AsyncValue<List<Response>> available = ref.watch(
        availibleStampsProvider.select((value) => value.hasValue
            ? AsyncValue.data(value.valueOrNull!.filteredVisible)
            : const AsyncLoading<List<Response>>()));

    if (available.isLoading) {
      return const SliverToBoxAdapter(child: LoadingWidget());
    }

    if (available.valueOrNull!.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 25.0,
        ),
      );
    }

    final List<Response> availableStamps =
        (available.valueOrNull ?? []).reversed.toList();

    if (!daysSeparated) {
      return SliverPadding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        sliver: SliverToBoxAdapter(
          child: RenderEntryGroup(
              responses: availableStamps, grouped: symptomsGrouping),
        ),
      );
    }

    Map<DateTime, List<Response>> questionsByDay = {};
    for (final Response response in availableStamps) {
      final DateTime responseDate = dateFromStamp(response.stamp);
      final DateTime day =
          DateTime(responseDate.year, responseDate.month, responseDate.day);
      if (questionsByDay.containsKey(day)) {
        questionsByDay[day]!.add(response);
      } else {
        questionsByDay[day] = [response];
      }
    }

    final List<DateTime> keys = questionsByDay.keys.toList();
    List<Widget> components = [];
    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final DateFormat headerFormat = dateGroup.year == DateTime.now().year
          ? DateFormat.MMMd()
          : DateFormat.yMMMd();
      final List<Response> daySymptoms = questionsByDay[dateGroup]!;
      if (keys.length > 1) {
        components.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                    text: headerFormat.format(dateGroup),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text:
                            " · ${AppLocalizations.of(context)!.eventFilterResults(daySymptoms.length)}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.75)),
                      )
                    ]),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        );
      }
      components.add(
          RenderEntryGroup(responses: daySymptoms, grouped: symptomsGrouping));
      if (i < keys.length - 1) {
        components.add(
          const Divider(
            height: 32.0,
          ),
        );
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
            (context, index) => components[index],
            childCount: components.length),
      ),
    );
  }
}
