import 'package:flutter/material.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

showSnack(BuildContext context, String message,
    {Function? action, String? actionMessage}) {
  showTopSnackBar(
      Overlay.of(context),
      SnackBar(
        content: Text(message),
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).size.height - 100),
        action: action != null
            ? SnackBarAction(
                label: actionMessage ?? AppLocalizations.of(context)!.undo,
                onPressed: () {
                  action();
                })
            : null,
      ));
}
