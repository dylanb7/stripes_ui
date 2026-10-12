import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/terms_acceptance_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/onboarding_header.dart';
import 'package:stripes_ui/UI/Resources/resource_markdown.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Runs before all app routes, including deep links and baseline prompts.
/// App terms are accepted for the account, not for each care recipient/study.
class TermsOnboardingGate extends ConsumerWidget {
  final Widget child;

  const TermsOnboardingGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(configProvider).betaUi.onboardingTerms) return child;
    final account = ref.watch(authStream);
    if (account.isLoading) return const _TermsLoading();
    if (account.hasError) {
      return _TermsLoadError(onRetry: () => ref.invalidate(authStream));
    }
    final accountId = account.value?.uid;
    // Authentication remains owned by the embedding app.
    if (accountId == null || accountId.isEmpty) return const _TermsLoading();

    final provider = termsAcceptanceProvider(accountId);
    final acceptance = ref.watch(provider);
    if (acceptance.isLoading) return const _TermsLoading();
    if (acceptance.hasError) {
      return _TermsLoadError(onRetry: () => ref.invalidate(provider));
    }
    if (acceptance.value?.version == stripesTermsVersion) return child;
    return _TermsOnboardingScreen(
      key: ValueKey(accountId),
      accountId: accountId,
    );
  }
}

class _TermsOnboardingScreen extends ConsumerStatefulWidget {
  final String accountId;

  const _TermsOnboardingScreen({required this.accountId, super.key});

  @override
  ConsumerState<_TermsOnboardingScreen> createState() =>
      _TermsOnboardingScreenState();
}

class _TermsOnboardingScreenState
    extends ConsumerState<_TermsOnboardingScreen> {
  final _scrollController = ScrollController();
  bool _agreed = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (!_agreed || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(termsAcceptanceProvider(widget.accountId).notifier)
          .accept();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We couldn’t save your agreement. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      if (await launchUrl(Uri.parse(stripesPrivacyPolicyUrl))) return;
    } catch (_) {
      // Keep the document and agreement in place if the browser cannot open.
    }
    if (mounted) {
      setState(
        () => _error =
            'Unable to open the Privacy Policy. '
            'Please visit $stripesPrivacyPolicyUrl in your browser.',
      );
    }
  }

  Future<void> _signOut() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(authProvider).logOut();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstProfile =
        ref.watch(subHolderProvider).asData?.value.subUsers.isEmpty ?? false;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  key: const Key('onboarding-terms-scroll'),
                  child: Column(
                    children: [
                      OnboardingHeader(
                        title: 'Terms and privacy',
                        totalSteps: isFirstProfile ? 3 : 1,
                        currentStep: 0,
                        labelForStep: (index) => const [
                          'Terms and privacy',
                          'Profile',
                          'Overview',
                        ][index],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppPadding.large),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Breakpoint.medium.value,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _saving ? null : _signOut,
                                    child: const Text('Sign out'),
                                  ),
                                ),
                                const Text(
                                  'Please review the Terms of Service and Privacy Policy before continuing.',
                                ),
                                const SizedBox(height: AppPadding.large),
                                const ResourceMarkdown(
                                  data: stripesTermsOfServiceMarkdown,
                                ),
                                const SizedBox(height: AppPadding.medium),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _openPrivacyPolicy,
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Read Privacy Policy'),
                                  ),
                                ),
                                const SizedBox(height: AppPadding.medium),
                                CheckboxListTile(
                                  key: const Key('onboarding-terms-agreement'),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: _agreed,
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(
                                          () => _agreed = value ?? false,
                                        ),
                                  title: const Text(
                                    'I agree to the Terms of Service and have read the Privacy Policy.',
                                  ),
                                ),
                                const SizedBox(height: AppPadding.small),
                                const Text(
                                  'Research studies have their own participation and consent process.',
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: AppPadding.medium),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
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
              Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Breakpoint.medium.value,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _agreed && !_saving ? _accept : null,
                      child: Text(_saving ? 'Saving…' : 'Agree and continue'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsLoading extends StatelessWidget {
  const _TermsLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _TermsLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TermsLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to check your terms agreement.'),
              const SizedBox(height: AppPadding.medium),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    ),
  );
}
