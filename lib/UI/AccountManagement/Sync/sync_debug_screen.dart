import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Sync/sync_providers.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class SyncDebugScreen extends ConsumerWidget {
  const SyncDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sync Debug'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Queue'),
              Tab(text: 'Logs'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                ref.read(syncEventsProvider.notifier).clear();
              },
              tooltip: 'Clear Logs',
            )
          ],
        ),
        body: const TabBarView(
          children: [
            QueueView(),
            LogsView(),
          ],
        ),
      ),
    );
  }
}

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(syncQueueProvider);

    return queueAsync.when(
      data: (queue) {
        if (queue.isEmpty) {
          return const Center(child: Text('Queue is empty'));
        }
        return ListView.builder(
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final item = queue[index];
            return ListTile(
              title: Text(item.id),
              subtitle:
                  Text('${item.action.name} - ${item.subUserId ?? 'N/A'}'),
              trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text("Payload"),
                              content: SingleChildScrollView(
                                child: Text(item.payload),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"))
                              ],
                            ));
                  }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class LogsView extends ConsumerWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(syncEventsProvider);

    if (events.isEmpty) {
      return const Center(child: Text('No events logged'));
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.all(AppPadding.small),
          child: Text(event.toString()),
        );
      },
    );
  }
}
