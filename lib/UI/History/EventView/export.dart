import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:share_plus/share_plus.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Util/palette.dart';

class Export extends ConsumerWidget {
  const Export({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        Share.share('hey');
      },
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
    Available available = ref.watch(availibleStampsProvider);
    return OverlayBackdrop(child: Container());
  }
}
