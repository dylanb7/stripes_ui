import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_onboarding_wizard.dart';

class CreatePatient extends ConsumerWidget {
  const CreatePatient({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ProfileOnboardingWizard(
            title: 'Care recipient details',
            subtitle:
                'Create a profile for the person whose symptoms '
                'you will track.',
            headerIcon: Icons.person_add_outlined,
            showTour: true,
            // Mark onboarding complete → Home switches to TabContent.
            onFinished: () =>
                ref.read(onboardingCompleteProvider.notifier).complete(),
          ),
        ),
      ),
    );
  }
}
