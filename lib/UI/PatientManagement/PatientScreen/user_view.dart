import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/Util/constants.dart';

import 'edit_patient.dart';

class UserView extends ConsumerWidget {
  final SubUser subUser;

  final bool selected;

  const UserView({required this.subUser, required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    return Expandible(
      canExpand: isSmall,
      highlightColor: selected ? Theme.of(context).colorScheme.secondary : null,
      highlightOnShrink: true,
      header: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subUser.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      view: Column(
        children: [
          const SizedBox(
            height: 6.0,
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Birth Year:",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    "Gender:",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(
                width: 16.0,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${subUser.birthYear}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    subUser.gender,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(
            height: 6.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              selected
                  ? Text(
                      'Current Patient',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : TextButton(
                      child: const Text('Select'),
                      onPressed: () {
                        _changeToCurrent(ref);
                      },
                    ),
              IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  _editPatient(ref);
                },
                icon: const Icon(Icons.edit),
              )
            ],
          ),
          const SizedBox(
            height: 6.0,
          ),
        ],
      ),
    );
  }

  _changeToCurrent(WidgetRef ref) {
    ref.read(subHolderProvider.notifier).changeCurrent(subUser);
  }

  _editPatient(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        OverlayQuery(widget: EditUserWidget(subUser: subUser));
  }
}
