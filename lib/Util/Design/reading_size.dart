import 'package:flutter/widgets.dart';

/// Grow controls alongside body text, while leaving room for their labels.
double readingIconSize(BuildContext context, [double size = 24]) {
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return size * scale.clamp(1.0, 2.0);
}
