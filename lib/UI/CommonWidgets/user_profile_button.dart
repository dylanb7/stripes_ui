import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/navigation_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/tonal_button.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/entry.dart';

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
            while (router.state.uri.pathSegments.contains(RouteName.ACCOUNT)) {
              if (!router.canPop()) {
                router.go(Routes.HOME);
                return;
              }
              router.pop();
            }
          } else {
            ref
                .read(navigationControllerProvider)
                .pushNamed(context, RouteName.ACCOUNT);
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
    return Center(
      child: SizedBox(
        width: Breakpoint.tiny.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRounding.small))),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small, vertical: AppPadding.medium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      context.translate.errorPreventionTitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    Text(
                      context.translate.exitStudyWarning,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: AppPadding.tiny,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton(
                    onPressed: () {
                      _closeOverlay(context);
                    },
                    child: Text(context.translate.stampDeleteCancel)),
                TonalButtonTheme(
                  child: FilledButton.tonal(
                    onPressed: () {
                      _confirm(ref, context);
                    },
                    child: Text(context.translate.stampDeleteConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _confirm(WidgetRef ref, BuildContext context) async {
    _closeOverlay(context);
    final Function? exitAction = ref.watch(configProvider).onExitStudy;
    try {
      await exitAction!();
    } finally {
      ref.read(authProvider).logOut();
    }
  }

  _closeOverlay(BuildContext context) {
    Navigator.of(context).pop();
  }
}
