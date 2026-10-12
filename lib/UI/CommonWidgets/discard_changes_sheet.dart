import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

Future<bool> showDiscardChangesSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await ref
      .read(sheetControllerProvider)
      .show<bool>(
        context: context,
        scrollControlled: true,
        bottomSheetShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRounding.medium),
          ),
        ),
        child: (_) => const DiscardChangesSheet(),
      );
  return result ?? false;
}

class DiscardChangesSheet extends StatelessWidget {
  const DiscardChangesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.translate;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.discardEntryTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.small),
                Text(
                  strings.discardEntryDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppPadding.large),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.discardEntryKeep),
                ),
                const SizedBox(height: AppPadding.small),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(strings.discardEntryDiscard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
