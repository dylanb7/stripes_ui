import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

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

final ThemeData light = FlexThemeData.light(
  colors: const FlexSchemeColor(
    primary: Color(0xff1460a5),
    primaryContainer: Color(0xffd3e4ff),
    secondary: Color(0xffd6783f),
    secondaryContainer: Color(0xffebb790),
    tertiary: Color(0xff6d6f34),
    tertiaryContainer: Color(0xff95f0ff),
    appBarColor: Color(0xffebb790),
    error: Color(0xffb00020),
  ),
  surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
  blendLevel: 1,
  appBarStyle: FlexAppBarStyle.background,
  bottomAppBarElevation: 2.0,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 6,
    blendOnColors: false,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    adaptiveRemoveElevationTint: FlexAdaptive.excludeWebAndroidFuchsia(),
    adaptiveElevationShadowsBack: FlexAdaptive.excludeWebAndroidFuchsia(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.excludeWebAndroidFuchsia(),
    adaptiveRadius: FlexAdaptive.excludeWebAndroidFuchsia(),
    defaultRadiusAdaptive: 10.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    elevatedButtonRadius: 8.0,
    filledButtonRadius: 8.0,
    outlinedButtonRadius: 8.0,
    filledButtonSchemeColor: SchemeColor.secondary,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorBackgroundAlpha: 19,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    cardRadius: 14.0,
    popupMenuRadius: 6.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    dialogRadius: 18.0,
    useInputDecoratorThemeInDialogs: true,
    appBarScrolledUnderElevation: 1.0,
    drawerElevation: 1.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomSheetRadius: 18.0,
    bottomSheetElevation: 2.0,
    bottomSheetModalElevation: 4.0,
    bottomNavigationBarMutedUnselectedLabel: true,
    bottomNavigationBarMutedUnselectedIcon: true,
    menuRadius: 6.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    menuBarShadowColor: Color(0x00000000),
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorOpacity: 1.00,
    navigationBarElevation: 1.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailMutedUnselectedLabel: false,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedIcon: false,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);
final ThemeData dark = FlexThemeData.dark(
  colors: const FlexSchemeColor(
    primary: Color(0xffb1cff5),
    primaryContainer: Color(0xff3873ba),
    secondary: Color(0xffffd270),
    secondaryContainer: Color(0xffd26900),
    tertiary: Color(0xffc9cbfc),
    tertiaryContainer: Color(0xff535393),
    appBarColor: Color(0xffd26900),
    error: Color(0xffcf6679),
  ),
  surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
  blendLevel: 2,
  appBarStyle: FlexAppBarStyle.background,
  bottomAppBarElevation: 2.0,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 8,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    adaptiveElevationShadowsBack: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.excludeWebAndroidFuchsia(),
    adaptiveRadius: FlexAdaptive.excludeWebAndroidFuchsia(),
    defaultRadiusAdaptive: 10.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorBackgroundAlpha: 22,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    cardRadius: 14.0,
    popupMenuRadius: 6.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    dialogRadius: 18.0,
    useInputDecoratorThemeInDialogs: true,
    appBarScrolledUnderElevation: 3.0,
    drawerElevation: 1.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomSheetRadius: 18.0,
    bottomSheetElevation: 2.0,
    bottomSheetModalElevation: 4.0,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 6.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    menuBarShadowColor: Color(0x00000000),
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorOpacity: 1.00,
    navigationBarElevation: 1.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailMutedUnselectedLabel: false,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedIcon: false,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

const ColorScheme flexSchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff00296b),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xffa0c2ed),
  onPrimaryContainer: Color(0xff080a0c),
  secondary: Color(0xffd26900),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffffb866),
  onSecondaryContainer: Color(0xff0c0905),
  tertiary: Color(0xff5c5c95),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffc8dbf8),
  onTertiaryContainer: Color(0xff0a0b0c),
  error: Color(0xffb00020),
  onError: Color(0xffffffff),
  errorContainer: Color(0xfffcd8df),
  onErrorContainer: Color(0xff0c0b0b),
  background: Color(0xfffcfcfc),
  onBackground: Color(0xff080808),
  surface: Color(0xfffefefe),
  onSurface: Color(0xff050505),
  surfaceVariant: Color(0xffececec),
  onSurfaceVariant: Color(0xff0b0b0b),
  outline: Color(0xff7b7b7b),
  outlineVariant: Color(0xffc7c7c7),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xff101111),
  onInverseSurface: Color(0xfff9f9f9),
  inversePrimary: Color(0xff8dacdd),
  surfaceTint: Color(0xff00296b),
);

const ColorScheme flexSchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffb1cff5),
  onPrimary: Color(0xff070808),
  primaryContainer: Color(0xff3873ba),
  onPrimaryContainer: Color(0xfff6f9fe),
  secondary: Color(0xffffd270),
  onSecondary: Color(0xff080805),
  secondaryContainer: Color(0xffd26900),
  onSecondaryContainer: Color(0xfffff9f2),
  tertiary: Color(0xffc9cbfc),
  onTertiary: Color(0xff070708),
  tertiaryContainer: Color(0xff535393),
  onTertiaryContainer: Color(0xfff7f7fb),
  error: Color(0xffcf6679),
  onError: Color(0xff080405),
  errorContainer: Color(0xffb1384e),
  onErrorContainer: Color(0xfffdf6f7),
  background: Color(0xff111212),
  onBackground: Color(0xfff3f3f3),
  surface: Color(0xff121212),
  onSurface: Color(0xfff7f7f7),
  surfaceVariant: Color(0xff333435),
  onSurfaceVariant: Color(0xfff2f2f2),
  outline: Color(0xff808080),
  outlineVariant: Color(0xff343434),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xfffefefe),
  onInverseSurface: Color(0xff070707),
  inversePrimary: Color(0xff566270),
  surfaceTint: Color(0xffb1cff5),
);
