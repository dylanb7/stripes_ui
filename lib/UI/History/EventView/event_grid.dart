import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class EventGrid extends ConsumerWidget {
  final bool daysSeparated;

  const EventGrid({this.daysSeparated = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool symptomsGrouping = ref.watch(
        displayDataProvider.select((settings) => settings.groupSymptoms));
    final AsyncValue<List<Response>> available =
        ref.watch(availableStampsProvider);

    // Get check-in path types to filter them out
    final AsyncValue<List<ReviewItem>> checkins =
        ref.watch(reviewPaths(const ReviewPathsProps()));
    final Set<String> checkinTypes =
        checkins.valueOrNull?.map((item) => item.type).toSet() ?? {};

    if (available.isLoading) {
      return const SliverFillRemaining(child: LoadingWidget());
    }

    if (available.valueOrNull!.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.only(top: AppPadding.xl),
      );
    }

    // Filter out check-in entries
    final List<Response> availableStamps = (available.valueOrNull ?? [])
        .where((response) => !checkinTypes.contains(response.type))
        .toList();

    // Use SliverGrid for large screens
    if (MediaQuery.of(context).size.width > Breakpoint.large.value) {
      if (!daysSeparated) {
        return SliverPadding(
          padding: const EdgeInsets.only(
              left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 180,
              crossAxisSpacing: AppPadding.small,
              mainAxisSpacing: AppPadding.small,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => EntryDisplay(event: availableStamps[index]),
              childCount: availableStamps.length,
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.only(
            left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
        sliver:
            _buildAdaptiveGrid(context, ref, availableStamps, symptomsGrouping),
      );
    }

    if (!daysSeparated) {
      return SliverPadding(
        padding: const EdgeInsets.only(
            left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
        sliver: RenderEntryGroupSliver(
            responses: availableStamps, grouped: symptomsGrouping),
      );
    }

    // Flatten the list into lightweight data items
    final List<_GridItem> items = _buildGridItems(
      context,
      availableStamps,
      symptomsGrouping,
    );

    return SliverPadding(
      padding: const EdgeInsets.only(
          left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return item.build(context, ref);
        },
      ),
    );
  }

  Widget _buildAdaptiveGrid(
    BuildContext context,
    WidgetRef ref,
    List<Response> stamps,
    bool groupSymptoms,
  ) {
    final Map<DateTime, List<Response>> questionsByDay = {};
    for (final Response response in stamps) {
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
    final List<Widget> slivers = [];

    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final List<Response> daySymptoms = questionsByDay[dateGroup]!;

      // Add Header
      slivers.add(SliverToBoxAdapter(
        child: _HeaderItem(date: dateGroup, count: daySymptoms.length)
            .build(context, ref),
      ));

      // Calculate grid item width based on screen size
      int crossAxisCount = (MediaQuery.of(context).size.width / 400).ceil();
      if (crossAxisCount < 1) crossAxisCount = 1;

      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppPadding.medium),
          child: Wrap(
            spacing: AppPadding.small,
            runSpacing: AppPadding.small,
            children: daySymptoms
                .map((e) => SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              AppPadding.xl * 2 -
                              AppPadding.small * (crossAxisCount - 1)) /
                          crossAxisCount,
                      child: EntryDisplay(event: e),
                    ))
                .toList(),
          ),
        ),
      ));

      // Add Divider if not last day
      if (i < keys.length - 1) {
        slivers.add(const SliverToBoxAdapter(
          child: Divider(
            height: AppPadding.xxl,
          ),
        ));
      }
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  List<_GridItem> _buildGridItems(
    BuildContext context,
    List<Response> stamps,
    bool groupSymptoms,
  ) {
    final Map<DateTime, List<Response>> questionsByDay = {};
    for (final Response response in stamps) {
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
    final List<_GridItem> items = [];

    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final List<Response> daySymptoms = questionsByDay[dateGroup]!;

      // Add Header
      items.add(_HeaderItem(date: dateGroup, count: daySymptoms.length));

      // Add Content
      if (groupSymptoms) {
        // Group by type
        Map<String, List<Response>> byType = {};
        for (final Response response in daySymptoms) {
          if (byType.containsKey(response.type)) {
            byType[response.type]!.add(response);
          } else {
            byType[response.type] = [response];
          }
        }
        for (final type in byType.keys) {
          items.add(_GroupedItem(
            type: type,
            responses: byType[type]!,
          ));
        }
      } else {
        // Flat list of responses
        for (final response in daySymptoms) {
          items.add(_ResponseItem(response: response));
        }
      }

      // Add Divider if not last day
      if (i < keys.length - 1) {
        items.add(const _DividerItem());
      }
    }

    return items;
  }
}

sealed class _GridItem {
  const _GridItem();
  Widget build(BuildContext context, WidgetRef ref);
}

class _HeaderItem extends _GridItem {
  final DateTime date;
  final int count;

  const _HeaderItem({required this.date, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateFormat headerFormat = date.year == DateTime.now().year
        ? DateFormat.MMMd()
        : DateFormat.yMMMd();

    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: AppPadding.tiny),
      child: RichText(
        text: TextSpan(
            text: headerFormat.format(date),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: " · ${context.translate.eventFilterResults(count)}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75)),
              )
            ]),
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _ResponseItem extends _GridItem {
  final Response response;

  const _ResponseItem({required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: EntryDisplay(event: response),
    );
  }
}

class _GroupedItem extends _GridItem {
  final String type;
  final List<Response> responses;

  const _GroupedItem({required this.type, required this.responses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: ExpandibleSymptomArea(
          header: RichText(
            text: TextSpan(
                text: localizations?.value(type) ?? type,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text:
                        " · ${context.translate.eventFilterResults(responses.length)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75)),
                  )
                ]),
            textAlign: TextAlign.left,
          ),
          responses: responses),
    );
  }
}

class _DividerItem extends _GridItem {
  const _DividerItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Divider(
      height: AppPadding.xxl,
    );
  }
}
