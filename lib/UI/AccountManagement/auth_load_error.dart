import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

/// Account metadata is unknown; keep retry and sign-out available before routes.
class AuthLoadError extends ConsumerStatefulWidget {
  const AuthLoadError({super.key});

  @override
  ConsumerState<AuthLoadError> createState() => _AuthLoadErrorState();
}

class _AuthLoadErrorState extends ConsumerState<AuthLoadError> {
  bool _refreshing = false;
  bool _signingOut = false;
  String? _error;

  Future<void> _retry() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await ref.read(authProvider).refresh();
    } catch (_) {
      if (mounted && !_signingOut) {
        setState(
          () => _error = 'Unable to refresh your account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await ref.read(authProvider).logOut();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unable to load your account. Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppPadding.medium),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppPadding.medium),
                FilledButton(
                  onPressed: _refreshing || _signingOut ? null : _retry,
                  child: Text(_refreshing ? 'Trying again…' : 'Try again'),
                ),
                TextButton(
                  onPressed: _signingOut ? null : _signOut,
                  child: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
