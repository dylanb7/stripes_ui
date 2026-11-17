import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class TestAsyncError extends ConsumerWidget {
  final Object error;

  const TestAsyncError({required this.error, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load test data: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: AppPadding.medium),
            TextButton(
              onPressed: () => ref.invalidate(testProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
