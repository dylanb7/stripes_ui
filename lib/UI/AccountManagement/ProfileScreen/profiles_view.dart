import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';

import 'edit_profile.dart';
import 'profile_avatar.dart';

String profileDetails(SubUser user, [ProfileCondition? condition]) => [
  if (condition != null) condition.label,
  if (user.birthYear > 0) 'Born ${user.birthYear}',
].join(' · ');

class ProfileView extends StatelessWidget {
  final SubUser subUser;
  final bool selected;

  const ProfileView({required this.subUser, required this.selected, super.key});

  @override
  Widget build(BuildContext context) =>
      _ProfileRow(subUser: subUser, selected: selected, showDetails: true);
}

class MinimalProfileView extends StatelessWidget {
  final SubUser subUser;
  final bool selected;

  const MinimalProfileView({
    required this.subUser,
    required this.selected,
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      _ProfileRow(subUser: subUser, selected: selected, showDetails: false);
}

class _ProfileRow extends ConsumerWidget {
  final SubUser subUser;
  final bool selected;
  final bool showDetails;

  const _ProfileRow({
    required this.subUser,
    required this.selected,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final condition = showDetails
        ? ref.watch(profileConditionProvider(subUser.uid)).value
        : null;
    final details = profileDetails(subUser, condition);
    return Semantics(
      selected: selected,
      container: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRounding.small),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('profile-row-${subUser.uid}'),
          onTap: selected ? null : () => _select(ref, context),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final edit = TextButton(
                  key: ValueKey('edit-profile-${subUser.uid}'),
                  onPressed: () => ref
                      .read(sheetControllerProvider)
                      .show<void>(
                        context: context,
                        scrollControlled: true,
                        avoidKeyboard: true,
                        child: (_) => EditUserWidget(subUser: subUser),
                      ),
                  child: const Text('Edit'),
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(name: subUser.name),
                    const SizedBox(width: AppPadding.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subUser.name,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (showDetails && details.isNotEmpty)
                            Text(
                              details,
                              style: text.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          if (selected) ...[
                            const SizedBox(height: AppPadding.small),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.small,
                                vertical: AppPadding.tiny,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Current profile',
                                style: text.labelMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                          if (stacked) edit,
                        ],
                      ),
                    ),
                    if (!stacked) ...[
                      const SizedBox(width: AppPadding.small),
                      edit,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, BuildContext context) async {
    try {
      final changed = await ref
          .read(subHolderProvider.notifier)
          .changeCurrent(subUser);
      if (!changed && context.mounted) {
        showSnack(context, 'Unable to switch profiles. Please try again.');
      }
    } catch (_) {
      if (context.mounted) {
        showSnack(context, 'Unable to switch profiles. Please try again.');
      }
    }
  }
}
