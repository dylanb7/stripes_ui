import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

const recordTimeField = 'recordTime';
final _responseTimes = Expando<RecordTime>('recordTiming');
final _responseRecords = Expando<Object>('recordIdentity');
final _responseEntries = Expando<Entry>('recordEntry');

enum RecordTimePrecision { exact, dayPart, unknown }

enum RecordDayPart {
  earlyMorning(0, 6),
  morning(6, 12),
  afternoon(12, 18),
  evening(18, 21),
  night(21, 24);

  const RecordDayPart(this.startHour, this.endHour);
  final int startHour;
  final int endHour;

  String label(AppLocalizations strings) => switch (this) {
    earlyMorning => strings.recordEarlyMorning,
    morning => strings.recordMorning,
    afternoon => strings.recordAfternoon,
    evening => strings.recordEvening,
    night => strings.recordNight,
  };

  String range(BuildContext context) {
    final start = TimeOfDay(hour: startHour, minute: 0).format(context);
    final end = TimeOfDay(hour: endHour - 1, minute: 59).format(context);
    return '$start – $end';
  }
}

/// Timing is kept separately from question answers. The extra metadata preserves
/// the five PDF day parts without changing the backend's existing enum values.
@immutable
class RecordTime {
  final RecordTimePrecision precision;
  final TimeOfDay exactTime;
  final RecordDayPart? dayPart;

  /// The calendar date selected when recording, independent of the viewer's zone.
  final DateTime? localDate;

  const RecordTime({
    this.precision = RecordTimePrecision.exact,
    required this.exactTime,
    this.dayPart,
    this.localDate,
  });

  RecordTime copyWith({
    RecordTimePrecision? precision,
    TimeOfDay? exactTime,
    RecordDayPart? dayPart,
  }) => RecordTime(
    precision: precision ?? this.precision,
    exactTime: exactTime ?? this.exactTime,
    dayPart: dayPart ?? this.dayPart,
    localDate: localDate,
  );

  bool get isComplete =>
      precision != RecordTimePrecision.dayPart || dayPart != null;

  bool isValidFor(DateTime date, DateTime now, {bool requiresExact = false}) {
    if (!isComplete ||
        (requiresExact && precision != RecordTimePrecision.exact)) {
      return false;
    }
    if (DateUtils.dateOnly(date).isAfter(DateUtils.dateOnly(now))) return false;
    if (precision == RecordTimePrecision.unknown) return true;
    return !stampOn(date).isAfter(now);
  }

  /// Approximate timestamps are sorting anchors, never observed clock times.
  DateTime stampOn(DateTime date) =>
      DateTime(date.year, date.month, date.day, switch (precision) {
        RecordTimePrecision.exact => exactTime.hour,
        RecordTimePrecision.dayPart => dayPart?.startHour ?? 0,
        RecordTimePrecision.unknown => 0,
      }, precision == RecordTimePrecision.exact ? exactTime.minute : 0);

  TimeOfDayEntry get storagePrecision => switch (precision) {
    RecordTimePrecision.exact => TimeOfDayEntry.exact,
    RecordTimePrecision.unknown => TimeOfDayEntry.notSure,
    RecordTimePrecision.dayPart => switch (dayPart) {
      RecordDayPart.morning => TimeOfDayEntry.morning,
      RecordDayPart.afternoon => TimeOfDayEntry.afternoon,
      RecordDayPart.evening => TimeOfDayEntry.evening,
      RecordDayPart.earlyMorning ||
      RecordDayPart.night ||
      null => TimeOfDayEntry.night,
    },
  };

  Map<String, dynamic> toJson(DateTime date) => {
    'precision': precision.name,
    if (precision == RecordTimePrecision.dayPart) 'dayPart': dayPart?.name,
    'localDate': DateFormat('yyyy-MM-dd').format(date),
    'utcOffsetMinutes': stampOn(date).timeZoneOffset.inMinutes,
  };

  factory RecordTime.fromEntry(Entry entry) {
    final raw = entry.data[recordTimeField];
    final part = raw is Map ? raw['dayPart'] : null;
    RecordDayPart? dayPart;
    for (final candidate in RecordDayPart.values) {
      if (candidate.name == part) dayPart = candidate;
    }
    final precision = entry.timeOfDay ?? TimeOfDayEntry.exact;
    return RecordTime(
      exactTime: TimeOfDay.fromDateTime(entry.stamp.toLocal()),
      localDate: raw is Map ? _parseLocalDate(raw['localDate']) : null,
      precision: switch (precision) {
        TimeOfDayEntry.exact => RecordTimePrecision.exact,
        TimeOfDayEntry.notSure => RecordTimePrecision.unknown,
        _ => RecordTimePrecision.dayPart,
      },
      dayPart:
          dayPart ??
          switch (precision) {
            TimeOfDayEntry.morning => RecordDayPart.morning,
            TimeOfDayEntry.afternoon => RecordDayPart.afternoon,
            TimeOfDayEntry.evening => RecordDayPart.evening,
            TimeOfDayEntry.night => RecordDayPart.night,
            _ => null,
          },
    );
  }

  String label(BuildContext context, {bool includeRange = false}) {
    final strings = AppLocalizations.of(context)!;
    return switch (precision) {
      RecordTimePrecision.exact => exactTime.format(context),
      RecordTimePrecision.unknown => strings.recordTimeUnknown,
      RecordTimePrecision.dayPart =>
        dayPart == null
            ? strings.recordChoosePeriod
            : '${dayPart!.label(strings)}${includeRange ? ' (${dayPart!.range(context)})' : ''}',
    };
  }
}

/// Keeps precision attached when existing History/export code consumes the
/// backend's legacy response projection. Question definitions stay untouched.
class TimedDetailResponse extends DetailResponse {
  final Entry entry;
  RecordTime get recordTime => RecordTime.fromEntry(entry);

  TimedDetailResponse({required DetailResponse response, required this.entry})
    : super(
        id: response.id,
        group: response.group,
        linkingId: response.linkingId,
        stamp: response.stamp,
        detailType: response.type,
        description: response.description,
        responses: response.responses,
      ) {
    final Object recordIdentity = entry.id ?? Object();
    void attach(Response value) {
      _responseTimes[value] = recordTime;
      _responseRecords[value] = recordIdentity;
      _responseEntries[value] = entry;
      if (value is ResponseWrap) {
        for (final child in value.responses) {
          attach(child);
        }
      }
    }

    attach(this);
  }
}

bool hasApproximateRecordTime(Response response) =>
    recordTimeForResponse(response)?.precision != null &&
    recordTimeForResponse(response)!.precision != RecordTimePrecision.exact;

RecordTime? recordTimeForResponse(Response response) =>
    response is TimedDetailResponse
    ? response.recordTime
    : _responseTimes[response];

String? approximateRecordTimeLabel(Response response, BuildContext context) =>
    hasApproximateRecordTime(response)
    ? recordTimeForResponse(response)!.label(context)
    : null;

DateTime? _parseLocalDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || DateFormat('yyyy-MM-dd').format(parsed) != value) {
    return null;
  }
  return parsed;
}

/// Approximate timestamps are date/period anchors, never observed clock times.
DateTime occurrenceTimeForResponse(Response response) {
  final time = recordTimeForResponse(response);
  final stamp = dateFromStamp(response.stamp);
  if (time == null || time.precision == RecordTimePrecision.exact) return stamp;
  return time.stampOn(time.localDate ?? stamp);
}

/// The interval in which an approximately timed event may have occurred.
DateTimeRange? occurrenceRangeForResponse(Response response) {
  final time = recordTimeForResponse(response);
  if (time == null || time.precision == RecordTimePrecision.exact) return null;
  final date = occurrenceTimeForResponse(response);
  final part = time.precision == RecordTimePrecision.dayPart
      ? time.dayPart
      : null;
  return DateTimeRange(
    start: DateTime(date.year, date.month, date.day, part?.startHour ?? 0),
    end: DateTime(date.year, date.month, date.day, part?.endHour ?? 24),
  );
}

/// Children of a recording share its identity even when their timestamps match
/// another recording. Object identity keeps legacy entries without IDs distinct.
Object recordIdentityForResponse(Response response) =>
    _responseRecords[response] ??= response.id ?? Object();

Entry? entryForResponse(Response response) => response is TimedDetailResponse
    ? response.entry
    : _responseEntries[response];

/// Preserve recording identity when legacy wrappers are flattened for graphs.
/// This does not assign precision to records without timing metadata.
void attachRecordIdentity(Response response) {
  final identity = _responseRecords[response] ?? response.id ?? Object();
  void attach(Response current) {
    if (_responseEntries[current] == null) {
      _responseRecords[current] = identity;
    }
    if (current is ResponseWrap) {
      for (final child in current.responses) {
        attach(child);
      }
    }
  }

  attach(response);
}
