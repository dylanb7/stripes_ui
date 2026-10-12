import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/Accessibility/display_settings_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class DisplaySettingsTile extends ConsumerWidget {
  const DisplaySettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(displaySettingsProvider).value?.detailLayout;
    return ListTile(
      title: Text(context.translate.displaySettingsTitle),
      subtitle: Text(
        preference == DetailLayoutPreference.stacked
            ? context.translate.detailLayoutStacked
            : context.translate.detailLayoutAutomatic,
      ),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => ref
          .read(sheetControllerProvider)
          .show<void>(
            context: context,
            scrollControlled: true,
            child: (_) => const DisplaySettingsSheet(),
          ),
    );
  }
}

class DisplaySettingsSheet extends ConsumerStatefulWidget {
  const DisplaySettingsSheet({super.key});

  @override
  ConsumerState<DisplaySettingsSheet> createState() =>
      _DisplaySettingsSheetState();
}

class _DisplaySettingsSheetState extends ConsumerState<DisplaySettingsSheet> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _select(DetailLayoutPreference? preference) async {
    if (preference == null || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(displaySettingsProvider.notifier)
          .setDetailLayout(preference);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(displaySettingsProvider);
    final text = context.translate;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      text.displaySettingsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                text.detailLayoutTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppPadding.small),
              RadioGroup<DetailLayoutPreference>(
                groupValue:
                    settings.value?.detailLayout ??
                    DetailLayoutPreference.automatic,
                onChanged: _select,
                child: Column(
                  children: [
                    RadioListTile<DetailLayoutPreference>(
                      value: DetailLayoutPreference.automatic,
                      enabled: !_saving && !settings.isLoading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.detailLayoutAutomatic),
                      subtitle: Text(text.detailLayoutAutomaticDescription),
                    ),
                    RadioListTile<DetailLayoutPreference>(
                      value: DetailLayoutPreference.stacked,
                      enabled: !_saving && !settings.isLoading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.detailLayoutStacked),
                      subtitle: Text(text.detailLayoutStackedDescription),
                    ),
                  ],
                ),
              ),
              if (_failed || settings.hasError)
                Text(
                  text.detailLayoutSaveError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: AppPadding.small),
              Text(
                text.detailLayoutDeviceNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
