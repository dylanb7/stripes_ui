import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/base_auth_repo.dart';
import 'package:stripes_ui/Providers/repos_provider.dart';

final authProvider =
    Provider<AuthRepo>((ref) => ref.watch(reposProvider).auth());

final authUserStream = StreamProvider<AuthUser>((ref) {
  return ref.watch(authProvider).user;
});

final currentAuthProvider = StateNotifierProvider<CurrentAuth, AuthUser>(
    (ref) => CurrentAuth(ref.watch(authUserStream)));

class CurrentAuth extends StateNotifier<AuthUser> {
  final AsyncValue<AuthUser> _ref;
  CurrentAuth(this._ref) : super(const AuthUser.empty()) {
    _ref.whenData((value) => state = value);
  }

  @override
  String toString() {
    return '$_ref';
  }
}
