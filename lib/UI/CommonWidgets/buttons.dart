import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class StripesRoundedButton extends StatelessWidget {
  final String text;

  final Function onClick;

  final Function()? disabledClick;

  final bool isLight, isTall, isDisabled, hasShadow;

  final double roundAmount;

  const StripesRoundedButton(
      {required this.text,
      required this.onClick,
      light = true,
      tall = true,
      disabled = false,
      shadow = true,
      rounding = 15.0,
      this.disabledClick,
      Key? key})
      : isLight = light,
        isTall = tall,
        hasShadow = shadow,
        isDisabled = disabled,
        roundAmount = rounding,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTall ? 50 : null,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(roundAmount)),
          boxShadow: [
            if (hasShadow)
              BoxShadow(
                  color: isLight
                      ? buttonLightBackground2.withOpacity(0.2)
                      : buttonDarkBackground2.withOpacity(0.2),
                  blurRadius: 1,
                  spreadRadius: 1,
                  offset: const Offset(0, 5))
          ]),
      child: ElevatedButton(
        onPressed: isDisabled
            ? disabledClick
            : () {
                onClick();
              },
        style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            elevation: MaterialStateProperty.all(0),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(roundAmount))))),
        child: Ink(
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(roundAmount)),
              gradient: LinearGradient(
                  colors: isDisabled
                      ? [Colors.grey.shade500, Colors.grey.shade800]
                      : isLight
                          ? [buttonLightBackground, buttonLightBackground2]
                          : [buttonDarkBackground, buttonDarkBackground2])),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                text,
                style: buttonTextStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StripesTextButton extends StatelessWidget {
  final String buttonText, prefixText, suffixText;

  final bool isDisabled;

  final Color mainTextColor;

  final Function onClicked;

  const StripesTextButton(
      {required this.buttonText,
      required this.onClicked,
      this.mainTextColor = buttonLightBackground,
      bool disabled = false,
      String prefix = '',
      String suffix = '',
      Key? key})
      : isDisabled = disabled,
        prefixText = prefix,
        suffixText = suffix,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: RichText(
        text:
            TextSpan(text: prefixText, style: lightBackgroundStyle, children: [
          TextSpan(
              text: buttonText, style: link.copyWith(color: mainTextColor)),
          TextSpan(text: suffixText, style: lightBackgroundStyle)
        ]),
      ),
      onPressed: () {
        onClicked();
      },
    );
  }
}
