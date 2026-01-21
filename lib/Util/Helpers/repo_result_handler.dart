import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';

extension RepoResultHandler<T> on RepoResult<T> {
  void handle(BuildContext context,
      {Function(T)? onSuccess, Function(Failure)? onFailure}) {
    if (this is Success<T>) {
      if (onSuccess != null) {
        onSuccess((this as Success<T>).data);
      }
    } else if (this is Failure<T>) {
      final failure = this as Failure<T>;
      if (onFailure != null) {
        onFailure(failure);
      } else {
        showSnack(context, failure.message);
      }
    }
  }
}
