import 'package:flutter/foundation.dart';

@immutable
class AsyncUiCallback {
  final void Function({String? err}) onError;
  final void Function() onSuccess;

  const AsyncUiCallback({
    required this.onSuccess,
    required this.onError,
  });
}
