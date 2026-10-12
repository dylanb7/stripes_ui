import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';

void main() {
  occurrenceMetadataTests();
  final date = DateTime(2026, 10, 6);
  final now = DateTime(2026, 10, 7, 14, 30);

  test('exact time uses the selected date and preserves local clock time', () {
    const time = RecordTime(exactTime: TimeOfDay(hour: 9, minute: 42));

    expect(time.stampOn(date), DateTime(2026, 10, 6, 9, 42));
    final restored = RecordTime.fromEntry(_roundTrip(time, date));
    expect(restored.precision, RecordTimePrecision.exact);
    expect(restored.exactTime, time.exactTime);
    expect(restored.storagePrecision, TimeOfDayEntry.exact);
  });

  for (final part in RecordDayPart.values) {
    test('${part.name} survives an Entry JSON round trip', () {
      final time = RecordTime(
        exactTime: const TimeOfDay(hour: 10, minute: 30),
        precision: RecordTimePrecision.dayPart,
        dayPart: part,
      );
      final entry = _roundTrip(time, date);
      final restored = RecordTime.fromEntry(entry);

      expect(restored.precision, RecordTimePrecision.dayPart);
      expect(restored.dayPart, part);
      expect(entry.stamp.toLocal(), DateTime(2026, 10, 6, part.startHour));
      expect(entry.data[recordTimeField]['localDate'], '2026-10-06');
      expect(
        entry.data[recordTimeField]['utcOffsetMinutes'],
        time.stampOn(date).timeZoneOffset.inMinutes,
      );
    });
  }

  test('unknown time stays unknown through persistence', () {
    const time = RecordTime(
      exactTime: TimeOfDay(hour: 11, minute: 59),
      precision: RecordTimePrecision.unknown,
    );
    final entry = _roundTrip(time, date);

    expect(entry.timeOfDay, TimeOfDayEntry.notSure);
    expect(entry.stamp.toLocal(), date);
    expect(RecordTime.fromEntry(entry).precision, RecordTimePrecision.unknown);
  });

  test('legacy precision remains readable without additional metadata', () {
    for (final value in <TimeOfDayEntry?>[null, ...TimeOfDayEntry.values]) {
      final entry = Entry(
        subUserId: 'profile',
        stamp: DateTime(2026, 10, 6, 9, 42),
        entityType: InputCategory.event.name,
        data: const {},
        timeOfDay: value,
      );
      final time = RecordTime.fromEntry(entry);

      expect(time.storagePrecision, value ?? TimeOfDayEntry.exact);
      if (value == TimeOfDayEntry.night) {
        expect(time.dayPart, RecordDayPart.night);
      }
    }
  });

  test('future dates and exact clock times are rejected', () {
    const exact = RecordTime(exactTime: TimeOfDay(hour: 14, minute: 31));
    const unknown = RecordTime(
      exactTime: TimeOfDay(hour: 0, minute: 0),
      precision: RecordTimePrecision.unknown,
    );

    expect(exact.isValidFor(DateTime(2026, 10, 7), now), isFalse);
    expect(exact.isValidFor(date, now), isTrue);
    expect(unknown.isValidFor(DateTime(2026, 10, 8), now), isFalse);
    expect(unknown.isValidFor(DateTime(2026, 10, 7), now), isTrue);
  });

  test('approximate period must be selected and have started', () {
    const unspecified = RecordTime(
      exactTime: TimeOfDay(hour: 0, minute: 0),
      precision: RecordTimePrecision.dayPart,
    );

    expect(unspecified.isComplete, isFalse);
    expect(unspecified.isValidFor(date, now), isFalse);
    expect(
      unspecified
          .copyWith(dayPart: RecordDayPart.afternoon)
          .isValidFor(DateTime(2026, 10, 7), now),
      isTrue,
    );
    expect(
      unspecified
          .copyWith(dayPart: RecordDayPart.evening)
          .isValidFor(DateTime(2026, 10, 7), now),
      isFalse,
    );
  });

  test('study timing accepts only complete exact timestamps', () {
    const exact = RecordTime(exactTime: TimeOfDay(hour: 9, minute: 0));

    expect(exact.isValidFor(date, now, requiresExact: true), isTrue);
    for (final time in [
      exact.copyWith(precision: RecordTimePrecision.unknown),
      exact.copyWith(
        precision: RecordTimePrecision.dayPart,
        dayPart: RecordDayPart.morning,
      ),
    ]) {
      expect(time.isValidFor(date, now, requiresExact: true), isFalse);
    }
  });

  test('legacy response projection can retain precision for its readers', () {
    const time = RecordTime(
      exactTime: TimeOfDay(hour: 0, minute: 0),
      precision: RecordTimePrecision.dayPart,
      dayPart: RecordDayPart.earlyMorning,
    );
    final entry = _roundTrip(time, date);
    final response = DetailResponse(
      id: 'entry',
      detailType: 'Pain',
      stamp: entry.stamp.millisecondsSinceEpoch,
      responses: const [],
      description: 'A note',
    );
    final timed = TimedDetailResponse(response: response, entry: entry);

    expect(timed.id, response.id);
    expect(timed.stamp, response.stamp);
    expect(timed.description, response.description);
    expect(timed.recordTime.dayPart, RecordDayPart.earlyMorning);
    expect(hasApproximateRecordTime(timed), isTrue);
    expect(hasApproximateRecordTime(response), isFalse);
  });
}

Entry _roundTrip(RecordTime time, DateTime date) {
  final entry = Entry(
    id: 'entry',
    subUserId: 'profile',
    stamp: time.stampOn(date),
    entityType: InputCategory.event.name,
    timeOfDay: time.storagePrecision,
    data: {recordTimeField: time.toJson(date)},
  );
  return Entry.fromJson(jsonDecode(jsonEncode(entry.toJson())));
}

void occurrenceMetadataTests() {
  test(
    'saved local date survives a changed viewing zone for approximate entries',
    () {
      final day = DateTime(2026, 10, 6);
      const time = RecordTime(
        exactTime: TimeOfDay(hour: 0, minute: 0),
        precision: RecordTimePrecision.unknown,
      );
      final entry = _roundTrip(
        time,
        day,
      ).copyWith(stamp: DateTime(2026, 10, 5, 21));
      final child = NumericResponse(
        question: const Numeric(id: 'pain', prompt: 'Pain', type: 'GI'),
        response: 2,
        stamp: entry.stamp.millisecondsSinceEpoch,
      );
      final response = TimedDetailResponse(
        response: DetailResponse(
          id: 'entry',
          detailType: 'GI',
          stamp: entry.stamp.millisecondsSinceEpoch,
          responses: [child],
        ),
        entry: entry,
      );
      expect(occurrenceTimeForResponse(response), day);
      expect(occurrenceTimeForResponse(child), day);
      expect(
        occurrenceRangeForResponse(child),
        DateTimeRange(start: day, end: DateTime(2026, 10, 7)),
      );
      expect(entryForResponse(child), same(entry));
      expect(
        recordIdentityForResponse(child),
        recordIdentityForResponse(response),
      );
    },
  );

  test(
    'invalid saved dates fall back safely and exact instants remain exact',
    () {
      for (final invalid in ['2026-02-30', 'yesterday', 123]) {
        final entry = Entry(
          id: 'entry',
          subUserId: 'profile',
          stamp: DateTime(2026, 10, 6, 6),
          entityType: InputCategory.event.name,
          timeOfDay: TimeOfDayEntry.morning,
          data: {
            recordTimeField: {'localDate': invalid},
          },
        );
        expect(RecordTime.fromEntry(entry).localDate, isNull);
      }
      final date = DateTime(2026, 10, 6, 9, 42);
      const time = RecordTime(exactTime: TimeOfDay(hour: 9, minute: 42));
      final entry = _roundTrip(time, date);
      final response = TimedDetailResponse(
        response: DetailResponse(
          id: 'entry',
          detailType: 'GI',
          stamp: dateToStamp(date),
          responses: const [],
        ),
        entry: entry,
      );
      expect(occurrenceTimeForResponse(response), date);
      expect(occurrenceRangeForResponse(response), isNull);
    },
  );
}
