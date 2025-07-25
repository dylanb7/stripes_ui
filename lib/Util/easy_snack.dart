import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnack(
    BuildContext context, String message,
    {Function? action, String? actionMessage}) {
  if (!context.mounted) return null;
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      dismissDirection: DismissDirection.down,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
          left: AppPadding.tiny,
          right: AppPadding.tiny,
          bottom: AppPadding.tiny),
      action: action != null
          ? SnackBarAction(
              label: actionMessage ?? context.translate.undo,
              onPressed: () {
                action();
              })
          : null,
    ),
  );
}
