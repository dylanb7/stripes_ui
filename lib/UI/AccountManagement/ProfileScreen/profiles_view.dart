import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/edit_profile.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/splitter.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/easy_snack.dart';

class UserView extends ConsumerWidget {
  final SubUser subUser;

  final bool selected;

  const UserView({required this.subUser, required this.selected, super.key});

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
            _editPatient(ref);
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
        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
          controlRow,
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
        CurrentOverlay(widget: EditUserWidget(subUser: subUser));
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? primary : surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  subUser.name,
                  textAlign: TextAlign.left,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: selected ? surface : text),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _editProfile(ref);
                },
                icon: Icon(
                  Icons.edit,
                  color: selected ? surface : text,
                ),
              ),
              const SizedBox(
                width: 6.0,
              ),
              IconButton(
                onPressed: () {
                  _deleteProfile(ref);
                },
                icon: Icon(
                  Icons.delete,
                  color: selected ? surface : text,
                ),
              ),
              const SizedBox(
                width: 6.0,
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

  _editProfile(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        CurrentOverlay(widget: EditUserWidget(subUser: subUser));
  }

  _deleteProfile(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        CurrentOverlay(widget: DeleteConfirmation(toDelete: subUser));
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
      body: Text(
          "This action is irreversable and will delete all entries associated with ${toDelete.name}"),
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
