import 'package:flutter/material.dart';

class TonalButtonTheme extends StatelessWidget {
  final Widget child;
  const TonalButtonTheme({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Theme(
        data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(
                secondaryContainer: scheme.secondary,
                onSecondaryContainer: scheme.onSecondary)),
        child: child);
  }
}
