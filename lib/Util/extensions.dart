import 'package:flutter/material.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

extension Space on List<Widget> {
  List<Widget> spacedBy({required double space, Axis axis = Axis.vertical}) {
    final Iterable<Widget> expanded = expand((widget) => [
          widget,
          axis == Axis.horizontal
              ? SizedBox(
                  width: space,
                )
              : SizedBox(
                  height: space,
                )
        ]);
    return expanded.toList()..removeLast();
  }
}

extension Separated on Iterable<Widget> {
  List<Widget> separated({required Widget by, bool includeEnds = false}) {
    if (isEmpty) return [];
    final Iterable<Widget> expanded = expand((widget) => [widget, by]);
    if (includeEnds) return [by, ...expanded];
    return expanded.toList()..removeLast();
  }
}

extension CarouselExtensions on CarouselController {
  int? determineWeightedIndex(List<int> weights) {
    if (hasClients && position.hasViewportDimension && position.hasPixels) {
      final index = _calculateCarouselIndex(
          weights, position.viewportDimension, position.pixels);
      return index;
    }
    return null;
  }

  Future<void> animateToWeightedPage(List<int> weights, int index,
      {required Duration duration, required Curve curve}) async {
    if (hasClients && position.hasViewportDimension) {
      final offset =
          _calculateCarouselOffset(weights, position.viewportDimension, index);
      await animateTo(offset, duration: duration, curve: curve);
    }
  }

  int sum(Iterable<int> collection) =>
      collection.fold(0, (prev, current) => prev + current);

  int _calculateCarouselIndex(
      List<int> weights, double dimension, double pixels) {
    final relevantDimension = (dimension * (weights.first / sum(weights)));
    final index = (pixels / relevantDimension).round();
    return index;
  }

  double _calculateCarouselOffset(
      List<int> weights, double dimension, int index) {
    final relevantDimension = (dimension * (weights.first / sum(weights)));
    final pixels = relevantDimension * index;
    return pixels;
  }
}

extension Translate on BuildContext {
  AppLocalizations get translate => AppLocalizations.of(this)!;
}

extension Contains on DateTimeRange {
  bool contains(DateTime dateTime) {
    return (start.isBefore(dateTime) || start.isAtSameMomentAs(dateTime)) &&
        (end.isAfter(dateTime) || end.isAtSameMomentAs(dateTime));
  }
}

extension GroupBy<T> on Iterable<T> {
  Map<String, List<T>> groupBy(String Function(T) key) {
    final Map<String, List<T>> grouped = {};
    for (final T item in this) {
      final String groupKey = key(item);
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(item);
    }
    return grouped;
  }
}
