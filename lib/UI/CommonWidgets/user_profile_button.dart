import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class UserProileButton extends ConsumerWidget {
  const UserProileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 1),
      color: darkBackgroundText,
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Row(children: [
            Text(
              'Manage Patients',
              style: lightBackgroundStyle,
            ),
            Spacer(),
            Icon(
              Icons.edit_note,
              color: darkIconButton,
            ),
          ]),
          onTap: () {
            context.push(Routes.USERS);
          },
        ),
        PopupMenuItem(
          child: const Row(children: [
            Text(
              'Log Out',
              style: lightBackgroundStyle,
            ),
            Spacer(),
            Icon(
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
