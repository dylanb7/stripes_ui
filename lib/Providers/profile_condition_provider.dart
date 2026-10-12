import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

final profileConditionProvider =
    AsyncNotifierProvider.family<
      ProfileConditionNotifier,
      ProfileCondition?,
      String
    >(ProfileConditionNotifier.new, retry: (_, _) => null);

class ProfileConditionNotifier extends AsyncNotifier<ProfileCondition?> {
  final String profileId;

  ProfileConditionNotifier(this.profileId);

  @override
  Future<ProfileCondition?> build() async {
    final repo = await ref.watch(subProvider.future);
    if (repo == null) return null;
    return ref
        .read(sharedSeviceProvider)
        .getProfileCondition(
          accountId: repo.authUser.uid,
          profileId: profileId,
        );
  }

  Future<void> save(ProfileCondition? condition) async {
    await future;
    final repo = await ref.read(subProvider.future);
    if (repo == null) throw StateError('No account selected');
    final accountId = repo.authUser.uid;
    await ref
        .read(sharedSeviceProvider)
        .setProfileCondition(
          accountId: accountId,
          profileId: profileId,
          condition: condition,
        );
    if (ref.mounted && ref.read(subProvider).value?.authUser.uid == accountId) {
      state = AsyncData(condition);
    }
  }
}
