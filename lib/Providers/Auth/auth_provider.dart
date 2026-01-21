import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/base_auth_repo.dart';
import 'package:stripes_ui/Providers/base_providers.dart';

final authProvider =
    Provider<AuthRepo>((ref) => ref.watch(reposProvider).auth());

final authStream =
    StreamProvider<AuthUser>((ref) => ref.watch(authProvider).user);
