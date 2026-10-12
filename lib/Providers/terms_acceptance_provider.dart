import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Models/terms_acceptance.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/UI/Resources/terms_of_service.dart';

/// Account-keyed so a pending write cannot accept terms for another account.
final termsAcceptanceProvider =
    AsyncNotifierProvider.family<
      TermsAcceptanceNotifier,
      TermsAcceptance?,
      String
    >(TermsAcceptanceNotifier.new, retry: (_, _) => null);

class TermsAcceptanceNotifier extends AsyncNotifier<TermsAcceptance?> {
  final String accountId;

  TermsAcceptanceNotifier(this.accountId);

  @override
  Future<TermsAcceptance?> build() =>
      ref.watch(sharedSeviceProvider).getTermsAcceptance(accountId);

  Future<void> accept() async {
    if (accountId.isEmpty) throw StateError('No account selected');
    await future;
    final acceptance = TermsAcceptance(
      version: stripesTermsVersion,
      acceptedAt: DateTime.now().toUtc(),
    );
    await ref
        .read(sharedSeviceProvider)
        .setTermsAcceptance(accountId, acceptance);
    if (ref.mounted) state = AsyncData(acceptance);
  }
}
