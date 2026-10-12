import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';

final displaySettingsProvider =
    AsyncNotifierProvider<DisplaySettingsNotifier, AppDisplaySettings>(
      DisplaySettingsNotifier.new,
      retry: (_, _) => null,
    );

class DisplaySettingsNotifier extends AsyncNotifier<AppDisplaySettings> {
  Future<void> _pendingSave = Future.value();

  @override
  Future<AppDisplaySettings> build() =>
      ref.read(sharedSeviceProvider).getDisplaySettings();

  Future<void> setDetailLayout(DetailLayoutPreference layout) {
    // Serialize writes so rapid selections cannot persist out of order.
    final save = _pendingSave.then((_) async {
      final settings = (await future).copyWith(detailLayout: layout);
      await ref.read(sharedSeviceProvider).setDisplaySettings(settings);
      if (ref.mounted) state = AsyncData(settings);
    });
    _pendingSave = save.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return save;
  }
}
