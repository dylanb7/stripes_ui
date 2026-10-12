import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';

class PatientChanger extends ConsumerWidget {
  final TabOption tab;

  const PatientChanger({this.tab = TabOption.record, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> state = ref.watch(subHolderProvider);
    final StripesConfig config = ref.watch(configProvider);

    return state.when(
      skipLoadingOnReload: true,
      loading: () => const LoadingWidget(),
      error: (error, stack) => Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        semanticLabel: 'Unable to load profile: $error',
      ),
      data: (subState) {
        final SubUser? current = subState.selected;
        final List<SubUser> subUsers = subState.subUsers;
        final bool isMarker = current != null && SubUser.isMarker(current);

        String getTitle() {
          if (isMarker) {
            return tab == TabOption.record
                ? context.translate.recordTab
                : tab == TabOption.tests
                ? context.translate.testTab
                : context.translate.historyTab;
          }
          final String firstName = config.profileType == ProfileType.username
              ? current?.name ?? ''
              : (current?.name.split(' ')[0]) ?? '';
          return tab == TabOption.record
              ? (config.betaUi.dashboard
                    ? firstName
                    : context.translate.recordTitle(firstName))
              : tab == TabOption.tests
              ? context.translate.testTab
              : context.translate.historyTitle(firstName);
        }

        final canChange = subUsers.length > 1;
        final label = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                getTitle(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            if (canChange) ...[
              const SizedBox(width: AppPadding.tiny),
              Icon(
                Icons.keyboard_arrow_down,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ],
        );
        if (!canChange) return label;

        return Semantics(
          button: true,
          onTap: () => _openUserSelect(ref, context),
          label:
              '${tab == TabOption.record ? 'Recording for' : 'Current profile'} ${current?.name ?? ''}. Change profile',
          excludeSemantics: true,
          child: Tooltip(
            message: 'Change Profile',
            child: InkWell(
              onTap: () => _openUserSelect(ref, context),
              borderRadius: BorderRadius.circular(AppRounding.small),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.tiny,
                  ),
                  child: label,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openUserSelect(WidgetRef ref, BuildContext context) {
    ref
        .read(sheetControllerProvider)
        .show(
          context: context,
          scrollControlled: true,
          sheetBuilder: (context, controller) =>
              UserSelect(scrollController: controller),
        );
  }
}

class UserSelect extends ConsumerWidget {
  final ScrollController? scrollController;

  const UserSelect({this.scrollController, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> subNotif = ref.watch(subHolderProvider);
    final SubState? subState = subNotif.value;
    final SubUser? current = subState?.selected;
    final List<SubUser> subUsers = subState?.subUsers ?? [];
    final Color action = Theme.of(context).colorScheme.secondary;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: AppPadding.medium,
        right: AppPadding.medium,
        top: AppPadding.large,
        bottom: AppPadding.large,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Select Profile',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () {
                _close(context);
              },
              iconSize: 35,
              tooltip: 'Close',
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ],
        ),
        for (final user in subUsers)
          ListTile(
            key: ValueKey('select-profile-${user.uid}'),
            minTileHeight: 48,
            selected: user.uid == current?.uid,
            selectedColor: action,
            title: Text(
              user.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: user.uid == current?.uid ? const Icon(Icons.check) : null,
            onTap: () async {
              if (user.uid == current?.uid) {
                _close(context);
                return;
              }
              final changed = await ref
                  .read(subHolderProvider.notifier)
                  .changeCurrent(user);
              if (context.mounted && changed) _close(context);
            },
          ),
      ],
    );
  }

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }
}
