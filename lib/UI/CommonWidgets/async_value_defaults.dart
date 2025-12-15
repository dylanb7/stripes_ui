import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';

class AsyncValueDefaults<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) onData;
  final Widget Function(AsyncError<T>)? onError;
  final Widget Function(AsyncLoading<T>)? onLoading;

  const AsyncValueDefaults(
      {required this.value,
      required this.onData,
      this.onError,
      this.onLoading,
      super.key});

  @override
  Widget build(BuildContext context) {
    return value.when(
        skipLoadingOnReload: true,
        data: (data) => onData(data),
        error: (error, stack) {
          if (onError != null) {
            return onError!(AsyncError(error, stack));
          }
          return Center(
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
        },
        loading: () {
          if (onLoading != null) {
            return onLoading!(AsyncLoading<T>());
          }
          return const LoadingWidget();
        });
  }
}
