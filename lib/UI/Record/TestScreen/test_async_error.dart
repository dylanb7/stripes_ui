import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class TestAsyncError extends StatelessWidget {
  final Object error;

  const TestAsyncError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Text(
          'Unable to load test data: $error',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
