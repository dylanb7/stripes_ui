import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';

import 'add_profile_widget.dart';
import 'profiles_view.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ref
        .watch(subHolderProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const LoadingWidget(),
          error: (error, stack) => Center(
            child: Text(
              'Unable to load profiles: $error',
              style: TextStyle(color: colors.error),
            ),
          ),
          data: (subState) {
            final current = subState.selected;
            final showDetails = config.profileType == ProfileType.name;
            final condition = current != null && showDetails
                ? ref.watch(profileConditionProvider(current.uid)).value
                : null;
            return RefreshWidget(
              depth: RefreshDepth.subuser,
              scrollable: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppPadding.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Breakpoint.small.value,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.small,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back to account',
                                onPressed: () =>
                                    context.goNamed(RouteName.ACCOUNT),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              Expanded(
                                child: Text(
                                  'Profiles',
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (current != null)
                          Semantics(
                            container: true,
                            child: Container(
                              key: const ValueKey('current-profile-banner'),
                              color: colors.primary,
                              padding: const EdgeInsets.all(AppPadding.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current profile',
                                    style: text.labelLarge?.copyWith(
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.tiny),
                                  Text(
                                    current.name,
                                    style: text.headlineSmall?.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (showDetails &&
                                      profileDetails(
                                        current,
                                        condition,
                                      ).isNotEmpty)
                                    Text(
                                      profileDetails(current, condition),
                                      style: text.bodyMedium?.copyWith(
                                        color: colors.onPrimary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppPadding.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Choose who you are recording for. Home, Record and History show the current profile’s data.',
                                style: text.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppPadding.xl),
                              for (final user in subState.subUsers) ...[
                                if (showDetails)
                                  ProfileView(
                                    subUser: user,
                                    selected: user.uid == current?.uid,
                                  )
                                else
                                  MinimalProfileView(
                                    subUser: user,
                                    selected: user.uid == current?.uid,
                                  ),
                                const SizedBox(height: AppPadding.large),
                              ],
                              const AddUserWidget(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }
}
