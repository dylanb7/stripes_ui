import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/SyncOperations/manager_base.dart';
import 'package:stripes_backend_helper/repo_package.dart';
import 'package:stripes_ui/config.dart';

final reposProvider = Provider<StripesRepoPackage>((ref) => LocalRepoPackage());

final configProvider =
    Provider<StripesConfig>((ref) => const StripesConfig.sandbox());
