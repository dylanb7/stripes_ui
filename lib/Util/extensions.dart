import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
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

  bool overlaps(DateTimeRange other) {
    return (start.isBefore(other.end) || start.isAtSameMomentAs(other.end)) &&
        (end.isAfter(other.start) || end.isAtSameMomentAs(other.start));
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

extension IntExtensions on int {
  int coerceAtMost(int max) {
    if (this > max) return max;
    return this;
  }

  int coerceAtLeast(int min) {
    if (this < min) return min;
    return this;
  }
}

extension MarkdownConfigTheme on MarkdownConfig {
  static MarkdownConfig fromTheme(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownConfig(configs: [
      H1Config(
        style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      H2Config(
        style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      H3Config(
        style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      H4Config(
        style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      H5Config(
        style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      H6Config(
        style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
      ),
      PConfig(
        textStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
      ),
      LinkConfig(
        style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ) ??
            TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
      ),
      if (isDark) ...[
        HrConfig.darkConfig,
        PreConfig.darkConfig,
        CodeConfig.darkConfig,
        BlockquoteConfig.darkConfig,
      ],
    ]);
  }
}

extension MarkdownThemeContext on BuildContext {
  MarkdownConfig get markdownConfig => MarkdownConfigTheme.fromTheme(this);
}


