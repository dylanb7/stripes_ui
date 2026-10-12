import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/repo_package.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';
import 'package:stripes_ui/config.dart';

final reposProvider = Provider<StripesRepoPackage>((ref) => LocalRepoPackage());

final configProvider = Provider<StripesConfig>(
  (ref) => const StripesConfig.sandbox(),
);

/// UI-side registry for custom question display and entry widget builders.
///
/// Override this provider to register app-specific overrides (e.g. Bristol
/// stool scale slider, pain face widget, etc.).
final questionUIRegistryProvider = Provider<QuestionUIRegistry>((ref) {
  final config = ref.watch(configProvider);
  return config.betaUi.multiSessionFlow
      ? bowelMovementFullViewRegistry()
      : QuestionUIRegistry();
});
