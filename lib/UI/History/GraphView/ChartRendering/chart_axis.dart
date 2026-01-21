import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

abstract class ChartAxis<D> extends Equatable {
  final D? min;
  final D? max;
  final double? interval;
  final bool showing;

  const ChartAxis({
    this.min,
    this.max,
    this.interval,
    this.showing = true,
  });

  String format(D value);
  String formatFromDouble(double value) => format(value as D);
  double toDouble(D value);
  double? maxValue() => max != null ? toDouble(max as D) : null;
  double? minValue() => min != null ? toDouble(min as D) : null;

  double normalizeDouble(double value, double min, double max) {
    final range = max - min;
    if (range == 0) return 0.0;
    return (value - min) / range;
  }

  @override
  List<Object?> get props => [min, max, interval, showing];
}

class DateTimeAxis extends ChartAxis<DateTime> {
  final DateFormat formatter;

  const DateTimeAxis({
    super.min,
    super.max,
    super.interval,
    super.showing,
    required this.formatter,
  });

  @override
  String format(DateTime value) {
    return formatter.format(value);
  }

  @override
  double toDouble(DateTime value) {
    return value.millisecondsSinceEpoch.toDouble();
  }

  @override
  String formatFromDouble(double value) {
    // Guard against NaN, infinity, or values that would overflow DateTime
    if (!value.isFinite) return '';
    final ms = value.toInt();
    // DateTime can handle dates roughly between years -271821 and 275760
    // Use a safe range for milliseconds (roughly 1900-2100)
    const minMs = -2208988800000; // ~1900
    const maxMs = 4102444800000; // ~2100
    if (ms < minMs || ms > maxMs) return '';
    try {
      return format(DateTime.fromMillisecondsSinceEpoch(ms));
    } catch (_) {
      return '';
    }
  }
}

class NumberAxis extends ChartAxis<num> {
  final NumberFormat? formatter;

  const NumberAxis({
    super.min,
    super.max,
    super.showing,
    super.interval,
    this.formatter,
  });

  @override
  String format(num value) {
    return formatter?.format(value) ?? value.toString();
  }

  @override
  double toDouble(num value) {
    return value.toDouble();
  }

  @override
  String formatFromDouble(double value) => format(value);
}

class SqrtNumberAxis extends NumberAxis {
  const SqrtNumberAxis({
    super.min,
    super.max,
    super.showing,
    super.interval,
    super.formatter,
  });

  @override
  double normalizeDouble(double value, double min, double max) {
    // Ensure we don't take sqrt of negative
    final v = value < 0 ? 0.0 : value;
    final mn = min < 0 ? 0.0 : min;
    final mx = max < 0 ? 0.0 : max;

    final range = sqrt(mx) - sqrt(mn);
    if (range == 0) return 0.0;
    return (sqrt(v) - sqrt(mn)) / range;
  }
}

class CategoryAxis extends ChartAxis<String> {
  final List<String> categories;

  const CategoryAxis({
    required this.categories,
    super.min,
    super.max,
    super.showing,
    super.interval,
  });

  @override
  String format(String value) {
    return value;
  }

  @override
  double toDouble(String value) {
    return categories.indexOf(value).toDouble();
  }

  @override
  String formatFromDouble(double value) {
    final index = value.round();
    if (index >= 0 && index < categories.length) {
      return format(categories[index]);
    }
    return '';
  }
}

class HourAxis extends ChartAxis<num> {
  const HourAxis({
    super.min = 0,
    super.max = 24,
    super.showing,
    super.interval = 6.0,
  });

  @override
  String format(num value) {
    final int hour = value.toInt() % 24;
    final DateTime date = DateTime(0, 1, 1, hour);
    return DateFormat.j().format(date);
  }

  @override
  double toDouble(num value) {
    return value.toDouble();
  }

  @override
  String formatFromDouble(double value) => format(value);
}
