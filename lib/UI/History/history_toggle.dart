import 'package:flutter/cupertino.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class LocationToggle extends StatelessWidget {
  final List<String> options;

  final String toggled;

  final Function(String?) onChange;

  final double? fontSize;

  const LocationToggle({
    required this.options,
    required this.toggled,
    required this.onChange,
    this.fontSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = fontSize != null
        ? darkBackgroundHeaderStyle.copyWith(fontSize: fontSize)
        : darkBackgroundHeaderStyle;
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: CupertinoSlidingSegmentedControl<String>(
            children: Map.fromEntries(
              options.map(
                (e) => MapEntry(
                  e,
                  Text(
                    e,
                    style: e == toggled
                        ? baseStyle.copyWith(
                            color: lightIconButton, fontWeight: FontWeight.bold)
                        : baseStyle,
                  ),
                ),
              ),
            ),
            groupValue: toggled,
            thumbColor: darkBackgroundText,
            backgroundColor: lightIconButton,
            onValueChanged: onChange));
  }
}
