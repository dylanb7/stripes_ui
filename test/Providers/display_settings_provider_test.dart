import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/Accessibility/display_settings_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';

void main() {
  for (final stored in [null, 'future-unknown-value', 'automatic', 'stacked']) {
    test('restores $stored safely', () async {
      SharedPreferences.setMockInitialValues(
        stored == null ? {} : {detailLayoutPreferenceKey: stored},
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        (await container.read(displaySettingsProvider.future)).detailLayout,
        stored == 'stacked'
            ? DetailLayoutPreference.stacked
            : DetailLayoutPreference.automatic,
      );
    });
  }

  test(
    'rapid choices persist in selection order and automatic can be restored',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(displaySettingsProvider.future);
      final notifier = container.read(displaySettingsProvider.notifier);
      await Future.wait([
        notifier.setDetailLayout(DetailLayoutPreference.stacked),
        notifier.setDetailLayout(DetailLayoutPreference.automatic),
      ]);
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(
        (await reopened.read(displaySettingsProvider.future)).detailLayout,
        DetailLayoutPreference.automatic,
      );
      expect(
        container.read(displaySettingsProvider).value?.detailLayout,
        DetailLayoutPreference.automatic,
      );
    },
  );
}
