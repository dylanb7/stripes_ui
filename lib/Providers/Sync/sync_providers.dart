import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/SyncOperations/manager_base.dart';
import 'package:stripes_backend_helper/SyncOperations/queue_item.dart';
import 'package:stripes_backend_helper/SyncOperations/status_event.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

final syncManagerProvider = FutureProvider<SyncManagerBase?>((ref) async {
  final auth = await ref.watch(authStream.future);
  final sub =
      await ref.watch(subHolderProvider.selectAsync((value) => value.selected));

  final bool subEmpty = sub == null || SubUser.isEmpty(sub);

  if (AuthUser.isEmpty(auth) || subEmpty) {
    return null;
  }
  return ref.watch(reposProvider).syncManager(subUser: sub);
});

final syncQueueProvider = StreamProvider<List<SyncQueueItem>>((ref) async* {
  final SyncManagerBase? manager = await ref.watch(syncManagerProvider.future);
  if (manager == null) yield* const Stream<List<SyncQueueItem>>.empty();
  yield* manager?.queueStream ?? const Stream<List<SyncQueueItem>>.empty();
});

final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(syncQueueProvider).valueOrNull?.length ?? 0;
});

final syncStatusStreamProvider = StreamProvider<SyncStatusEvent>((ref) async* {
  final SyncManagerBase? manager = await ref.watch(syncManagerProvider.future);
  if (manager == null) yield* const Stream.empty();
  if (manager != null) {
    yield* manager.statusStream;
  }
});

final syncEventsProvider =
    StateNotifierProvider<SyncEventsNotifier, List<SyncStatusEvent>>((ref) {
  return SyncEventsNotifier(ref);
});

class SyncEventsNotifier extends StateNotifier<List<SyncStatusEvent>> {
  final Ref ref;

  SyncEventsNotifier(this.ref) : super([]) {
    ref.listen(syncStatusStreamProvider, (previous, next) {
      next.whenData((event) {
        state = [event, ...state].take(50).toList();
      });
    });
  }

  void clear() {
    state = [];
  }
}
