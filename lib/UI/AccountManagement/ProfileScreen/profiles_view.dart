import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/edit_profile.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';

import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/paddings.dart';

class ProfileView extends ConsumerWidget {
  final SubUser subUser;

  final bool selected;

  const ProfileView({required this.subUser, required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);

    final Widget controlRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        selected
            ? TextButton(
                onPressed: null,
                child: Text(
                  'Selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
            _editPatient(ref, context);
          },
          icon: const Icon(Icons.edit),
        )
      ],
    );

    return Expandible(
      canExpand: isSmall,
      highlightColor: selected ? Theme.of(context).colorScheme.primary : null,
      highlightOnShrink: true,
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
        child: Text(
          subUser.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      view: Column(
        children: [
          const SizedBox(
            height: AppPadding.tiny,
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
                width: AppPadding.large,
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
            height: AppPadding.small,
          ),
          controlRow,
          const SizedBox(
            height: AppPadding.small,
          ),
        ],
      ),
    );
  }

  _changeToCurrent(WidgetRef ref) {
    ref.read(subHolderProvider.notifier).changeCurrent(subUser);
  }

  _editPatient(WidgetRef ref, BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => EditUserWidget(subUser: subUser));
  }
}

class MinimalProfileView extends ConsumerWidget {
  final SubUser subUser;

  final bool selected;

  const MinimalProfileView(
      {required this.subUser, required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primary = Theme.of(context).primaryColor;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color text = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        if (!selected) {
          _changeToCurrent(ref);
        }
      },
      child: AnimatedContainer(
        duration: Durations.short1,
        decoration: BoxDecoration(
            color: selected ? primary : surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRounding.medium),
            ),
            border: selected ? null : Border.all(width: 1.0, color: text)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.tiny, vertical: AppPadding.tiny),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppPadding.small),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    subUser.name,
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: selected ? surface : text),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _editProfile(ref, context);
                },
                icon: Icon(
                  Icons.edit,
                  color: selected ? surface : text,
                ),
              ),
              IconButton(
                onPressed: () {
                  _deleteProfile(ref, context);
                },
                icon: Icon(
                  Icons.delete,
                  color: selected ? surface : text,
                ),
              ),
              const SizedBox(
                width: AppPadding.tiny,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _changeToCurrent(WidgetRef ref) {
    ref.read(subHolderProvider.notifier).changeCurrent(subUser);
  }

  _editProfile(WidgetRef ref, BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => EditUserWidget(subUser: subUser));
  }

  _deleteProfile(WidgetRef ref, BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => DeleteConfirmation(toDelete: subUser));
  }
}

class DeleteConfirmation extends ConsumerWidget {
  final SubUser toDelete;

  const DeleteConfirmation({required this.toDelete, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
      title: Text(
        "Delete Profile",
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(color: Theme.of(context).primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.small),
        child: Text(
            "This action is irreversable and will delete all entries associated with ${toDelete.name}"),
      ),
      cancel: 'Cancel',
      confirm: 'Confirm',
      onConfirm: () async {
        if (!await _deleteSubUser(ref) && context.mounted) {
          showSnack(context, "Failed to delete ${toDelete.name}");
        }
      },
    );
  }

  Future<bool> _deleteSubUser(WidgetRef ref) async {
    final SubUserRepo? repo = await ref.read(subProvider.future);
    if (repo == null) return false;
    return repo.deleteSubUser(toDelete);
  }
}
