import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Provider for study onboarding state.
final studyOnboardingProvider =
    StateNotifierProvider<StudyOnboardingNotifier, StudyOnboardingState>(
  (ref) => StudyOnboardingNotifier(ref),
);

class StudyOnboardingState {
  final bool isLoading;
  final bool hasCompletedOnboarding;
  final String? currentGroup;

  const StudyOnboardingState({
    this.isLoading = true,
    this.hasCompletedOnboarding = false,
    this.currentGroup,
  });

  StudyOnboardingState copyWith({
    bool? isLoading,
    bool? hasCompletedOnboarding,
    String? currentGroup,
  }) {
    return StudyOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      currentGroup: currentGroup ?? this.currentGroup,
    );
  }
}

class StudyOnboardingNotifier extends StateNotifier<StudyOnboardingState> {
  final Ref ref;
  static const String _onboardingKey = 'study_onboarding_completed';

  StudyOnboardingNotifier(this.ref) : super(const StudyOnboardingState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final AuthUser user = await ref.read(authStream.future);
    final String? group = user.attributes['custom:group'];
    final bool completed = prefs.getBool('$_onboardingKey:$group') ?? false;

    state = state.copyWith(
      isLoading: false,
      hasCompletedOnboarding: group == null || completed,
      currentGroup: group,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.currentGroup == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_onboardingKey:${state.currentGroup}', true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  // For testing/debugging
  Future<void> resetOnboarding() async {
    if (state.currentGroup == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_onboardingKey:${state.currentGroup}');
    state = state.copyWith(hasCompletedOnboarding: false);
  }
}

/// A gate that shows study terms of service and info before allowing access.
class StudyGate extends ConsumerWidget {
  final Widget child;
  final Widget Function(VoidCallback onComplete) studyInfoBuilder;

  const StudyGate({
    required this.child,
    required this.studyInfoBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyOnboardingProvider);

    if (state.isLoading) {
      return child;
    }

    if (state.hasCompletedOnboarding) {
      return child;
    }

    // User is in a study group but hasn't completed onboarding
    return Scaffold(
      body: SafeArea(
        child: studyInfoBuilder(() {
          ref.read(studyOnboardingProvider.notifier).completeOnboarding();
        }),
      ),
    );
  }
}

/// A simple default study gate content widget.
class DefaultStudyGateContent extends StatefulWidget {
  final VoidCallback onComplete;
  final String studyTitle;
  final String studyDescription;
  final String termsText;

  const DefaultStudyGateContent({
    required this.onComplete,
    required this.studyTitle,
    required this.studyDescription,
    required this.termsText,
    super.key,
  });

  @override
  State<DefaultStudyGateContent> createState() =>
      _DefaultStudyGateContentState();
}

class _DefaultStudyGateContentState extends State<DefaultStudyGateContent> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studyTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    Text(widget.studyDescription),
                    const SizedBox(height: AppPadding.large),
                    Text(
                      'Terms of Service',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppPadding.small),
                    Container(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(widget.termsText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(AppPadding.medium),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _agreed,
                          onChanged: (value) {
                            setState(() {
                              _agreed = value ?? false;
                            });
                          },
                          fillColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'I have read and agree to the terms of service',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.small),
                    FilledButton(
                      onPressed: _agreed ? widget.onComplete : null,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
