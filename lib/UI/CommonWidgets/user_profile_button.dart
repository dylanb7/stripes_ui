import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class UserProfileButton extends ConsumerWidget {
  const UserProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMarker =
        SubUser.isMarker(ref.watch(subHolderProvider).current);
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 1),
      color: darkBackgroundText,
      itemBuilder: (context) => [
        if (!isMarker)
          PopupMenuItem(
            child: Row(children: [
              Text(
                AppLocalizations.of(context)!.managePatientsButton,
                style: lightBackgroundStyle,
              ),
              const Spacer(),
              const Icon(
                Icons.edit_note,
                color: darkIconButton,
              ),
            ]),
            onTap: () {
              context.push(Routes.USERS);
            },
          ),
        PopupMenuItem(
          child: Row(children: [
            Text(
              AppLocalizations.of(context)!.logOutButton,
              style: lightBackgroundStyle,
            ),
            const Spacer(),
            const Icon(
              Icons.logout,
              color: darkIconButton,
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
        color: darkBackgroundText,
      ),
      tooltip: 'Account',
    );
  }
}
