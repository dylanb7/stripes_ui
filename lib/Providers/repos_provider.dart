import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/repo_package.dart';

final reposProvider = Provider<StripesRepoPackage>((ref) => LocalRepoPackage());
