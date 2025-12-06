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
  double toDouble(D value);
  double? maxValue() => max != null ? toDouble(max as D) : null;
  double? minValue() => min != null ? toDouble(min as D) : null;

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
}
