import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/tab_view.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class PatientChanger extends ConsumerWidget {
  final TabOption tab;

  const PatientChanger({this.tab = TabOption.record, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> state = ref.watch(subHolderProvider);

    if (state.isLoading) return const Text('...');
    final SubUser? current = state.valueOrNull?.selected;
    final List<SubUser> subUsers = state.valueOrNull?.subUsers ?? [];
    final bool isMarker = current != null && SubUser.isMarker(current);

    String getTitle() {
      if (isMarker) {
        return tab == TabOption.record
            ? AppLocalizations.of(context)!.recordTab
            : tab == TabOption.tests
                ? AppLocalizations.of(context)!.testTab
                : AppLocalizations.of(context)!.historyTab;
      }
      String firstName = (current?.name.split(' ')[0]) ?? '';
      firstName = firstName.substring(0, min(firstName.length, 11));
      return tab == TabOption.record
          ? AppLocalizations.of(context)!.recordTitle(firstName)
          : tab == TabOption.tests
              ? AppLocalizations.of(context)!.testTab
              : AppLocalizations.of(context)!.historyTitle(firstName);
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
              style: Theme.of(context).textTheme.headlineMedium,
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
                  _openUserSelect(ref);
                },
                tooltip: "Change Patient",
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 35.0,
                  color: Theme.of(context).colorScheme.secondary,
                )),
        ]);
  }

  _openUserSelect(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        const OverlayQuery(widget: UserSelect());
  }
}

class UserSelect extends ConsumerWidget {
  const UserSelect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> subNotif = ref.read(subHolderProvider);
    final SubUser? current = subNotif.valueOrNull?.selected;
    final List<SubUser> subUsers = subNotif.valueOrNull?.subUsers ?? [];
    final Color action = Theme.of(context).colorScheme.secondary;
    return Stack(
      children: [
        Positioned.fill(
            child: Container(
          color: Colors.black.withOpacity(0.9),
        )),
        Positioned.fill(
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text(
                    'Select Patient',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  IconButton(
                      onPressed: () {
                        _close(ref);
                      },
                      iconSize: 35,
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: action,
                      )),
                  const Spacer(),
                  IconButton(
                      onPressed: () {
                        _close(ref);
                      },
                      iconSize: 35,
                      icon: Icon(
                        Icons.close,
                        color: action,
                      ))
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subUsers
                      .map((user) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: user.uid == current?.uid
                              ? _getSelected(ref, context, user, action)
                              : _getSelectible(ref, context, user)))
                      .toList(),
                ),
              ],
            ),
          )),
        )
      ],
    );
  }

  Widget _getSelected(
      WidgetRef ref, BuildContext context, SubUser current, Color selected) {
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: selected),
            ),
            Icon(
              Icons.check,
              color: selected,
              size: 35,
            ),
          ],
        ));
  }

  Widget _getSelectible(WidgetRef ref, BuildContext context, SubUser user) {
    final String firstName = user.name.split(' ')[0];
    return InkWell(
      onTap: () {
        ref.read(subHolderProvider.notifier).changeCurrent(user);
        _close(ref);
      },
      splashFactory: NoSplash.splashFactory,
      child: Text(
        firstName,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.white),
      ),
    );
  }

  _close(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }
}
