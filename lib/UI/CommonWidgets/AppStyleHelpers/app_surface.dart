import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Standardized surface container background levels.
///
/// Maps to Material 3 `ColorScheme` surface container roles so that
/// every surface in the app resolves to the same palette regardless
/// of the current theme.
enum SurfaceLevel {
  /// `colorScheme.surface` — the lowest emphasis background.
  flat,

  /// `colorScheme.surfaceContainerLow`
  low,

  /// `colorScheme.surfaceContainer`
  medium,

  /// `colorScheme.surfaceContainerHigh`
  high,

  /// `colorScheme.surfaceContainerHighest`
  highest,
}

/// A themed surface container with consistent defaults.
///
/// Replaces the ad-hoc `Container(decoration: BoxDecoration(...))` pattern
/// that is repeated across the codebase with varying border alphas, colors,
/// and radii.
///
/// ```dart
/// AppSurface(
///   level: SurfaceLevel.low,
///   child: Text('Hello'),
/// )
/// ```
class AppSurface extends StatelessWidget {
  /// The content to display inside the surface.
  final Widget child;

  /// Surface container emphasis level.
  final SurfaceLevel level;

  /// Corner radius.  Defaults to [AppRounding.medium].
  final double rounding;

  /// Alpha value for the outline border.
  /// Set to `0` to remove the border entirely.
  final double borderAlpha;

  /// Shadow elevation (blur radius). `0` means no shadow.
  final double elevation;

  /// Inner padding. `null` means no padding.
  final EdgeInsetsGeometry? padding;

  /// Override the border color.  When `null` the theme's
  /// `outlineVariant` is used at [borderAlpha] opacity.
  final Color? borderColor;

  /// Override the background color.  When `null` the [level] determines
  /// the color from the theme.
  final Color? color;

  const AppSurface({
    required this.child,
    this.level = SurfaceLevel.low,
    this.rounding = AppRounding.medium,
    this.borderAlpha = 0.3,
    this.elevation = 0,
    this.padding,
    this.borderColor,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = color ?? _resolveColor(colors);
    final Color border = borderColor ??
        colors.outlineVariant.withValues(alpha: borderAlpha);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(rounding),
        border: borderAlpha > 0 ? Border.all(color: border) : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: elevation,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }

  Color _resolveColor(ColorScheme colors) => switch (level) {
        SurfaceLevel.flat => colors.surface,
        SurfaceLevel.low => colors.surfaceContainerLow,
        SurfaceLevel.medium => colors.surfaceContainer,
        SurfaceLevel.high => colors.surfaceContainerHigh,
        SurfaceLevel.highest => colors.surfaceContainerHighest,
      };
}
