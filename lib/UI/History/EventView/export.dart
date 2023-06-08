import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Util/palette.dart';

class Export extends ConsumerWidget {
  const Export({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(
        Icons.ios_share,
        color: darkBackgroundText,
      ),
      tooltip: 'Export',
    );
  }
}

class ExportOverlay extends ConsumerWidget {
  const ExportOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(availibleStampsProvider);
    return OverlayBackdrop(child: Container());
  }
}
