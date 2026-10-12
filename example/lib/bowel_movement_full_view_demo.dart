import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/Record/Demo/bowel_movement_full_view_demo.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => const StripesConfig.sandbox(betaUi: BetaUiConfig.enabled()),
        ),
      ],
      child: const _DemoApp(),
    ),
  );
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bowel Movement Full View Demo',
    theme: light,
    home: const BowelMovementFullViewDemo(),
  );
}
