import 'package:flutter/cupertino.dart';

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: CupertinoSlidingSegmentedControl<String>(
            children: Map.fromEntries(
              options.map(
                (e) => MapEntry(
                  e,
                  Text(
                    e,
                  ),
                ),
              ),
            ),
            groupValue: toggled,
            onValueChanged: onChange));
  }
}
