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

    // Get check-in path types to identify them
    final AsyncValue<List<ReviewItem>> checkins =
        ref.watch(reviewPaths(const ReviewPathsProps()));
    final Map<String, ReviewItem> reviewMap = {
      for (final item in checkins.valueOrNull ?? [])
        if (item.response != null) item.response!.id: item
    };
    final Set<String> checkinTypes =
        reviewMap.values.map((e) => e.type).toSet();

    if (available.isLoading) {
      return const SliverFillRemaining(child: LoadingWidget());
    }

    if (available.valueOrNull!.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.only(top: AppPadding.xl),
      );
    }

    final List<Response> availableStamps = available.valueOrNull ?? [];

    // Use SliverGrid for medium and large screens
    if (MediaQuery.of(context).size.width > Breakpoint.medium.value) {
      if (!daysSeparated) {
        return _buildDesktopGrid(
            context, availableStamps, checkinTypes, reviewMap);
      }

      return SliverPadding(
        padding: const EdgeInsets.only(
            left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
        sliver: _buildAdaptiveGrid(context, ref, availableStamps,
            symptomsGrouping, checkinTypes, reviewMap),
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
      checkinTypes,
      reviewMap,
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

  Widget _buildDesktopGrid(BuildContext context, List<Response> stamps,
      Set<String> checkinTypes, Map<String, ReviewItem> reviewMap) {
    // Separate reviews and events
    final List<Response> reviews = [];
    final List<Response> events = [];

    for (final stamp in stamps) {
      if (checkinTypes.contains(stamp.type)) {
        reviews.add(stamp);
      } else {
        events.add(stamp);
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.only(
          left: AppPadding.xl, right: AppPadding.xl, bottom: AppPadding.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (reviews.isNotEmpty) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.medium),
                  child: _ReviewSection(
                    responses: reviews,
                    reviewMap: reviewMap,
                  ),
                );
              }

              index -= 1;
            }

            final double screenWidth = MediaQuery.of(context).size.width;

            int crossAxisCount = (screenWidth / 400).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;

            if (crossAxisCount > 4) crossAxisCount = 4;

            final int rowIndex = index;
            final int startIndex = rowIndex * crossAxisCount;

            if (startIndex >= events.length) return null;

            final int endIndex = (startIndex + crossAxisCount < events.length)
                ? startIndex + crossAxisCount
                : events.length;

            final List<Response> rowItems =
                events.sublist(startIndex, endIndex);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.small),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < rowItems.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppPadding.small),
                    Expanded(
                      child: EntryDisplay(event: rowItems[i]),
                    ),
                  ],
                  for (int i = 0; i < crossAxisCount - rowItems.length; i++)
                    const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdaptiveGrid(
    BuildContext context,
    WidgetRef ref,
    List<Response> stamps,
    bool groupSymptoms,
    Set<String> checkinTypes,
    Map<String, ReviewItem> reviewMap,
  ) {
    final Map<DateTime, List<Response>> eventsByDay = {};
    final List<Response> allReviews = [];

    for (final Response response in stamps) {
      final DateTime responseDate = dateFromStamp(response.stamp);
      final DateTime day =
          DateTime(responseDate.year, responseDate.month, responseDate.day);

      if (checkinTypes.contains(response.type)) {
        allReviews.add(response);
      } else {
        if (eventsByDay.containsKey(day)) {
          eventsByDay[day]!.add(response);
        } else {
          eventsByDay[day] = [response];
        }
      }
    }

    // Combine keys
    final Set<DateTime> allKeys = eventsByDay.keys.toSet();
    final List<DateTime> keys = allKeys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    final List<Widget> slivers = [];

    // Feature all reviews
    if (allReviews.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppPadding.medium),
          child: _ReviewSection(
            responses: allReviews,
            reviewMap: reviewMap,
          ),
        ),
      ));
    }

    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final List<Response> dayEvents = eventsByDay[dateGroup] ?? [];

      // Add Header
      slivers.add(SliverToBoxAdapter(
        child: _HeaderItem(date: dateGroup, count: dayEvents.length)
            .build(context, ref),
      ));

      // Events Grid for this day
      if (dayEvents.isNotEmpty) {
        // Calculate grid item width based on screen size
        final double screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = (screenWidth / 400).ceil();
        if (crossAxisCount < 1) crossAxisCount = 1;

        const double spacing = AppPadding.small;
        const double totalPadding = AppPadding.xl * 2;
        final double availableWidth = screenWidth - totalPadding;
        final double itemWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppPadding.medium),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: dayEvents
                  .map((e) => ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: itemWidth),
                        child: EntryDisplay(event: e),
                      ))
                  .toList(),
            ),
          ),
        ));
      }

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
    Set<String> checkinTypes,
    Map<String, ReviewItem> reviewMap,
  ) {
    final Map<DateTime, List<Response>> eventsByDay = {};
    final List<Response> allReviews = [];

    for (final Response response in stamps) {
      final DateTime responseDate = dateFromStamp(response.stamp);
      final DateTime day =
          DateTime(responseDate.year, responseDate.month, responseDate.day);

      if (checkinTypes.contains(response.type)) {
        allReviews.add(response);
      } else {
        if (eventsByDay.containsKey(day)) {
          eventsByDay[day]!.add(response);
        } else {
          eventsByDay[day] = [response];
        }
      }
    }

    final Set<DateTime> allKeys = eventsByDay.keys.toSet();
    final List<DateTime> keys = allKeys.toList()
      ..sort((a, b) => b.compareTo(a));
    final List<_GridItem> items = [];

    // Feature all check-ins
    if (allReviews.isNotEmpty) {
      for (final r in allReviews) {
        final ReviewItem? item = reviewMap[r.id];
        final String? dateLabel =
            item?.path.period!.getRangeString(dateFromStamp(r.stamp), context);
        items.add(
            _ResponseItem(response: r, isReview: true, dateLabel: dateLabel));
      }
    }

    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final List<Response> dayEvents = eventsByDay[dateGroup] ?? [];

      // Add Header
      items.add(_HeaderItem(date: dateGroup, count: dayEvents.length));

      // Add Content
      if (groupSymptoms) {
        // Group by type (only for events, reviews usually distinct)
        Map<String, List<Response>> byType = {};
        for (final Response response in dayEvents) {
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
        for (final response in dayEvents) {
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

class _ReviewSection extends StatelessWidget {
  final List<Response> responses;
  final Map<String, ReviewItem> reviewMap;

  const _ReviewSection({required this.responses, required this.reviewMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRounding.medium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppPadding.small),
              Text(
                "Completed Check-ins",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          LayoutBuilder(builder: (context, constraints) {
            final double width = constraints.maxWidth;
            // logic matching grid
            int crossAxisCount = (width / 400).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;

            return Wrap(
              spacing: AppPadding.small,
              runSpacing: AppPadding.small,
              children: responses.map((e) {
                final ReviewItem? item = reviewMap[e.id];
                final String? dateLabel = item?.path.period!
                    .getRangeString(dateFromStamp(e.stamp), context);

                final double itemWidth =
                    (width - (AppPadding.small * (crossAxisCount - 1))) /
                        crossAxisCount;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: itemWidth),
                  child: EntryDisplay(
                      event: e, isReview: true, dateLabel: dateLabel),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
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
  final bool isReview;
  final String? dateLabel;

  const _ResponseItem(
      {required this.response, this.isReview = false, this.dateLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: EntryDisplay(
          event: response, isReview: isReview, dateLabel: dateLabel),
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
