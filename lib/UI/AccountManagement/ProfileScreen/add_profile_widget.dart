import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/constants.dart';

// ---------------------------------------------------------------------------
// AddUserWidget — a simple "Add Profile" button that pushes the full-screen
// onboarding wizard route (RouteName.ADD_PROFILE).
// The expandable-card form previously here has been replaced by the unified
// ProfileOnboardingWizard to give the same guided step flow as first-profile
// creation, including baseline collection.
// ---------------------------------------------------------------------------

class AddUserWidget extends StatelessWidget {
  const AddUserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.large,
          vertical: AppPadding.medium,
        ),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRounding.small),
        ),
        foregroundColor: colors.onSurface,
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => context.pushNamed(RouteName.ADD_PROFILE),
      icon: Icon(Icons.add, color: colors.primary),
      label: Text(
        'Add Profile',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
