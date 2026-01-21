import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Sync/sync_providers.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int pendingCount = ref.watch(pendingSyncCountProvider);

    return AnimatedSwitcher(
      duration: Durations.medium1,
      child: pendingCount > 0
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
              child: Badge(
                label: Text(pendingCount.toString()),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
