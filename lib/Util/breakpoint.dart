import 'package:flutter/widgets.dart';

enum Breakpoint {
  tiny(450.0),
  small(650.0),
  medium(1000.0),
  large(1400.0);

  final double value;
  const Breakpoint(this.value);
  bool isLessThan(Breakpoint breakpoint) => value <= breakpoint.value;
  bool isGreaterThan(Breakpoint breakpoint) => value >= breakpoint.value;
  static const ordered = [tiny, small, medium, large];
}

Breakpoint getBreakpoint(BuildContext context) {
  final double width = MediaQuery.of(context).size.width;
  for (Breakpoint breakpoint in Breakpoint.ordered) {
    if (width <= breakpoint.value) {
      return breakpoint;
    }
  }
  return Breakpoint.large;
}
