import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

showSnack(BuildContext context, String message,
    {Function? action, String? actionMessage}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    dismissDirection: DismissDirection.up,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(left: 6.0, right: 6.0, top: 6.0),
    action: action != null
        ? SnackBarAction(
            label: actionMessage ?? AppLocalizations.of(context)!.undo,
            onPressed: () {
              action();
            })
        : null,
  ));
}
