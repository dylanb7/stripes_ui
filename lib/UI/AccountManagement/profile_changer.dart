import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class PatientChanger extends ConsumerWidget {
  final TabOption tab;

  const PatientChanger({this.tab = TabOption.record, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> state = ref.watch(subHolderProvider);
    final StripesConfig config = ref.watch(configProvider);

    if (state.isLoading) {
      return const LoadingWidget();
    }
    final SubUser? current = state.valueOrNull?.selected;
    final List<SubUser> subUsers = state.valueOrNull?.subUsers ?? [];
    final bool isMarker = current != null && SubUser.isMarker(current);

    String getTitle() {
      if (isMarker) {
        return tab == TabOption.record
            ? context.translate.recordTab
            : tab == TabOption.tests
                ? context.translate.testTab
                : context.translate.historyTab;
      }
      String firstName = config.profileType == ProfileType.username
          ? current?.name ?? ''
          : (current?.name.split(' ')[0]) ?? '';
      firstName = firstName.substring(0, min(firstName.length, 11));
      return tab == TabOption.record
          ? context.translate.recordTitle(firstName)
          : tab == TabOption.tests
              ? context.translate.testTab
              : context.translate.historyTitle(firstName);
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              getTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(
            width: 2.0,
          ),
          if (subUsers.length > 1)
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _openUserSelect(ref, context);
                },
                tooltip: "Change Profile",
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 35.0,
                  color: Theme.of(context).colorScheme.secondary,
                )),
        ]);
  }

  _openUserSelect(WidgetRef ref, BuildContext context) {
    ref.read(sheetControllerProvider).show(
        context: context,
        scrollControlled: true,
        sheetBuilder: (context, controller) => const UserSelect());
  }
}

class UserSelect extends ConsumerWidget {
  const UserSelect({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> subNotif = ref.read(subHolderProvider);
    final SubUser? current = subNotif.valueOrNull?.selected;
    final List<SubUser> subUsers = subNotif.valueOrNull?.subUsers ?? [];
    final StripesConfig config = ref.watch(configProvider);
    final Color action = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppPadding.xl,
        right: AppPadding.xl,
        top: AppPadding.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(
              'Select Profile',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
                onPressed: () {
                  _close(context);
                },
                iconSize: 35,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                ))
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: subUsers
                .map(
                  (user) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppPadding.tiny),
                    child: user.uid == current?.uid
                        ? _getSelected(ref, context, user, action,
                            config.profileType ?? ProfileType.username)
                        : _getSelectible(ref, context, user,
                            config.profileType ?? ProfileType.username),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _getSelected(WidgetRef ref, BuildContext context, SubUser current,
      Color selected, ProfileType profileType) {
    final String firstName = profileType == ProfileType.name
        ? current.name.split(' ')[0]
        : current.name;
    return InkWell(
        onTap: () {
          _close(context);
        },
        splashFactory: NoSplash.splashFactory,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              firstName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: selected, fontWeight: FontWeight.bold),
            ),
            Icon(
              Icons.check,
              color: selected,
              size: 35,
            ),
          ],
        ));
  }

  Widget _getSelectible(WidgetRef ref, BuildContext context, SubUser user,
      ProfileType profileType) {
    final String firstName =
        profileType == ProfileType.name ? user.name.split(' ')[0] : user.name;
    return InkWell(
      onTap: () {
        ref.read(subHolderProvider.notifier).changeCurrent(user);
        _close(context);
      },
      splashFactory: NoSplash.splashFactory,
      child: Text(firstName, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  _close(BuildContext context) {
    context.pop();
  }
}
