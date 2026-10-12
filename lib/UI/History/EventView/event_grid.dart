import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/date_header.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class EventGrid extends ConsumerWidget {
  final bool daysSeparated;

  const EventGrid({this.daysSeparated = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool symptomsGrouping = ref.watch(
      displayDataProvider.select((settings) => settings.groupSymptoms),
    );
    final AsyncValue<List<Response>> available = ref.watch(
      availableStampsProvider,
    );

    final AsyncValue<List<ReviewItem>> checkins = ref.watch(
      reviewPaths(const ReviewPathsProps()),
    );
    final Map<String, ReviewItem> reviewMap = {
      for (final item in checkins.value ?? [])
        if (item.response != null) item.response!.id: item,
    };
    final Set<String> checkinTypes = reviewMap.values
        .map((e) => e.type)
        .toSet();

    if (available.isLoading && !available.hasValue) {
      return const SliverFillRemaining(child: LoadingWidget());
    }

    if (available.hasError && !available.hasValue) {
      return SliverFillRemaining(
        child: Center(child: Text('Unable to load events: ${available.error}')),
      );
    }

    if (checkins.hasError && !checkins.hasValue) {
      return SliverFillRemaining(
        child: Center(
          child: Text('Unable to load review paths: ${checkins.error}'),
        ),
      );
    }

    final List<Response> availableStamps = available.value ?? const [];
    if (availableStamps.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.only(top: AppPadding.xl));
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 400).floor();
    if (crossAxisCount < 1) crossAxisCount = 1;
    if (crossAxisCount > 4) crossAxisCount = 4;
    // Single-column entries own their inset, allowing compact backgrounds to
    // span the viewport while keeping card and text alignment unchanged.
    final horizontalInset = crossAxisCount == 1 ? AppPadding.xl : 0.0;
    final gridPadding = EdgeInsets.only(
      left: crossAxisCount == 1 ? 0 : AppPadding.xl,
      right: crossAxisCount == 1 ? 0 : AppPadding.xl,
      bottom: AppPadding.xl,
    );

    if (!daysSeparated) {
      final List<Response> reviews = [];
      final List<Response> events = [];

      for (final stamp in availableStamps) {
        if (checkinTypes.contains(stamp.type)) {
          reviews.add(stamp);
        } else {
          events.add(stamp);
        }
      }

      final List<_GridItem> flatItems = [];

      if (reviews.isNotEmpty) {
        flatItems.add(const _ReviewHeaderItem());
        if (crossAxisCount > 1) {
          for (int j = 0; j < reviews.length; j += crossAxisCount) {
            flatItems.add(
              _ReviewRowItem(
                responses: reviews.sublist(
                  j,
                  j + crossAxisCount > reviews.length
                      ? reviews.length
                      : j + crossAxisCount,
                ),
                crossAxisCount: crossAxisCount,
                reviewMap: reviewMap,
              ),
            );
          }
        } else {
          for (final r in reviews) {
            flatItems.add(
              _ResponseItem(
                response: r,
                isReview: true,
                dateLabel: reviewMap[r.id]?.path.period!.getRangeString(
                  dateFromStamp(r.stamp),
                  context,
                ),
              ),
            );
          }
        }
        flatItems.add(const _DividerItem());
      }

      if (symptomsGrouping) {
        Map<String, List<Response>> byType = {};
        for (final Response response in events) {
          if (byType.containsKey(response.type)) {
            byType[response.type]!.add(response);
          } else {
            byType[response.type] = [response];
          }
        }
        final List<String> typeKeys = byType.keys.toList();
        for (final type in typeKeys) {
          flatItems.add(_GroupedItem(type: type, responses: byType[type]!));
        }
      } else {
        if (crossAxisCount > 1) {
          for (int j = 0; j < events.length; j += crossAxisCount) {
            flatItems.add(
              _RowItem(
                responses: events.sublist(
                  j,
                  j + crossAxisCount > events.length
                      ? events.length
                      : j + crossAxisCount,
                ),
                crossAxisCount: crossAxisCount,
              ),
            );
          }
        } else {
          for (final r in events) {
            flatItems.add(_ResponseItem(response: r));
          }
        }
      }

      return SliverPadding(
        padding: gridPadding,
        sliver: SliverList.builder(
          itemCount: flatItems.length,
          itemBuilder: (context, index) => flatItems[index].build(
            context,
            ref,
            horizontalInset: horizontalInset,
          ),
        ),
      );
    }

    final List<Widget> sliverGroups = _buildSliverGroups(
      context,
      ref,
      availableStamps,
      symptomsGrouping,
      checkinTypes,
      reviewMap,
      crossAxisCount,
      horizontalInset,
    );

    return SliverPadding(
      padding: gridPadding,
      sliver: SliverMainAxisGroup(slivers: sliverGroups),
    );
  }

  List<Widget> _buildSliverGroups(
    BuildContext context,
    WidgetRef ref,
    List<Response> stamps,
    bool groupSymptoms,
    Set<String> checkinTypes,
    Map<String, ReviewItem> reviewMap,
    int crossAxisCount,
    double horizontalInset,
  ) {
    final Map<DateTime, List<Response>> eventsByDay = {};
    final List<Response> allReviews = [];

    for (final Response response in stamps) {
      final DateTime responseDate = dateFromStamp(response.stamp);
      final DateTime day = DateTime(
        responseDate.year,
        responseDate.month,
        responseDate.day,
      );

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
    final List<Widget> sliverGroups = [];

    // Feature all check-ins
    if (allReviews.isNotEmpty) {
      final List<Widget> groupSlivers = [];
      groupSlivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.medium + horizontalInset,
              vertical: AppPadding.small,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppPadding.small),
                Text(
                  "Completed Check-ins",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final List<_GridItem> reviewItems = [];
      if (crossAxisCount > 1) {
        for (int j = 0; j < allReviews.length; j += crossAxisCount) {
          reviewItems.add(
            _ReviewRowItem(
              responses: allReviews.sublist(
                j,
                j + crossAxisCount > allReviews.length
                    ? allReviews.length
                    : j + crossAxisCount,
              ),
              crossAxisCount: crossAxisCount,
              reviewMap: reviewMap,
            ),
          );
        }
      } else {
        for (final r in allReviews) {
          final ReviewItem? item = reviewMap[r.id];
          final String? dateLabel = item?.path.period!.getRangeString(
            dateFromStamp(r.stamp),
            context,
          );
          reviewItems.add(
            _ResponseItem(response: r, isReview: true, dateLabel: dateLabel),
          );
        }
      }

      groupSlivers.add(
        SliverList.builder(
          itemCount: reviewItems.length,
          itemBuilder: (context, index) => reviewItems[index].build(
            context,
            ref,
            horizontalInset: horizontalInset,
          ),
        ),
      );

      groupSlivers.add(
        SliverToBoxAdapter(
          child: const _DividerItem().build(
            context,
            ref,
            horizontalInset: horizontalInset,
          ),
        ),
      );

      sliverGroups.add(SliverMainAxisGroup(slivers: groupSlivers));
    }

    for (int i = 0; i < keys.length; i++) {
      final DateTime dateGroup = keys[i];
      final List<Response> dayEvents = eventsByDay[dateGroup] ?? [];
      final List<Widget> groupSlivers = [];

      // Add Header
      groupSlivers.add(
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverPersistentHeader(
            pinned: true,
            delegate: DateHeaderDelegate.measured(
              context: context,
              width: constraints.crossAxisExtent,
              date: dateGroup,
              eventCount: dayEvents.length,
              horizontalInset: horizontalInset,
            ),
          ),
        ),
      );

      final List<_GridItem> dayItems = [];
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
          dayItems.add(_GroupedItem(type: type, responses: byType[type]!));
        }
      } else {
        // Flat list of responses
        if (crossAxisCount > 1) {
          for (int j = 0; j < dayEvents.length; j += crossAxisCount) {
            dayItems.add(
              _RowItem(
                responses: dayEvents.sublist(
                  j,
                  j + crossAxisCount > dayEvents.length
                      ? dayEvents.length
                      : j + crossAxisCount,
                ),
                crossAxisCount: crossAxisCount,
              ),
            );
          }
        } else {
          for (final response in dayEvents) {
            dayItems.add(_ResponseItem(response: response));
          }
        }
      }

      groupSlivers.add(
        SliverList.builder(
          itemCount: dayItems.length,
          itemBuilder: (context, index) => dayItems[index].build(
            context,
            ref,
            horizontalInset: horizontalInset,
          ),
        ),
      );

      // Add Divider if not last day
      if (i < keys.length - 1) {
        groupSlivers.add(
          SliverToBoxAdapter(
            child: const _DividerItem().build(
              context,
              ref,
              horizontalInset: horizontalInset,
            ),
          ),
        );
      }

      sliverGroups.add(
        SliverMainAxisGroup(key: ValueKey(dateGroup), slivers: groupSlivers),
      );
    }

    return sliverGroups;
  }
}

sealed class _GridItem {
  const _GridItem();
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  });
}

class _ResponseItem extends _GridItem {
  final Response response;
  final bool isReview;
  final String? dateLabel;

  const _ResponseItem({
    required this.response,
    this.isReview = false,
    this.dateLabel,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    return Padding(
      key: ValueKey(response.id ?? '${response.type}-${response.stamp}'),
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: RepaintBoundary(
        child: EntryDisplay(
          key: ValueKey(response.id ?? '${response.type}-${response.stamp}'),
          event: response,
          horizontalInset: horizontalInset,
          isReview: isReview,
          dateLabel: dateLabel,
        ),
      ),
    );
  }
}

class _GroupedItem extends _GridItem {
  final String type;
  final List<Response> responses;

  const _GroupedItem({required this.type, required this.responses});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: ExpandibleSymptomArea(
        horizontalInset: horizontalInset,
        header: Text.rich(
          TextSpan(
            text: localizations?.value(type) ?? type,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text:
                    " · ${context.translate.historyEntryCount(responses.length)}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.left,
        ),
        responses: responses,
      ),
    );
  }
}

class _DividerItem extends _GridItem {
  const _DividerItem();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: const Divider(height: AppPadding.xxl),
    );
  }
}

class _RowItem extends _GridItem {
  final List<Response> responses;
  final int crossAxisCount;

  const _RowItem({required this.responses, required this.crossAxisCount});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int k = 0; k < responses.length; k++) ...[
            if (k > 0) const SizedBox(width: AppPadding.small),
            Expanded(
              child: RepaintBoundary(child: EntryDisplay(event: responses[k])),
            ),
          ],
          for (int k = 0; k < crossAxisCount - responses.length; k++) ...[
            if (responses.isNotEmpty || k > 0)
              const SizedBox(width: AppPadding.small),
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}

class _ReviewRowItem extends _GridItem {
  final List<Response> responses;
  final int crossAxisCount;
  final Map<String, ReviewItem> reviewMap;

  const _ReviewRowItem({
    required this.responses,
    required this.crossAxisCount,
    required this.reviewMap,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int k = 0; k < responses.length; k++) ...[
            if (k > 0) const SizedBox(width: AppPadding.small),
            Expanded(
              child: RepaintBoundary(
                child: EntryDisplay(
                  event: responses[k],
                  isReview: true,
                  dateLabel: reviewMap[responses[k].id]?.path.period!
                      .getRangeString(
                        dateFromStamp(responses[k].stamp),
                        context,
                      ),
                ),
              ),
            ),
          ],
          for (int k = 0; k < crossAxisCount - responses.length; k++) ...[
            if (responses.isNotEmpty || k > 0)
              const SizedBox(width: AppPadding.small),
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}

class _ReviewHeaderItem extends _GridItem {
  const _ReviewHeaderItem();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref, {
    double horizontalInset = 0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.medium + horizontalInset,
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppPadding.small),
          Text(
            "Completed Check-ins",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
