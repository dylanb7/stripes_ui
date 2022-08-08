import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

final ButtonStyle historyButtonStyle = ButtonStyle(
  backgroundColor: MaterialStateProperty.resolveWith((states) =>
      states.contains(MaterialState.hovered)
          ? darkBackgroundText.withOpacity(0.9)
          : darkBackgroundText),
  shape: const MaterialStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(50),
      ),
    ),
  ),
);

TextStyle buttonText = darkBackgroundStyle.copyWith(
    fontWeight: FontWeight.bold, color: darkIconButton);
