import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';
import 'package:stripes_ui/Util/Design/palette.dart';

/// Run with: flutter run -t example/lib/resources_demo.dart
void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'STRiPES resources',
    theme: light,
    darkTheme: dark,
    home: const ResourcesScreen(),
  ),
);
