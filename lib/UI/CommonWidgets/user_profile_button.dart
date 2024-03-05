import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/tonal_button.dart';
import 'package:stripes_ui/UI/History/EventView/export.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class UserProfileButton extends ConsumerWidget {
  const UserProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser user = ref.watch(currentAuthProvider);
    final bool hasSession =
        !AuthUser.isEmpty(user) && !AuthUser.isLocalCode(user);
    final bool isMarker =
        SubUser.isMarker(ref.watch(subHolderProvider).current);
    final ExportAction? exportAction = ref.watch(exportProvider);
    final Function? exitAction = ref.watch(exitStudyProvider);
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 1),
      itemBuilder: (context) => [
        if (!isMarker)
          PopupMenuItem(
            child: Row(children: [
              Text(
                AppLocalizations.of(context)!.managePatientsButton,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.edit_note,
              ),
            ]),
            onTap: () {
              context.push(Routes.USERS);
            },
          ),
        if (exportAction != null)
          PopupMenuItem(
            child: Row(children: [
              Text(
                "Hilfe",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.info,
              ),
            ]),
            onTap: () {
              ref.read(overlayProvider.notifier).state = OverlayQuery(
                widget: OverlayBackdrop(
                  dismissOnBackdropTouch: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Hilfe",
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 4.0,
                            ),
                            SelectableText(
                              "Bitte reichen Sie Ihre gesamten Daten nach einem Monat Dokumentation nach Studienvisite ein. Drücken Sie hierzu bitte auf „Datenexport“. So können wir Ihre Daten pseudonymisiert erhalten. Bei Fragen wenden Sie sich bitte an gpeschke@ukaachen.de",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        if (exportAction != null && hasSession)
          PopupMenuItem(
            child: Row(children: [
              Text(
                AppLocalizations.of(context)!.exportName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.download,
              ),
            ]),
            onTap: () {
              final ExportAction? action = ref.watch(exportProvider);
              if (action == null) {
                showSnack(context, AppLocalizations.of(context)!.exportError);
                return;
              }
              List<Response> stamps = ref
                  .watch(stampHolderProvider)
                  .stamps
                  .whereType<Response>()
                  .toList();
              ref.read(overlayProvider.notifier).state =
                  OverlayQuery(widget: ExportOverlay(responses: stamps));
            },
          ),
        if (exitAction != null && hasSession)
          PopupMenuItem(
            child: Row(children: [
              Text(
                AppLocalizations.of(context)!.exitStudy,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.close,
              ),
            ]),
            onTap: () {
              ref.read(overlayProvider.notifier).state =
                  const OverlayQuery(widget: ExitErrorPrevention());
            },
          ),
        PopupMenuItem(
          child: Row(children: [
            Text(
              AppLocalizations.of(context)!.logOutButton,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            const Icon(
              Icons.logout,
            ),
          ]),
          onTap: () {
            ref.read(authProvider).logOut();
          },
        ),
      ],
      icon: const Icon(
        Icons.person,
        size: 35.0,
      ),
      tooltip: 'Account',
    );
  }
}

class ExitErrorPrevention extends ConsumerWidget {
  const ExitErrorPrevention({Key? key}) : super(key: key);

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
    final Function? exitAction = ref.watch(exitStudyProvider);
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
