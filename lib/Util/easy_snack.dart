import 'package:flutter/material.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

showSnack(BuildContext context, String message,
    {Function? action, String? actionMessage}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    dismissDirection: DismissDirection.up,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150, left: 10, right: 10),
    action: action != null
        ? SnackBarAction(
            label: actionMessage ?? AppLocalizations.of(context)!.undo,
            onPressed: () {
              action();
            })
        : null,
  ));
}
