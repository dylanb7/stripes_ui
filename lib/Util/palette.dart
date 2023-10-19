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
      brightness: brightness,
      primary: RadixColorsDynamic(context, brightness: brightness).blue.step9,
      onPrimary: RadixColorsDynamic(context, brightness: brightness).blue.step3,
      secondary:
          RadixColorsDynamic(context, brightness: brightness).orange.step2,
      onSecondary:
          RadixColorsDynamic(context, brightness: brightness).orange.step11,
      error: RadixColorsDynamic(context, brightness: brightness).tomato.step1,
      onError:
          RadixColorsDynamic(context, brightness: brightness).tomato.step12,
      background:
          RadixColorsDynamic(context, brightness: brightness).blue.step1,
      onBackground:
          RadixColorsDynamic(context, brightness: brightness).blue.step12,
      surface: RadixColorsDynamic(context, brightness: brightness).slate.step3,
      onSurface:
          RadixColorsDynamic(context, brightness: brightness).slate.step9);

  return ThemeData.from(colorScheme: stripesScheme, useMaterial3: true)
    ..copyWith(splashFactory: NoSplash.splashFactory);
}
