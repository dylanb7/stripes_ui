import 'dart:async';

export 'onboarding_header.dart' show OnboardingProgressBar;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/Resources/resource_article.dart';
import 'package:stripes_ui/UI/Resources/resource_sheet.dart';
import 'package:stripes_ui/UI/AccountManagement/onboarding_header.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_condition_field.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/Questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/baseline_entry.dart';
import 'package:stripes_ui/Util/Helpers/form_input.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

// ---------------------------------------------------------------------------
// ProfileOnboardingWizard
//
// Step 0      : profile form
// Step 1…N    : one embedded BaselineEntry per incomplete BaselineTrigger
// Step N+1    : optional AppTourStep (showTour)
//
// Questions and baselines load only after the newly created profile has
// appeared in the repository stream and has been selected.
// ---------------------------------------------------------------------------

class ProfileOnboardingWizard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;

  /// Append an "Overview" tour step after all baselines (first-profile only).
  final bool showTour;

  /// Called once the wizard completes (pop, navigate, etc.).
  final VoidCallback? onFinished;

  const ProfileOnboardingWizard({
    super.key,
    required this.title,
    required this.subtitle,
    this.headerIcon = Icons.person_add_outlined,
    this.showTour = false,
    this.onFinished,
  });

  @override
  ConsumerState<ProfileOnboardingWizard> createState() =>
      _ProfileOnboardingWizardState();
}

class _ProfileOnboardingWizardState
    extends ConsumerState<ProfileOnboardingWizard> {
  // ── Profile form ──────────────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  final BirthYearController _yearController = BirthYearController();

  // ── Wizard state ──────────────────────────────────────────────────────────
  int _step = 0;
  List<BaselineTrigger> _triggers = [];
  bool _triggersLoaded = false;

  ProfileCondition? _condition;
  bool _loading = false;
  String? _error;
  SubUser? _createdProfile;
  ProviderSubscription<AsyncValue<SubState>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    // Defer ref.read calls until after initState completes — reading
    // Riverpod providers inside initState triggers the inherited-widget
    // dependency error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryEagerLoad();
    });
  }

  Future<void> _tryEagerLoad() async {
    final subState = ref.read(subHolderProvider);
    final SubUser? current = subState.value?.selected;
    if (current != null && !SubUser.isEmpty(current)) {
      try {
        await _loadTriggers();
      } catch (_) {
        // Profile creation can still proceed; retry for the new profile.
        if (mounted) setState(() => _triggersLoaded = true);
      }
    } else {
      // Mark loaded with empty list — bar renders as single "Profile" segment.
      if (mounted) setState(() => _triggersLoaded = true);
    }
  }

  Future<void> _loadTriggers() async {
    ref.invalidate(incompleteBaselinesProvider);
    // BaselineGate does not watch this chain during onboarding. Keep its
    // streams active until their first values arrive.
    final subscription = ref.listenManual(
      incompleteBaselinesProvider,
      (_, _) {},
    );
    try {
      final triggers = await ref.read(incompleteBaselinesProvider.future);
      if (!mounted) return;
      setState(() {
        _triggers = triggers;
        _triggersLoaded = true;
      });
    } finally {
      subscription.close();
    }
  }

  Future<void> _loadTriggersAndAdvance() async {
    await _loadTriggers();
    if (!mounted) return;

    // Move past the profile step.
    // If no baselines and no tour → finish immediately.
    if (_totalSteps <= 1) {
      _finish();
    } else {
      setState(() => _step = 1);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _profileSubscription?.close();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  int get _totalSteps => 1 + _triggers.length + (widget.showTour ? 1 : 0);

  bool get _isTourStep => widget.showTour && _step == 1 + _triggers.length;

  String _labelForStep(int index, QuestionsLocalizations? localizations) {
    if (index == 0) return 'Profile';
    if (widget.showTour && index == 1 + _triggers.length) return 'Overview';
    final i = index - 1;
    if (i >= _triggers.length) return '';
    final trigger = _triggers[i];
    return localizations?.value(trigger.baselineType) ?? trigger.title;
  }

  void _advanceStep() {
    final int next = _step + 1;
    if (next >= _totalSteps) {
      _finish();
    } else {
      setState(() => _step = next);
    }
  }

  void _finish() => widget.onFinished?.call();

  // ── Profile submit ────────────────────────────────────────────────────────
  Future<void> _submitProfile() async {
    if (_loading) return;
    final bool isName =
        ref.read(configProvider).profileType == ProfileType.name;
    if (_createdProfile == null) {
      _formKey.currentState?.save();
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_createdProfile == null) {
        final SubUser user = isName
            ? SubUser(
                name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
                gender: '',
                birthYear: _yearController.year,
                isControl: false,
              )
            : SubUser(
                name: _firstName.text.trim(),
                gender: '',
                birthYear: 0,
                isControl: false,
              );
        final subRepo = await ref.read(subProvider.future);
        if (!mounted) return;
        final result = await subRepo?.addSubUser(user);
        if (!mounted) return;
        _createdProfile = result is Success<SubUser?> ? result.data : null;
        if (_createdProfile == null) {
          throw StateError('Profile creation failed');
        }
      }

      final newSubUser = _createdProfile!;
      if (isName) {
        await ref
            .read(profileConditionProvider(newSubUser.uid).notifier)
            .save(_condition);
        if (!mounted) return;
      }
      final userReady = Completer<void>();
      _profileSubscription = ref.listenManual<AsyncValue<SubState>>(
        subHolderProvider,
        (_, next) {
          if (userReady.isCompleted) return;
          if (next.hasError) {
            userReady.completeError(next.error!, next.stackTrace);
          } else if (next.value?.subUsers.any(
                (user) => user.uid == newSubUser.uid,
              ) ??
              false) {
            userReady.complete();
          }
        },
        fireImmediately: true,
      );
      await userReady.future.timeout(const Duration(seconds: 20));
      _profileSubscription?.close();
      _profileSubscription = null;
      if (!mounted) return;

      final selected = await ref
          .read(subHolderProvider.notifier)
          .changeCurrent(newSubUser);
      if (!mounted) return;
      if (!selected) throw StateError('Profile selection failed');

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await ref.read(questionsProvider.future);
      if (!mounted) return;
      await _loadTriggersAndAdvance();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _createdProfile == null
              ? 'We could not create your profile. Please try again.'
              : 'Your profile was created, but setup could not finish. '
                    'Please continue setup to try again.';
        });
      }
    } finally {
      _profileSubscription?.close();
      _profileSubscription = null;
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Skip ──────────────────────────────────────────────────────────────────
  void _skipBaseline(BaselineTrigger trigger) {
    ref.read(baselineDismissProvider.notifier).dismiss(trigger.baselineType);
    _advanceStep();
  }

  // ── Baseline completed ────────────────────────────────────────────────────
  void _onBaselineCompleted() {
    ref.invalidate(baselinesStreamProvider);
    if (!mounted) return;
    _advanceStep();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    // Keep the form mounted while saving so failed requests preserve every
    // field, including the birth-year FormField state.
    final bool showLoading = _step > 0 && (_loading || !_triggersLoaded);

    // Clamp defensively.
    final int safeStep = _step.clamp(0, _totalSteps - 1);

    // Account terms precede first-profile setup; signup remains separate.
    final termsOffset =
        widget.showTour && ref.watch(configProvider).betaUi.onboardingTerms
        ? 1
        : 0;

    final header = OnboardingHeader(
      title: safeStep == 0
          ? widget.title
          : _labelForStep(safeStep, localizations),
      totalSteps: _totalSteps + termsOffset,
      currentStep: safeStep + termsOffset,
      labelForStep: (i) => i < termsOffset
          ? 'Terms and privacy'
          : _labelForStep(i - termsOffset, localizations),
      onBack: safeStep == 0 && termsOffset > 0 ? _reviewTerms : null,
      backTooltip: 'Review terms and privacy',
    );

    // Scroll the title with the form so the action still fits when the
    // keyboard is open or the user increases their reading size.
    if (safeStep == 0) {
      return _ProfileStep(
        header: header,
        formKey: _formKey,
        firstName: _firstName,
        lastName: _lastName,
        yearController: _yearController,
        condition: _condition,
        onConditionChanged: (value) => _condition = value,
        isLoading: _loading,
        profileCreated: _createdProfile != null,
        error: _error,
        subtitle: widget.subtitle,
        onSubmit: _submitProfile,
      );
    }

    if (_isTourStep && !showLoading) {
      return AppTourStep(header: header, onDone: _finish);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: showLoading
              ? const Center(child: CircularProgressIndicator())
              : _BaselineStep(
                  key: ValueKey(_triggers[safeStep - 1].baselineType),
                  trigger: _triggers[safeStep - 1],
                  onCompleted: _onBaselineCompleted,
                  onSkip: () => _skipBaseline(_triggers[safeStep - 1]),
                ),
        ),
      ],
    );
  }

  void _reviewTerms() {
    FocusScope.of(context).unfocus();
    ref
        .read(sheetControllerProvider)
        .show<void>(
          context: context,
          scrollControlled: true,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          sheetBuilder: (context, controller) => ResourceSheetBody(
            topic: ResourceTopic.termsOfService,
            scrollController: controller,
          ),
        );
  }
}

// ---------------------------------------------------------------------------
// AppTourStep
// ---------------------------------------------------------------------------

class AppTourStep extends StatefulWidget {
  final VoidCallback onDone;
  final Widget? header;

  const AppTourStep({super.key, required this.onDone, this.header});

  @override
  State<AppTourStep> createState() => _AppTourStepState();
}

class _AppTourStepState extends State<AppTourStep> {
  final _scrollController = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _sections = [
    _TourSection(
      icon: Icons.add_circle_outline,
      label: 'Record',
      description:
          'Log symptoms, meals, and events as they happen. '
          'Quick entry keeps tracking simple and consistent.',
    ),
    _TourSection(
      icon: Icons.history_outlined,
      label: 'History',
      description:
          'Review past entries in a timeline. '
          'Spot patterns and share a full picture with your care team.',
    ),
    _TourSection(
      icon: Icons.menu,
      label: 'Menu',
      description:
          'Manage profiles and adjust settings. '
          'Open Menu using the icon in the top-right.',
    ),
    _TourSection(
      icon: Icons.menu_book_outlined,
      label: 'Help and resources',
      description:
          'Find STRiPES guides, study instructions, and tracking tips in '
          'Menu → Help and resources. You can review the Terms of Service there too.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            primary: false,
            child: Column(
              children: [
                ?widget.header,
                Padding(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppPadding.large),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 36,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: AppPadding.medium),
                              Text(
                                "You're all set!",
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppPadding.small),
                              Text(
                                'Your profile is ready. Start logging to build '
                                'a clearer picture of your health.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppPadding.large),

                          ..._sections.map(
                            (s) => _TourCard(section: s, colors: colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FilledButton(
                  onPressed: widget.onDone,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.all(AppPadding.medium),
                  ),
                  child: const Text(
                    'Continue to Home',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TourSection {
  final IconData icon;
  final String label;
  final String description;

  const _TourSection({
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _TourCard extends StatelessWidget {
  final _TourSection section;
  final ColorScheme colors;

  const _TourCard({required this.section, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRounding.small),
                ),
                child: Icon(section.icon, size: 22, color: colors.primary),
              ),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      section.description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileStep
// ---------------------------------------------------------------------------

class _ProfileStep extends ConsumerWidget {
  final Widget header;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final BirthYearController yearController;
  final ProfileCondition? condition;
  final ValueChanged<ProfileCondition?> onConditionChanged;
  final bool isLoading;
  final bool profileCreated;
  final String? error;
  final String subtitle;
  final VoidCallback onSubmit;

  const _ProfileStep({
    required this.header,
    required this.formKey,
    required this.firstName,
    required this.lastName,
    required this.yearController,
    required this.condition,
    required this.onConditionChanged,
    required this.isLoading,
    required this.profileCreated,
    required this.error,
    required this.subtitle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FocusTraversalGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    header,
                    Padding(
                      padding: const EdgeInsets.all(AppPadding.large),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: AppPadding.large),
                              AbsorbPointer(
                                absorbing: isLoading || profileCreated,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (config.profileType ==
                                        ProfileType.name) ...[
                                      TextFormField(
                                        validator: (name) =>
                                            _requiredName(name, 'first name'),
                                        controller: firstName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        decoration: formFieldDecoration(
                                          hintText: 'First name',
                                          controller: firstName,
                                          clearable: false,
                                        ),
                                      ),
                                      const SizedBox(height: AppPadding.large),
                                      TextFormField(
                                        validator: (name) =>
                                            _requiredName(name, 'last name'),
                                        controller: lastName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        decoration: formFieldDecoration(
                                          hintText: 'Last name',
                                          controller: lastName,
                                          clearable: false,
                                        ),
                                      ),
                                      const SizedBox(height: AppPadding.large),
                                      BirthYearSelector(
                                        controller: yearController,
                                        context: context,
                                      ),
                                      const SizedBox(height: AppPadding.large),
                                      ProfileConditionField(
                                        initialValue: condition,
                                        required: true,
                                        enabled: !isLoading && !profileCreated,
                                        onChanged: onConditionChanged,
                                      ),
                                    ] else ...[
                                      TextFormField(
                                        validator: (name) =>
                                            _requiredName(name, 'username'),
                                        controller: firstName,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => onSubmit(),
                                        decoration: formFieldDecoration(
                                          hintText: 'Username',
                                          controller: firstName,
                                          clearable: false,
                                        ),
                                      ),
                                      const SizedBox(height: AppPadding.small),
                                      Text(
                                        'Use a name or nickname to identify this profile.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppPadding.large),
                              Text(
                                'You can edit these details or add another profile later.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                              if (error != null) ...[
                                const SizedBox(height: AppPadding.large),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    error!,
                                    style: TextStyle(color: colors.error),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: FilledButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.all(AppPadding.medium),
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: 'Creating your profile',
                              ),
                            )
                          : Text(
                              profileCreated
                                  ? 'Continue setup'
                                  : 'Create profile',
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredName(String? name, String label) =>
      name == null || name.trim().isEmpty ? 'Please enter a $label' : null;
}

// ---------------------------------------------------------------------------
// _BaselineStep
// ---------------------------------------------------------------------------

class _BaselineStep extends ConsumerWidget {
  final BaselineTrigger trigger;
  final VoidCallback onCompleted;
  final VoidCallback onSkip;

  const _BaselineStep({
    super.key,
    required this.trigger,
    required this.onCompleted,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );
    final String baselineName =
        localizations?.value(trigger.baselineType) ?? trigger.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.surfaceContainerLow,
          padding: const EdgeInsets.fromLTRB(
            AppPadding.large,
            AppPadding.medium,
            AppPadding.large,
            AppPadding.medium,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A few quick questions about $baselineName',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppPadding.tiny),
                    Text(
                      'These help us tailor what we ask you when tracking. '
                      'You can update your answers any time in Menu → Baselines.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppPadding.small),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: colors.outline,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                  ),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _ScopedBaselineNavigator(
            trigger: trigger,
            onCompleted: onCompleted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scoped Navigator — isolates BaselineEntry's pop from the wizard route.
// ---------------------------------------------------------------------------

class _ScopedBaselineNavigator extends StatefulWidget {
  final BaselineTrigger trigger;
  final VoidCallback onCompleted;

  const _ScopedBaselineNavigator({
    required this.trigger,
    required this.onCompleted,
  });

  @override
  State<_ScopedBaselineNavigator> createState() =>
      _ScopedBaselineNavigatorState();
}

class _ScopedBaselineNavigatorState extends State<_ScopedBaselineNavigator> {
  late final GlobalKey<NavigatorState> _navKey;

  @override
  void initState() {
    super.initState();
    _navKey = GlobalKey<NavigatorState>();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        // PopScope(canPop:false) absorbs any context.pop() that BaselineEntry
        // fires after submit, preventing it from leaking into the main navigator.
        builder: (_) => PopScope(
          canPop: false,
          child: _SubmitAwareBaselineEntry(
            trigger: widget.trigger,
            onCompleted: widget.onCompleted,
          ),
        ),
      ),
    );
  }
}

/// Watches baselinesStreamProvider and calls [onCompleted] directly the moment
/// the trigger's stamp appears.  We do NOT rely on context.pop() timing
/// because BaselineEntry pops before the stamp is persisted; by the time the
/// stream updates, there is no pending pop to intercept.
class _SubmitAwareBaselineEntry extends ConsumerStatefulWidget {
  final BaselineTrigger trigger;
  final VoidCallback onCompleted;

  const _SubmitAwareBaselineEntry({
    required this.trigger,
    required this.onCompleted,
  });

  @override
  ConsumerState<_SubmitAwareBaselineEntry> createState() =>
      _SubmitAwareBaselineEntryState();
}

class _SubmitAwareBaselineEntryState
    extends ConsumerState<_SubmitAwareBaselineEntry> {
  // Guard: only fire onCompleted once even if the stream emits multiple times.
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final stampsAsync = ref.watch(baselinesStreamProvider);
    return AsyncValueDefaults(
      value: stampsAsync,
      onData: (stamps) {
        if (!_completed && widget.trigger.isComplete(stamps)) {
          _completed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onCompleted();
          });
        }
        return BaselineEntry(
          recordPath: widget.trigger.recordPath,
          isEmbedded: true,
        );
      },
    );
  }
}
