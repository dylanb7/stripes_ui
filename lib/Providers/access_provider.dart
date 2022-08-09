import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AccessBase/base_access_repo.dart';
import 'package:stripes_ui/entry.dart';

final accessProvider =
    Provider<AccessCodeRepo>((ref) => ref.watch(reposProvider).access());
