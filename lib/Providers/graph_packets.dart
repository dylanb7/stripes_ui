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
  severity("Severity"),
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
            ? range.start.add(const Duration(days: 7))
            : range.start.subtract(const Duration(days: 7));
        return DateTimeRange(
          start: newStart,
          end: newStart.add(
            const Duration(days: 7),
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
        return DateTimeRange(
          start: range.start.copyWith(year: range.start.year - 1),
          end: range.end.copyWith(year: range.end.year - 1),
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

  bool _canShift(bool forward, DateTimeRange range) {
    final DateTime minDate = SigDates.minDate;
    if (forward) return range.end.isAfter(minDate);
    return range.start.isBefore(DateTime.now());
  }

  GraphSettings shift(bool forward) {
    DateTimeRange newRange = _calculateNewRange(forward);
    if (!_canShift(forward, newRange)) return this;
    return copyWith(range: newRange);
  }

  @override
  List<Object?> get props => [range, span, axis];
}

final graphSettingsProvider = StateProvider.autoDispose<GraphSettings>(
  (ref) => GraphSettings.from(span: GraphSpan.week, axis: GraphYAxis.frequency),
);

final graphStampsProvider =
    FutureProvider.autoDispose<Map<String, List<Response>>>((ref) async {
  final GraphSettings settings = ref.watch(graphSettingsProvider);
  final List<Response> responses = (await ref.watch(stampHolderProvider.future))
      .whereType<Response>()
      .toList();
  final Map<String, List<Response>> byType = {};
  final Map<String, List<Response>> byQuestion = {};
  for (final Response wrappedResponse in responses) {
    if (!settings.range.contains(dateFromStamp(wrappedResponse.stamp))) {
      continue;
    }
    List<Response> flattened = _flattenedResponse(wrappedResponse);
    if (settings.axis == GraphYAxis.severity) {
      flattened = flattened.whereType<NumericResponse>().toList();
    }
    for (final Response response in flattened) {
      if (byQuestion.containsKey(response.question.prompt)) {
        byQuestion[response.question.prompt]!.add(response);
      } else {
        byQuestion[response.question.prompt] = [response];
      }
      if (byType.containsKey(response.type)) {
        byType[response.type]!.add(response);
      } else {
        byType[response.type] = [response];
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
