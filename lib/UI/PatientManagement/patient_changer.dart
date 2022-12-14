import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class PatientChanger extends ConsumerWidget {
  final bool isRecords;

  const PatientChanger({this.isRecords = true, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SubNotifier sub = ref.watch(subHolderProvider);
    final bool isSmall = ref.watch(isSmallProvider);

    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentUserName(sub.current, isSmall),
            style: darkBackgroundScreenHeaderStyle.copyWith(
                letterSpacing: 1.4, fontSize: 32),
          ),
          if (sub.users.length > 1)
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _openUserSelect(ref);
                },
                tooltip: "Change Patient",
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 50.0,
                  color: darkIconButton,
                )),
        ]);
  }

  _currentUserName(SubUser user, bool isSmall) {
    if (SubUser.isEmpty(user)) return 'No Patients';
    String firstName = (user.name.split(' ')[0]);
    firstName = firstName.substring(0, min(firstName.length, 11));
    return isRecords
        ? 'Record for${isSmall ? '\n' : ' '}$firstName'
        : '$firstName\'s${isSmall ? '\n' : ' '}History';
  }

  _openUserSelect(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const OverlayQuery(widget: UserSelect());
  }
}

class UserSelect extends ConsumerWidget {
  const UserSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SubNotifier subNotif = ref.read(subHolderProvider);
    final SubUser current = subNotif.current;
    return Stack(
      children: [
        Positioned.fill(
            child: Container(
          color: lightBackgroundText.withOpacity(0.9),
        )),
        Positioned.fill(
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  const Text(
                    'Select Patient',
                    style: darkBackgroundScreenHeaderStyle,
                  ),
                  IconButton(
                      onPressed: () {
                        _close(ref);
                      },
                      iconSize: 50,
                      icon: const Icon(
                        Icons.keyboard_arrow_up,
                        color: darkIconButton,
                      ))
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subNotif.users
                      .map((user) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: user.uid == current.uid
                              ? _getSelected(ref, user)
                              : _getSelectible(ref, user)))
                      .toList(),
                ),
              ],
            ),
          )),
        )
      ],
    );
  }

  Widget _getSelected(WidgetRef ref, SubUser current) {
    final String firstName = current.name.split(' ')[0];
    return InkWell(
        onTap: () {
          _close(ref);
        },
        splashFactory: NoSplash.splashFactory,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              firstName,
              style: darkBackgroundScreenHeaderStyle.copyWith(
                  color: buttonDarkBackground),
            ),
            const Icon(
              Icons.check,
              color: darkIconButton,
              size: 35,
            ),
          ],
        ));
  }

  Widget _getSelectible(WidgetRef ref, SubUser user) {
    final String firstName = user.name.split(' ')[0];
    return InkWell(
      onTap: () {
        ref.read(subHolderProvider.notifier).changeCurrent(user);
        _close(ref);
      },
      splashFactory: NoSplash.splashFactory,
      child: Text(
        firstName,
        style: darkBackgroundScreenHeaderStyle,
      ),
    );
  }

  _close(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}
