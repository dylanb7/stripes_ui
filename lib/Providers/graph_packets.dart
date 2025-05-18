import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/Util/extensions.dart';

enum GraphYAxis {
  frequency("Frequency"),
  average("Average"),
  entrytime("Time");

  final String value;

  const GraphYAxis(this.value);
}

enum GraphSpan {
  day("Day"),
  week("Week"),
  month("Month"),
  year("Year");

  final String value;

  const GraphSpan(this.value);

  DateFormat getFormat() {
    switch (this) {
      case GraphSpan.day:
        return DateFormat.j();
      case GraphSpan.week:
        return DateFormat.d();
      case GraphSpan.month:
        return DateFormat.d();
      case GraphSpan.year:
        return DateFormat.MMM();
    }
  }

  int getBuckets(DateTime current) {
    switch (this) {
      case GraphSpan.day:
        return 4;
      case GraphSpan.week:
        return 7;
      case GraphSpan.month:
        return DateTime(current.year, current.month + 1, 0).day;
      case GraphSpan.year:
        return 12;
    }
  }

  int getTitles() {
    switch (this) {
      case GraphSpan.day:
        return 4;
      case GraphSpan.week:
        return 7;
      case GraphSpan.month:
        return 6;
      case GraphSpan.year:
        return 12;
    }
  }
}

@immutable
class GraphSettings extends Equatable {
  final DateTimeRange range;
  final GraphSpan span;
  final GraphYAxis axis;

  const GraphSettings(
      {required this.range, required this.span, required this.axis});

  GraphSettings copyWith(
          {DateTimeRange? range, GraphSpan? span, GraphYAxis? axis}) =>
      GraphSettings(
          range: range ?? this.range,
          span: span ?? this.span,
          axis: axis ?? this.axis);

  factory GraphSettings.from(
      {required GraphSpan span, required GraphYAxis axis}) {
    final DateTime now = DateTime.now();
    switch (span) {
      case GraphSpan.day:
        final DateTime start = DateTime(now.year, now.month, now.day);
        return GraphSettings(
            range: DateTimeRange(
                start: start, end: start.add((const Duration(days: 1)))),
            span: span,
            axis: axis);
      case GraphSpan.week:
        final DateTime start =
            previous(DateTime(now.year, now.month, now.day), DateTime.monday);
        return GraphSettings(
            range: DateTimeRange(
                start: start, end: start.add((const Duration(days: 7)))),
            span: span,
            axis: axis);
      case GraphSpan.month:
        final DateTime start = DateTime(now.year, now.month);
        return GraphSettings(
            range: DateTimeRange(
                start: start, end: start.add(Duration(days: daysInMonth(now)))),
            span: span,
            axis: axis);
      case GraphSpan.year:
        return GraphSettings(
            range: DateTimeRange(
                start: DateTime(now.year),
                end: DateTime(now.year).add(const Duration(days: 365))),
            span: span,
            axis: axis);
    }
  }

  DateTimeRange _calculateNewRange(bool forward) {
    switch (span) {
      case GraphSpan.day:
        final DateTime newStart = forward
            ? range.start.add(const Duration(days: 1))
            : range.start.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: newStart,
          end: newStart.add(const Duration(days: 1)),
        );
      case GraphSpan.week:
        final DateTime newStart = forward
            ? range.start.add(const Duration(days: 6))
            : range.start.subtract(const Duration(days: 6));
        return DateTimeRange(
          start: newStart,
          end: newStart.add(
            const Duration(days: 6),
          ),
        );
      case GraphSpan.month:
        DateTime newStart;
        if (!forward) {
          if (range.start.month == 1) {
            newStart = DateTime(range.start.year - 1, 12);
          } else {
            newStart = DateTime(range.start.year, range.start.month - 1);
          }
        } else {
          if (range.start.month == 12) {
            newStart = DateTime(range.start.year + 1, 1);
          } else {
            newStart = DateTime(range.start.year, range.start.month + 1);
          }
        }

        return DateTimeRange(
          start: newStart,
          end: newStart.add(
            Duration(
              days: daysInMonth(newStart),
            ),
          ),
        );
      case GraphSpan.year:
        final DateTime newStart = forward
            ? DateTime(range.start.year + 1)
            : DateTime(range.start.year - 1);
        return DateTimeRange(
          start: newStart,
          end: newStart.copyWith(year: newStart.year + 1),
        );
    }
  }

  String getRangeString(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;

    final DateFormat yearFormat = DateFormat.yMMMd(locale);

    switch (span) {
      case GraphSpan.day:
        return yearFormat.format(range.start);
      case GraphSpan.week:
        final bool sameYear = range.end.year == range.start.year;
        final bool sameMonth = sameYear && range.end.month == range.start.month;
        final String firstPortion = sameYear
            ? DateFormat.MMMd(locale).format(range.start)
            : yearFormat.format(range.start);
        final String lastPortion = sameMonth
            ? '${DateFormat.d(locale).format(range.end)}, ${DateFormat.y(locale).format(range.end)}'
            : yearFormat.format(range.end);
        return '$firstPortion - $lastPortion';
      case GraphSpan.month:
        return DateFormat.yMMM(locale).format(range.start);
      case GraphSpan.year:
        return DateFormat.y(locale).format(range.start);
    }
  }

  bool canShift({required bool forward, DateTimeRange? range}) {
    DateTimeRange newRange = range ?? _calculateNewRange(forward);
    final DateTime minDate = SigDates.minDate;
    if (forward) return newRange.start.isBefore(DateTime.now());
    return newRange.end.isAfter(minDate);
  }

  GraphSettings shift(bool forward) {
    final DateTimeRange newRange = _calculateNewRange(forward);
    if (!canShift(forward: forward, range: newRange)) return this;
    return copyWith(range: newRange);
  }

  @override
  List<Object?> get props => [range, span, axis];
}

@immutable
class GraphKey extends Equatable {
  final bool isCategory;
  final String title;
  final String? qid;

  const GraphKey({required this.title, required this.isCategory, this.qid});

  @override
  String toString() {
    return "${isCategory ? "Category · " : ""} $title";
  }

  @override
  List<Object?> get props => [isCategory, title, qid];
}

final graphSettingsProvider = StateProvider.autoDispose<GraphSettings>(
  (ref) => GraphSettings.from(span: GraphSpan.week, axis: GraphYAxis.frequency),
);

final graphStampsProvider =
    FutureProvider.autoDispose<Map<GraphKey, List<Response>>>((ref) async {
  final GraphSettings settings = ref.watch(graphSettingsProvider);
  final List<Response> responses = (await ref.watch(stampHolderProvider.future))
      .whereType<Response>()
      .toList();
  final Map<GraphKey, List<Response>> byType = {};
  final Map<GraphKey, List<Response>> byQuestion = {};
  for (final Response wrappedResponse in responses) {
    if (!settings.range.contains(dateFromStamp(wrappedResponse.stamp))) {
      continue;
    }
    List<Response> flattened = _flattenedResponse(wrappedResponse);
    if (settings.axis == GraphYAxis.average) {
      flattened = flattened.whereType<NumericResponse>().toList();
    }
    for (final Response response in flattened) {
      final GraphKey key = GraphKey(
          title: response.question.prompt,
          isCategory: false,
          qid: response.question.id);
      if (byQuestion.containsKey(key)) {
        byQuestion[key]!.add(response);
      } else {
        byQuestion[key] = [response];
      }
      final GraphKey categoryKey = GraphKey(
        title: response.type,
        isCategory: true,
      );
      if (byType.containsKey(categoryKey)) {
        byType[categoryKey]!.add(response);
      } else {
        byType[categoryKey] = [response];
      }
    }
    /*if (flattened.isEmpty) {
      if (byType.containsKey(wrappedResponse.type)) {
        byType[wrappedResponse.type]!.add(wrappedResponse);
      } else {
        byType[wrappedResponse.type] = [wrappedResponse];
      }
    }*/
  }
  return byType..addAll(byQuestion);
});

List<Response> _flattenedResponses(Iterable<Response> input) {
  List<Response> flat = [];
  for (Response res in input) {
    if (res is DetailResponse) {
      flat.addAll(_flattenedResponses(res.responses));
    } else {
      flat.add(res);
    }
  }
  return flat;
}

List<Response> _flattenedResponse(Response input) {
  return _flattenedResponses([input]);
}
