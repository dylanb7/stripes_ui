import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/extensions.dart';

showSnack(BuildContext context, String message,
    {Function? action, String? actionMessage}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    dismissDirection: DismissDirection.down,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0),
    action: action != null
        ? SnackBarAction(
            label: actionMessage ?? context.translate.undo,
            onPressed: () {
              action();
            })
        : null,
  ));
}
