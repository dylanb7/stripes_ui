import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategoryAppearance {
  final IconData icon;
  final Color color;
  final String? svgAsset;

  const CategoryAppearance({
    required this.icon,
    required this.color,
    this.svgAsset,
  });
}

/// A category illustration, with a Material icon for custom categories.
///
/// SVG artwork retains its original colors unless [color] explicitly tints it.
/// Leave [semanticLabel] unset when adjacent text already names the category.
class CategoryIcon extends StatelessWidget {
  final CategoryAppearance appearance;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const CategoryIcon({
    required this.appearance,
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final asset = appearance.svgAsset;
    if (asset == null) {
      return Icon(
        appearance.icon,
        size: size,
        color: color ?? appearance.color,
        semanticLabel: semanticLabel,
      );
    }
    final dimension = size ?? IconTheme.of(context).size ?? 24;
    return SizedBox.square(
      dimension: dimension,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      ),
    );
  }
}

class CategoryTheme {
  CategoryTheme._();

  static const _assetDirectory =
      'packages/stripes_ui/assets/svg/category_themes';

  // Category accents match the primary fills in the bundled SVG artwork.
  static const Map<String, CategoryAppearance> _appearances = {
    'category.Meal-Time': CategoryAppearance(
      icon: Icons.restaurant_rounded,
      color: Color(0xFF496EA1),
      svgAsset: '$_assetDirectory/meal.svg',
    ),
    'category.PAIN': CategoryAppearance(
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: Color(0xFFA20000),
      svgAsset: '$_assetDirectory/pain.svg',
    ),
    'category.BM': CategoryAppearance(
      icon: Icons.wc_rounded,
      color: Color(0xFF84572F),
      svgAsset: '$_assetDirectory/bowel_movement.svg',
    ),
    'category.REFLUX': CategoryAppearance(
      icon: Icons.healing_rounded,
      color: Color(0xFFF28282),
      svgAsset: '$_assetDirectory/GI.svg',
    ),
    'category.NB': CategoryAppearance(
      icon: Icons.bedtime_rounded,
      color: Color(0xFFD4C900),
      svgAsset: '$_assetDirectory/sleep.svg',
    ),
    'category.SEIZURE_BASELINE': CategoryAppearance(
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF2E8B57),
    ),
    'category.SEIZURE_INTERIM': CategoryAppearance(
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF2E8B57),
    ),
  };

  static CategoryAppearance resolve(String typeName) {
    return _appearances[typeName] ?? _fallback(typeName);
  }

  static bool isKnown(String typeName) => _appearances.containsKey(typeName);

  static CategoryAppearance _fallback(String typeName) {
    return CategoryAppearance(
      icon: Icons.category_rounded,
      color: _hashColor(typeName),
    );
  }

  static Color _hashColor(String seed) {
    int hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final double h = (hash.abs() % 360).toDouble();
    final double s = 0.55 + ((hash.abs() % 20) / 100.0);
    final double l = 0.40 + ((hash.abs() % 15) / 100.0);
    return HSLColor.fromAHSL(1.0, h, s, l).toColor();
  }
}
