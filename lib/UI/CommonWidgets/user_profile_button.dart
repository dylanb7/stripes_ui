import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/tonal_button.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class UserProfileButton extends ConsumerWidget {
  final bool selected;
  const UserProfileButton({this.selected = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : ElevationOverlay.applySurfaceTint(Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surfaceTint, 6),
          shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          final GoRouter router = GoRouter.of(context);
          if (selected) {
            while (router.location.startsWith(Routes.ACCOUNT)) {
              if (!router.canPop()) {
                router.pushNamed(Routes.HOME);
                return;
              }
              router.pop();
            }
          } else {
            context.pushNamed(Routes.ACCOUNT);
          }
        },
        icon: Icon(
          Icons.person_outline,
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        tooltip: 'Account',
      ),
    );
  }
}

class ExitErrorPrevention extends ConsumerWidget {
  const ExitErrorPrevention({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OverlayBackdrop(
      child: SizedBox(
        width: SMALL_LAYOUT / 1.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.errorPreventionTitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!.exitStudyWarning,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton(
                    onPressed: () {
                      _closeOverlay(ref);
                    },
                    child:
                        Text(AppLocalizations.of(context)!.stampDeleteCancel)),
                TonalButtonTheme(
                  child: FilledButton.tonal(
                    onPressed: () {
                      _confirm(ref);
                    },
                    child:
                        Text(AppLocalizations.of(context)!.stampDeleteConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _confirm(WidgetRef ref) async {
    _closeOverlay(ref);
    final Function? exitAction = ref.watch(configProvider).onExitStudy;
    try {
      await exitAction!();
    } finally {
      ref.read(authProvider).logOut();
    }
  }

  _closeOverlay(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}
