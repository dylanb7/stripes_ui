import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Questions/record_session_provider.dart';

typedef SessionEntryBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  RecordSessionState session,
);

/// Shared async/lifecycle boundary for record and baseline entry flows.
class SessionEntryScaffold extends ConsumerWidget {
  final RecordSessionArgs args;
  final SessionEntryBuilder builder;
  final String errorLabel;

  const SessionEntryScaffold({
    required this.args,
    required this.builder,
    this.errorLabel = 'Unable to load session',
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(recordSessionProvider(args));
    return sessionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('$errorLabel: $error')),
      data: (session) {
        if (session.sessionGraph.data.hasUnresolvedResponses) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record unavailable')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Some saved answers need question definitions that are '
                  'missing or incompatible. Your answers are retained. '
                  'Load the matching questions before editing this record.',
                ),
              ),
            ),
          );
        }
        return builder(context, ref, session);
      },
    );
  }
}
