import 'package:flutter/material.dart';
import 'package:radix_colors/radix_colors.dart';

const Color darkIconButton = Color(0xffff651f);
const Color lightIconButton = Color(0xff1744a3);
const Color buttonDarkBackground = Color(0xffff823d);
const Color buttonDarkBackground2 = Color(0xffff9b53);
const Color buttonLightBackground = Color(0xff3368b7);
const Color buttonLightBackground2 = Color(0xff0f3b9e);
const Color trackerButtons = Color(0xff2d6eb7);
const Color disabled = Color.fromARGB(255, 156, 163, 175);

const Color backgroundStrong = Color(0xff1d47a6);
const Color backgroundLight = Color(0xff75bce5);

const Color lightBackgroundText = Colors.black;
const Color darkBackgroundText = Colors.white;

const Color error = Color(0xffff321b);

ThemeData getThemeData(BuildContext context, Brightness brightness) {
  RadixColorsDynamic(context, brightness: brightness).blue.step5;
  final ColorScheme stripesScheme = ColorScheme(
      brightness: Brightness.light,
      primary: backgroundStrong,
      onPrimary: darkIconButton,
      secondary: darkBackgroundText,
      onSecondary:
          RadixColorsDynamic(context, brightness: brightness).whiteA.step11,
      error: error,
      onError: darkBackgroundText,
      background: backgroundStrong,
      onBackground: darkBackgroundText,
      surface: darkBackgroundText,
      onSurface: lightBackgroundText);

  return ThemeData.from(colorScheme: stripesScheme, useMaterial3: true)
    ..copyWith(splashColor: null, splashFactory: NoSplash.splashFactory);
}

/*
const ColorScheme _colorSchemeLightM3 = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF6750A4),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEADDFF),
  onPrimaryContainer: Color(0xFF21005D),
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF1D192B),
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF31111D),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  background: Color(0xFFFFFBFE),
  onBackground: Color(0xFF1C1B1F),
  surface: Color(0xFFFFFBFE),
  onSurface: Color(0xFF1C1B1F),
  surfaceVariant: Color(0xFFE7E0EC),
  onSurfaceVariant: Color(0xFF49454F),
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFD0BCFF),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(0xFF6750A4),
);

const ColorScheme _colorSchemeDarkM3 = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFEADDFF),
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  background: Color(0xFF1C1B1F),
  onBackground: Color(0xFFE6E1E5),
  surface: Color(0xFF1C1B1F),
  onSurface: Color(0xFFE6E1E5),
  surfaceVariant: Color(0xFF49454F),
  onSurfaceVariant: Color(0xFFCAC4D0),
  outline: Color(0xFF938F99),
  outlineVariant: Color(0xFF49454F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE6E1E5),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6750A4),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(0xFFD0BCFF),
);
*/
